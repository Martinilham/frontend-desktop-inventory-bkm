import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:inventory_bkm_desktop/services/api_service.dart';
import 'package:inventory_bkm_desktop/widgets/section_card.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

class _ImportedCell {
  const _ImportedCell(this.value);

  final Object? value;
}

class InventoryTransactionScreen extends StatefulWidget {
  const InventoryTransactionScreen({super.key, required this.apiService});
  final ApiService apiService;

  @override
  State<InventoryTransactionScreen> createState() =>
      _InventoryTransactionScreenState();
}

class _InventoryTransactionScreenState
    extends State<InventoryTransactionScreen> {
  late Future<Map<String, dynamic>> _future;
  bool _busy = false;
  String _search = '';
  int _balancePage = 0;
  static const int _balancePageSize = 25;
  final _number = NumberFormat('#,##0.##', 'id_ID');

  @override
  void initState() {
    super.initState();
    _future = widget.apiService.getInventoryTransactions();
  }

  String _cell(dynamic cell) {
    final value = cell is _ImportedCell ? cell.value : cell?.value;
    return value?.toString().trim() ?? '';
  }

  String _header(dynamic value) =>
      _cell(value).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  int _column(List<dynamic> headers, List<String> names) =>
      headers.indexWhere((cell) => names.contains(_header(cell)));
  String _value(List<dynamic> row, int index) =>
      index >= 0 && index < row.length ? _cell(row[index]) : '';
  double _quantity(String input) {
    var normalized = input.trim().replaceAll(RegExp(r'[^0-9,.-]'), '');
    final comma = normalized.lastIndexOf(',');
    final dot = normalized.lastIndexOf('.');
    if (comma >= 0 && dot >= 0) {
      // Treat the last separator as the decimal separator.
      normalized = comma > dot
          ? normalized.replaceAll('.', '').replaceFirst(',', '.')
          : normalized.replaceAll(',', '');
    } else if (comma >= 0) {
      normalized = normalized.replaceFirst(',', '.');
    }
    return double.tryParse(normalized) ?? 0;
  }

  int _valueReportHeader(List<dynamic> rows) => rows.indexWhere((row) {
        final headers = row.map(_header).toList();
        return headers.contains('resource') &&
            headers.contains('reference') &&
            headers.contains('inventoryquantity');
      });

  List<List<dynamic>> _readXlsxRows(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    String readXml(String path) {
      final file = archive.findFile(path);
      if (file == null) {
        throw FormatException('Bagian XLSX "$path" tidak ditemukan.');
      }
      return utf8.decode(file.content as List<int>);
    }

    const mainNs = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
    const officeRelNs =
        'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
    const packageRelNs =
        'http://schemas.openxmlformats.org/package/2006/relationships';

    final workbook = XmlDocument.parse(readXml('xl/workbook.xml'));
    final workbookSheets =
        workbook.findAllElements('sheet', namespace: mainNs).toList();
    if (workbookSheets.isEmpty) {
      throw const FormatException('Workbook tidak memiliki worksheet.');
    }
    final firstSheet = workbookSheets.first;
    final relationshipId =
        firstSheet.getAttribute('id', namespace: officeRelNs);
    if (relationshipId == null) {
      throw const FormatException('Relasi worksheet tidak ditemukan.');
    }

    final relationships =
        XmlDocument.parse(readXml('xl/_rels/workbook.xml.rels'));
    final matchingRelationships = relationships
        .findAllElements('Relationship', namespace: packageRelNs)
        .where((element) => element.getAttribute('Id') == relationshipId)
        .toList();
    final relationship = matchingRelationships.isEmpty
        ? null
        : matchingRelationships.first;
    final target = relationship?.getAttribute('Target');
    if (target == null) {
      throw const FormatException('File worksheet tidak ditemukan.');
    }
    final sheetPath = _resolveZipPath('xl/workbook.xml', target);

    final sharedStrings = <String>[];
    final stringsFile = archive.findFile('xl/sharedStrings.xml');
    if (stringsFile != null) {
      final strings =
          XmlDocument.parse(utf8.decode(stringsFile.content as List<int>));
      for (final item in strings.findAllElements('si', namespace: mainNs)) {
        sharedStrings.add(item
            .findAllElements('t', namespace: mainNs)
            .map((text) => text.innerText)
            .join());
      }
    }

    final sheet = XmlDocument.parse(readXml(sheetPath));
    final rows = <List<dynamic>>[];
    for (final row in sheet.findAllElements('row', namespace: mainNs)) {
      final rowNumber =
          int.tryParse(row.getAttribute('r') ?? '') ?? rows.length + 1;
      while (rows.length < rowNumber) {
        rows.add(<dynamic>[]);
      }
      final cells = row.findAllElements('c', namespace: mainNs).toList();
      var width = 0;
      final columns = <int>[];
      for (final cell in cells) {
        final column = _xlsxColumnIndex(cell.getAttribute('r') ?? '');
        columns.add(column);
        if (column + 1 > width) width = column + 1;
      }
      final values = List<dynamic>.filled(width, null);
      for (var index = 0; index < cells.length; index++) {
        final cell = cells[index];
        final column = columns[index];
        final type = cell.getAttribute('t');
        final valueNodes = cell.findElements('v', namespace: mainNs).toList();
        final valueNode = valueNodes.isEmpty ? null : valueNodes.first;
        Object? value;
        if (type == 'inlineStr') {
          value = cell
              .findAllElements('t', namespace: mainNs)
              .map((text) => text.innerText)
              .join();
        } else if (valueNode != null) {
          final raw = valueNode.innerText;
          if (type == 's') {
            final sharedIndex = int.tryParse(raw);
            value = sharedIndex != null &&
                    sharedIndex >= 0 &&
                    sharedIndex < sharedStrings.length
                ? sharedStrings[sharedIndex]
                : '';
          } else if (type == 'b') {
            value = raw == '1' ? 'TRUE' : 'FALSE';
          } else {
            value = raw;
          }
        }
        values[column] = _ImportedCell(value);
      }
      rows[rowNumber - 1] = values;
    }
    return rows;
  }

  String _resolveZipPath(String baseFile, String target) {
    final parts = <String>[];
    if (!target.startsWith('/')) {
      parts.addAll(baseFile.split('/')..removeLast());
    }
    for (final part in target.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else {
        parts.add(part);
      }
    }
    return parts.join('/');
  }

  int _xlsxColumnIndex(String cellReference) {
    final match = RegExp(r'^([A-Z]+)').firstMatch(cellReference.toUpperCase());
    if (match == null) {
      throw FormatException('Referensi sel tidak valid: $cellReference');
    }
    var column = 0;
    for (final code in match.group(1)!.codeUnits) {
      column = column * 26 + code - 64;
    }
    return column - 1;
  }

  Future<void> _import(bool baseline) async {
    if (_busy) return;
    final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true);
    if (picked == null || picked.files.single.bytes == null) return;
    setState(() => _busy = true);
    try {
      final sourceBytes = picked.files.single.bytes!;
      final isXlsx = sourceBytes.length >= 2 &&
          sourceBytes[0] == 0x50 &&
          sourceBytes[1] == 0x4b;
      final sheetRows = baseline && isXlsx
          ? _readXlsxRows(sourceBytes)
          : (() {
              final workbook = xls.Excel.decodeBytes(sourceBytes);
              if (workbook.tables.isEmpty) {
                throw Exception(
                    'Workbook tidak memiliki worksheet yang dapat dibaca.');
              }
              return workbook.tables.values.first.rows;
            })();
      if (sheetRows.length < 2)
        throw Exception('Workbook tidak memiliki baris data.');
      final reportHeaderRow = baseline ? _valueReportHeader(sheetRows) : -1;
      final isValueReport = reportHeaderRow >= 0;
      final headers = sheetRows[isValueReport ? reportHeaderRow : 0];
      final ix = baseline
          ? {
              'itemNumber': _column(
                  headers, isValueReport ? ['resource'] : ['itemnumber']),
              'productName': _column(headers, ['productname']),
              'warehouse': _column(headers, ['warehouse']),
              'unit': _column(headers, ['inventoryunit', 'unit']),
              'reference': _column(headers, ['reference']),
              'quantity': _column(
                  headers,
                  isValueReport
                      ? ['inventoryquantity']
                      : [
                          'availablephysical',
                          'physicalinventory',
                          'onhand',
                          'quantity'
                        ])
            }
          : {
              'journal': _column(headers, ['number', 'journal']),
              'itemNumber': _column(headers, ['itemnumber']),
              'productName': _column(headers, ['productname']),
              'warehouse': _column(headers, ['warehouse']),
              'site': _column(headers, ['site']),
              'reference': _column(headers, ['reference']),
              'unit': _column(headers, ['unit']),
              'quantity': _column(headers, ['quantity']),
              'expectedDate': _column(headers, ['expecteddate']),
              'physicalDate': _column(headers, ['physicaldate']),
              'issueStatus': _column(headers, ['issuestatus']),
              'receiptStatus': _column(headers, ['receiptstatus'])
            };
      for (final field in (baseline
          ? ['itemNumber', 'quantity', if (isValueReport) 'reference']
          : ['journal', 'itemNumber', 'warehouse', 'quantity'])) {
        if ((ix[field] ?? -1) < 0)
          throw Exception(
              'Kolom "$field" tidak ditemukan. Periksa judul kolom Excel.');
      }
      final rows = <Map<String, dynamic>>[];
      final baselineTotals = <String, Map<String, dynamic>>{};
      var skippedPendingWithoutWarehouse = 0;
      for (final row
          in sheetRows.skip((isValueReport ? reportHeaderRow : 0) + 1)) {
        if (row.every((cell) => _cell(cell).isEmpty)) continue;
        if (baseline &&
            isValueReport &&
            _value(row, ix['reference'] ?? -1)
                    .toLowerCase()
                    .replaceAll(RegExp(r'[^a-z0-9]'), '') !=
                'endingbalance') {
          continue;
        }
          final quantity = _quantity(_value(row, ix['quantity'] ?? -1));
        if (baseline) {
          final itemNumber = _value(row, ix['itemNumber'] ?? -1);
          if (itemNumber.isEmpty) continue;
          final warehouse = _value(row, ix['warehouse'] ?? -1);
          final key = '$itemNumber|$warehouse';
          final item = baselineTotals.putIfAbsent(
              key,
              () => {
                    'itemNumber': itemNumber,
                    'productName': _value(row, ix['productName'] ?? -1),
                    'warehouse': warehouse,
                    'unit': _value(row, ix['unit'] ?? -1),
                    'quantity': 0.0,
                  });
          item['quantity'] = (item['quantity'] as double) + quantity;
        } else {
          final reference = _value(row, ix['reference'] ?? -1);
          final issueStatus =
              _value(row, ix['issueStatus'] ?? -1).toLowerCase().trim();
          final normalizedReference = reference.toLowerCase().trim();
          final receiptStatus =
              _value(row, ix['receiptStatus'] ?? -1).toLowerCase().trim();
          final isReturnedPo = normalizedReference == 'purchase order' &&
              receiptStatus.isEmpty;
          final isUnreceivedPo = normalizedReference == 'purchase order' &&
              receiptStatus.isNotEmpty && receiptStatus != 'received';
          final isPendingTransfer = normalizedReference == 'transfer' &&
              (issueStatus == 'on order' || receiptStatus == 'ordered');
          final isPendingInventoryEvent = isUnreceivedPo || isPendingTransfer;
          final effectiveQuantity = isReturnedPo
              ? -quantity.abs()
              : isPendingInventoryEvent
                  ? 0.0
                  : quantity;
          final warehouse = _value(row, ix['warehouse'] ?? -1);
          if (warehouse.isEmpty && isPendingInventoryEvent) {
            skippedPendingWithoutWarehouse++;
            continue;
          }
          rows.add({
            'journal': _value(row, ix['journal'] ?? -1),
            'itemNumber': _value(row, ix['itemNumber'] ?? -1),
            'productName': _value(row, ix['productName'] ?? -1),
            'warehouse': warehouse,
            'site': _value(row, ix['site'] ?? -1),
            'reference': reference,
            'receiptStatus': _value(row, ix['receiptStatus'] ?? -1).trim(),
            'unit': _value(row, ix['unit'] ?? -1),
            'quantity': quantity,
            'effectiveQuantity': effectiveQuantity,
            'expectedDate': _excelDate(_value(row, ix['expectedDate'] ?? -1)),
            'physicalDate': _excelDate(_value(row, ix['physicalDate'] ?? -1))
          });
        }
      }
      if (baseline) rows.addAll(baselineTotals.values);
      if (rows.isEmpty)
        throw Exception(isValueReport
            ? 'Tidak ada baris Reference = Ending balance.'
            : 'File tidak berisi baris data yang valid.');
      final result = await widget.apiService.importInventorySnapshot(
          baseline ? 'baseline' : 'upload', picked.files.single.name, rows);
      if (!mounted) return;
      setState(() {
        _future = widget.apiService.getInventoryTransactions();
      });
      final skippedMessage = skippedPendingWithoutWarehouse > 0
          ? ' $skippedPendingWithoutWarehouse transaksi pending tanpa Warehouse dilewati.'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${result['message']} ${result['imported']} baris.$skippedMessage')));
    } catch (error, stackTrace) {
      debugPrint('Inventory import failed: $error\n$stackTrace');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Impor gagal: $error'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _transactionCategory(Map<String, dynamic> transaction) {
    final reference = (transaction['reference']?.toString() ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    final quantity = (transaction['effectiveQuantity'] as num?)?.toDouble() ??
        (transaction['quantity'] as num?)?.toDouble() ?? 0;
    if (reference.contains('statement') || reference.contains('salesorder')) {
      return 'Penjualan';
    }
    if (reference == 'transaction') return 'Pembuangan';
    if (reference.contains('purchaseorder') || reference.contains('transfer') || reference == 'to') {
      return quantity < 0 ? 'Retur' : 'Barang Masuk';
    }
    return quantity < 0 ? 'Barang Keluar' : 'Barang Masuk';
  }

  Future<void> _showItemTransactions(Map<String, dynamic> item) async {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Rincian ${item['itemNumber']}'),
        content: SizedBox(
          width: 900,
          height: 520,
          child: FutureBuilder<List<dynamic>>(
            future: widget.apiService.getInventoryItemTransactions(
                '${item['itemNumber']}', '${item['warehouse']}'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Gagal memuat transaksi: ${snapshot.error}'));
              }
              final rows = snapshot.data ?? [];
              if (rows.isEmpty) return const Center(child: Text('Belum ada transaksi untuk item ini.'));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item['productName']} • ${item['warehouse']}'),
                  const SizedBox(height: 12),
                  const Row(children: [
                    Expanded(flex: 2, child: Text('Jurnal', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Reference', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Jenis', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Qty', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Status PO', style: TextStyle(fontWeight: FontWeight.bold))),
                  ]),
                  const Divider(),
                  Expanded(child: ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final tx = Map<String, dynamic>.from(rows[index] as Map);
                      final quantity = (tx['effectiveQuantity'] as num?)?.toDouble() ?? (tx['quantity'] as num?)?.toDouble() ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(children: [
                          Expanded(flex: 2, child: Text('${tx['journal'] ?? '-'}')),
                          Expanded(flex: 2, child: Text('${tx['reference'] ?? '-'}')),
                          Expanded(flex: 2, child: Text(_transactionCategory(tx))),
                          Expanded(child: Text(_number.format(quantity), textAlign: TextAlign.right)),
                          Expanded(child: Text('${tx['receiptStatus'] ?? '-'}')),
                        ]),
                      );
                    },
                  )),
                ],
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Tutup'))],
      ),
    );
  }

  String? _excelDate(String serial) {
    if (serial.isEmpty) return null;
    final value = double.tryParse(serial);
    if (value != null)
      return DateTime.utc(1899, 12, 30)
          .add(Duration(days: value.floor()))
          .toIso8601String();
    final parsed = DateTime.tryParse(serial);
    return parsed?.toIso8601String();
  }

  Future<void> _deleteSnapshot(String dataset) async {
    final isBaseline = dataset == 'baseline';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
            isBaseline ? 'Hapus data Value Report?' : 'Hapus data transaksi?'),
        content: Text(isBaseline
            ? 'Data Value Report yang sedang aktif akan dihapus. Saldo On Hand akan dihitung tanpa saldo awal.'
            : 'Snapshot transaksi yang sedang aktif akan dihapus. Perubahan stok dari transaksi akan hilang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await widget.apiService.deleteInventorySnapshot(dataset);
      if (!mounted) return;
      setState(() {
        _future = widget.apiService.getInventoryTransactions();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                result['message']?.toString() ?? 'Data berhasil dihapus.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Hapus data gagal: $error'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
              child: Text('Gagal memuat inventory: ${snapshot.error}'));
        final data = snapshot.data ?? {};
        final balances = List<Map<String, dynamic>>.from(
            (data['balances'] as List? ?? [])
                .map((e) => Map<String, dynamic>.from(e)));
        final transactions = List<Map<String, dynamic>>.from(
            (data['transactions'] as List? ?? [])
                .map((e) => Map<String, dynamic>.from(e)));
        final visible = balances
            .where((row) =>
                '${row['itemNumber']} ${row['productName']} ${row['warehouse']}'
                    .toLowerCase()
                    .contains(_search.toLowerCase()))
            .toList();
        final pageCount = (visible.length / _balancePageSize).ceil();
        final currentPage =
            pageCount == 0 ? 0 : _balancePage.clamp(0, pageCount - 1).toInt();
        final pageRows = visible
            .skip(currentPage * _balancePageSize)
            .take(_balancePageSize)
            .toList();
        final summary = Map<String, dynamic>.from(data['summary'] ?? {});
        return ListView(padding: const EdgeInsets.only(bottom: 20), children: [
          Row(children: [
            Expanded(
                child: Text('Inventory Transaction',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold))),
            if (_busy)
              const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            OutlinedButton.icon(
                onPressed: _busy ? null : () => _import(true),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Upload Value Report')),
            const SizedBox(width: 10),
            FilledButton.icon(
                onPressed: _busy ? null : () => _import(false),
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Transaksi'))
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _deleteSnapshot('baseline'),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Hapus Data Value Report'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _deleteSnapshot('transactions'),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('Hapus Data Transaksi'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
              'Value + IT (On Hand) = saldo akhir Value Report (Reference: Ending balance) ditambah atau dikurangi total Quantity transaksi aktif. Upload transaksi memakai snapshot terbaru, termasuk koreksi jurnal. Purchase Order menambah saldo saat Receipt Status = Received. Purchase Order dengan Receipt Status kosong dianggap barang retur dan mengurangi saldo Store.'),
          const SizedBox(height: 18),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _metric('Item / lokasi', '${summary['items'] ?? 0}',
                Icons.inventory_2_outlined),
            _metric(
                'Jumlah saldo On Hand',
                _number.format(summary['onHand'] ?? 0),
                Icons.stacked_bar_chart),
            _metric(
                'Baris transaksi aktif',
                '${summary['transactionRows'] ?? 0}',
                Icons.receipt_long_outlined),
          ]),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: SectionCard(
              title: 'Saldo per Item dan Gudang',
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Cari item, nama produk, atau gudang',
                    ),
                    onChanged: (value) => setState(() {
                      _search = value;
                      _balancePage = 0;
                    }),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 470,
                    child: balances.isEmpty
                        ? const Center(
                            child:
                                Text('Upload file Value Report untuk memulai.'),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final tableWidth = constraints.maxWidth < 1540
                                  ? 1540.0
                                  : constraints.maxWidth;
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: tableWidth,
                                  child: Column(
                                    children: [
                                      _balanceRow(const {
                                        'itemNumber': 'Item',
                                        'productName': 'Nama Produk',
                                        'warehouse': 'Gudang',
                                        'openingQuantity': 'Saldo Awal',
                                        'incomingQuantity': 'Barang Masuk',
                                        'outgoingQuantity': 'Barang Keluar',
                                        'resultQuantity': 'Hasil',
                                        'remainingStock': 'Sisa Stok',
                                      }, header: true),
                                      SizedBox(
                                        height: 420,
                                        child: ListView.builder(
                                          itemCount: pageRows.length,
                                          itemBuilder: (context, index) =>
                                              _balanceRow(pageRows[index]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (visible.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                            '${currentPage * _balancePageSize + 1}–${(currentPage * _balancePageSize + pageRows.length)} dari ${visible.length}'),
                        IconButton(
                          tooltip: 'Halaman sebelumnya',
                          onPressed: currentPage > 0
                              ? () =>
                                  setState(() => _balancePage = currentPage - 1)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('${currentPage + 1} / $pageCount'),
                        IconButton(
                          tooltip: 'Halaman berikutnya',
                          onPressed: currentPage + 1 < pageCount
                              ? () =>
                                  setState(() => _balancePage = currentPage + 1)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title:
                '100 Transaksi Terakhir (dari ${summary['transactionRows'] ?? 0})',
            child: SizedBox(
              height: 230,
              child: transactions.isEmpty
                  ? const Center(child: Text('Belum ada transaksi.'))
                  : ListView.separated(
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final row = transactions[index];
                        return ListTile(
                          dense: true,
                          title:
                              Text('${row['journal']}  •  ${row['reference']}'),
                          subtitle: Text(
                              '${row['itemNumber']} ${row['productName']}  •  ${row['warehouse']}'),
                          trailing: Text(
                              '${_number.format(row['quantity'])} ${row['unit']}'),
                        );
                      },
                    ),
            ),
          ),
        ]);
      });

  Widget _metric(String label, String value, IconData icon) => SizedBox(
      width: 220,
      child: SectionCard(
          title: label,
          child: Row(children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
                child: Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)))
          ])));

  Widget _balanceRow(Map<String, dynamic> row, {bool header = false}) {
    final style = TextStyle(
      fontWeight: header ? FontWeight.bold : FontWeight.normal,
      color: header ? Theme.of(context).colorScheme.primary : null,
    );
    Widget cell(String text, {bool numeric = false}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(text,
                textAlign: numeric ? TextAlign.right : TextAlign.left,
                overflow: TextOverflow.ellipsis,
                style: style),
          ),
        );
    return InkWell(
      onTap: header ? null : () => _showItemTransactions(row),
      child: Container(
      height: 42,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(children: [
        cell(header ? 'Item' : '${row['itemNumber']}'),
        Expanded(
            flex: 3,
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(header ? 'Nama Produk' : '${row['productName']}',
                    overflow: TextOverflow.ellipsis, style: style))),
        cell(header ? 'Gudang' : '${row['warehouse']}'),
        cell(header ? 'Saldo Awal' : _number.format(row['openingQuantity'] ?? 0),
            numeric: true),
        cell(header ? 'Barang Masuk' : _number.format(row['incomingQuantity'] ?? 0),
            numeric: true),
        cell(header ? 'Barang Keluar' : _number.format(row['outgoingQuantity'] ?? 0),
            numeric: true),
        cell(header ? 'Hasil' : _number.format(row['resultQuantity'] ?? row['onHand'] ?? 0),
            numeric: true),
        cell(header ? 'Sisa Stok' : _number.format(row['remainingStock'] ?? row['onHand'] ?? 0),
            numeric: true),
      ]),
    ));
  }
}

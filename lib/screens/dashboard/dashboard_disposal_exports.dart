// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, unused_element
part of '../dashboard_screen.dart';

extension DashboardDisposalExports on _DashboardScreenState {
  static const double _pdfScanImageWidth = 500;
  static const double _pdfScanImageHeight = 600;

  Future<void> _exportDisposalPostingDataToExcel(
      List<dynamic> disposals) async {
    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) return;

    final workbook = xls.Excel.createExcel();
    workbook.rename('Sheet1', 'Posting per Jurnal');
    workbook.setDefaultSheet('Posting per Jurnal');
    final sheet = workbook['Posting per Jurnal'];
    const headers = ['Tanggal', 'Divisi', 'Jurnal', 'Status Posting Jurnal'];
    final navy = xls.ExcelColor.fromHexString('#17365D');
    final lightBlue = xls.ExcelColor.fromHexString('#DCE6F1');
    final borderColor = xls.ExcelColor.fromHexString('#D9E2F3');
    final white = xls.ExcelColor.fromHexString('#FFFFFF');
    final green = xls.ExcelColor.fromHexString('#E2F0D9');
    final orange = xls.ExcelColor.fromHexString('#FCE4D6');
    final blue = xls.ExcelColor.fromHexString('#DDEBF7');

    sheet.merge(
        xls.CellIndex.indexByString('A1'), xls.CellIndex.indexByString('D1'));
    sheet.cell(xls.CellIndex.indexByString('A1')).value =
        xls.TextCellValue('RINGKASAN KELAYAKAN POSTING PER JURNAL');
    sheet.cell(xls.CellIndex.indexByString('A1')).cellStyle = xls.CellStyle(
      backgroundColorHex: navy,
      fontColorHex: white,
      bold: true,
      fontSize: 16,
      horizontalAlign: xls.HorizontalAlign.Center,
      verticalAlign: xls.VerticalAlign.Center,
    );
    sheet.setRowHeight(0, 34);
    sheet.merge(
        xls.CellIndex.indexByString('A2'), xls.CellIndex.indexByString('D2'));
    sheet.cell(xls.CellIndex.indexByString('A2')).value = xls.TextCellValue(
      'Purchased/Received dijumlah sampai tanggal jurnal, lalu dikurangi qty jurnal sebelumnya dan jurnal ini. Ordered belum dihitung sebagai stok tersedia.',
    );
    sheet.cell(xls.CellIndex.indexByString('A2')).cellStyle = xls.CellStyle(
      backgroundColorHex: lightBlue,
      fontColorHex: navy,
      italic: true,
      horizontalAlign: xls.HorizontalAlign.Center,
      verticalAlign: xls.VerticalAlign.Center,
      textWrapping: xls.TextWrapping.WrapText,
    );
    sheet.setRowHeight(1, 28);

    for (var column = 0; column < headers.length; column++) {
      final cell = sheet.cell(
          xls.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 3));
      cell.value = xls.TextCellValue(headers[column]);
      cell.cellStyle = xls.CellStyle(
        backgroundColorHex: navy,
        fontColorHex: white,
        bold: true,
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
        textWrapping: xls.TextWrapping.WrapText,
        bottomBorder: xls.Border(
          borderStyle: xls.BorderStyle.Thin,
          borderColorHex: borderColor,
        ),
      );
    }
    sheet.setRowHeight(3, 38);

    String postingLabel(String status) => switch (status) {
          'ready' => 'BISA POSTING',
          'ordered' => 'BELUM BISA POSTING: masih Ordered',
          'insufficient' => 'BELUM BISA POSTING: qty melebihi batas',
          'legacyCombined' =>
            'BELUM BISA POSTING: data lama menggabungkan beberapa jurnal; impor ulang',
          'notApplicable' =>
            'DOKUMENTASI SAJA: tidak ada rincian item untuk pengecekan posting',
          _ => 'BELUM BISA POSTING: Receipt Status belum tersedia',
        };
    final journalRows = <String, Map<String, dynamic>>{};
    for (final raw in disposals) {
      final disposal = Map<String, dynamic>.from(raw as Map);
      final journals = (disposal['journal']?.toString() ?? '')
          .split(',')
          .map((journal) => journal.trim())
          .where((journal) => journal.isNotEmpty)
          .toSet()
          .toList();
      if (journals.isEmpty) journals.add('');
      final items = List<dynamic>.from(disposal['items'] ?? []);
      final statuses = items
          .map((rawItem) =>
              Map<String, dynamic>.from(rawItem as Map)['stockStatus']
                  ?.toString() ??
              'unknown')
          .toList();
      for (final journal in journals) {
        final journalKey = journal.isEmpty
            ? 'NO-JOURNAL:${disposal['_id'] ?? disposal['id'] ?? '${disposal['date']}|${disposal['division']}'}'
            : '${disposal['date']}|${disposal['division']}|${journal.toUpperCase()}';
        final row = journalRows.putIfAbsent(
            journalKey,
            () => {
                  'date': disposal['date']?.toString() ?? '-',
                  'division': disposal['division']?.toString() ?? '-',
                  'journal': journal.isEmpty ? '-' : journal,
                  'statuses': <String>[],
                });
        final journalStatuses = row['statuses'] as List<String>;
        if (journals.length > 1) {
          journalStatuses.add('legacyCombined');
        } else if (statuses.isEmpty) {
          journalStatuses
              .add(disposal['postingStatus']?.toString() ?? 'unknown');
        } else {
          journalStatuses.addAll(statuses);
        }
      }
    }

    var rowIndex = 4;
    for (final row in journalRows.values) {
      final statuses = row['statuses'] as List<String>;
      final status =
          statuses.isNotEmpty && statuses.every((value) => value == 'ready')
              ? 'ready'
              : statuses.isNotEmpty &&
                      statuses.every((value) => value == 'notApplicable')
                  ? 'notApplicable'
                  : statuses.contains('legacyCombined')
                      ? 'legacyCombined'
                      : statuses.contains('unknown')
                          ? 'unknown'
                          : statuses.contains('ordered')
                              ? 'ordered'
                              : 'insufficient';
      final background = switch (status) {
        'ready' => green,
        'ordered' => blue,
        'insufficient' => orange,
        _ => white,
      };
      final values = [
        xls.TextCellValue(row['date'] as String),
        xls.TextCellValue(row['division'] as String),
        xls.TextCellValue(row['journal'] as String),
        xls.TextCellValue(postingLabel(status)),
      ];
      for (var column = 0; column < values.length; column++) {
        final cell = sheet.cell(xls.CellIndex.indexByColumnRow(
            columnIndex: column, rowIndex: rowIndex));
        cell.value = values[column];
        cell.cellStyle = xls.CellStyle(
          backgroundColorHex: background,
          verticalAlign: xls.VerticalAlign.Center,
          horizontalAlign: xls.HorizontalAlign.Left,
          textWrapping: xls.TextWrapping.WrapText,
          bottomBorder: xls.Border(
            borderStyle: xls.BorderStyle.Thin,
            borderColorHex: borderColor,
          ),
        );
      }
      sheet.setRowHeight(rowIndex, 28);
      rowIndex++;
    }
    const widths = [14.0, 20.0, 30.0, 42.0];
    for (var column = 0; column < widths.length; column++) {
      sheet.setColumnWidth(column, widths[column]);
    }

    final bytes = workbook.encode();
    if (bytes == null) return;
    final fileName =
        'data_pembuangan_posting_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    await File('$directoryPath${Platform.pathSeparator}$fileName')
        .writeAsBytes(bytes);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Excel disimpan: $fileName')));
  }

  Future<void> _exportAnalysisToExcel(
    List<Map<String, dynamic>> items,
    String dateFrom,
    String dateTo, {
    String filePrefix = 'analisa_selisih',
  }) async {
    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) return;

    final excel = xls.Excel.createExcel();
    final sheet = excel['Analisa Selisih'];
    excel.setDefaultSheet('Analisa Selisih');
    sheet.appendRow([
      xls.TextCellValue('Tanggal'),
      xls.TextCellValue('Kategori'),
      xls.TextCellValue('Item Number'),
      xls.TextCellValue('Nama Barang'),
      xls.TextCellValue('Unit'),
      xls.TextCellValue('PO/BO/TO IN'),
      xls.TextCellValue('Sales'),
      xls.TextCellValue('Selisih'),
      xls.TextCellValue('Note'),
    ]);

    for (final item in items) {
      sheet.appendRow([
        xls.TextCellValue(item['date']?.toString() ?? '-'),
        xls.TextCellValue(item['group']?.toString() ?? '-'),
        xls.TextCellValue(item['itemNumber']?.toString() ?? '-'),
        xls.TextCellValue(item['itemName']?.toString() ?? '-'),
        xls.TextCellValue(item['unit']?.toString() ?? '-'),
        xls.DoubleCellValue((item['poBoToIn'] as num?)?.toDouble() ?? 0),
        xls.DoubleCellValue((item['sales'] as num?)?.toDouble() ?? 0),
        xls.DoubleCellValue((item['difference'] as num?)?.toDouble() ?? 0),
        xls.TextCellValue(item['note']?.toString() ?? '-'),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) return;
    final fileName =
        '${filePrefix}_${dateFrom}_sd_${dateTo}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('$directoryPath${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Excel disimpan: $fileName')));
  }

  Future<void> _exportAnalysisToPdf(
    List<Map<String, dynamic>> items,
    String dateFrom,
    String dateTo, {
    String title = 'Analisa Selisih Produk Harian',
    String filePrefix = 'analisa_selisih',
  }) async {
    final pdf = pw.Document();
    final rows = items
        .map((item) => [
              item['date']?.toString() ?? '-',
              item['group']?.toString() ?? '-',
              item['itemNumber']?.toString() ?? '-',
              item['itemName']?.toString() ?? '-',
              ((item['poBoToIn'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
              ((item['sales'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
              ((item['difference'] as num?)?.toDouble() ?? 0)
                  .toStringAsFixed(2),
              item['note']?.toString() ?? '-',
            ])
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(title,
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('$dateFrom sampai $dateTo',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Tanggal',
              'Kategori',
              'Item Number',
              'Nama Barang',
              'PO/BO/TO IN',
              'Sales',
              'Selisih',
              'Note'
            ],
            data: rows,
            headerStyle:
                pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    final fileName =
        '${filePrefix}_${dateFrom}_sd_${dateTo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await _savePdfFile(fileName, await pdf.save());
  }

  Future<void> _exportWeeklyDisposalsReport(
    List<dynamic> disposals,
    DateTime periodStart,
    DateTime periodEndExclusive,
  ) async {
    final rows = <List<String>>[];
    var totalQuantity = 0.0;
    var totalCost = 0.0;
    final quantityByDivision = <String, double>{};
    final costByDivision = <String, double>{};

    for (final rawRecord in disposals) {
      final record = Map<String, dynamic>.from(rawRecord as Map);
      final date = record['date']?.toString() ?? '-';
      final division = record['division']?.toString() ?? '-';
      final items = List<dynamic>.from(record['items'] ?? []);
      quantityByDivision.putIfAbsent(division, () => 0);
      costByDivision.putIfAbsent(division, () => 0);
      if (items.isEmpty) {
        rows.add([date, division, '-', 'Belum ada detail item', '0', '0.00']);
        continue;
      }
      for (final rawItem in items) {
        final item = Map<String, dynamic>.from(rawItem as Map);
        final quantity = ((item['quantity'] as num?)?.toDouble() ?? 0).abs();
        final cost = (item['costAmount'] as num?)?.toDouble() ?? 0;
        totalQuantity += quantity;
        totalCost += cost;
        quantityByDivision.update(
          division,
          (value) => value + quantity,
        );
        costByDivision.update(
          division,
          (value) => value + cost,
          ifAbsent: () => cost,
        );
        final itemNumber = item['itemNumber']?.toString() ?? '';
        final productName = item['productName']?.toString() ?? '';
        rows.add([
          date,
          division,
          itemNumber,
          productName,
          NumberFormat('#,##0.##', 'id_ID').format(quantity),
          NumberFormat('#,##0.00', 'id_ID').format(cost),
        ]);
      }
    }

    final dateFrom = DateFormat('dd-MM-yyyy').format(periodStart);
    final dateTo = DateFormat('dd-MM-yyyy')
        .format(periodEndExclusive.subtract(const Duration(days: 1)));
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text(
            'Laporan Pembuangan',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Periode: $dateFrom sampai $dateTo'),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              pw.Text('Total baris item: ${rows.length}'),
              pw.Text(
                  'Total quantity: ${NumberFormat('#,##0.##', 'id_ID').format(totalQuantity)}'),
              pw.Text(
                  'Total Cost Amount: Rp ${NumberFormat('#,##0.00', 'id_ID').format(totalCost)}'),
            ],
          ),
          pw.SizedBox(height: 12),
          if (costByDivision.isNotEmpty) ...[
            pw.Text('Ringkasan Pembuangan per Divisi',
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.TableHelper.fromTextArray(
              headers: const ['Divisi', 'Total Quantity', 'Cost Amount'],
              data: quantityByDivision.entries
                  .map((entry) => [
                        entry.key,
                        NumberFormat('#,##0.##', 'id_ID').format(entry.value),
                        'Rp ${NumberFormat('#,##0.00', 'id_ID').format(costByDivision[entry.key] ?? 0)}',
                      ])
                  .toList(),
              headerStyle:
                  pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 12),
          ],
          pw.TableHelper.fromTextArray(
            headers: const [
              'Tanggal',
              'Divisi',
              'Item Number',
              'Nama Barang',
              'Quantity',
              'Cost Amount',
            ],
            data: rows,
            headerStyle:
                pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    final fileName = 'laporan_pembuangan_${dateFrom}_sd_$dateTo.pdf';
    await _savePdfFile(fileName, await pdf.save());
  }

  Future<void> _exportAnalysisProductsToExcel(
    List<Map<String, dynamic>> products,
    String dateFrom,
    String dateTo, {
    required String group,
    required String filePrefix,
  }) async {
    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) return;

    final excel = xls.Excel.createExcel();
    final sheet = excel['Ringkasan $group'];
    excel.setDefaultSheet('Ringkasan $group');
    sheet.appendRow([
      xls.TextCellValue('Item Number'),
      xls.TextCellValue('Nama Produk'),
      xls.TextCellValue('Unit'),
      xls.TextCellValue('Total Selisih'),
      xls.TextCellValue('Tanggal'),
      xls.TextCellValue('PO/BO/TO IN'),
      xls.TextCellValue('Sales'),
      xls.TextCellValue('Selisih'),
      xls.TextCellValue('Note'),
    ]);

    for (final product in products) {
      final dates = List<Map<String, dynamic>>.from(product['dates'] ?? [])
        ..sort((a, b) => (a['date']?.toString() ?? '')
            .compareTo(b['date']?.toString() ?? ''));
      for (var index = 0; index < dates.length; index++) {
        final item = dates[index];
        sheet.appendRow([
          xls.TextCellValue(
              index == 0 ? product['itemNumber']?.toString() ?? '-' : ''),
          xls.TextCellValue(
              index == 0 ? product['itemName']?.toString() ?? '-' : ''),
          xls.TextCellValue(
              index == 0 ? product['unit']?.toString() ?? '-' : ''),
          index == 0
              ? xls.DoubleCellValue(
                  (product['totalDifference'] as num?)?.toDouble() ?? 0)
              : xls.TextCellValue(''),
          xls.TextCellValue(item['date']?.toString() ?? '-'),
          xls.DoubleCellValue((item['poBoToIn'] as num?)?.toDouble() ?? 0),
          xls.DoubleCellValue((item['sales'] as num?)?.toDouble() ?? 0),
          xls.DoubleCellValue((item['difference'] as num?)?.toDouble() ?? 0),
          xls.TextCellValue(item['note']?.toString() ?? '-'),
        ]);
      }
      sheet.appendRow([]);
    }

    final bytes = excel.encode();
    if (bytes == null) return;
    final fileName =
        '${filePrefix}_${dateFrom}_sd_${dateTo}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('$directoryPath${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Excel disimpan: $fileName')));
  }

  Future<void> _exportAnalysisProductsToPdf(
    List<Map<String, dynamic>> products,
    String dateFrom,
    String dateTo, {
    required String group,
    required String filePrefix,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text('Ringkasan Selisih Kategori $group',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('$dateFrom sampai $dateTo',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 14),
          for (final product in products) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: const PdfColor(0.95, 0.97, 0.99),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${product['itemNumber'] ?? '-'} - ${product['itemName'] ?? '-'}',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Unit ${product['unit'] ?? '-'} | Total selisih ${((product['totalDifference'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Tanggal',
                'PO/BO/TO IN',
                'Sales',
                'Selisih',
                'Note'
              ],
              data: (List<Map<String, dynamic>>.from(product['dates'] ?? [])
                    ..sort((a, b) => (a['date']?.toString() ?? '')
                        .compareTo(b['date']?.toString() ?? '')))
                  .map((item) => [
                        item['date']?.toString() ?? '-',
                        ((item['poBoToIn'] as num?)?.toDouble() ?? 0)
                            .toStringAsFixed(2),
                        ((item['sales'] as num?)?.toDouble() ?? 0)
                            .toStringAsFixed(2),
                        ((item['difference'] as num?)?.toDouble() ?? 0)
                            .toStringAsFixed(2),
                        item['note']?.toString() ?? '-',
                      ])
                  .toList(),
              headerStyle:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );

    final fileName =
        '${filePrefix}_${dateFrom}_sd_${dateTo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await _savePdfFile(fileName, await pdf.save());
  }

  Future<void> _exportFilteredDisposalsToPdf(List<dynamic> disposals) async {
    setState(() => _isExportingPdf = true);
    try {
      final pdf = await _buildPdfDocument(
          disposals.cast<Map<String, dynamic>>().toList());
      final bytes = await pdf.save();
      final fileName =
          'disposal_filtered_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await _savePdfFile(fileName, bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF berhasil disimpan: $fileName')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e')));
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _exportSingleDisposalToPdf(Map<String, dynamic> disposal) async {
    try {
      final pdf = await _buildPdfDocument([disposal]);
      final bytes = await pdf.save();
      final fileName =
          'disposal_${disposal['division'] ?? 'data'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await _savePdfFile(fileName, bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF berhasil disimpan: $fileName')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e')));
    }
  }

  Future<pw.Document> _buildPdfDocument(
      List<Map<String, dynamic>> disposals) async {
    final pdf = pw.Document();
    final papayaLogo = await _loadPdfAssetImage('assets/logos/logo_papaya.png');

    for (var index = 0; index < disposals.length; index++) {
      final disposal = disposals[index];
      final content = await _buildPdfDisposalContent(disposal, index + 1);

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 42),
        footer: (context) => _buildPdfFooter(papayaLogo),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Laporan Data Pembuangan',
                      style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor(0.10, 0.18, 0.30))),
                  pw.SizedBox(height: 4),
                  pw.Text('Data pembuangan dengan dokumentasi lengkap',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColor(0.35, 0.39, 0.45))),
                ],
              ),
              pw.Text('Data ${index + 1} dari ${disposals.length}',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor(0.12, 0.30, 0.55))),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(height: 2, color: const PdfColor(0.10, 0.18, 0.30)),
          pw.SizedBox(height: 14),
          ...content,
        ],
      ));

      final photos = List<String>.from(disposal['photos'] ?? []);
      for (var photoIndex = 0; photoIndex < photos.length; photoIndex++) {
        final photo = await _loadPdfImage(photos[photoIndex]);
        if (photo == null) continue;

        final savedTurns = _photoQuarterTurns[photos[photoIndex]] ??
            _storedPhotoRotation(disposal, photos[photoIndex]);
        final portraitAfterSavedRotation = photo.isPortrait != savedTurns.isOdd;
        final turns = (savedTurns + (portraitAfterSavedRotation ? 1 : 0)) % 4;
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(28),
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        'Foto Pembuangan ${photoIndex + 1} dari ${photos.length}',
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        '${disposal['division'] ?? '-'} - ${disposal['date'] ?? '-'}',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Expanded(
                  child: pw.Center(
                    child: _rotatedPdfImage(
                      photo.image,
                      turns,
                      width: PdfPageFormat.a4.landscape.width - 56,
                      height: PdfPageFormat.a4.landscape.height - 96,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return pdf;
  }

  pw.Widget _buildPdfFooter(pw.MemoryImage? papayaLogo) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          if (papayaLogo != null)
            pw.Image(papayaLogo, width: 44, fit: pw.BoxFit.contain)
          else
            pw.Text('papaya',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor(0.40, 0.62, 0.28))),
          pw.SizedBox(height: 2),
          pw.Text(
            'COPYRIGHT ${DateTime.now().year} EDP MELAWAI-PAPAYA FRESH GALLERY',
            style: const pw.TextStyle(
                fontSize: 7, color: PdfColor(0.25, 0.36, 0.28)),
          ),
        ],
      ),
    );
  }

  Future<List<pw.Widget>> _buildPdfDisposalContent(
      Map<String, dynamic> disposal, int number) async {
    final summaryCard = await _buildPdfDisposalCard(disposal, number);
    final movementItems = List<dynamic>.from(disposal['items'] ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final scannedPdfs = List<String>.from(
      disposal['scannedPdfs'] ??
          (disposal['scannedPdf'] == null
              ? <String>[]
              : [disposal['scannedPdf'].toString()]),
    );
    final scannedPages = <pw.MemoryImage>[];
    for (final scannedPdf in scannedPdfs) {
      scannedPages.addAll(await _loadScannedPdfPageImages(scannedPdf));
    }

    return [
      summaryCard,
      pw.SizedBox(height: 14),
      _pdfSectionTitle('Data Movement (${movementItems.length} item)'),
      pw.SizedBox(height: 8),
      if (movementItems.isEmpty)
        pw.Text(
          'Belum ada data Movement untuk data pembuangan ini.',
          style: const pw.TextStyle(
              fontSize: 10, color: PdfColor(0.45, 0.49, 0.55)),
        )
      else
        pw.TableHelper.fromTextArray(
          headers: const [
            'No.',
            'Item Number',
            'Product Name',
            'Quantity',
            'Offset Account',
          ],
          data: [
            for (var itemIndex = 0;
                itemIndex < movementItems.length;
                itemIndex++)
              [
                '${itemIndex + 1}',
                movementItems[itemIndex]['itemNumber']?.toString() ?? '-',
                movementItems[itemIndex]['productName']?.toString() ?? '-',
                movementItems[itemIndex]['quantity']?.toString() ?? '-',
                movementItems[itemIndex]['offsetAccount']?.toString() ?? '-',
              ],
          ],
          border: pw.TableBorder.all(
              color: const PdfColor(0.82, 0.85, 0.89), width: 0.6),
          headerDecoration:
              const pw.BoxDecoration(color: PdfColor(0.91, 0.95, 1.00)),
          headerStyle: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor(0.10, 0.18, 0.30),
          ),
          cellStyle: const pw.TextStyle(
              fontSize: 7.5, color: PdfColor(0.20, 0.24, 0.30)),
          cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          cellAlignment: pw.Alignment.centerLeft,
          columnWidths: const {
            0: pw.FixedColumnWidth(28),
            1: pw.FlexColumnWidth(1.15),
            2: pw.FlexColumnWidth(2.4),
            3: pw.FlexColumnWidth(0.9),
            4: pw.FlexColumnWidth(1.2),
          },
        ),
      if (scannedPdfs.isNotEmpty) ...[
        if (scannedPages.isNotEmpty) pw.NewPage(),
        _pdfSectionTitle('Preview Scan PDF'),
        pw.SizedBox(height: 8),
        if (scannedPages.isEmpty)
          pw.Text('PDF scan tidak dapat dirender ke laporan.',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColor(0.45, 0.49, 0.55)))
        else
          for (var pageIndex = 0; pageIndex < scannedPages.length; pageIndex++)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: const PdfColor(0.86, 0.88, 0.9)),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Halaman Scan ${pageIndex + 1}',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor(0.35, 0.39, 0.45))),
                  pw.SizedBox(height: 6),
                  pw.Center(
                    child: pw.SizedBox(
                      width: _pdfScanImageWidth,
                      height: _pdfScanImageHeight,
                      child: pw.Image(
                        scannedPages[pageIndex],
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
      pw.SizedBox(height: 8),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
            'Dicetak ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColor(0.45, 0.49, 0.55))),
      ),
    ];
  }

  Future<pw.MemoryImage?> _loadPdfAssetImage(String assetPath) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<pw.Widget> _buildPdfDisposalCard(
      Map<String, dynamic> disposal, int number) async {
    final photos = List<String>.from(disposal['photos'] ?? []);

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: const PdfColor(1, 1, 1),
        border: pw.Border.all(color: const PdfColor(0.84, 0.87, 0.91)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Data Pembuangan #$number',
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor(0.10, 0.18, 0.30))),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: const PdfColor(0.91, 0.95, 1.00),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(20)),
                ),
                child: pw.Text(disposal['division']?.toString() ?? '-',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor(0.12, 0.30, 0.55))),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: const PdfColor(0.97, 0.98, 0.99),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                _pdfTextRow('Tanggal', disposal['date']?.toString() ?? '-'),
                _pdfTextRow(
                    'Jurnal',
                    (disposal['journal']?.toString() ?? '').trim().isEmpty
                        ? '-'
                        : disposal['journal'].toString()),
                _pdfTextRow(
                    'Uploaded By', disposal['uploadedBy']?.toString() ?? '-'),
                _pdfTextRow(
                    'Created At', disposal['createdAt']?.toString() ?? '-'),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          _pdfSectionTitle('Foto Dokumentasi'),
          pw.SizedBox(height: 8),
          pw.Text(
            photos.isEmpty
                ? 'Tidak ada foto dokumentasi.'
                : '${photos.length} foto dokumentasi. Setiap foto dicetak pada halaman landscape tersendiri.',
            style: const pw.TextStyle(
                fontSize: 10, color: PdfColor(0.35, 0.39, 0.45)),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Text(title,
        style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
            color: const PdfColor(0.10, 0.18, 0.30)));
  }

  pw.Widget _pdfTextRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 88,
            child: pw.Text('$label:',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    color: const PdfColor(0.20, 0.24, 0.30))),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColor(0.20, 0.24, 0.30))),
          ),
        ],
      ),
    );
  }

  Future<List<pw.MemoryImage>> _loadScannedPdfPageImages(
      String relativePath) async {
    if (relativePath.trim().isEmpty) return [];
    try {
      final bytes = await _loadNetworkFile(_storageUrl(relativePath));
      final pages = <pw.MemoryImage>[];
      await for (final page in Printing.raster(bytes, dpi: 90)) {
        pages.add(pw.MemoryImage(await page.toPng()));
      }
      return pages;
    } catch (_) {
      return [];
    }
  }

  Future<({pw.MemoryImage image, bool isPortrait})?> _loadPdfImage(
      String relativePath) async {
    try {
      final response = await http.get(Uri.parse(_storageUrl(relativePath)));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }
      final codec = await ui.instantiateImageCodec(response.bodyBytes);
      final frame = await codec.getNextFrame();
      final isPortrait = frame.image.height > frame.image.width;
      frame.image.dispose();
      codec.dispose();
      return (
        image: pw.MemoryImage(response.bodyBytes),
        isPortrait: isPortrait
      );
    } catch (_) {
      return null;
    }
  }

  pw.Widget _rotatedPdfImage(
    pw.MemoryImage image,
    int quarterTurns, {
    required double width,
    required double height,
  }) {
    final normalizedTurns = quarterTurns % 4;
    final picture = pw.SizedBox(
      width: normalizedTurns.isOdd ? height : width,
      height: normalizedTurns.isOdd ? width : height,
      child: pw.Image(image, fit: pw.BoxFit.contain),
    );
    if (normalizedTurns == 0) return picture;
    return pw.Center(
      child: pw.Transform.rotate(
        angle: normalizedTurns * math.pi / 2,
        child: picture,
      ),
    );
  }

  Future<String?> _chooseExportDirectory() async {
    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Penyimpanan dibatalkan.')));
      return null;
    }
    return directoryPath;
  }

  Future<void> _savePdfFile(String fileName, Uint8List bytes) async {
    final directoryPath = await _chooseExportDirectory();
    if (directoryPath == null) return;
    final file = File('$directoryPath/$fileName');
    await file.writeAsBytes(bytes);
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF disimpan di: $directoryPath')));
  }

  Future<void> _confirmDeleteDisposal(Map<String, dynamic> disposal) async {
    final id = disposal['id']?.toString() ?? disposal['_id']?.toString();
    if (id == null || id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data disposal tidak memiliki ID.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF17212B).withOpacity(0.46),
      builder: (context) => DesktopModalShell(
        title: 'Hapus Disposal',
        subtitle: 'Data yang sudah dihapus tidak bisa dikembalikan.',
        icon: Icons.delete_outline,
        maxWidth: 430,
        child: const Text(
          'Apakah Anda yakin ingin menghapus data pembuangan ini?',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5484D),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus')),
        ],
      ),
    );

    if (confirmed != true) return;
    await _deleteDisposal(id);
  }

  Future<void> _deleteDisposal(String id) async {
    try {
      await widget.apiService.deleteDisposal(id);
      if (!mounted) return;
      Navigator.of(context).pop();
      await _showActionPopup(
          title: 'Berhasil', message: 'Data disposal berhasil dihapus.');
      if (!mounted) return;
      await _refreshDashboard();
    } catch (e) {
      if (!mounted) return;
      await _showActionPopup(
          title: 'Hapus Gagal',
          message: 'Gagal menghapus data: $e',
          success: false);
    }
  }

  Future<void> _printDisposal(Map<String, dynamic> disposal) async {
    try {
      final pdf = await _buildPdfDocument([disposal]);
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'disposal_print_${disposal['division'] ?? 'data'}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka dialog printer: $e')));
    }
  }
}

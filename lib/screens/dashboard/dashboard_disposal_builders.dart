// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, unused_element
part of '../dashboard_screen.dart';

extension DashboardDisposalBuilders on _DashboardScreenState {
  List<dynamic> _addDisposalStockStatus(
      List<dynamic> disposals,
      List<dynamic> inventoryBalances,
      List<dynamic> receiptHistory) {
    final stockByItem = <String, double>{};
    final stockByItemWarehouse = <String, double>{};
    final receiptByItem = <String, List<Map<String, dynamic>>>{};
    for (final rawReceipt in receiptHistory) {
      final receipt = Map<String, dynamic>.from(rawReceipt as Map);
      final itemNumber =
          receipt['itemNumber']?.toString().trim().toUpperCase() ?? '';
      if (itemNumber.isEmpty) continue;
      receiptByItem.putIfAbsent(itemNumber, () => []).add(receipt);
    }
    for (final rawBalance in inventoryBalances) {
      final balance = Map<String, dynamic>.from(rawBalance as Map);
      final itemNumber = balance['itemNumber']?.toString().trim().toUpperCase();
      if (itemNumber == null || itemNumber.isEmpty) continue;
      final warehouse =
          balance['warehouse']?.toString().trim().toUpperCase() ?? '';
      final openingQuantity =
          (balance['openingQuantity'] as num?)?.toDouble() ??
              double.tryParse(balance['openingQuantity']?.toString() ?? '') ??
              0;
      // Disposal availability starts with the prior Value Report. Purchased
      // receipts from the transaction history are added regardless of date.
      final quantity = openingQuantity;
      stockByItem.update(itemNumber, (value) => value + quantity,
          ifAbsent: () => quantity);
      if (warehouse.isNotEmpty) {
        final key = '$itemNumber|$warehouse';
        stockByItemWarehouse.update(key, (value) => value + quantity,
            ifAbsent: () => quantity);
      }
    }

    final disposalMaps = disposals
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    final calculatedItems = <String, List<Map<String, dynamic>>>{};
    for (final disposal in disposalMaps) {
      final items = List<Map<String, dynamic>>.from(
        (disposal['items'] as List? ?? []).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
      if (items.isEmpty) {
        calculatedItems[disposal['_id']?.toString() ?? disposal['id']?.toString() ?? '${disposal['date']}|${disposal['division']}'] = [];
        continue;
      }

      // Compare against this journal only. Other disposal journals must not
      // reduce the remaining quantity shown for the current journal.
      final disposedByItem = <String, double>{};
      double purchasedInventory(String itemNumber, String warehouse) {
        var quantity = 0.0;
        for (final receipt in receiptByItem[itemNumber] ?? const []) {
          final receiptWarehouse =
              receipt['warehouse']?.toString().trim().toUpperCase() ?? '';
          if (warehouse.isNotEmpty &&
              receiptWarehouse.isNotEmpty &&
              warehouse != receiptWarehouse) {
            continue;
          }
          final receiptQuantity =
              (receipt['quantity'] as num?)?.toDouble() ?? 0;
          if (receiptQuantity > 0) quantity += receiptQuantity;
        }
        return quantity;
      }
      for (final item in items) {
        final itemNumber =
            item['itemNumber']?.toString().trim().toUpperCase() ?? '';
        final quantity = (item['quantity'] as num?)?.toDouble() ??
            double.tryParse(item['quantity']?.toString() ?? '') ??
            0;
        if (itemNumber.isEmpty) continue;
        disposedByItem.update(itemNumber, (value) => value + quantity.abs(),
            ifAbsent: () => quantity.abs());
      }

      final requiredByKey = <String, double>{};
      for (final item in items) {
        final itemNumber =
            item['itemNumber']?.toString().trim().toUpperCase() ?? '';
        final warehouse =
            item['warehouse']?.toString().trim().toUpperCase() ?? '';
        if (itemNumber.isEmpty) continue;
        final key = warehouse.isEmpty ? itemNumber : '$itemNumber|$warehouse';
        final quantity = (item['quantity'] as num?)?.toDouble() ??
            double.tryParse(item['quantity']?.toString() ?? '') ??
            0;
        requiredByKey.update(key, (value) => value + quantity.abs(),
            ifAbsent: () => quantity.abs());
      }

      final stockCheckByKey = <String, Map<String, dynamic>>{};
      for (final entry in requiredByKey.entries) {
        final key = entry.key;
        final itemNumber = key.split('|').first;
        final baseAvailable = key.contains('|')
            ? (stockByItemWarehouse[key] ?? 0)
            : (stockByItem[itemNumber] ?? 0);
        final warehouse = key.contains('|') ? key.split('|').skip(1).join('|') : '';
        final available = baseAvailable + purchasedInventory(itemNumber, warehouse);
        stockCheckByKey[key] = {
          'inventoryQuantity': available,
          'requiredQuantity': entry.value,
          'stockSufficient': available + 1e-9 >= entry.value,
        };
      }

      final checkedItems = items.map((item) {
        final itemNumber =
            item['itemNumber']?.toString().trim().toUpperCase() ?? '';
        final warehouse =
            item['warehouse']?.toString().trim().toUpperCase() ?? '';
        final key = itemNumber.isEmpty
            ? ''
            : warehouse.isEmpty
                ? itemNumber
                : '$itemNumber|$warehouse';
        final check = stockCheckByKey[key];
        final itemKey = itemNumber;
        var purchased = 0.0;
        var ordered = 0.0;
        var receiptDataFound = false;
        for (final receipt in receiptByItem[itemKey] ?? const []) {
          final receiptWarehouse =
              receipt['warehouse']?.toString().trim().toUpperCase() ?? '';
          if (warehouse.isNotEmpty &&
              receiptWarehouse.isNotEmpty &&
              warehouse != receiptWarehouse) {
            continue;
          }
          final receiptStatus =
              receipt['receiptStatus']?.toString().toLowerCase().trim() ?? '';
          final receiptQuantity =
              (receipt['quantity'] as num?)?.toDouble() ?? 0;
          if (receiptStatus == 'ordered') {
            receiptDataFound = true;
            ordered += receiptQuantity.abs();
          }
          if (receiptQuantity > 0) {
            receiptDataFound = true;
            purchased += receiptQuantity;
          }
        }
        final disposedInJournal = disposedByItem[itemKey] ?? 0;
        final remaining = receiptDataFound
            ? purchased - disposedInJournal
            : null;
        final isEligible = remaining != null && remaining >= -1e-9;
        return {
          ...item,
          'inventoryQuantity': check?['inventoryQuantity'],
          'requiredQuantity': check?['requiredQuantity'],
          'stockSufficient': check?['stockSufficient'] == true,
          'purchasedQuantity': receiptDataFound
              ? purchased
              : null,
          'orderedQuantity': ordered,
          'remainingQuantity': remaining,
          'stockStatus': !receiptDataFound
              ? 'unknown'
              : purchased <= 0 && ordered > 0
                  ? 'ordered'
              : isEligible
                  ? 'ready'
                  : 'insufficient',
          'canPost': isEligible,
        };
      }).toList();
      final key = disposal['_id']?.toString() ?? disposal['id']?.toString() ?? '${disposal['date']}|${disposal['division']}';
      calculatedItems[key] = checkedItems;
    }
    return disposalMaps.map((disposal) {
      final key = disposal['_id']?.toString() ?? disposal['id']?.toString() ?? '${disposal['date']}|${disposal['division']}';
      final items = calculatedItems[key] ?? [];
      final canPost = items.isNotEmpty && items.every((item) => item['canPost'] == true);
      return {
        ...disposal,
        'items': items,
        'postingStatus': items.any((item) => item['stockStatus'] == 'unknown')
            ? 'unknown'
            : items.any((item) => item['stockStatus'] == 'ordered')
                ? 'ordered'
                : canPost ? 'ready' : 'insufficient',
      };
    }).toList();
  }

  Widget _disposalPostingStatusBadge(Map<String, dynamic> record) {
    final status = record['postingStatus']?.toString() ?? 'unknown';
    final (label, color, icon) = switch (status) {
      'ready' => ('Siap posting', Colors.green, Icons.check_circle_outline),
      'ordered' => ('Masih Ordered', Colors.blueGrey, Icons.schedule_outlined),
      'insufficient' => (
          'Qty melebihi batas',
          Colors.orange.shade800,
          Icons.warning_amber_rounded
        ),
      _ => ('Stok belum tersedia', Colors.grey, Icons.help_outline),
    };
    final explanation = switch (status) {
      'insufficient' =>
        'Qty dibuang melebihi jumlah Purchased/Received yang tersedia.',
      'ordered' => 'Barang masih berstatus Ordered dan belum bisa diposting.',
      'ready' => 'Qty pembuangan masih dalam batas Purchased/Received.',
      _ => 'Data Receipt Status inventory belum tersedia.',
    };
    return Tooltip(
      message: explanation,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importDisposalExcel() async {
    if (_isImportingDisposals || _isManagingDisposalImports) return;
    setState(() => _isImportingDisposals = true);
    try {
      final selected = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xlsm'],
        dialogTitle: 'Pilih Excel Data Pembuangan',
      );
      final path = selected?.files.single.path;
      if (path == null || !mounted) return;
      final result = await widget.apiService.importDisposals(path);
      if (!mounted) return;
      setState(() => _dashboardFuture = _loadDashboardData());
      final conflicts = List<dynamic>.from(result['conflicts'] ?? []);
      await _showActionPopup(
        title: conflicts.isEmpty
            ? 'Impor Selesai'
            : 'Impor Selesai dengan Catatan',
        message: '${result['created']} data baru, '
            '${result['updated']} data dilengkapi, '
            '${result['skipped']} data dilewati.\n'
            '${result['importedItems']} item tersimpan. '
            '${result['ignoredRows']} baris selain IPROD_MW diabaikan.\n'
            'Foto dan PDF dapat ditambahkan melalui Edit.'
            '${conflicts.isEmpty ? '' : '\n\n${conflicts.join('\n')}'}',
      );
    } catch (error) {
      if (!mounted) return;
      if (error is AuthException) {
        await widget.onLogout();
        return;
      }
      // Also refresh if the server saved some groups before a connection error.
      setState(() => _dashboardFuture = _loadDashboardData());
      await _showActionPopup(
          title: 'Impor Gagal', message: error.toString(), success: false);
    } finally {
      if (mounted) setState(() => _isImportingDisposals = false);
    }
  }

  Widget _buildDataPanel(
      BuildContext context,
      List<dynamic> disposals,
      List<dynamic> users,
      List<dynamic> audits,
      List<dynamic> files,
      Color backgroundColor) {
    return Column(
      children: [
        SectionCard(
          title: 'Import Excel Pembuangan',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data IPROD_MW dikelompokkan berdasarkan Date dan '
                  'Offset account: 501 F&V, 502 FISH, 503 MEAT, 504 SOZAI. '
                  'SOZAI (SISA PRODUKSI) dipisahkan dari Description. '
                  'Cost Amount dari Excel dijumlahkan per item dan data pembuangan.'),
              const SizedBox(height: 8),
              const Text('Tanggal dan kategori baru dibuat otomatis. Data lama '
                  'tanpa item dilengkapi; data yang sudah berisi item dilewati. '
                  'Foto dan PDF bisa menyusul melalui Edit.'),
              const SizedBox(height: 16),
              PrimaryButton(
                label: _isImportingDisposals ? 'Mengimpor...' : 'Import Excel',
                leading: const Icon(Icons.upload_file_outlined),
                isLoading: _isImportingDisposals,
                onPressed: _isImportingDisposals || _isManagingDisposalImports
                    ? null
                    : _importDisposalExcel,
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 12, runSpacing: 12, children: [
                OutlinedButton.icon(
                  onPressed: _isImportingDisposals || _isManagingDisposalImports
                      ? null
                      : () => _deleteImportedJournals(disposals),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Hapus Hasil Impor'),
                ),
                OutlinedButton.icon(
                  onPressed: _isImportingDisposals || _isManagingDisposalImports
                      ? null
                      : _uploadDisposalPdfFolder,
                  icon: const Icon(Icons.drive_folder_upload_outlined),
                  label: const Text('Upload Folder Scan PDF'),
                ),
              ]),
              if (_disposalFolderProgress.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_disposalFolderProgress),
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        SectionCard(
          title: 'Upload Data',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 16, runSpacing: 16, children: [
                _metricCard('Disposal', disposals.length.toString(),
                    Icons.inventory_2_outlined),
                _metricCard(
                    'Pengguna', users.length.toString(), Icons.group_outlined),
                _metricCard(
                    'Audit', audits.length.toString(), Icons.history_outlined),
                _metricCard('File', files.length.toString(),
                    Icons.folder_open_outlined),
              ]),
              const SizedBox(height: 24),
              _buildDisposalPanel(disposals.take(4).toList()),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildUploadPanel(),
      ],
    );
  }

  Widget _buildAnalysisCard(List<dynamic> disposals) {
    final filteredDisposals = _filterAnalysisTrendDisposals(disposals);
    final counts = _buildDivisionDisposalCounts(filteredDisposals);
    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    return SectionCard(
      title: 'Analisa Tren',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _analysisSummaryPill(
                  'Total Pembuangan', total.toString(), Icons.delete_outline),
              _analysisSummaryPill(
                'Divisi Aktif',
                counts.values.where((value) => value > 0).length.toString(),
                Icons.storefront_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildAnalysisTrendFilters(),
          const SizedBox(height: 18),
          if (total == 0)
            Container(
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.tableHeader,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Text('Belum ada data pembuangan.'),
            )
          else
            SizedBox(
              height: 230,
              child: _buildDivisionTrendChart(counts),
            ),
        ],
      ),
    );
  }

  Widget _buildDisposalTrendComparison(List<dynamic> disposals) {
    final anchor = _disposalComparisonDate;
    final today = DateTime(anchor.year, anchor.month, anchor.day);
    final defaultCurrentStart =
        _disposalComparisonPeriod == DisposalComparisonPeriod.weekly
            ? today.subtract(Duration(days: today.weekday - 1))
            : DateTime(today.year, today.month);
    final defaultCurrentEnd =
        _disposalComparisonPeriod == DisposalComparisonPeriod.weekly
            ? defaultCurrentStart.add(const Duration(days: 7))
            : DateTime(defaultCurrentStart.year, defaultCurrentStart.month + 1);
    final defaultPreviousStart =
        _disposalComparisonPeriod == DisposalComparisonPeriod.weekly
            ? defaultCurrentStart.subtract(const Duration(days: 7))
            : DateTime(defaultCurrentStart.year, defaultCurrentStart.month - 1);
    final defaultPreviousEnd = defaultCurrentStart;
    final customCurrentRange = _customCurrentDisposalRange ??
        DateTimeRange(
          start: defaultCurrentStart,
          end: defaultCurrentEnd.subtract(const Duration(days: 1)),
        );
    final customPreviousRange = _customPreviousDisposalRange ??
        DateTimeRange(
          start: defaultPreviousStart,
          end: defaultPreviousEnd.subtract(const Duration(days: 1)),
        );
    final currentStart =
        _disposalComparisonMode == DisposalComparisonMode.custom
            ? customCurrentRange.start
            : defaultCurrentStart;
    final currentEndExclusive =
        _disposalComparisonMode == DisposalComparisonMode.custom
            ? customCurrentRange.end.add(const Duration(days: 1))
            : defaultCurrentEnd;
    final previousStart =
        _disposalComparisonMode == DisposalComparisonMode.custom
            ? customPreviousRange.start
            : defaultPreviousStart;
    final previousEndExclusive =
        _disposalComparisonMode == DisposalComparisonMode.custom
            ? customPreviousRange.end.add(const Duration(days: 1))
            : defaultPreviousEnd;
    final periodLabel =
        _disposalComparisonPeriod == DisposalComparisonPeriod.weekly
            ? 'Minggu'
            : 'Bulan';
    String dateRange(DateTime start, DateTime end) {
      return '${DateFormat('dd MMM').format(start)} - '
          '${DateFormat('dd MMM yyyy').format(end.subtract(const Duration(days: 1)))}';
    }

    final currentLabel = _disposalComparisonMode ==
            DisposalComparisonMode.custom
        ? 'Rentang A (${dateRange(currentStart, currentEndExclusive)})'
        : '$periodLabel ini (${dateRange(currentStart, currentEndExclusive)})';
    final previousLabel = _disposalComparisonMode ==
            DisposalComparisonMode.custom
        ? 'Rentang B (${dateRange(previousStart, previousEndExclusive)})'
        : '$periodLabel sebelumnya (${dateRange(previousStart, previousEndExclusive)})';
    final currentDisposals =
        _disposalsInDateRange(disposals, currentStart, currentEndExclusive);
    final previousDisposals =
        _disposalsInDateRange(disposals, previousStart, previousEndExclusive);
    final now = DateTime.now();
    final currentWeekStart = DateTime(now.year, now.month, now.day).subtract(
      Duration(days: DateTime(now.year, now.month, now.day).weekday - 1),
    );
    final defaultWeekEnd = currentWeekStart.add(const Duration(days: 7));
    final weeklyRange = _weeklyDisposalDateRange ??
        DateTimeRange(
          start: currentWeekStart,
          end: defaultWeekEnd.subtract(const Duration(days: 1)),
        );
    final disposalPeriodStart = weeklyRange.start;
    final disposalPeriodEndExclusive =
        weeklyRange.end.add(const Duration(days: 1));
    final periodDisposals = _disposalsInDateRange(
      disposals,
      disposalPeriodStart,
      disposalPeriodEndExclusive,
    );
    final periodRows = _weeklyDisposalRows(periodDisposals);
    final periodTotalPages = periodRows.isEmpty
        ? 1
        : (periodRows.length / _weeklyDisposalRowsPerPage).ceil();
    final periodPage =
        _weeklyDisposalPage.clamp(0, periodTotalPages - 1).toInt();
    if (periodPage != _weeklyDisposalPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _weeklyDisposalPage = periodPage);
      });
    }
    final periodStartIndex = periodPage * _weeklyDisposalRowsPerPage;
    final visiblePeriodRows = periodRows
        .skip(periodStartIndex)
        .take(_weeklyDisposalRowsPerPage)
        .toList();
    final numberFormat = NumberFormat('#,##0.##', 'id_ID');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 2,
    );

    final itemTotals =
        <String, ({String name, double current, double previous})>{};
    void collectItems(List<dynamic> records, bool current) {
      for (final raw in records) {
        final record = Map<String, dynamic>.from(raw as Map);
        for (final rawItem in List<dynamic>.from(record['items'] ?? [])) {
          final item = Map<String, dynamic>.from(rawItem as Map);
          final itemNumber = item['itemNumber']?.toString().trim() ?? '';
          final productName = item['productName']?.toString().trim() ?? '';
          final key = itemNumber.isNotEmpty
              ? itemNumber.toLowerCase()
              : productName.toLowerCase();
          if (key.isEmpty) continue;
          final total = itemTotals.putIfAbsent(
            key,
            () => (
              name: itemNumber.isEmpty
                  ? productName
                  : '$itemNumber - $productName',
              current: 0,
              previous: 0,
            ),
          );
          final quantity = ((item['quantity'] as num?)?.toDouble() ?? 0).abs();
          itemTotals[key] = current
              ? (
                  name: total.name,
                  current: total.current + quantity,
                  previous: total.previous
                )
              : (
                  name: total.name,
                  current: total.current,
                  previous: total.previous + quantity
                );
        }
      }
    }

    collectItems(currentDisposals, true);
    collectItems(previousDisposals, false);
    final topItems = itemTotals.entries
        .map((entry) => (
              label: entry.key,
              title: entry.value.name,
              current: entry.value.current,
              previous: entry.value.previous,
            ))
        .where((item) => item.current > 0)
        .toList()
      ..sort((a, b) => b.current.compareTo(a.current));
    final topItemComparisons = topItems.take(8).toList();

    final divisions = <String>[
      'SOZAI',
      'SOZAI (SISA PRODUKSI)',
      'F&V',
      'FISH',
      'MEAT',
      'GROCERY',
    ];
    final costComparisons = divisions.map((division) {
      double sumCost(List<dynamic> records) => records
          .where((record) =>
              (record as Map)['division']?.toString().toUpperCase() == division)
          .fold<double>(
            0,
            (total, record) =>
                total +
                _disposalRecordCost(Map<String, dynamic>.from(record as Map)),
          );
      return (
        label: _divisionChartLabel(division).replaceAll('\n', ' '),
        title: _divisionDisplayLabel(division),
        current: sumCost(currentDisposals),
        previous: sumCost(previousDisposals),
      );
    }).toList();
    final currentQuantity = _disposalsQuantity(currentDisposals);
    final previousQuantity = _disposalsQuantity(previousDisposals);
    final currentCost = currentDisposals.fold<double>(
      0,
      (total, record) =>
          total + _disposalRecordCost(Map<String, dynamic>.from(record as Map)),
    );
    final previousCost = previousDisposals.fold<double>(
      0,
      (total, record) =>
          total + _disposalRecordCost(Map<String, dynamic>.from(record as Map)),
    );

    return SectionCard(
      title: 'Perbandingan Tren Pembuangan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<DisposalComparisonMode>(
                segments: const [
                  ButtonSegment(
                    value: DisposalComparisonMode.defaultPeriod,
                    icon: Icon(Icons.auto_awesome_outlined),
                    label: Text('Default'),
                  ),
                  ButtonSegment(
                    value: DisposalComparisonMode.custom,
                    icon: Icon(Icons.tune_outlined),
                    label: Text('Custom'),
                  ),
                ],
                selected: {_disposalComparisonMode},
                onSelectionChanged: (selection) =>
                    setState(() => _disposalComparisonMode = selection.first),
              ),
              if (_disposalComparisonMode ==
                  DisposalComparisonMode.defaultPeriod)
                SegmentedButton<DisposalComparisonPeriod>(
                  segments: const [
                    ButtonSegment(
                      value: DisposalComparisonPeriod.weekly,
                      icon: Icon(Icons.date_range_outlined),
                      label: Text('Mingguan'),
                    ),
                    ButtonSegment(
                      value: DisposalComparisonPeriod.monthly,
                      icon: Icon(Icons.calendar_month_outlined),
                      label: Text('Bulanan'),
                    ),
                  ],
                  selected: {_disposalComparisonPeriod},
                  onSelectionChanged: (selection) => setState(
                      () => _disposalComparisonPeriod = selection.first),
                ),
              if (_disposalComparisonMode ==
                  DisposalComparisonMode.defaultPeriod)
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _disposalComparisonDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                    );
                    if (picked != null) {
                      setState(() => _disposalComparisonDate = picked);
                    }
                  },
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                      'Tanggal acuan: ${DateFormat('dd MMM yyyy').format(_disposalComparisonDate)}'),
                ),
              if (_disposalComparisonMode == DisposalComparisonMode.custom)
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                      initialDateRange: customCurrentRange,
                      helpText: 'PILIH RENTANG PERIODE A',
                    );
                    if (picked != null) {
                      setState(() => _customCurrentDisposalRange = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                      'Periode A: ${dateRange(currentStart, currentEndExclusive)}'),
                ),
              if (_disposalComparisonMode == DisposalComparisonMode.custom)
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                      initialDateRange: customPreviousRange,
                      helpText: 'PILIH RENTANG PERIODE B',
                    );
                    if (picked != null) {
                      setState(() => _customPreviousDisposalRange = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                      'Periode B: ${dateRange(previousStart, previousEndExclusive)}'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _comparisonLegend(currentLabel, AppTheme.primary),
              _comparisonLegend(previousLabel, AppTheme.accent),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _disposalComparisonMetric(
                'Jumlah item dibuang',
                numberFormat.format(currentQuantity),
                'sebelumnya ${numberFormat.format(previousQuantity)}',
              ),
              _disposalComparisonMetric(
                'Total Cost Amount',
                currencyFormat.format(currentCost),
                'sebelumnya ${currencyFormat.format(previousCost)}',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Item pembuangan terbanyak pada periode ini (jumlah absolut)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (topItemComparisons.isEmpty)
            const _DisposalComparisonEmptyState()
          else ...[
            SizedBox(
              height: 290,
              child: _buildDisposalComparisonChart(
                topItemComparisons,
                valueFormat: numberFormat.format,
                intervalHint: 1,
              ),
            ),
            const SizedBox(height: 10),
            _buildTopDisposalItemsTable(
              topItemComparisons,
              numberFormat,
              currentLabel:
                  _disposalComparisonMode == DisposalComparisonMode.custom
                      ? 'Periode A'
                      : '$periodLabel ini',
              previousLabel:
                  _disposalComparisonMode == DisposalComparisonMode.custom
                      ? 'Periode B'
                      : '$periodLabel lalu',
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Total Cost Amount per divisi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (costComparisons
              .every((item) => item.current == 0 && item.previous == 0))
            const _DisposalComparisonEmptyState(
              message: 'Belum ada Cost Amount untuk periode yang dibandingkan.',
            )
          else
            SizedBox(
              height: 300,
              child: _buildDisposalComparisonChart(
                costComparisons,
                valueFormat: currencyFormat.format,
                intervalHint: 100,
              ),
            ),
          const SizedBox(height: 24),
          _buildWeeklyDisposalTable(
            visiblePeriodRows,
            periodRows.length,
            periodStartIndex,
            periodPage,
            periodTotalPages,
            disposalPeriodStart,
            disposalPeriodEndExclusive,
            periodDisposals,
            weeklyRange,
          ),
        ],
      ),
    );
  }

  List<
      ({
        String date,
        String division,
        String item,
        double quantity,
        double cost
      })> _weeklyDisposalRows(List<dynamic> disposals) {
    final rows = <({
      String date,
      String division,
      String item,
      double quantity,
      double cost
    })>[];
    final ordered = disposals
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList()
      ..sort((a, b) =>
          (a['date']?.toString() ?? '').compareTo(b['date']?.toString() ?? ''));
    for (final record in ordered) {
      final items = List<dynamic>.from(record['items'] ?? []);
      if (items.isEmpty) {
        rows.add((
          date: record['date']?.toString() ?? '-',
          division: record['division']?.toString() ?? '-',
          item: 'Belum ada detail item',
          quantity: 0,
          cost: 0,
        ));
        continue;
      }
      for (final rawItem in items) {
        final item = Map<String, dynamic>.from(rawItem as Map);
        final itemNumber = item['itemNumber']?.toString() ?? '';
        final productName = item['productName']?.toString() ?? '';
        rows.add((
          date: record['date']?.toString() ?? '-',
          division: record['division']?.toString() ?? '-',
          item: itemNumber.isEmpty ? productName : '$itemNumber - $productName',
          quantity: ((item['quantity'] as num?)?.toDouble() ?? 0).abs(),
          cost: (item['costAmount'] as num?)?.toDouble() ?? 0,
        ));
      }
    }
    return rows;
  }

  Widget _buildWeeklyDisposalTable(
    List<
            ({
              String date,
              String division,
              String item,
              double quantity,
              double cost
            })>
        rows,
    int totalRows,
    int startIndex,
    int page,
    int totalPages,
    DateTime periodStart,
    DateTime periodEndExclusive,
    List<dynamic> weeklyDisposals,
    DateTimeRange selectedRange,
  ) {
    final quantityFormat = NumberFormat('#,##0.##', 'id_ID');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 2,
    );
    final dateLabel = '${DateFormat('dd MMM yyyy').format(periodStart)} - '
        '${DateFormat('dd MMM yyyy').format(periodEndExclusive.subtract(const Duration(days: 1)))}';

    return SectionCard(
      title: 'Semua Pembuangan Periode Pilihan',
      actions: [
        OutlinedButton.icon(
          onPressed: totalRows == 0
              ? null
              : () => _exportWeeklyDisposalsReport(
                    weeklyDisposals,
                    periodStart,
                    periodEndExclusive,
                  ),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Download Report PDF'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(DateTime.now().year + 1, 12, 31),
                    initialDateRange: selectedRange,
                    helpText: 'PILIH PERIODE PEMBUANGAN',
                    saveText: 'Terapkan',
                  );
                  if (picked != null && mounted) {
                    setState(() {
                      _weeklyDisposalDateRange = picked;
                      _weeklyDisposalPage = 0;
                    });
                  }
                },
                icon: const Icon(Icons.date_range_outlined),
                label: const Text('Pilih tanggal'),
              ),
              if (_weeklyDisposalDateRange != null)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _weeklyDisposalDateRange = null;
                    _weeklyDisposalPage = 0;
                  }),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Kembali ke minggu ini'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$dateLabel • $totalRows baris',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const _DisposalComparisonEmptyState(
              message: 'Tidak ada data pembuangan pada periode ini.',
            )
          else
            _buildFullWidthWeeklyTable(rows, quantityFormat, currencyFormat),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                totalRows == 0
                    ? 'Tidak ada data'
                    : 'Menampilkan ${startIndex + 1}-${math.min(startIndex + rows.length, totalRows)} dari $totalRows',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const Spacer(),
              const Text('Baris per halaman'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _weeklyDisposalRowsPerPage,
                items: const [10, 15, 25, 50]
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() {
                  _weeklyDisposalRowsPerPage = value ?? 15;
                  _weeklyDisposalPage = 0;
                }),
              ),
              IconButton(
                tooltip: 'Halaman sebelumnya',
                onPressed: page <= 0
                    ? null
                    : () => setState(() => _weeklyDisposalPage--),
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${page + 1} / $totalPages'),
              IconButton(
                tooltip: 'Halaman berikutnya',
                onPressed: page >= totalPages - 1
                    ? null
                    : () => setState(() => _weeklyDisposalPage++),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthWeeklyTable(
    List<
            ({
              String date,
              String division,
              String item,
              double quantity,
              double cost
            })>
        rows,
    NumberFormat quantityFormat,
    NumberFormat currencyFormat,
  ) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 1000.0;
          return Table(
            columnWidths: {
              0: FixedColumnWidth(math.max(115.0, width * 0.12)),
              1: FixedColumnWidth(math.max(150.0, width * 0.16)),
              2: FlexColumnWidth(width < 900 ? 2 : 3),
              3: FixedColumnWidth(math.max(100.0, width * 0.11)),
              4: FixedColumnWidth(math.max(170.0, width * 0.18)),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppTheme.tableHeader),
                children: [
                  _weeklyTableCell('Tanggal', heading: true),
                  _weeklyTableCell('Divisi', heading: true),
                  _weeklyTableCell('Item', heading: true),
                  _weeklyTableCell('Quantity', heading: true, alignEnd: true),
                  _weeklyTableCell('Cost Amount',
                      heading: true, alignEnd: true),
                ],
              ),
              for (var index = 0; index < rows.length; index++)
                TableRow(
                  decoration: BoxDecoration(
                    color:
                        index.isEven ? Colors.white : const Color(0xFFFFFCFA),
                    border: const Border(
                      bottom: BorderSide(color: AppTheme.border),
                    ),
                  ),
                  children: [
                    _weeklyTableCell(rows[index].date),
                    _weeklyTableCell(rows[index].division),
                    _weeklyTableCell(rows[index].item),
                    _weeklyTableCell(
                      quantityFormat.format(rows[index].quantity),
                      alignEnd: true,
                    ),
                    _weeklyTableCell(
                      currencyFormat.format(rows[index].cost),
                      alignEnd: true,
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _weeklyTableCell(String text,
      {bool heading = false, bool alignEnd = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          maxLines: heading ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            color: heading ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: heading ? FontWeight.w800 : FontWeight.w600,
            fontSize: heading ? 12 : 12,
          ),
        ),
      ),
    );
  }

  List<dynamic> _disposalsInDateRange(
      List<dynamic> disposals, DateTime start, DateTime end) {
    return disposals.where((raw) {
      final record = raw as Map;
      final date = DateTime.tryParse(record['date']?.toString() ?? '');
      return date != null && !date.isBefore(start) && date.isBefore(end);
    }).toList();
  }

  double _disposalRecordCost(Map<String, dynamic> record) {
    final items = List<dynamic>.from(record['items'] ?? []);
    return items.fold<double>(
      0,
      (total, rawItem) =>
          total +
          ((Map<String, dynamic>.from(rawItem as Map)['costAmount'] as num?)
                  ?.toDouble() ??
              0),
    );
  }

  double _disposalsQuantity(List<dynamic> records) {
    return records.fold<double>(
      0,
      (total, rawRecord) {
        final record = Map<String, dynamic>.from(rawRecord as Map);
        return total +
            List<dynamic>.from(record['items'] ?? []).fold<double>(
              0,
              (itemTotal, rawItem) =>
                  itemTotal +
                  ((Map<String, dynamic>.from(rawItem as Map)['quantity']
                                  as num?)
                              ?.toDouble() ??
                          0)
                      .abs(),
            );
      },
    );
  }

  Widget _disposalComparisonMetric(
      String label, String value, String previousValue) {
    return Container(
      constraints: const BoxConstraints(minWidth: 260),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.tableHeader,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 5),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(previousValue,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _comparisonLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildTopDisposalItemsTable(
      List<({String label, String title, double current, double previous})>
          items,
      NumberFormat formatter,
      {required String currentLabel,
      required String previousLabel}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 46,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 58,
          columnSpacing: 22,
          columns: [
            const DataColumn(label: Text('No.')),
            const DataColumn(label: Text('Item')),
            DataColumn(label: Text(currentLabel), numeric: true),
            DataColumn(label: Text(previousLabel), numeric: true),
            const DataColumn(label: Text('Selisih'), numeric: true),
          ],
          rows: [
            for (var index = 0; index < items.length; index++)
              DataRow(
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(SizedBox(
                    width: 280,
                    child: Text(
                      items[index].title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                  DataCell(Text(formatter.format(items[index].current))),
                  DataCell(Text(formatter.format(items[index].previous))),
                  DataCell(_comparisonDeltaCell(
                    items[index].current - items[index].previous,
                    formatter,
                  )),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonDeltaCell(double difference, NumberFormat formatter) {
    final increased = difference > 0;
    final decreased = difference < 0;
    final color = increased
        ? const Color(0xFFB42318)
        : decreased
            ? AppTheme.accent
            : AppTheme.textSecondary;
    final icon = increased
        ? Icons.trending_up
        : decreased
            ? Icons.trending_down
            : Icons.horizontal_rule;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          formatter.format(difference.abs()),
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildDisposalComparisonChart(
    List<({String label, String title, double current, double previous})>
        values, {
    required String Function(num) valueFormat,
    required double intervalHint,
  }) {
    final allValues = values.expand((item) => [item.current, item.previous]);
    final minimum =
        allValues.fold<double>(0, (value, item) => item < value ? item : value);
    final maximum =
        allValues.fold<double>(0, (value, item) => item > value ? item : value);
    final span = maximum - minimum;
    final padding = span == 0 ? intervalHint : span * 0.15;
    final minY = minimum < 0 ? minimum - padding : 0.0;
    final maxY = maximum > 0 ? maximum + padding : intervalHint;
    final interval = ((maxY - minY) / 4).clamp(1.0, double.infinity).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 18, 18, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: BarChart(
        BarChartData(
          minY: minY,
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppTheme.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppTheme.textPrimary,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = values[group.x];
                final period = rodIndex == 0 ? 'Periode ini' : 'Periode lalu';
                return BarTooltipItem(
                  '${item.title}\n$period: ${valueFormat(rod.toY)}',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 70,
                interval: interval,
                getTitlesWidget: (value, meta) => Text(
                  valueFormat(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= values.length) {
                    return const SizedBox.shrink();
                  }
                  final label = values[index].label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label.length > 12 ? label.substring(0, 12) : label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var index = 0; index < values.length; index++)
              BarChartGroupData(
                x: index,
                barsSpace: 4,
                barRods: [
                  BarChartRodData(
                    toY: values[index].current,
                    width: values.length > 6 ? 10 : 18,
                    color: AppTheme.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                  BarChartRodData(
                    toY: values[index].previous,
                    width: values.length > 6 ? 10 : 18,
                    color: AppTheme.accent,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _filterAnalysisTrendDisposals(List<dynamic> disposals) {
    return disposals.where((item) {
      final map = item as Map<String, dynamic>;
      final date = DateTime.tryParse(map['date']?.toString() ?? '');
      if (date == null) return false;
      final sameYear = date.year == _analysisTrendYear;
      final sameMonth = date.month == _analysisTrendDate.month;
      if (_analysisTrendMode == TrendFilterMode.monthly) {
        return sameYear && sameMonth;
      }
      return sameYear && sameMonth && date.day == _analysisTrendDate.day;
    }).toList();
  }

  Widget _buildAnalysisTrendFilters() {
    final currentYear = DateTime.now().year;
    final years = [
      for (var year = currentYear - 5; year <= currentYear + 1; year++) year,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.tableHeader,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<TrendFilterMode>(
            segments: const [
              ButtonSegment(
                value: TrendFilterMode.monthly,
                icon: Icon(Icons.calendar_view_month_outlined, size: 18),
                label: Text('Bulanan'),
              ),
              ButtonSegment(
                value: TrendFilterMode.daily,
                icon: Icon(Icons.today_outlined, size: 18),
                label: Text('Tanggal'),
              ),
            ],
            selected: {_analysisTrendMode},
            onSelectionChanged: (selection) {
              setState(() => _analysisTrendMode = selection.first);
            },
          ),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<int>(
              initialValue: _analysisTrendDate.month,
              decoration: const InputDecoration(
                labelText: 'Bulan',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              items: [
                for (var month = 1; month <= 12; month++)
                  DropdownMenuItem(
                    value: month,
                    child:
                        Text(DateFormat('MMMM').format(DateTime(2026, month))),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                final day = _analysisTrendDate.day
                    .clamp(
                      1,
                      DateUtils.getDaysInMonth(_analysisTrendYear, value),
                    )
                    .toInt();
                setState(() {
                  _analysisTrendDate = DateTime(_analysisTrendYear, value, day);
                });
              },
            ),
          ),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<int>(
              initialValue: years.contains(_analysisTrendYear)
                  ? _analysisTrendYear
                  : currentYear,
              decoration: const InputDecoration(
                labelText: 'Tahun',
                prefixIcon: Icon(Icons.event_outlined),
              ),
              items: years
                  .map((year) => DropdownMenuItem(
                      value: year, child: Text(year.toString())))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                final day = _analysisTrendDate.day
                    .clamp(
                      1,
                      DateUtils.getDaysInMonth(value, _analysisTrendDate.month),
                    )
                    .toInt();
                setState(() {
                  _analysisTrendYear = value;
                  _analysisTrendDate = DateTime(
                    value,
                    _analysisTrendDate.month,
                    day,
                  );
                });
              },
            ),
          ),
          if (_analysisTrendMode == TrendFilterMode.daily)
            SizedBox(
              width: 210,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Color(0xFFD8DEE8)),
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _analysisTrendDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(currentYear + 1, 12, 31),
                  );
                  if (picked == null) return;
                  setState(() {
                    _analysisTrendDate = picked;
                    _analysisTrendYear = picked.year;
                  });
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      DateFormat('dd MMM yyyy').format(_analysisTrendDate)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivisionTrendChart(Map<String, int> counts) {
    final entries = counts.entries.toList();
    final maxCount = entries.fold<int>(
        0, (max, entry) => entry.value > max ? entry.value : max);
    final maxY = (maxCount + 4).toDouble();

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY <= 4 ? 5 : maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppTheme.border,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppTheme.textPrimary,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = entries[group.x.toInt()];
              return BarTooltipItem(
                '${_divisionDisplayLabel(entry.key)}\n${entry.value} data',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: _chartInterval(maxCount),
              getTitlesWidget: (value, meta) {
                if (value < 0 || value > maxY) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 58,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= entries.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _divisionChartLabel(entries[index].key),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var index = 0; index < entries.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entries[index].value.toDouble(),
                  width: 24,
                  color: AppTheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY <= 4 ? 5 : maxY,
                    color: AppTheme.border,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  double _chartInterval(int maxCount) {
    if (maxCount <= 5) return 1;
    if (maxCount <= 20) return 5;
    if (maxCount <= 50) return 10;
    return 20;
  }

  Map<String, int> _buildDivisionDisposalCounts(List<dynamic> disposals) {
    final counts = {
      'GROCERY': 0,
      'SOZAI': 0,
      'SOZAI (SISA PRODUKSI)': 0,
      'FISH': 0,
      'F&V': 0,
      'MEAT': 0,
    };

    for (final item in disposals) {
      final map = item as Map<String, dynamic>;
      final division = (map['division']?.toString() ?? '').toUpperCase();
      if (counts.containsKey(division)) {
        counts[division] = counts[division]! + 1;
      }
    }
    return counts;
  }

  String _divisionDisplayLabel(String division) {
    final match = _disposalDivisions.firstWhere(
      (item) => item['apiValue'] == division,
      orElse: () => {'label': division},
    );
    return match['label']!.toUpperCase();
  }

  String _divisionChartLabel(String division) {
    switch (division) {
      case 'GROCERY':
        return 'Grocery';
      case 'SOZAI':
        return 'Sozai';
      case 'SOZAI (SISA PRODUKSI)':
        return 'Sozai\nSisa';
      case 'F&V':
        return 'F&V';
      case 'MEAT':
        return 'Meat';
      default:
        return division;
    }
  }

  Widget _analysisSummaryPill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.tableHeader,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(width: 10),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _divisionTrendRow({
    required String label,
    required int count,
    required int maxCount,
  }) {
    final ratio = maxCount == 0 ? 0.0 : count / maxCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 14,
                value: ratio,
                backgroundColor: AppTheme.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 58,
            child: Text(
              '$count data',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisposalFilterCard(
      BuildContext context, List<dynamic> disposals) {
    return SectionCard(
      title: 'Filter Data Pembuangan',
      actions: [
        PrimaryButton(
          label: 'Export Semua Data Excel',
          leading: const Icon(Icons.table_view_outlined),
          onPressed: disposals.isEmpty ||
                  _filterStartDate == null ||
                  _filterEndDate == null
              ? null
              : () => _exportDisposalPostingDataToExcel(
                    _filterDisposals(disposals).expand((item) {
                      final records = item['_groupedDisposals'];
                      return records is List ? records : [item];
                    }).cast<Map<String, dynamic>>().toList(),
                  ),
        ),
        PrimaryButton(
          label: 'Download Semua PDF',
          leading: const Icon(Icons.picture_as_pdf_outlined),
          onPressed: disposals.isEmpty
              ? null
              : () => _showFilteredDisposalsDialog(disposals),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildFilterDateField(context, 'Dari tanggal', true),
              _buildFilterDateField(context, 'Sampai tanggal', false),
              _buildDivisionFilter(context),
            ],
          ),
          const SizedBox(height: 20),
          Text(
              'Pilih range tanggal dan divisi lalu tekan tombol untuk menampilkan data.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildFilterDateField(
      BuildContext context, String label, bool isStart) {
    final selectedDate = isStart ? _filterStartDate : _filterEndDate;
    return SizedBox(
      width: 260,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFFFFFF),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(color: AppTheme.border),
        ),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
          );
          if (picked == null) return;
          setState(() {
            if (isStart) {
              _filterStartDate = picked;
            } else {
              _filterEndDate = picked;
            }
          });
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            selectedDate == null
                ? label
                : '$label: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildDivisionFilter(BuildContext context) {
    final selectedValue =
        _normalizeDivisionFilterValue(_disposalFilterDivision);
    return SizedBox(
      width: 260,
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          prefixIcon: const Icon(Icons.storefront_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        items: [
          const DropdownMenuItem(value: 'all', child: Text('Semua Divisi')),
          ..._disposalDivisions.map((division) => DropdownMenuItem(
                value: division['value'],
                child: Text(division['label']!),
              )),
        ],
        onChanged: (value) =>
            setState(() => _disposalFilterDivision = value ?? 'all'),
      ),
    );
  }

  String _normalizeDivisionFilterValue(String value) {
    final normalized = value.toLowerCase();
    if (normalized == 'all') return 'all';
    if (_disposalDivisions.any((division) => division['value'] == normalized)) {
      return normalized;
    }
    final byApiValue = _disposalDivisions.firstWhere(
      (division) => division['apiValue']!.toLowerCase() == normalized,
      orElse: () => const {},
    );
    if (byApiValue.isNotEmpty) return byApiValue['value']!;
    return 'all';
  }

  String _divisionFilterApiValue(String filterValue) {
    final normalized = _normalizeDivisionFilterValue(filterValue);
    if (normalized == 'all') return 'all';
    final match = _disposalDivisions.firstWhere(
      (division) => division['value'] == normalized,
      orElse: () => const {'apiValue': 'all'},
    );
    return match['apiValue']!;
  }
}

// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, unused_element
part of '../dashboard_screen.dart';

extension DashboardDisposalPanels on _DashboardScreenState {
  Widget _buildDailyProductAnalysisPanel(
      BuildContext context, Map<String, dynamic> analysis) {
    final items = List<dynamic>.from(analysis['items'] ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final summary = List<dynamic>.from(analysis['groupSummary'] ?? []);
    final dateFrom = analysis['dateFrom']?.toString() ?? '-';
    final dateTo = analysis['dateTo']?.toString() ?? '-';
    final workbook = analysis['workbook']?.toString() ?? 'Excel analisa';
    final formatter = NumberFormat('#,##0.####', 'id_ID');
    final availableGroups = ['all', ...summary.map((raw) {
      final item = Map<String, dynamic>.from(raw as Map);
      return item['group']?.toString() ?? '-';
    })];
    final activeGroup = availableGroups.contains(_analysisGroupFilter)
        ? _analysisGroupFilter
        : 'all';
    final filteredItems = activeGroup == 'all'
        ? items
        : items.where((item) => item['group'] == activeGroup).toList();
    final totalPages = filteredItems.isEmpty
        ? 1
        : (filteredItems.length / _analysisRowsPerPage).ceil();
    final currentPage = _analysisPage.clamp(0, totalPages - 1).toInt();
    if (currentPage != _analysisPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _analysisPage = currentPage);
      });
    }
    final start = currentPage * _analysisRowsPerPage;
    final pageItems = filteredItems
        .skip(start)
        .take(_analysisRowsPerPage)
        .toList();

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5EBDD)),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.analytics_outlined,
                      color: Color(0xFF2E7D32), size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analisa Selisih Produk Harian',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: const Color(0xFF1D2B38),
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$workbook | $dateFrom sampai $dateTo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF68777A)),
                      ),
                    ],
                  ),
                ),
                PrimaryButton(
                  label: 'Refresh',
                  leading: const Icon(Icons.refresh),
                  onPressed: _refreshDashboard,
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: items.isEmpty
                      ? null
                      : () => _exportAnalysisToExcel(
                          filteredItems,
                          dateFrom,
                          dateTo,
                          filePrefix: activeGroup == 'all'
                              ? 'analisa_selisih'
                              : 'analisa_selisih_${activeGroup.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}',
                        ),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('Export Excel'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: items.isEmpty
                      ? null
                      : () => _exportAnalysisToPdf(
                          filteredItems,
                          dateFrom,
                          dateTo,
                          title: activeGroup == 'all'
                              ? 'Analisa Selisih Produk Harian'
                              : 'Analisa Selisih Produk $activeGroup',
                          filePrefix: activeGroup == 'all'
                              ? 'analisa_selisih'
                              : 'analisa_selisih_${activeGroup.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}',
                        ),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Export PDF'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _analysisInfoCard('Total Selisih', items.length.toString(),
                  Icons.format_list_numbered_outlined,
                  const Color(0xFF2E7D32)),
              _analysisInfoCard('Dari Tanggal', dateFrom,
                  Icons.calendar_today_outlined, const Color(0xFF1AAE9C)),
              _analysisInfoCard('Sampai Tanggal', dateTo,
                  Icons.event_available_outlined, const Color(0xFFE07A2F)),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 18),
            SectionCard(
              title: 'Ringkasan Kategori',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: summary.map((raw) {
                  final item = Map<String, dynamic>.from(raw as Map);
                  final total =
                      (item['totalAbsDifference'] as num?)?.toDouble() ?? 0;
                  return _analysisGroupChip(
                    item['group']?.toString() ?? '-',
                    '${item['count'] ?? 0} item',
                    formatter.format(total),
                    onTap: () => _showAnalysisGroupDialog(
                      item['group']?.toString() ?? '-',
                      items,
                      formatter,
                      dateFrom,
                      dateTo,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SectionCard(
            title: 'Item Dengan Selisih Terbesar',
            child: items.isEmpty
                ? const SizedBox(
                    height: 140,
                    child: Center(child: Text('Tidak ada selisih produk.')),
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          const Text('Filter kategori',
                              style: TextStyle(
                                  color: Color(0xFF1D2B38),
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: activeGroup,
                            items: availableGroups
                                .map((group) => DropdownMenuItem(
                                      value: group,
                                      child: Text(
                                          group == 'all' ? 'Semua' : group),
                                    ))
                                .toList(),
                            onChanged: (value) => setState(() {
                              _analysisGroupFilter = value ?? 'all';
                              _analysisPage = 0;
                            }),
                          ),
                          const Spacer(),
                          Text(
                            '${filteredItems.length} data',
                            style:
                                const TextStyle(color: Color(0xFF68777A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5EBDD)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 28,
                              dataRowMinHeight: 58,
                              dataRowMaxHeight: 68,
                              columns: const [
                                DataColumn(label: Text('Tanggal')),
                                DataColumn(label: Text('Kategori')),
                                DataColumn(label: Text('Item Number')),
                                DataColumn(label: Text('Nama Barang')),
                                DataColumn(label: Text('Unit')),
                                DataColumn(
                                    numeric: true,
                                    label: Text('PO/BO/TO IN')),
                                DataColumn(numeric: true, label: Text('Sales')),
                                DataColumn(numeric: true, label: Text('Selisih')),
                                DataColumn(label: Text('Note')),
                              ],
                              rows: pageItems.map((item) {
                                final difference =
                                    (item['difference'] as num?)?.toDouble() ??
                                        0;
                                return DataRow(
                                  onSelectChanged: (_) =>
                                      _showAnalysisItemDialog(
                                          item, items, formatter),
                                  cells: [
                                    DataCell(Text(
                                        item['date']?.toString() ?? '-')),
                                    DataCell(Text(
                                        item['group']?.toString() ?? '-')),
                                    DataCell(Text(
                                        item['itemNumber']?.toString() ?? '-')),
                                    DataCell(Text(
                                      item['itemName']?.toString() ?? '-',
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                    DataCell(
                                        Text(item['unit']?.toString() ?? '-')),
                                    DataCell(Text(formatter.format(
                                        (item['poBoToIn'] as num?)
                                                ?.toDouble() ??
                                            0))),
                                    DataCell(Text(formatter.format(
                                        (item['sales'] as num?)?.toDouble() ??
                                            0))),
                                    DataCell(Text(
                                      formatter.format(difference),
                                      style: TextStyle(
                                        color: difference < 0
                                            ? const Color(0xFFB42318)
                                            : const Color(0xFF067647),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    )),
                                    DataCell(Text(
                                      item['note']?.toString() ?? '-',
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Menampilkan ${start + 1}-${math.min(start + pageItems.length, filteredItems.length)} dari ${filteredItems.length}',
                            style: const TextStyle(color: Color(0xFF68777A)),
                          ),
                          const Spacer(),
                          DropdownButton<int>(
                            value: _analysisRowsPerPage,
                            items: const [10, 15, 25, 50]
                                .map((value) => DropdownMenuItem(
                                      value: value,
                                      child: Text('$value / halaman'),
                                    ))
                                .toList(),
                            onChanged: (value) => setState(() {
                              _analysisRowsPerPage = value ?? 15;
                              _analysisPage = 0;
                            }),
                          ),
                          IconButton(
                            tooltip: 'Halaman sebelumnya',
                            onPressed: currentPage == 0
                                ? null
                                : () => setState(() => _analysisPage--),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text('${currentPage + 1} / $totalPages'),
                          IconButton(
                            tooltip: 'Halaman berikutnya',
                            onPressed: currentPage >= totalPages - 1
                                ? null
                                : () => setState(() => _analysisPage++),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _analysisInfoCard(
      String label, String value, IconData icon, Color accentColor) {
    return SizedBox(
      width: 260,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5EBDD)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D2B38)),
                  ),
                  Text(label, style: const TextStyle(color: Color(0xFF68777A))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _analysisGroupChip(String title, String count, String total,
      {required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7EF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5EBDD)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: Color(0xFF1D2B38),
                          fontWeight: FontWeight.w800)),
                ),
                const Icon(Icons.open_in_new,
                    size: 16, color: Color(0xFF68777A)),
              ],
            ),
            const SizedBox(height: 6),
            Text(count, style: const TextStyle(color: Color(0xFF68777A))),
            const SizedBox(height: 4),
            Text('Total |selisih| $total',
                style:
                    const TextStyle(color: Color(0xFF68777A), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _analysisProductsForGroup(
      String group, List<Map<String, dynamic>> items) {
    final grouped = <String, Map<String, dynamic>>{};
    for (final item in items.where((item) => item['group'] == group)) {
      final itemNumber = item['itemNumber']?.toString() ?? '-';
      final difference = (item['difference'] as num?)?.toDouble() ?? 0;
      grouped[itemNumber] ??= {
        'itemNumber': itemNumber,
        'itemName': item['itemName']?.toString() ?? '-',
        'unit': item['unit']?.toString() ?? '-',
        'totalDifference': 0.0,
        'totalAbsDifference': 0.0,
        'dates': <Map<String, dynamic>>[],
      };
      grouped[itemNumber]!['totalDifference'] =
          (grouped[itemNumber]!['totalDifference'] as double) + difference;
      grouped[itemNumber]!['totalAbsDifference'] =
          (grouped[itemNumber]!['totalAbsDifference'] as double) +
              difference.abs();
      (grouped[itemNumber]!['dates'] as List<Map<String, dynamic>>).add(item);
    }
    final products = grouped.values.toList();
    products.sort((a, b) => (b['totalAbsDifference'] as double)
        .compareTo(a['totalAbsDifference'] as double));
    return products;
  }

  Future<void> _showAnalysisGroupDialog(
    String group,
    List<Map<String, dynamic>> items,
    NumberFormat formatter,
    String dateFrom,
    String dateTo,
  ) async {
    final products = _analysisProductsForGroup(group, items);
    final exportKey =
        group.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0xFF17212B).withOpacity(0.46),
      builder: (context) => DesktopModalShell(
        title: 'Kategori $group',
        subtitle: '$dateFrom sampai $dateTo',
        icon: Icons.category_outlined,
        maxWidth: 980,
        actions: [
          OutlinedButton.icon(
            onPressed: () => _exportAnalysisProductsToExcel(
              products,
              dateFrom,
              dateTo,
              group: group,
              filePrefix: 'ringkasan_selisih_$exportKey',
            ),
            icon: const Icon(Icons.table_chart_outlined),
            label: const Text('Export Excel'),
          ),
          OutlinedButton.icon(
            onPressed: () => _exportAnalysisProductsToPdf(
              products,
              dateFrom,
              dateTo,
              group: group,
              filePrefix: 'ringkasan_selisih_$exportKey',
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export PDF'),
          ),
        ],
        child: SizedBox(
          width: 920,
          height: 520,
          child: ListView.separated(
            itemCount: products.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = products[index];
              final total =
                  (product['totalDifference'] as num?)?.toDouble() ?? 0;
              final totalAbs =
                  (product['totalAbsDifference'] as num?)?.toDouble() ?? 0;
              return ListTile(
                onTap: () => _showAnalysisProductDatesDialog(
                    product, formatter),
                title: Text(
                  '${product['itemNumber']} - ${product['itemName']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                    '${product['unit']} | ${product['dates'].length} tanggal selisih'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatter.format(total),
                      style: TextStyle(
                        color: total < 0
                            ? const Color(0xFFB42318)
                            : const Color(0xFF067647),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('|selisih| ${formatter.format(totalAbs)}',
                        style: const TextStyle(
                            color: Color(0xFF68777A), fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showAnalysisItemDialog(Map<String, dynamic> item,
      List<Map<String, dynamic>> items, NumberFormat formatter) async {
    final product = _analysisProductsForGroup(item['group']?.toString() ?? '-',
            items)
        .firstWhere(
            (product) =>
                product['itemNumber']?.toString() ==
                item['itemNumber']?.toString(),
            orElse: () => {});
    if (product.isEmpty) return;
    await _showAnalysisProductDatesDialog(product, formatter);
  }

  Future<void> _showAnalysisProductDatesDialog(
      Map<String, dynamic> product, NumberFormat formatter) async {
    final dates = List<Map<String, dynamic>>.from(product['dates'] ?? [])
      ..sort((a, b) =>
          (a['date']?.toString() ?? '').compareTo(b['date']?.toString() ?? ''));
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0xFF17212B).withOpacity(0.46),
      builder: (context) => DesktopModalShell(
        title: product['itemNumber']?.toString() ?? '-',
        subtitle: product['itemName']?.toString() ?? '-',
        icon: Icons.inventory_2_outlined,
        maxWidth: 860,
        child: SizedBox(
          width: 800,
          height: 460,
          child: ListView.separated(
            itemCount: dates.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = dates[index];
              final difference = (item['difference'] as num?)?.toDouble() ?? 0;
              return ListTile(
                title: Text(item['date']?.toString() ?? '-'),
                subtitle: Text(
                  'PO/BO/TO IN ${formatter.format((item['poBoToIn'] as num?)?.toDouble() ?? 0)} | Sales ${formatter.format((item['sales'] as num?)?.toDouble() ?? 0)} | ${item['note']?.toString() ?? '-'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  formatter.format(difference),
                  style: TextStyle(
                    color: difference < 0
                        ? const Color(0xFFB42318)
                        : const Color(0xFF067647),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    final title =
        _selectedSection == DashboardSection.home ? 'Home' : 'Analisa';
    final description = _selectedSection == DashboardSection.home
        ? 'Halaman Home masih kosong. Konten premium akan ditambahkan segera.'
        : 'Halaman Analisa masih kosong. Detail analisa akan hadir di pembaruan berikutnya.';

    return Center(
      child: Card(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE5EBDD)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Text(description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black54),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return SizedBox(
      width: 180,
      child: Card(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE5EBDD)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.12),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    Text(label, style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisposalPanel(List<dynamic> disposals) {
    final sampleDisposals = disposals.take(1).toList();

    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5EBDD)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Data Disposal Terbaru',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                    onPressed: _refreshDashboard, child: const Text('Refresh')),
              ],
            ),
            const SizedBox(height: 12),
            if (sampleDisposals.isEmpty)
              const Text('Belum ada data disposal')
            else ...[
              ...sampleDisposals.map((item) {
                final map = item as Map<String, dynamic>;
                final journal = (map['journal']?.toString() ??
                        map['description']?.toString() ??
                        '')
                    .trim();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7EF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5EBDD)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(map['division'] ?? '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(map['date'] ?? '-',
                                style: TextStyle(color: Colors.black54)),
                            const SizedBox(height: 6),
                            Text(
                                journal.isEmpty ? 'Tidak ada jurnal.' : journal,
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showDisposalDetailDialog(map),
                        child: const Text('Lihat Detail'),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPanel() {
    return SectionCard(
      title: 'Upload Disposal ke Backend',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedDivision,
            items: _disposalDivisions
                .map((division) => DropdownMenuItem(
                      value: division['value'],
                      child: Text(division['label']!),
                    ))
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedDivision = value ?? 'grocery'),
            decoration: const InputDecoration(
              labelText: 'Divisi',
              prefixIcon: Icon(Icons.category_outlined),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime(2035),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tanggal',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _journalController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Jurnal (opsional)',
              prefixIcon: Icon(Icons.notes_outlined),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickPhotos,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(_photoPaths.isEmpty
                      ? 'Pilih foto'
                      : '${_photoPaths.length} foto'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickScannedPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label:
                      Text(_scannedPdfPath == null ? 'Pilih PDF' : 'PDF siap'),
                ),
              ),
            ],
          ),
          if (_photoPaths.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Preview Foto',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1D2B38),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            _DisposalPhotoPickerPreview(
              photoPaths: _photoPaths,
              onOpen: (path) {
                final fileName = File(path).uri.pathSegments.last;
                _showLocalImagePreview(fileName, path);
              },
              onRemove: (index) => setState(() =>
                  _photoPaths = List<String>.from(_photoPaths)
                    ..removeAt(index)),
            ),
          ],
          if (_scannedPdfPath != null) ...[
            const SizedBox(height: 14),
            Text(
              'Preview PDF',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1D2B38),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            _buildLocalPdfPreviewBox(_scannedPdfPath!),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: _isUploading ? 'Mengirim...' : 'Kirim ke backend',
              leading: const Icon(Icons.cloud_upload_outlined),
              isLoading: _isUploading,
              onPressed: _isUploading ? null : _submitUpload,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLocalImagePreview(String title, String path) async {
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0xFF17212B).withOpacity(0.46),
      builder: (context) => DesktopModalShell(
        title: title,
        subtitle: 'Preview sebelum upload',
        icon: Icons.image_outlined,
        maxWidth: 1040,
        child: SizedBox(
          width: 980,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: InteractiveViewer(
              minScale: 0.6,
              maxScale: 4,
              child: LandscapeImageFrame(
                filePath: path,
                fit: BoxFit.contain,
                placeholder: const Center(child: Text('Gagal memuat preview')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopHorizontalDragScrollBehavior extends MaterialScrollBehavior {
  const _DesktopHorizontalDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
      };
}

class _DisposalPhotoPickerPreview extends StatefulWidget {
  const _DisposalPhotoPickerPreview({
    required this.photoPaths,
    required this.onOpen,
    required this.onRemove,
  });

  final List<String> photoPaths;
  final ValueChanged<String> onOpen;
  final ValueChanged<int> onRemove;

  @override
  State<_DisposalPhotoPickerPreview> createState() =>
      _DisposalPhotoPickerPreviewState();
}

class _DisposalPhotoPickerPreviewState
    extends State<_DisposalPhotoPickerPreview> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ScrollConfiguration(
        behavior: const _DesktopHorizontalDragScrollBehavior(),
        child: Scrollbar(
          controller: _controller,
          thumbVisibility: true,
          trackVisibility: true,
          child: ListView.separated(
            controller: _controller,
            padding: const EdgeInsets.only(bottom: 14),
            scrollDirection: Axis.horizontal,
            itemCount: widget.photoPaths.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final path = widget.photoPaths[index];
              return Stack(
                children: [
                  LandscapeImageFrame(
                    filePath: path,
                    width: 190,
                    height: 108,
                    onTap: () => widget.onOpen(path),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.black.withOpacity(0.50),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => widget.onRemove(index),
                        child: const Padding(
                          padding: EdgeInsets.all(5),
                          child:
                              Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

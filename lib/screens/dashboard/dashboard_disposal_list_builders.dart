// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, unused_element
part of '../dashboard_screen.dart';

extension DashboardDisposalListBuilders on _DashboardScreenState {
  Future<void> _showFilteredDisposalsDialog(List<dynamic> disposals) async {
    if (_filterStartDate == null || _filterEndDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Pilih tanggal mulai dan tanggal selesai terlebih dahulu.')));
      return;
    }

    final dataToShow = _filterDisposals(disposals);

    _disposalSearchController.clear();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final searchQuery =
              _disposalSearchController.text.trim().toLowerCase();
          final visibleItems = _sortDisposals(dataToShow
              .cast<Map<String, dynamic>>()
              .where((item) => _matchesDisposalSearch(item, searchQuery))
              .toList());

          return DesktopModalShell(
            title: 'Hasil Filter Data Pembuangan',
            subtitle: '${visibleItems.length} data sesuai filter',
            icon: Icons.filter_alt_outlined,
            maxWidth: 1180,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 650),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _disposalSearchController,
                            onChanged: (_) => setDialogState(() {}),
                            decoration: InputDecoration(
                              hintText:
                                  'Cari item number, nama barang, divisi, tanggal...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: searchQuery.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Bersihkan pencarian',
                                      onPressed: () {
                                        _disposalSearchController.clear();
                                        setDialogState(() {});
                                      },
                                      icon: const Icon(Icons.close),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 260,
                          child: DropdownButtonFormField<DisposalSortOption>(
                            initialValue: _disposalSortOption,
                            decoration: const InputDecoration(
                              labelText: 'Urutkan',
                              prefixIcon: Icon(Icons.sort_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: DisposalSortOption.newestDate,
                                child: Text('Tanggal terbaru'),
                              ),
                              DropdownMenuItem(
                                value: DisposalSortOption.oldestDate,
                                child: Text('Tanggal terlama'),
                              ),
                              DropdownMenuItem(
                                value: DisposalSortOption.journalNumberAsc,
                                child: Text('No jurnal terkecil'),
                              ),
                              DropdownMenuItem(
                                value: DisposalSortOption.journalNumberDesc,
                                child: Text('No jurnal terbesar'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _disposalSortOption =
                                  value ?? DisposalSortOption.newestDate);
                              setDialogState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: visibleItems.isEmpty
                        ? const Center(
                            child: Text('Tidak ada data yang cocok.'),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount =
                                  constraints.maxWidth >= 1040
                                      ? 3
                                      : constraints.maxWidth >= 680
                                          ? 2
                                          : 1;
                              return GridView.builder(
                                padding: EdgeInsets.zero,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: switch (crossAxisCount) {
                                    1 => 3.05,
                                    2 => 2.35,
                                    _ => 2.1,
                                  },
                                ),
                                itemCount: visibleItems.length,
                                itemBuilder: (context, index) =>
                                    _buildFilteredDisposalCard(
                                        visibleItems[index]),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              SizedBox(
                width: 260,
                child: PrimaryButton(
                  label:
                      _isExportingPdf ? 'Mengekspor...' : 'Download Semua PDF',
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  isLoading: _isExportingPdf,
                  onPressed: _isExportingPdf
                      ? null
                      : () => _exportFilteredDisposalsToPdf(
                            visibleItems.expand((item) {
                              final records = item['_groupedDisposals'];
                              return records is List ? records : [item];
                            }).cast<Map<String, dynamic>>().toList(),
                          ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<dynamic> _filterDisposals(List<dynamic> disposals) {
    final start = DateTime(
        _filterStartDate!.year, _filterStartDate!.month, _filterStartDate!.day);
    final end = DateTime(_filterEndDate!.year, _filterEndDate!.month,
        _filterEndDate!.day, 23, 59, 59);

    final filtered = disposals.where((item) {
      final map = item as Map<String, dynamic>;
      final dateString = map['date']?.toString() ?? '';
      final date = DateTime.tryParse(dateString);
      if (date == null) return false;
      final matchesDate = date.isAtSameMomentAs(start) ||
          date.isAfter(start) && date.isBefore(end) ||
          date.isAtSameMomentAs(end);
      final filterDivision = _divisionFilterApiValue(_disposalFilterDivision);
      final matchesDivision = filterDivision == 'all' ||
          map['division']?.toString().toLowerCase() ==
              filterDivision.toLowerCase();
      return matchesDate && matchesDivision;
    }).cast<Map<String, dynamic>>().toList();
    return _groupDisposalsByDateDivision(filtered);
  }

  List<Map<String, dynamic>> _groupDisposalsByDateDivision(
      List<Map<String, dynamic>> records) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final record in records) {
      final date = (record['date']?.toString() ?? '').split('T').first;
      final division = (record['division']?.toString() ?? '').trim();
      final key = '${date.toLowerCase()}|${division.toLowerCase()}';
      groups.putIfAbsent(key, () => []).add(record);
    }

    return groups.values.map((group) {
      if (group.length == 1) return group.first;
      final journals = group
          .map((record) => (record['journal']?.toString() ?? '').trim())
          .where((journal) => journal.isNotEmpty)
          .toSet()
          .toList();
      return <String, dynamic>{
        '_groupedDisposals': group,
        'date': group.first['date'],
        'division': group.first['division'],
        'journal': journals.isEmpty ? '' : journals.join(', '),
        'items': group.expand((record) => List<dynamic>.from(record['items'] ?? [])).toList(),
        'photos': group.expand((record) => List<String>.from(record['photos'] ?? [])).toSet().toList(),
        'scannedPdfs': group.expand((record) => List<String>.from(record['scannedPdfs'] ?? [])).toSet().toList(),
        'uploadedBy': group.map((record) => record['uploadedBy']?.toString()).whereType<String>().toSet().join(', '),
      };
    }).toList();
  }

  bool _matchesDisposalSearch(Map<String, dynamic> item, String query) {
    if (query.isEmpty) return true;
    final searchableText = <Object?>[
      item['division'],
      item['date'],
      item['journal'],
      item['description'],
      item['uploadedBy'],
      item['createdAt'],
      ...List<dynamic>.from(item['items'] ?? []).expand((rawItem) {
        if (rawItem is! Map) return const <Object?>[];
        return [rawItem['itemNumber'], rawItem['productName']];
      }),
    ]
        .whereType<Object>()
        .map((value) => value.toString().toLowerCase())
        .join(' ');
    return searchableText.contains(query);
  }

  List<Map<String, dynamic>> _sortDisposals(List<Map<String, dynamic>> items) {
    final sorted = List<Map<String, dynamic>>.from(items);
    sorted.sort((a, b) {
      switch (_disposalSortOption) {
        case DisposalSortOption.oldestDate:
          return _disposalDate(a).compareTo(_disposalDate(b));
        case DisposalSortOption.journalNumberAsc:
          return _journalNumber(a).compareTo(_journalNumber(b));
        case DisposalSortOption.journalNumberDesc:
          return _journalNumber(b).compareTo(_journalNumber(a));
        case DisposalSortOption.newestDate:
          return _disposalDate(b).compareTo(_disposalDate(a));
      }
    });
    return sorted;
  }

  DateTime _disposalDate(Map<String, dynamic> item) {
    return DateTime.tryParse(item['date']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  int _journalNumber(Map<String, dynamic> item) {
    final text = [
      item['journal'],
      item['journalNumber'],
      item['noJournal'],
      item['description'],
    ].whereType<Object>().map((value) => value.toString()).join(' ');
    final match = RegExp(r'\d+').firstMatch(text);
    if (match == null) return 0;
    return int.tryParse(match.group(0) ?? '') ?? 0;
  }

  String _storageUrl(String relativePath) {
    final cleanPath = relativePath.replaceAll('\\', '/').replaceFirst(
          RegExp(r'^/+'),
          '',
        );
    return '${widget.apiService.baseUrl}/storage/${Uri.encodeFull(cleanPath)}';
  }

  Widget _buildFilteredDisposalCard(Map<String, dynamic> item) {
    final groupedRecords = item['_groupedDisposals'] is List
        ? List<Map<String, dynamic>>.from(item['_groupedDisposals'] as List)
        : <Map<String, dynamic>>[];
    final isGrouped = groupedRecords.length > 1;
    final photos = List<String>.from(item['photos'] ?? []);
    final firstPhotoUrl = photos.isEmpty ? '' : _storageUrl(photos.first);
    final division = item['division']?.toString() ?? '-';
    final date = item['date']?.toString() ?? '-';
    final journal =
        (item['journal']?.toString() ?? item['description']?.toString() ?? '')
            .trim();

    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 420;
      return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => isGrouped
            ? _showGroupedDisposalDetailDialog(item)
            : _showDisposalDetailDialog(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildDisposalPhotoPreview(
                firstPhotoUrl,
                division,
                width: compact ? 126 : 220,
                height: compact ? 96 : 124,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            division,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        Text(date,
                            style: const TextStyle(
                                color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      journal.isEmpty ? 'Tidak ada jurnal.' : journal,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    if (!isGrouped)
                      _disposalPostingStatusBadge(item),
                    const Spacer(),
                    SizedBox(
                      height: 34,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Upload: ${item['uploadedBy']?.toString() ?? '-'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.black45, fontSize: 12),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Export Excel untuk jurnal ini',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                                width: 34, height: 34),
                            iconSize: 18,
                            onPressed: () => _exportDisposalPostingDataToExcel(
                                isGrouped ? groupedRecords : [item]),
                            icon: const Icon(Icons.table_view_outlined),
                          ),
                          if (isGrouped)
                            IconButton(
                              tooltip: 'Lihat data gabungan',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                              iconSize: 18,
                              onPressed: () => _showGroupedDisposalDetailDialog(item),
                              icon: const Icon(Icons.folder_open_outlined),
                            )
                          else ...[
                          IconButton(
                            tooltip: 'Edit',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                                width: 34, height: 34),
                            iconSize: 18,
                            onPressed: () => _showEditDisposalDialog(item),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                                width: 34, height: 34),
                            iconSize: 18,
                            color: Colors.red,
                            onPressed: () => _confirmDeleteDisposal(item),
                            icon: const Icon(Icons.delete_outline),
                          ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      );
    });
  }

  Future<void> _showGroupedDisposalDetailDialog(
      Map<String, dynamic> group) async {
    final merged = <String, dynamic>{
      ...group,
      'photoRotations': <String, int>{},
    }..remove('_groupedDisposals');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => DesktopModalShell(
        title: '${group['division']} - ${group['date']}',
        subtitle: 'Data gabungan berdasarkan tanggal dan kategori',
        icon: Icons.folder_copy_outlined,
        maxWidth: 1180,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 660),
          child: ListView(
            children: [
              _buildDetailRow('Kategori', group['division'].toString()),
              _buildDetailRow('Tanggal', group['date'].toString()),
              _buildDetailRow(
                'Nomor Jurnal',
                group['journal']?.toString().isNotEmpty == true
                    ? group['journal'].toString()
                    : '-',
              ),
              const SizedBox(height: 14),
              _buildDisposalItemsTable(merged),
              const SizedBox(height: 18),
              _buildDisposalDocumentationPreview(merged),
              const SizedBox(height: 18),
            ],
          ),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => _exportSingleDisposalToPdf(merged),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Download PDF Gabungan'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDisposalPhotoPreview(String imageUrl, String title,
      {required double width, required double height}) {
    return LandscapeImageFrame(
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      width: width,
      height: height,
      onTap: imageUrl.isEmpty
          ? null
          : () => _showImagePreview(context, title, imageUrl),
      placeholder: const Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: Color(0xFF98A2B3), size: 34),
      ),
    );
  }
}

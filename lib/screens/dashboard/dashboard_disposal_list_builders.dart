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
                                  'Cari divisi, tanggal, jurnal, uploader...',
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
                                  childAspectRatio:
                                      crossAxisCount == 1 ? 3.05 : 2.45,
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
                      : () => _exportFilteredDisposalsToPdf(visibleItems),
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

    return disposals.where((item) {
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
    }).toList();
  }

  bool _matchesDisposalSearch(Map<String, dynamic> item, String query) {
    if (query.isEmpty) return true;
    final searchableText = [
      item['division'],
      item['date'],
      item['journal'],
      item['description'],
      item['uploadedBy'],
      item['createdAt'],
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
    final photos = List<String>.from(item['photos'] ?? []);
    final firstPhotoUrl = photos.isEmpty ? '' : _storageUrl(photos.first);
    final division = item['division']?.toString() ?? '-';
    final date = item['date']?.toString() ?? '-';
    final journal =
        (item['journal']?.toString() ?? item['description']?.toString() ?? '')
            .trim();

    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5EBDD)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDisposalDetailDialog(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildDisposalPhotoPreview(firstPhotoUrl, division),
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
  }

  Widget _buildDisposalPhotoPreview(String imageUrl, String title) {
    return LandscapeImageFrame(
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      width: 154,
      height: 88,
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

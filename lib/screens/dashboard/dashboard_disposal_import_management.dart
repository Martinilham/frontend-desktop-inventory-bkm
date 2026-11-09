// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api
part of '../dashboard_screen.dart';

extension DashboardDisposalImportManagement on _DashboardScreenState {
  Future<void> _deleteImportedJournals(List<dynamic> disposals) async {
    final imported = disposals
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .where((item) =>
            item['hasExcelImport'] == true ||
            (item['sourceFile']?.toString().isNotEmpty ?? false))
        .toList();
    if (imported.isEmpty) {
      await _showActionPopup(
          title: 'Hasil Impor Kosong',
          message: 'Belum ada hasil impor Excel yang bisa dihapus.');
      return;
    }
    setState(() => _isManagingDisposalImports = true);
    try {
      final selected = <String>{};
      final sources = imported
          .map((item) => item['sourceFile']?.toString() ?? '')
          .toSet()
          .toList()
        ..sort();
      String? source;
      final ids = await showDialog<List<String>>(
        context: context,
        builder: (dialogContext) =>
            StatefulBuilder(builder: (dialogContext, updateDialog) {
          final visible = imported
              .where((item) => source == null || item['sourceFile'] == source)
              .toList();
          return DesktopModalShell(
            title: 'Hapus Hasil Impor Excel',
            subtitle:
                'Pilih data yang akan dibersihkan. Maksimal 1000 data per proses.',
            maxWidth: 880,
            child: SizedBox(
              height: 480,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Item dan jurnal hasil impor akan dihapus. Data tanggal/kategori, '
                        'foto, dan PDF tetap tersimpan. Setelah itu Anda dapat mengimpor ulang Excel.'),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: source,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'File sumber'),
                      items: [
                        const DropdownMenuItem<String>(
                            value: null, child: Text('Semua file')),
                        ...sources.map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.isEmpty ? 'Impor lama' : value,
                                overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (value) => updateDialog(() {
                        source = value;
                        selected.clear();
                      }),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                          'Pilih semua yang tampil (${visible.length}) — ${selected.length} dipilih'),
                      value: visible.isNotEmpty &&
                          visible.every((item) =>
                              selected.contains(item['id'].toString())),
                      onChanged: (checked) => updateDialog(() {
                        selected.clear();
                        if (checked == true)
                          selected.addAll(visible
                              .take(1000)
                              .map((item) => item['id'].toString()));
                      }),
                    ),
                    Expanded(
                        child: ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final item = visible[index];
                        final id = item['id'].toString();
                        return CheckboxListTile(
                          value: selected.contains(id),
                          title: Text('${item['date']} — ${item['division']}'),
                          subtitle: Text('${item['sourceFile'] ?? ''}\n'
                              '${(item['items'] as List?)?.length ?? 0} item | Jurnal: ${item['journal'] ?? '-'}'),
                          onChanged: (checked) => updateDialog(() {
                            if (checked == true && selected.length < 1000) {
                              selected.add(id);
                            } else {
                              selected.remove(id);
                            }
                          }),
                        );
                      },
                    )),
                  ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal')),
              ElevatedButton.icon(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.pop(dialogContext, selected.toList()),
                icon: const Icon(Icons.delete_outline),
                label: Text('Hapus ${selected.length} Hasil Impor'),
              ),
            ],
          );
        }),
      );
      if (ids == null || ids.isEmpty || !mounted) return;
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                title: const Text('Hapus item dan jurnal Excel?'),
                content: Text(
                    '${ids.length} data dipilih. Item hasil impor akan dikosongkan. '
                    'Jurnal manual yang tercatat sebelum impor terbaru dipertahankan. '
                    'Foto dan PDF tetap tersimpan.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Batal')),
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Hapus')),
                ],
              ));
      if (confirmed != true || !mounted) return;
      final result =
          await widget.apiService.deleteImportedDisposalJournals(ids);
      if (!mounted) return;
      setState(() => _dashboardFuture = _loadDashboardData());
      await _showActionPopup(
          title: 'Hasil Impor Dihapus',
          message:
              '${result['cleared']} data dibersihkan, ${result['skipped']} dilewati. '
              'Foto/PDF tetap tersimpan. Excel bisa diimpor ulang.');
    } catch (error) {
      if (!mounted) return;
      if (error is AuthException) {
        await widget.onLogout();
        return;
      }
      setState(() => _dashboardFuture = _loadDashboardData());
      await _showActionPopup(
          title: 'Hapus Impor Gagal',
          message: error.toString(),
          success: false);
    } finally {
      if (mounted) setState(() => _isManagingDisposalImports = false);
    }
  }

  DateTime? _scanPdfDate(String name) {
    final match = RegExp(r'^(\d{2})(\d{2})(\d{4})\.pdf$', caseSensitive: false)
        .firstMatch(name);
    if (match == null) return null;
    final day = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final year = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    if (year < 1900 ||
        date.year != year ||
        date.month != month ||
        date.day != day) return null;
    return date;
  }

  Future<void> _uploadDisposalPdfFolder() async {
    if (_isManagingDisposalImports || _isImportingDisposals) return;
    setState(() => _isManagingDisposalImports = true);
    try {
      final folder = await FilePicker.platform
          .getDirectoryPath(dialogTitle: 'Pilih Folder Scan PDF Pembuangan');
      if (folder == null || !mounted) return;
      final files = <File>[];
      await for (final entity in Directory(folder).list(followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.pdf'))
          files.add(entity);
      }
      files.sort((a, b) => a.path.compareTo(b.path));
      if (!mounted) return;
      if (files.isEmpty) {
        await _showActionPopup(
            title: 'Folder Kosong',
            message:
                'Tidak ada PDF langsung di folder ini. Pilih folder yang berisi file DDMMYYYY.pdf.');
        return;
      }
      String? division;
      final chosen = await showDialog<String>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
                builder: (dialogContext, updateDialog) => DesktopModalShell(
                  title: 'Upload Folder Scan PDF',
                  subtitle: '${files.length} file PDF ditemukan',
                  maxWidth: 740,
                  child: SizedBox(
                      height: 420,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                                'Pilih kategori untuk folder ini. 01082026.pdf akan dipasang pada '
                                'data 01/08/2026 dalam kategori tersebut. PDF yang sudah ada tidak ditimpa.'),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              initialValue: division,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  labelText: 'Kategori pembuangan'),
                              items: _disposalDivisions
                                  .map((item) => DropdownMenuItem(
                                      value: item['apiValue'],
                                      child: Text(item['label']!)))
                                  .toList(),
                              onChanged: (value) =>
                                  updateDialog(() => division = value),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                                child: ListView.builder(
                                    itemCount: files.length,
                                    itemBuilder: (context, index) {
                                      final name =
                                          files[index].uri.pathSegments.last;
                                      final date = _scanPdfDate(name);
                                      return ListTile(
                                        leading: Icon(date == null
                                            ? Icons.warning_amber_outlined
                                            : Icons.picture_as_pdf_outlined),
                                        title: Text(name),
                                        subtitle: Text(date == null
                                            ? 'Dilewati: gunakan nama DDMMYYYY.pdf dengan tanggal valid'
                                            : DateFormat('dd/MM/yyyy')
                                                .format(date)),
                                      );
                                    })),
                          ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Batal')),
                    ElevatedButton.icon(
                      onPressed: division == null ||
                              !files.any((file) =>
                                  _scanPdfDate(file.uri.pathSegments.last) !=
                                  null)
                          ? null
                          : () => Navigator.pop(dialogContext, division),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Folder'),
                    ),
                  ],
                ),
              ));
      if (chosen == null || !mounted) return;
      var uploaded = 0;
      final notes = <String>[];
      for (var index = 0; index < files.length; index++) {
        if (!mounted) return;
        final file = files[index];
        final name = file.uri.pathSegments.last;
        setState(() => _disposalFolderProgress =
            'Memproses ${index + 1}/${files.length}: $name');
        if (_scanPdfDate(name) == null) {
          notes.add('$name: nama/tanggal tidak valid.');
          continue;
        }
        try {
          if (await file.length() > 50 * 1024 * 1024) {
            notes.add('$name: ukuran melebihi 50 MB.');
            continue;
          }
          final result = await widget.apiService
              .uploadDatedDisposalScan(file.path, chosen);
          if (result['status'] == 'uploaded') {
            uploaded++;
          } else {
            notes.add('$name: ${result['reason'] ?? 'dilewati'}');
          }
        } on AuthException {
          rethrow;
        } catch (error) {
          notes.add('$name: $error');
        }
      }
      if (!mounted) return;
      setState(() {
        _dashboardFuture = _loadDashboardData();
        _disposalFolderProgress = '';
      });
      await _showActionPopup(
          title: 'Upload Folder Selesai',
          message: '$uploaded PDF terpasang pada kategori $chosen. '
              '${notes.length} file dilewati/gagal.'
              '${notes.isEmpty ? '' : '\n\n${notes.join('\n')}'}');
    } catch (error) {
      if (!mounted) return;
      if (error is AuthException) {
        await widget.onLogout();
        return;
      }
      setState(() => _dashboardFuture = _loadDashboardData());
      await _showActionPopup(
          title: 'Upload Folder Gagal',
          message: error.toString(),
          success: false);
    } finally {
      if (mounted)
        setState(() {
          _isManagingDisposalImports = false;
          _disposalFolderProgress = '';
        });
    }
  }
}

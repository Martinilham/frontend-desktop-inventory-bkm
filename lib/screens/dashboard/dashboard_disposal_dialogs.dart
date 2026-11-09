// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, unused_element
part of '../dashboard_screen.dart';

extension DashboardDisposalDialogs on _DashboardScreenState {
  Future<void> _showEditDisposalDialog(Map<String, dynamic> disposal,
      {ValueChanged<Map<String, dynamic>>? onUpdated}) async {
    final id = disposal['id']?.toString() ?? disposal['_id']?.toString();
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data disposal tidak memiliki ID.')));
      return;
    }

    var selectedDivision =
        (disposal['division']?.toString() ?? 'GROCERY').toUpperCase();
    final apiDivisionValues =
        _disposalDivisions.map((division) => division['apiValue']).toSet();
    if (!apiDivisionValues.contains(selectedDivision)) {
      selectedDivision = 'GROCERY';
    }

    var selectedDate =
        DateTime.tryParse(disposal['date']?.toString() ?? '') ?? DateTime.now();
    final journalController = TextEditingController(
      text: disposal['journal']?.toString() ??
          disposal['description']?.toString() ??
          '',
    );
    List<String> newPhotoPaths = [];
    final existingPhotos = List<String>.from(disposal['photos'] ?? []);
    final removePhotoPaths = <String>{};
    List<String> newScannedPdfPaths = [];
    final existingScannedPdfs = List<String>.from(
      disposal['scannedPdfs'] ??
          (disposal['scannedPdf'] == null
              ? <String>[]
              : [disposal['scannedPdf'].toString()]),
    );
    final removeScannedPdfPaths = <String>{};
    String? previewNewScannedPdfPath;
    var isSaving = false;

    try {
      final updatedDisposal = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => DesktopModalShell(
            title: 'Edit Data Pembuangan',
            subtitle: 'Perbarui divisi, tanggal, jurnal, foto, atau PDF scan.',
            icon: Icons.edit_document,
            maxWidth: 600,
            child: SizedBox(
              width: 540,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedDivision,
                      items: _disposalDivisions
                          .map((division) => DropdownMenuItem(
                                value: division['apiValue'],
                                child: Text(division['label']!),
                              ))
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (value) => setDialogState(
                              () => selectedDivision = value ?? 'GROCERY'),
                      decoration: const InputDecoration(
                        labelText: 'Divisi',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: isSaving
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: this.context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedDate = picked);
                              }
                            },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Tanggal',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                            DateFormat('dd MMM yyyy').format(selectedDate)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: journalController,
                      enabled: !isSaving,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Jurnal',
                        prefixIcon: Icon(Icons.notes_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final result =
                                        await FilePicker.platform.pickFiles(
                                      allowMultiple: true,
                                      type: FileType.custom,
                                      allowedExtensions: ['jpg', 'jpeg', 'png'],
                                    );
                                    if (result == null) return;
                                    setDialogState(() {
                                      newPhotoPaths = result.paths
                                          .whereType<String>()
                                          .toList();
                                    });
                                  },
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(newPhotoPaths.isEmpty
                                ? 'Tambah foto'
                                : '${newPhotoPaths.length} foto baru'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final result =
                                        await FilePicker.platform.pickFiles(
                                      allowMultiple: true,
                                      type: FileType.custom,
                                      allowedExtensions: ['pdf'],
                                    );
                                    if (!mounted ||
                                        result == null ||
                                        result.paths
                                            .whereType<String>()
                                            .isEmpty) {
                                      return;
                                    }
                                    final pickedPaths =
                                        result.paths.whereType<String>();
                                    final combinedPaths = {
                                      ...newScannedPdfPaths,
                                      ...pickedPaths,
                                    }.toList();
                                    if (combinedPaths.length > 20) {
                                      ScaffoldMessenger.of(this.context)
                                          .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Maksimal 20 PDF baru per penyimpanan Edit.'),
                                      ));
                                      return;
                                    }
                                    setDialogState(() {
                                      newScannedPdfPaths = combinedPaths;
                                      previewNewScannedPdfPath ??=
                                          pickedPaths.first;
                                    });
                                  },
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: Text(newScannedPdfPaths.isEmpty
                                ? 'Tambah PDF'
                                : '${newScannedPdfPaths.length} PDF baru'),
                          ),
                        ),
                      ],
                    ),
                    if (existingPhotos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Foto tersimpan',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 168,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: existingPhotos.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final photo = existingPhotos[index];
                            final marked = removePhotoPaths.contains(photo);
                            return Stack(
                              children: [
                                Opacity(
                                  opacity: marked ? 0.35 : 1,
                                  child: LandscapeImageFrame(
                                    imageUrl: _storageUrl(photo),
                                    width: 250,
                                    height: 140,
                                    onTap: () => _showImagePreview(
                                      context,
                                      'Foto ${index + 1}',
                                      _storageUrl(photo),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Material(
                                    color: marked
                                        ? Colors.green.withOpacity(0.85)
                                        : Colors.red.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(8),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => setDialogState(() {
                                        if (marked) {
                                          removePhotoPaths.remove(photo);
                                        } else {
                                          removePhotoPaths.add(photo);
                                        }
                                      }),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          marked
                                              ? Icons.undo
                                              : Icons.delete_outline,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                    if (existingScannedPdfs.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'PDF tersimpan',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...existingScannedPdfs.map((pdfPath) {
                        final marked = removeScannedPdfPaths.contains(pdfPath);
                        final fileName =
                            Uri.decodeComponent(pdfPath.split('/').last);
                        return Opacity(
                          opacity: marked ? 0.4 : 1,
                          child: Card(
                            child: ListTile(
                              leading:
                                  const Icon(Icons.picture_as_pdf_outlined),
                              title: Text(fileName,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              onTap: marked
                                  ? null
                                  : () => _showPdfPreviewDialog(
                                      _storageUrl(pdfPath)),
                              trailing: IconButton(
                                tooltip:
                                    marked ? 'Batalkan hapus' : 'Hapus PDF',
                                onPressed: () => setDialogState(() {
                                  if (marked) {
                                    removeScannedPdfPaths.remove(pdfPath);
                                  } else {
                                    removeScannedPdfPaths.add(pdfPath);
                                  }
                                }),
                                icon: Icon(
                                    marked ? Icons.undo : Icons.delete_outline),
                                color: marked ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                    if (newScannedPdfPaths.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'PDF baru dipilih',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      ...newScannedPdfPaths.asMap().entries.map((entry) =>
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.picture_as_pdf_outlined),
                            title: Text(File(entry.value).uri.pathSegments.last,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () => setDialogState(
                                () => previewNewScannedPdfPath = entry.value),
                            trailing: IconButton(
                              tooltip: 'Hapus dari pilihan',
                              onPressed: () => setDialogState(() {
                                newScannedPdfPaths =
                                    List<String>.from(newScannedPdfPaths)
                                      ..removeAt(entry.key);
                                if (!newScannedPdfPaths
                                    .contains(previewNewScannedPdfPath)) {
                                  previewNewScannedPdfPath =
                                      newScannedPdfPaths.isEmpty
                                          ? null
                                          : newScannedPdfPaths.first;
                                }
                              }),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          )),
                      if (previewNewScannedPdfPath != null) ...[
                        const SizedBox(height: 8),
                        _buildLocalPdfPreviewBox(previewNewScannedPdfPath!),
                      ],
                    ],
                    if (newPhotoPaths.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Preview Foto Baru',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _DisposalPhotoPickerPreview(
                        photoPaths: newPhotoPaths,
                        onOpen: (path) {
                          final fileName = File(path).uri.pathSegments.last;
                          _showLocalImagePreview(fileName, path);
                        },
                        onRemove: (index) => setDialogState(() =>
                            newPhotoPaths = List<String>.from(newPhotoPaths)
                              ..removeAt(index)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        try {
                          final result = await widget.apiService.updateDisposal(
                            id,
                            division: selectedDivision,
                            date: selectedDate,
                            journal: journalController.text,
                            photoPaths: newPhotoPaths,
                            scannedPdfPaths: newScannedPdfPaths,
                            removePhotos: removePhotoPaths.toList(),
                            removeScannedPdfs: removeScannedPdfPaths.toList(),
                          );
                          if (!mounted) return;
                          Navigator.of(context).pop(result);
                        } catch (error) {
                          if (!mounted) return;
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Gagal mengupdate data: $error')));
                        }
                      },
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(isSaving ? 'Menyimpan...' : 'Simpan'),
              ),
            ],
          ),
        ),
      );
      if (updatedDisposal != null) {
        onUpdated?.call(updatedDisposal);
        if (!mounted) return;
        await _showActionPopup(
            title: 'Berhasil', message: 'Data disposal berhasil diupdate.');
        if (!mounted) return;
        await _refreshDashboard();
      }
    } finally {
      journalController.dispose();
    }
  }

  Future<void> _showDisposalDetailDialog(Map<String, dynamic> disposal) async {
    final detailData = Map<String, dynamic>.from(disposal);
    _applyDisposalPhotoRotations(detailData);

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDetailState) => DesktopModalShell(
          title: 'Detail Data Pembuangan',
          subtitle: 'Daftar item, dokumentasi, jurnal, dan file pendukung',
          icon: Icons.description_outlined,
          maxWidth: 1200,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 660, maxWidth: 1140),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                      'Divisi', detailData['division']?.toString() ?? '-'),
                  _buildDetailRow(
                      'Tanggal', detailData['date']?.toString() ?? '-'),
                  _buildDetailRow(
                      'Jurnal',
                      detailData['journal']?.toString() ??
                          detailData['description']?.toString() ??
                          '-'),
                  const SizedBox(height: 16),
                  _buildDisposalItemsTable(detailData),
                  const SizedBox(height: 20),
                  _buildDisposalDocumentationPreview(detailData),
                  const SizedBox(height: 12),
                  _buildDetailRow('Uploaded By',
                      detailData['uploadedBy']?.toString() ?? '-'),
                ],
              ),
            ),
          ),
          actions: [
            if (List<String>.from(detailData['photos'] ?? []).isNotEmpty)
              OutlinedButton.icon(
                onPressed: () async {
                  final saved = await _savePhotoRotations(detailData);
                  if (!saved || !mounted) return;
                  setDetailState(() {
                    detailData['photoRotations'] =
                        _photoRotationsForDisposal(detailData);
                  });
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Simpan Rotasi'),
              ),
            SizedBox(
              width: 220,
              child: PrimaryButton(
                label: 'Download PDF',
                leading: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: () => _exportSingleDisposalToPdf(detailData),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _printDisposal(detailData),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print'),
            ),
            OutlinedButton.icon(
              onPressed: () => _showEditDisposalDialog(
                detailData,
                onUpdated: (updated) {
                  setDetailState(() {
                    detailData
                      ..clear()
                      ..addAll(updated);
                  });
                },
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => _confirmDeleteDisposal(detailData),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisposalItemsTable(Map<String, dynamic> disposal) {
    final items = List<dynamic>.from(disposal['items'] ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final totalCostAmount = items.fold<double>(
      0,
      (total, item) => total + ((item['costAmount'] as num?)?.toDouble() ?? 0),
    );
    final costFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 2,
    );
    final quantityFormatter = NumberFormat('#,##0.##', 'id_ID');
    if (items.isEmpty) {
      return const Text('Belum ada detail item. Import Excel untuk melengkapi '
          'data pembuangan pada tanggal dan kategori ini.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Barang yang Dibuang (${items.length} item)',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'Total Cost Amount: ${costFormatter.format(totalCostAmount)}',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Receipt Status dihitung sesuai kondisi sampai tanggal jurnal ${disposal['date']?.toString() ?? '-'}; qty sisa = Purchased/Received sampai tanggal tersebut dikurangi qty jurnal ini.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
              ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: math.min(360.0, 58.0 + items.length * 56.0),
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                dataRowMinHeight: 48,
                dataRowMaxHeight: 72,
                columns: const [
                  DataColumn(label: Text('Item number')),
                  DataColumn(label: Text('Product name')),
                  DataColumn(label: Text('Warehouse')),
                  DataColumn(label: Text('Quantity'), numeric: true),
                  DataColumn(label: Text('Purchased / Received'), numeric: true),
                  DataColumn(label: Text('Ordered'), numeric: true),
                  DataColumn(label: Text('Sisa'), numeric: true),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Cost Amount'), numeric: true),
                  DataColumn(label: Text('Offset account')),
                ],
                rows: items
                    .map((item) => DataRow(cells: [
                          DataCell(SelectableText(
                              item['itemNumber']?.toString() ?? '-')),
                          DataCell(SizedBox(
                              width: 360,
                              child: Text(
                                  item['productName']?.toString() ?? '-'))),
                          DataCell(Text(item['warehouse']?.toString() ?? '-')),
                          DataCell(Text(quantityFormatter.format(
                              ((item['quantity'] as num?)?.toDouble() ??
                                      double.tryParse(item['quantity']?.toString() ?? '') ??
                                      0)
                                  .abs()))),
                          DataCell(Text(item['purchasedQuantity'] == null
                              ? '-'
                              : quantityFormatter.format(
                                  item['purchasedQuantity']))),
                          DataCell(Text(quantityFormatter.format(
                              (item['orderedQuantity'] as num?)?.toDouble() ?? 0))),
                          DataCell(Text(item['remainingQuantity'] == null
                              ? '-'
                              : quantityFormatter.format(item['remainingQuantity']))),
                          DataCell(_disposalPostingStatusBadge({
                            'postingStatus': item['stockStatus'] ?? 'unknown',
                          })),
                          DataCell(Text(costFormatter.format(
                              (item['costAmount'] as num?)?.toDouble() ?? 0))),
                          DataCell(SelectableText(
                              item['offsetAccount']?.toString() ?? '-')),
                        ]))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisposalDocumentationPreview(Map<String, dynamic> disposal) {
    final photos = List<String>.from(disposal['photos'] ?? []);
    final scannedPdfs = List<String>.from(
      disposal['scannedPdfs'] ??
          (disposal['scannedPdf'] == null
              ? <String>[]
              : [disposal['scannedPdf'].toString()]),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dokumentasi',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (photos.isEmpty)
          Container(
            height: 110,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: const Color(0xFFF1F3F6),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('Belum ada foto dokumentasi.'),
          )
        else
          SizedBox(
            height: 224,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final photoPath = photos[index];
                final imageUrl = _storageUrl(photoPath);
                return _buildRotatableDisposalPhoto(
                  photoPath: photoPath,
                  imageUrl: imageUrl,
                  title: 'Foto ${index + 1}',
                );
              },
            ),
          ),
        const SizedBox(height: 18),
        Text('PDF Scan',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (scannedPdfs.isEmpty)
          Container(
            height: 86,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: const Color(0xFFF1F3F6),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('Belum ada PDF scan.'),
          )
        else
          ...scannedPdfs.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Uri.decodeComponent(entry.value.split('/').last)),
                    const SizedBox(height: 6),
                    _buildPdfPreviewBox(entry.value),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildPdfPreviewBox(String relativePath) {
    final pdfUrl = _storageUrl(relativePath);
    final pdfBytes = _disposalPdfBytesCache.putIfAbsent(
        pdfUrl, () => _loadNetworkFile(pdfUrl));

    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Uint8List>(
        future: pdfBytes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: OutlinedButton.icon(
                onPressed: () => _showPdfPreviewDialog(pdfUrl),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Buka PDF scan'),
              ),
            );
          }

          final bytes = snapshot.data!;
          return _buildPdfRasterPreview(
            bytes,
            onOpen: () => _showPdfBytesPreviewDialog('Preview PDF Scan', bytes),
          );
        },
      ),
    );
  }

  Widget _buildRotatableDisposalPhoto({
    required String photoPath,
    required String imageUrl,
    required String title,
  }) {
    return SizedBox(
      width: 320,
      height: 216,
      child: ValueListenableBuilder<int>(
        valueListenable: _photoRotationVersion,
        builder: (context, _, __) {
          final turns = _photoQuarterTurns[photoPath] ?? 0;
          return Column(
            children: [
              LandscapeImageFrame(
                imageUrl: imageUrl,
                width: 320,
                height: 180,
                quarterTurns: turns,
                onTap: () => _showImagePreview(context, title, imageUrl,
                    quarterTurns: turns),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _photoToolButton(
                    tooltip: 'Rotate kiri',
                    icon: Icons.rotate_left,
                    onPressed: () => _rotatePhoto(photoPath, -1),
                  ),
                  const SizedBox(width: 6),
                  _photoToolButton(
                    tooltip: 'Reset rotate',
                    icon: Icons.crop_rotate,
                    onPressed: () => _resetPhotoRotation(photoPath),
                  ),
                  const SizedBox(width: 6),
                  _photoToolButton(
                    tooltip: 'Rotate kanan',
                    icon: Icons.rotate_right,
                    onPressed: () => _rotatePhoto(photoPath, 1),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _photoToolButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 28,
      height: 24,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 28, height: 24),
        iconSize: 16,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }

  void _rotatePhoto(String photoPath, int direction) {
    setState(() {
      final current = _photoQuarterTurns[photoPath] ?? 0;
      _photoQuarterTurns[photoPath] = (current + direction) % 4;
      if (_photoQuarterTurns[photoPath]! < 0) {
        _photoQuarterTurns[photoPath] = 3;
      }
      _dirtyPhotoRotations.add(photoPath);
    });
    _photoRotationVersion.value++;
  }

  void _resetPhotoRotation(String photoPath) {
    setState(() {
      _photoQuarterTurns[photoPath] = 0;
      _dirtyPhotoRotations.add(photoPath);
    });
    _photoRotationVersion.value++;
  }

  Map<String, int> _photoRotationsForDisposal(Map<String, dynamic> disposal) {
    final photos = List<String>.from(disposal['photos'] ?? []);
    return {
      for (final photo in photos)
        photo: ((_photoQuarterTurns[photo] ??
                        _storedPhotoRotation(disposal, photo)) %
                    4 +
                4) %
            4,
    };
  }

  int _storedPhotoRotation(Map<String, dynamic> disposal, String photoPath) {
    final rotations = disposal['photoRotations'];
    if (rotations is Map) {
      final value = rotations[photoPath];
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }
    return 0;
  }

  void _applyDisposalPhotoRotations(Map<String, dynamic> disposal) {
    final photos = List<String>.from(disposal['photos'] ?? []);
    setState(() {
      for (final photo in photos) {
        _photoQuarterTurns[photo] = _storedPhotoRotation(disposal, photo);
      }
      _dirtyPhotoRotations.removeWhere((photo) => photos.contains(photo));
    });
    _photoRotationVersion.value++;
  }

  bool _hasUnsavedPhotoRotations(Map<String, dynamic> disposal) {
    final photos = List<String>.from(disposal['photos'] ?? []);
    return photos.any(_dirtyPhotoRotations.contains);
  }

  Future<bool> _savePhotoRotations(Map<String, dynamic> disposal) async {
    final id = disposal['id']?.toString() ?? disposal['_id']?.toString();
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data disposal tidak memiliki ID.')));
      return false;
    }

    try {
      final updated = await widget.apiService.updateDisposal(
        id,
        division: disposal['division']?.toString() ?? 'GROCERY',
        date: DateTime.tryParse(disposal['date']?.toString() ?? '') ??
            DateTime.now(),
        journal: disposal['journal']?.toString() ??
            disposal['description']?.toString() ??
            '',
        photoRotations: _photoRotationsForDisposal(disposal),
      );
      if (!mounted) return false;
      setState(() {
        disposal
          ..clear()
          ..addAll(updated);
        final photos = List<String>.from(disposal['photos'] ?? []);
        _dirtyPhotoRotations.removeWhere((photo) => photos.contains(photo));
      });
      _applyDisposalPhotoRotations(disposal);
      await _showActionPopup(
          title: 'Berhasil', message: 'Rotasi foto berhasil disimpan.');
      if (!mounted) return true;
      await _refreshDashboard();
      return true;
    } catch (error) {
      if (!mounted) return false;
      await _showActionPopup(
          title: 'Simpan Gagal',
          message: 'Gagal menyimpan rotasi: $error',
          success: false);
      return false;
    }
  }

  Widget _buildLocalPdfPreviewBox(String path) {
    final pdfBytes = _disposalPdfBytesCache.putIfAbsent(
        'local:$path', () => File(path).readAsBytes());
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Uint8List>(
        future: pdfBytes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Gagal memuat PDF baru'));
          }

          final bytes = snapshot.data!;
          return _buildPdfRasterPreview(
            bytes,
            onOpen: () => _showPdfBytesPreviewDialog('Preview PDF Baru', bytes),
          );
        },
      ),
    );
  }

  Widget _buildPdfRasterPreview(Uint8List bytes,
      {required VoidCallback onOpen}) {
    final pageStream = _rasterizePdfPagesStream(bytes, maxPages: 4, dpi: 60);
    final rotations = <int, int>{};
    return Stack(
      children: [
        StatefulBuilder(
          builder: (context, setState) {
            return StreamBuilder<List<Uint8List>>(
              stream: pageStream,
              initialData: const [],
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Gagal menampilkan isi PDF'));
                }
                final pages = snapshot.data ?? const <Uint8List>[];
                if (pages.isEmpty &&
                    snapshot.connectionState == ConnectionState.done) {
                  return const Center(child: Text('PDF tidak memiliki halaman'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  scrollDirection: Axis.horizontal,
                  itemCount: pages.length +
                      (snapshot.connectionState == ConnectionState.done ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index >= pages.length) {
                      return const SizedBox(
                        width: 150,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final turns = rotations[index] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              tooltip: 'Rotate kiri',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setState(() => rotations[index] = (turns + 3) % 4),
                              icon: const Icon(Icons.rotate_left, size: 18),
                            ),
                            Text('Hal. ${index + 1}'),
                            IconButton(
                              tooltip: 'Rotate kanan',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setState(() => rotations[index] = (turns + 1) % 4),
                              icon: const Icon(Icons.rotate_right, size: 18),
                            ),
                          ]),
                          Expanded(
                            child: InkWell(
                              onTap: onOpen,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: RotatedBox(
                                    quarterTurns: turns,
                                    child: Image.memory(pages[index],
                                        width: 150, fit: BoxFit.contain),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        Positioned(
          top: 10,
          right: 10,
          child: ElevatedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_full, size: 16),
            label: const Text('Perbesar'),
          ),
        ),
      ],
    );
  }

  Stream<List<Uint8List>> _rasterizePdfPagesStream(Uint8List bytes,
      {required int maxPages, required double dpi}) async* {
    final pages = <Uint8List>[];
    await for (final page in Printing.raster(bytes, dpi: dpi)) {
      pages.add(await page.toPng());
      yield List<Uint8List>.unmodifiable(pages);
      if (pages.length >= maxPages) break;
    }
  }

  Future<Uint8List> _loadNetworkFile(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw Exception('File tidak dapat dimuat');
    }
    return response.bodyBytes;
  }

  Future<void> _showPdfPreviewDialog(String pdfUrl) async {
    await showDialog<void>(
      context: context,
      builder: (context) => DesktopModalShell(
        title: 'Preview PDF',
        subtitle: 'Dokumen scan',
        icon: Icons.picture_as_pdf_outlined,
        maxWidth: 1040,
        child: SizedBox(
          width: 980,
          height: 620,
          child: FutureBuilder<Uint8List>(
            future: _loadNetworkFile(pdfUrl),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(child: Text('Gagal memuat PDF'));
              }
              final bytes = snapshot.data!;
              return _buildFullPdfRasterView(bytes);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showPdfBytesPreviewDialog(String title, Uint8List bytes) async {
    await showDialog<void>(
      context: context,
      builder: (context) => DesktopModalShell(
        title: title,
        subtitle: 'Dokumen scan',
        icon: Icons.picture_as_pdf_outlined,
        maxWidth: 1040,
        child: SizedBox(
          width: 980,
          height: 620,
          child: _buildFullPdfRasterView(bytes),
        ),
      ),
    );
  }

  Widget _buildFullPdfRasterView(Uint8List bytes) {
    final pageStream = _rasterizePdfPagesStream(bytes, maxPages: 40, dpi: 80);
    final rotations = <int, int>{};
    return StatefulBuilder(
      builder: (context, setState) => StreamBuilder<List<Uint8List>>(
        stream: pageStream,
        initialData: const [],
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Gagal menampilkan isi PDF'));
          }
          final pages = snapshot.data ?? const <Uint8List>[];
          if (pages.isEmpty && snapshot.connectionState == ConnectionState.done) {
            return const Center(child: Text('PDF tidak memiliki halaman'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: pages.length +
                (snapshot.connectionState == ConnectionState.done ? 0 : 1),
            itemBuilder: (context, index) {
              if (index >= pages.length) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final turns = rotations[index] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text('Halaman ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        tooltip: 'Rotate kiri',
                        onPressed: () => setState(() => rotations[index] = (turns + 3) % 4),
                        icon: const Icon(Icons.rotate_left),
                      ),
                      IconButton(
                        tooltip: 'Rotate kanan',
                        onPressed: () => setState(() => rotations[index] = (turns + 1) % 4),
                        icon: const Icon(Icons.rotate_right),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black12),
                        ),
                        child: InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 5,
                          child: RotatedBox(
                            quarterTurns: turns,
                            child: Image.memory(pages[index], fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

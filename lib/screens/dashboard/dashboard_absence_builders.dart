// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, unused_element
part of '../dashboard_screen.dart';

extension DashboardAbsenceBuilders on _DashboardScreenState {
  Widget _buildCustomerUpdateFormPanel(
    BuildContext context,
    List<dynamic> items,
  ) {
    Map<String, dynamic>? selected;
    if (_selectedCustomerFormDocumentId != null) {
      for (final raw in items) {
        final item = Map<String, dynamic>.from(raw as Map);
        final id = item['id']?.toString() ?? item['_id']?.toString();
        if (id == _selectedCustomerFormDocumentId) {
          selected = item;
          break;
        }
      }
    }

    final baseUrl = widget.apiService.baseUrl;
    final customerRows = List<Map<String, dynamic>>.from(
      (selected?['customerRows'] as List<dynamic>? ?? const [])
          .map((row) => Map<String, dynamic>.from(row as Map)),
    );
    final formDate = DateTime.tryParse(selected?['formDate']?.toString() ?? '');
    final section = SectionCard(
      title: selected == null
          ? 'Dokumentasi Customer (${items.length})'
          : selected['name']?.toString() ?? 'Detail Dokumentasi',
      actions: [
        if (selected != null)
          OutlinedButton.icon(
            onPressed: () => setState(() => _selectedCustomerFormDocumentId = null),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Daftar Dokumentasi'),
          ),
        OutlinedButton.icon(
          onPressed: _refreshDashboard,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
      child: selected == null
          ? items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Text('Belum ada dokumentasi. Tambahkan form dari aplikasi mobile.'),
                )
              : Column(
                  children: items.map((raw) {
                    final item = Map<String, dynamic>.from(raw as Map);
                    final id = item['id']?.toString() ?? item['_id']?.toString() ?? '';
                    final image = item['imageUrl']?.toString() ?? '';
                    final rows = List<dynamic>.from(item['customerRows'] ?? []);
                    final date = DateTime.tryParse(item['formDate']?.toString() ?? '');
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        leading: SizedBox(
                          width: 88,
                          height: 64,
                          child: image.isEmpty
                              ? const Icon(Icons.image_not_supported_outlined)
                              : Image.network('$baseUrl$image', fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined)),
                        ),
                        title: Text(item['name']?.toString() ?? 'Form Customer',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${date == null ? '-' : DateFormat('dd/MM/yyyy').format(date)} • ${rows.length} baris data'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: id.isEmpty ? null : () => setState(() => _selectedCustomerFormDocumentId = id),
                      ),
                    );
                  }).toList(),
                )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanggal form: ${formDate == null ? '-' : DateFormat('dd/MM/yyyy').format(formDate)}',
                    style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 14),
                if ((selected['imageUrl']?.toString() ?? '').isNotEmpty)
                  LandscapeImageFrame(
                    imageUrl: '$baseUrl${selected['imageUrl']}',
                    height: 340,
                    onTap: () => _showImagePreview(context,
                        selected?['name']?.toString() ?? 'Form Customer',
                        '$baseUrl${selected?['imageUrl']}'),
                  ),
                const SizedBox(height: 18),
                Text('Data Customer (${customerRows.length})',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                if (customerRows.isEmpty)
                  Text(
                    (selected['recognizedText']?.toString() ?? '').trim().isEmpty
                        ? 'Data OCR belum tersedia. Jalankan Baca Form dengan OCR dari aplikasi mobile.'
                        : selected['recognizedText'].toString(),
                    style: const TextStyle(color: AppTheme.textSecondary),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Tanggal')),
                        DataColumn(label: Text('No Member')),
                        DataColumn(label: Text('Nama')),
                        DataColumn(label: Text('Alamat')),
                        DataColumn(label: Text('No Telepon')),
                        DataColumn(label: Text('Keterangan')),
                        DataColumn(label: Text('Staff Kasir')),
                      ],
                      rows: customerRows.map((row) => DataRow(cells: [
                        DataCell(Text((row['date'] ?? selected?['formDate'] ?? '-').toString())),
                        DataCell(Text((row['memberNumber'] ?? '-').toString())),
                        DataCell(Text((row['customerName'] ?? '-').toString())),
                        DataCell(Text((row['address'] ?? '-').toString())),
                        DataCell(Text((row['phone'] ?? '-').toString())),
                        DataCell(Text((row['note'] ?? '-').toString())),
                        DataCell(Text((row['cashier'] ?? '-').toString())),
                      ])).toList(),
                    ),
                  ),
              ],
            ),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Text(
            'Dokumentasi Form Update Data Customer',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 32, color: AppTheme.textPrimary),
          ),
        ),
        Padding(
          padding: _contentPadding(context),
          child: section,
        ),
      ],
    );
  }
  Widget _buildAbsenceCheckPanel(
    BuildContext context,
    List<dynamic> items, {
    String title = 'Dokumentasi Absensi',
    String listTitle = 'Data Absensi Cek',
    String description =
        'Dokumentasi surat izin, sakit, cuti, lemburan, dan pulang cepat.',
  }) {
    final baseUrl = widget.apiService.baseUrl;
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Text(title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 32,
                      color: AppTheme.textPrimary,
                    )),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final listPanel = _buildAbsenceListPanel(
                context,
                items,
                baseUrl,
                title: listTitle,
                description: description,
              );
              if (constraints.maxWidth < 980) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAbsenceUploadPanel(),
                    const SizedBox(height: 20),
                    listPanel,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 420, child: _buildAbsenceUploadPanel()),
                  const SizedBox(width: 20),
                  Expanded(child: listPanel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenceListPanel(
    BuildContext context,
    List<dynamic> items,
    String baseUrl, {
    required String title,
    required String description,
  }) {
    return SectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Belum ada dokumentasi absensi.',
                  style: TextStyle(color: Colors.black54)),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 3
                    : constraints.maxWidth > 520
                        ? 2
                        : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: crossAxisCount == 1 ? 1.08 : 0.82,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final map = items[index] as Map<String, dynamic>;
                    final imageUrl = map['imageUrl']?.toString() ?? '';
                    final fullUrl =
                        imageUrl.isNotEmpty ? '$baseUrl$imageUrl' : '';
                    final employeeName = map['employeeName']?.toString() ?? '-';
                    final documentLabel = map['documentLabel']?.toString() ??
                        map['documentType']?.toString() ??
                        '-';
                    return _buildAbsenceCard(
                      item: map,
                      employeeName: employeeName,
                      documentLabel: documentLabel,
                      uploadedBy: map['uploadedBy']?.toString() ?? '-',
                      createdAt: map['createdAt']?.toString() ?? '-',
                      imageUrl: fullUrl,
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAbsenceUploadPanel() {
    final selectedFileName = _absenceProofPath == null
        ? null
        : File(_absenceProofPath!).uri.pathSegments.last;
    return SectionCard(
      title: 'Tambah Dokumentasi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedAbsenceType,
            items: _DashboardScreenState._absenceDocumentTypes
                .map((item) => DropdownMenuItem(
                      value: item['value'],
                      child: Text(item['label'] ?? '-'),
                    ))
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedAbsenceType = value ?? 'izin'),
            decoration: const InputDecoration(
              labelText: 'Jenis dokumentasi',
              prefixIcon: Icon(Icons.assignment_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _absenceNameController,
            decoration: const InputDecoration(
              labelText: 'Nama',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),
          LandscapeImageFrame(
            filePath: _absenceProofPath,
            width: double.infinity,
            placeholder: const Center(
              child: Icon(Icons.image_outlined,
                  size: 44, color: Color(0xFF98A2B3)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickAbsenceProof,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(selectedFileName ?? 'Pilih foto bukti'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: _isUploadingAbsence ? 'Mengirim...' : 'Simpan dokumentasi',
              leading: const Icon(Icons.cloud_upload_outlined),
              isLoading: _isUploadingAbsence,
              onPressed: _isUploadingAbsence ? null : _submitAbsenceUpload,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenceCard({
    required Map<String, dynamic> item,
    required String employeeName,
    required String documentLabel,
    required String uploadedBy,
    required String createdAt,
    required String imageUrl,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: LandscapeImageFrame(
              imageUrl: imageUrl.isEmpty ? null : imageUrl,
              onTap: imageUrl.isEmpty
                  ? null
                  : () => _showImagePreview(context, employeeName, imageUrl),
              placeholder: const Center(child: Text('Tidak ada foto')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employeeName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text(documentLabel,
                    style: const TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Upload: $uploadedBy',
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(createdAt,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: imageUrl.isEmpty
                            ? null
                            : () => _showImagePreview(
                                context, employeeName, imageUrl),
                        child: const Text('Preview'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: imageUrl.isEmpty
                            ? null
                            : () =>
                                _downloadImage(context, imageUrl, employeeName),
                        child: const Text('Download'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _showEditAbsenceDialog(item),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Hapus',
                      onPressed: () => _confirmDeleteAbsence(item),
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFE5484D)),
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

  Future<void> _showEditAbsenceDialog(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? item['_id']?.toString();
    if (id == null || id.isEmpty) return;
    final nameController =
        TextEditingController(text: item['employeeName']?.toString() ?? '');
    var selectedType = item['documentType']?.toString() ?? 'izin';
    String? newPhotoPath;
    var isSaving = false;
    try {
      final updated = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => DesktopModalShell(
            title: 'Edit Dokumentasi Absensi',
            subtitle: item['employeeName']?.toString() ?? '-',
            icon: Icons.edit_document,
            maxWidth: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  items: _DashboardScreenState._absenceDocumentTypes
                      .map((type) => DropdownMenuItem(
                            value: type['value'],
                            child: Text(type['label'] ?? '-'),
                          ))
                      .toList(),
                  onChanged: isSaving
                      ? null
                      : (value) =>
                          setDialogState(() => selectedType = value ?? 'izin'),
                  decoration: const InputDecoration(
                    labelText: 'Jenis dokumentasi',
                    prefixIcon: Icon(Icons.assignment_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'jpeg', 'png'],
                          );
                          if (result?.paths.whereType<String>().isEmpty ?? true)
                            return;
                          setDialogState(() => newPhotoPath =
                              result!.paths.whereType<String>().first);
                        },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(newPhotoPath == null
                      ? 'Ganti foto bukti'
                      : 'Foto baru siap'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              PrimaryButton(
                label: isSaving ? 'Menyimpan...' : 'Simpan',
                leading: const Icon(Icons.save_outlined),
                isLoading: isSaving,
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        try {
                          final result =
                              await widget.apiService.updateAbsenceDocument(
                            id,
                            employeeName: nameController.text.trim(),
                            documentType: selectedType,
                            proofPhotoPath: newPhotoPath,
                          );
                          if (context.mounted) {
                            Navigator.of(context).pop(result);
                          }
                        } catch (error) {
                          setDialogState(() => isSaving = false);
                          if (!mounted) return;
                          await _showActionPopup(
                              title: 'Update Gagal',
                              message: error.toString(),
                              success: false);
                        }
                      },
              ),
            ],
          ),
        ),
      );
      if (updated != null) {
        await _showActionPopup(
            title: 'Berhasil',
            message: 'Dokumentasi absensi berhasil diperbarui');
        await _refreshDashboard();
      }
    } finally {
      nameController.dispose();
    }
  }

  Future<void> _confirmDeleteAbsence(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? item['_id']?.toString();
    if (id == null || id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DesktopModalShell(
        title: 'Hapus Dokumentasi Absensi',
        subtitle: 'Data yang dihapus tidak dapat dikembalikan.',
        icon: Icons.delete_outline,
        maxWidth: 430,
        child: Text(
            'Yakin ingin menghapus dokumentasi ${item['employeeName'] ?? '-'}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.apiService.deleteAbsenceDocument(id);
      await _showActionPopup(
          title: 'Berhasil', message: 'Dokumentasi absensi berhasil dihapus');
      await _refreshDashboard();
    } catch (error) {
      await _showActionPopup(
          title: 'Hapus Gagal', message: error.toString(), success: false);
    }
  }

  Widget _buildFilePanel(
    List<dynamic> files, {
    String title = 'Daftar File',
    String emptyMessage = 'Belum ada file di repository',
  }) {
    return SectionCard(
      title: title,
      child: files.isEmpty
          ? Text(emptyMessage)
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: files.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final map = Map<String, dynamic>.from(files[index] as Map);
                final fileName = map['originalName']?.toString() ?? '';
                final isPdf = fileName.toLowerCase().endsWith('.pdf');
                final relativePath = map['relativePath']?.toString() ?? '';
                final previewUrl = _storageUrl(relativePath);
                final displayName = (map['name']?.toString().trim().isNotEmpty ?? false)
                    ? map['name'].toString()
                    : (map['storedName'] ?? fileName);
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => isPdf
                            ? _showPdfPreviewDialog(previewUrl)
                            : _showReceiptImagePreview(previewUrl, displayName.toString()),
                        child: Stack(fit: StackFit.expand, children: [
                          if (isPdf)
                            Container(
                              color: AppTheme.tableHeader,
                              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.picture_as_pdf_outlined, size: 68, color: Colors.redAccent),
                                SizedBox(height: 8),
                                Text('PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                              ]),
                            )
                          else
                            Image.network(previewUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppTheme.tableHeader,
                                child: const Icon(Icons.broken_image_outlined, size: 48),
                              ),
                              loadingBuilder: (context, child, progress) => progress == null
                                  ? child
                                  : const Center(child: CircularProgressIndicator()),
                            ),
                          Positioned(right: 8, bottom: 8, child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: Icon(isPdf ? Icons.zoom_in : Icons.zoom_in, color: Colors.white),
                          )),
                        ]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 5, 4, 5),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text(displayName.toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if ((map['description']?.toString().trim().isNotEmpty ?? false))
                            Text(map['description'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          if ((map['documentDate']?.toString().isNotEmpty ?? false))
                            Text('Tanggal: ${map['documentDate'].toString().split('T').first}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          if ((map['fromLocation']?.toString().trim().isNotEmpty ?? false))
                            Text('Dari: ${map['fromLocation']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          if ((map['toLocation']?.toString().trim().isNotEmpty ?? false))
                            Text('Ke: ${map['toLocation']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ])),
                        IconButton(tooltip: 'Edit nama dan deskripsi', onPressed: () => _editReceiptAttachment(map), icon: const Icon(Icons.edit_outlined, size: 19)),
                        IconButton(tooltip: 'Hapus lampiran', onPressed: () => _deleteReceiptAttachment(map), icon: const Icon(Icons.delete_outline, size: 19, color: Colors.redAccent)),
                      ]),
                    ),
                  ]),
                );
              },
            ),
    );
  }

  Future<void> _showReceiptImagePreview(String imageUrl, String title) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: SizedBox(
          width: 900,
          height: 700,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
                IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close)),
              ]),
            ),
            Expanded(child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 6,
              child: Center(child: Image.network(imageUrl, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text('Gagal memuat gambar'),
                loadingBuilder: (context, child, progress) => progress == null ? child : const CircularProgressIndicator(),
              )),
            )),
          ]),
        ),
      ),
    );
  }
  Future<void> _pickReceiptDate(TextEditingController controller) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _uploadReceiptAttachment() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final dateController = TextEditingController();
    final fromController = TextEditingController();
    final toController = TextEditingController();
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final filePaths = picked.files.map((file) => file.path).whereType<String>().toList();
      if (filePaths.isEmpty || !mounted) return;
      final accepted = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
        title: Text('Tambah ${filePaths.length} Lampiran Tanda Terima'),
        content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama (opsional)')),
          const SizedBox(height: 12),
          TextField(controller: descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Deskripsi (opsional)')),
          const SizedBox(height: 12),
          TextField(controller: dateController, readOnly: true, onTap: () => _pickReceiptDate(dateController), decoration: InputDecoration(labelText: 'Tanggal (opsional)', suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [ IconButton(tooltip: 'Hapus tanggal', icon: const Icon(Icons.clear), onPressed: () => dateController.clear()), IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _pickReceiptDate(dateController)) ]))),
          const SizedBox(height: 12),
          _ReceiptLocationDropdown(controller: fromController, label: 'Dari mana', options: _receiptLocationOptions),
          const SizedBox(height: 12),
          _ReceiptLocationDropdown(controller: toController, label: 'Ke mana', options: _receiptLocationOptions),
          Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: _manageReceiptLocations, icon: const Icon(Icons.settings_outlined), label: const Text('Atur pilihan lokasi'))),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: Text('${filePaths.length} file dipilih')),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Unggah')),
        ],
      ));
      if (accepted != true || !mounted) return;
      setState(() => _isUploadingReceiptAttachment = true);
      final result = await widget.apiService.uploadReceiptAttachment(
        filePaths: filePaths,
        name: nameController.text,
        description: descriptionController.text,
        documentDate: dateController.text,
        fromLocation: fromController.text,
        toLocation: toController.text,
      );
      final uploadedFiles = List<dynamic>.from(result['files'] ?? []);
      if (mounted && uploadedFiles.isNotEmpty) {
        setState(() => _receiptFilesOverride = [
          ...uploadedFiles,
          ...(_receiptFilesOverride ?? const <dynamic>[]),
        ]);
      }
      await _showActionPopup(title: 'Berhasil', message: '${filePaths.length} lampiran berhasil diunggah.');
    } catch (error) {
      if (mounted) await _showActionPopup(title: 'Unggah Gagal', message: error.toString(), success: false);
    } finally {
      Future<void>.delayed(const Duration(milliseconds: 300), nameController.dispose);
      Future<void>.delayed(const Duration(milliseconds: 300), descriptionController.dispose);
      Future<void>.delayed(const Duration(milliseconds: 300), dateController.dispose);
      Future<void>.delayed(const Duration(milliseconds: 300), fromController.dispose);
      Future<void>.delayed(const Duration(milliseconds: 300), toController.dispose);
      if (mounted) setState(() => _isUploadingReceiptAttachment = false);
    }
  }

  Future<void> _deleteReceiptAttachment(Map<String, dynamic> file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Lampiran?'),
        content: Text('File "${file['name']?.toString().isNotEmpty == true ? file['name'] : file['originalName']}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final id = file['id'].toString();
      await widget.apiService.deleteReceiptAttachment(id);
      if (mounted) {
        setState(() => _receiptFilesOverride = (_receiptFilesOverride ?? <dynamic>[])
            .where((entry) => (entry as Map)['id']?.toString() != id)
            .toList());
      }
      await _showActionPopup(title: 'Berhasil', message: 'Lampiran berhasil dihapus.');
    } catch (error) {
      if (mounted) await _showActionPopup(title: 'Gagal Menghapus Lampiran', message: error.toString(), success: false);
    }
  }
  Future<void> _editReceiptAttachment(Map<String, dynamic> file) async {
    final nameController = TextEditingController(text: file['name']?.toString() ?? '');
    final descriptionController = TextEditingController(text: file['description']?.toString() ?? '');
    final dateController = TextEditingController(text: file['documentDate']?.toString().split('T').first ?? '');
    final fromController = TextEditingController(text: file['fromLocation']?.toString() ?? '');
    final toController = TextEditingController(text: file['toLocation']?.toString() ?? '');
    try {
      final accepted = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Lampiran'),
        content: SizedBox(width: 460, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama (opsional)')),
          const SizedBox(height: 12),
          TextField(controller: descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Deskripsi (opsional)')),
          const SizedBox(height: 12),
          TextField(controller: dateController, readOnly: true, onTap: () => _pickReceiptDate(dateController), decoration: InputDecoration(labelText: 'Tanggal (opsional)', suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [ IconButton(tooltip: 'Hapus tanggal', icon: const Icon(Icons.clear), onPressed: () => dateController.clear()), IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _pickReceiptDate(dateController)) ]))),
          const SizedBox(height: 12),
          _ReceiptLocationDropdown(controller: fromController, label: 'Dari mana', options: _receiptLocationOptions),
          const SizedBox(height: 12),
          _ReceiptLocationDropdown(controller: toController, label: 'Ke mana', options: _receiptLocationOptions),
          Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: _manageReceiptLocations, icon: const Icon(Icons.settings_outlined), label: const Text('Atur pilihan lokasi'))),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Simpan')),
        ],
      ));
      if (accepted != true || !mounted) return;
      final updated = await widget.apiService.updateReceiptAttachment(
        id: file['id'].toString(),
        name: nameController.text,
        description: descriptionController.text,
        documentDate: dateController.text,
        fromLocation: fromController.text,
        toLocation: toController.text,
      );
      if (mounted && updated.isNotEmpty) {
        setState(() => _receiptFilesOverride = (_receiptFilesOverride ?? <dynamic>[])
            .map((entry) => (entry as Map)['id']?.toString() == file['id']?.toString()
                ? updated
                : entry)
            .toList());
      }
      await _showActionPopup(title: 'Berhasil', message: 'Informasi lampiran diperbarui.');
    } catch (error) {
      if (mounted) await _showActionPopup(title: 'Gagal Mengubah Lampiran', message: error.toString(), success: false);
    } finally {
      Future<void>.delayed(const Duration(milliseconds: 300), nameController.dispose);
      Future<void>.delayed(const Duration(milliseconds: 300), descriptionController.dispose);
      Future<void>.delayed(const Duration(milliseconds: 300), dateController.dispose);
      Future<void>.delayed(const Duration(milliseconds: 300), fromController.dispose);
      Future<void>.delayed(const Duration(milliseconds: 300), toController.dispose);
    }
  }
}

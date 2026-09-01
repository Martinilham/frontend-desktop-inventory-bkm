// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, unused_element
part of '../dashboard_screen.dart';

extension DashboardAbsenceBuilders on _DashboardScreenState {
  Widget _buildAbsenceCheckPanel(BuildContext context, List<dynamic> items) {
    final baseUrl = widget.apiService.baseUrl;
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final listPanel = _buildAbsenceListPanel(context, items, baseUrl);
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
      BuildContext context, List<dynamic> items, String baseUrl) {
    return SectionCard(
      title: 'Data Absensi Cek',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dokumentasi surat izin, sakit, cuti, lemburan, dan pulang cepat.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFF68777A)),
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
        side: const BorderSide(color: Color(0xFFE5EBDD)),
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
                  color: Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
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
                          if (result?.paths.whereType<String>().isEmpty ??
                              true) return;
                          setDialogState(() =>
                              newPhotoPath = result!.paths.whereType<String>().first);
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

  Widget _buildFilePanel(List<dynamic> files) {
    return SectionCard(
      title: 'Daftar File',
      child: files.isEmpty
          ? const Text('Belum ada file di repository')
          : Column(
              children: files.map((item) {
                final map = item as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5F7EF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5EBDD))),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(
                              map['storedName'] ?? map['originalName'] ?? '-')),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, unused_element
part of '../dashboard_screen.dart';

extension DashboardAuditMediaBuilders on _DashboardScreenState {
  Widget _buildAuditLogPage(List<dynamic> audits) {
    final items =
        audits.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SectionCard(
            title: 'Log Aktivitas',
            actions: [
              PrimaryButton(
                label: 'Refresh',
                leading: const Icon(Icons.refresh),
                onPressed: _refreshDashboard,
              ),
            ],
            child: items.isEmpty
                ? const SizedBox(
                    height: 180,
                    child: Center(child: Text('Belum ada log aktivitas')),
                  )
                : Column(
                    children: items.map(_buildAuditLogTile).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogTile(Map<String, dynamic> item) {
    final title = _auditLogTitle(item);
    final subtitle = _auditLogSubtitle(item);
    final createdAt = item['createdAt']?.toString() ?? '-';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.receipt_long_outlined, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text(createdAt,
                    style: const TextStyle(
                        color: Color(0xFF98A2B3), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditPanel(List<dynamic> audits) {
    return SectionCard(
      title: 'Trail Audit',
      child: audits.isEmpty
          ? const Text('Belum ada aktivitas audit')
          : Column(
              children: audits.map((item) {
                final map = item as Map<String, dynamic>;
                return _buildAuditItemCard(map);
              }).toList(),
            ),
    );
  }

  Future<void> _showImagePreview(
    BuildContext context,
    String title,
    String imageUrl, {
    int quarterTurns = 0,
  }) async {
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0xFF17212B).withOpacity(0.46),
      builder: (context) {
        return DesktopModalShell(
          title: title,
          subtitle: 'Preview dokumentasi',
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
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  quarterTurns: quarterTurns,
                  placeholder: const Center(
                    child: Text('Gagal memuat preview'),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAuditItemCard(Map<String, dynamic> map) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.tableHeader,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            map['action'] ?? '-',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            map['details']?.toString() ?? '-',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadImage(
      BuildContext context, String imageUrl, String productName) async {
    try {
      final directory = await FilePicker.platform
          .getDirectoryPath(dialogTitle: 'Pilih folder tujuan');
      if (directory == null) return;

      final uri = Uri.parse(imageUrl);
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Gagal mengunduh gambar');
      }

      final safeName = productName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = '$safeName-${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('$directory${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(response.bodyBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gambar disimpan: $fileName')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Download gagal: $error')));
    }
  }
}

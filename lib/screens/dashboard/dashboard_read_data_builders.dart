// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, unused_element
part of '../dashboard_screen.dart';

extension DashboardReadDataBuilders on _DashboardScreenState {
  Widget _buildReadDataPanel(BuildContext context, List<dynamic> items) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SectionCard(
          title: 'Data Terbaca',
          actions: [
            OutlinedButton.icon(
              onPressed: _refreshDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
          child: items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Belum ada data terbaca dari mobile.'),
                )
              : Column(
                  children: items
                      .cast<Map<String, dynamic>>()
                      .map((item) => _buildReadDataListItem(item))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildReadDataListItem(Map<String, dynamic> item) {
    final createdAt = DateTime.tryParse(item['createdAt']?.toString() ?? '') ??
        DateTime.now();
    final imageUrl = item['imageUrl']?.toString() ?? '';
    final fullImageUrl =
        imageUrl.isEmpty ? '' : '${widget.apiService.baseUrl}$imageUrl';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EBDD)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: fullImageUrl.isEmpty
                ? Container(
                    width: 72,
                    height: 72,
                    color: const Color(0xFFEFF2F7),
                    child: const Icon(Icons.image_not_supported_outlined),
                  )
                : Image.network(
                    fullImageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_readDataName(item),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(DateFormat('dd MMM yyyy, HH:mm').format(createdAt),
                    style: const TextStyle(color: Color(0xFF68777A))),
                const SizedBox(height: 6),
                Text(
                  (item['recognizedText']?.toString() ?? '').trim().isEmpty
                      ? 'Belum ada hasil OCR.'
                      : item['recognizedText'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xFF68777A), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => _exportSingleReadDataToExcel(item),
            icon: const Icon(Icons.table_chart_outlined),
            label: const Text('Export Excel'),
          ),
        ],
      ),
    );
  }
}

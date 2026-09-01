// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, unused_element
part of '../dashboard_screen.dart';

extension DashboardGrabMerchBuilders on _DashboardScreenState {
  Widget _buildGrabMerchPanel(BuildContext context, List<dynamic> items) {
    final baseUrl = widget.apiService.baseUrl;
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SectionCard(
            title: 'GrabMerch Dashboard',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Hasil upload produk GrabMerch dengan background removed dan label.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: const Color(0xFF68777A))),
                const SizedBox(height: 20),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Belum ada data GrabMerch.',
                        style: TextStyle(color: Colors.black54)),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth >= 1220
                          ? 4
                          : constraints.maxWidth >= 900
                              ? 3
                              : constraints.maxWidth >= 560
                                  ? 2
                                  : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: crossAxisCount == 1 ? 1.25 : 0.92,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final map = items[index] as Map<String, dynamic>;
                          final imageUrl = map['imageUrl']?.toString() ?? '';
                          final fullUrl =
                              imageUrl.isNotEmpty ? '$baseUrl$imageUrl' : '';
                          final productName =
                              map['productName']?.toString() ?? '-';
                          return Card(
                            elevation: 0,
                            color: Colors.white,
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Color(0xFFE5EBDD)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: LandscapeImageFrame(
                                    imageUrl:
                                        fullUrl.isEmpty ? null : fullUrl,
                                    onTap: fullUrl.isEmpty
                                        ? null
                                        : () => _showImagePreview(
                                              context,
                                              productName,
                                              fullUrl,
                                            ),
                                    placeholder: const Center(
                                      child: Text('Tidak ada gambar'),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Uploaded by: ${map['uploadedBy'] ?? '-'}',
                                        style: const TextStyle(
                                            color: Color(0xFF68777A)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Created at: ${map['createdAt'] ?? '-'}',
                                        style: const TextStyle(
                                          color: Color(0xFF68777A),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: fullUrl.isEmpty
                                                  ? null
                                                  : () => _showImagePreview(
                                                        context,
                                                        productName,
                                                        fullUrl,
                                                      ),
                                              child: const Text('Preview'),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: fullUrl.isEmpty
                                                  ? null
                                                  : () => _downloadImage(
                                                        context,
                                                        fullUrl,
                                                        productName,
                                                      ),
                                              child: const Text('Download'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

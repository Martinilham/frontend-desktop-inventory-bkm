import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:inventory_bkm_desktop/services/api_service.dart';
import 'package:inventory_bkm_desktop/theme/app_theme.dart';
import 'package:inventory_bkm_desktop/widgets/desktop_modal_shell.dart';
import 'package:inventory_bkm_desktop/widgets/section_card.dart';

class SozaiProductionMasterScreen extends StatefulWidget {
  const SozaiProductionMasterScreen({
    super.key,
    required this.apiService,
  });

  final ApiService apiService;

  @override
  State<SozaiProductionMasterScreen> createState() =>
      _SozaiProductionMasterScreenState();
}

class _SozaiProductionMasterScreenState
    extends State<SozaiProductionMasterScreen> {
  late Future<List<dynamic>> _itemsFuture;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.apiService.listSozaiProductionMaster();
  }

  void _refresh() {
    setState(() {
      _itemsFuture = widget.apiService.listSozaiProductionMaster();
    });
  }

  Future<void> _importExcel() async {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xlsm'],
      allowMultiple: false,
      withData: false,
    );
    if (selection == null || selection.files.isEmpty) return;
    final path = selection.files.single.path;
    if (path == null || path.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi file Excel tidak dapat dibaca')),
      );
      return;
    }

    setState(() => _isImporting = true);
    try {
      final summary = await widget.apiService.importSozaiProductionMaster(path);
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impor selesai: ${summary['created'] ?? 0} baru, '
            '${summary['updated'] ?? 0} diperbarui, '
            '${summary['unchanged'] ?? 0} tidak berubah.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengimpor master sozai: $error')),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _editItem({Map<String, dynamic>? item}) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SozaiProductionMasterDialog(item: item),
    );
    if (result == null) return;

    try {
      if (item == null) {
        await widget.apiService.createSozaiProductionMaster(result);
      } else {
        await widget.apiService.updateSozaiProductionMaster(
          item['id'].toString(),
          result,
        );
      }
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(item == null
              ? 'Master sozai berhasil ditambahkan'
              : 'Master sozai berhasil diperbarui'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan master sozai: $error')),
      );
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DesktopModalShell(
        title: 'Hapus Master Sozai',
        subtitle: item['productName']?.toString() ?? '',
        icon: Icons.delete_outline,
        maxWidth: 460,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus'),
          ),
        ],
        child: Text(
          'Item number ${item['itemNumber']} akan dihapus dari aturan '
          'klasifikasi sisa produksi.',
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.apiService
          .deleteSozaiProductionMaster(item['id'].toString());
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Master sozai berhasil dihapus')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus master sozai: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined,
                    size: 38, color: AppTheme.textSecondary),
                const SizedBox(height: 12),
                Text('Gagal memuat master sozai: ${snapshot.error}'),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          );
        }

        final items = List<Map<String, dynamic>>.from(
          (snapshot.data ?? [])
              .map((item) => Map<String, dynamic>.from(item as Map)),
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 850;
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Master Sozai (Sisa Produksi)',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontSize: 28),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Item yang terdaftar akan dikategorikan sebagai '
                              'sisa produksi saat impor jurnal. Excel harus '
                              'memiliki kolom Item Number, Product Name, dan '
                              'Offset Account.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isImporting ? null : _importExcel,
                        icon: _isImporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file_outlined),
                        label: Text(compact ? 'Import' : 'Import Excel'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Muat ulang',
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _editItem(),
                        icon: const Icon(Icons.add),
                        label: Text(compact ? 'Tambah' : 'Tambah Item'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Daftar Item',
                    child: items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 28),
                            child: Center(
                              child: Text(
                                'Belum ada item master. Tambahkan item untuk '
                                'mengaktifkan klasifikasi sisa produksi.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (final item in items)
                                _buildItemRow(item, compact: compact),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildItemRow(
    Map<String, dynamic> item, {
    required bool compact,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _itemField(
              compact ? 'Item' : 'Item Number',
              item['itemNumber']?.toString() ?? '-',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: _itemField(
                'Nama Produk', item['productName']?.toString() ?? '-'),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _itemField(
              'Offset Account',
              item['offsetAccount']?.toString() ?? '-',
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () => _editItem(item: item),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Hapus',
            onPressed: () => _deleteItem(item),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Widget _itemField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            )),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SozaiProductionMasterDialog extends StatefulWidget {
  const _SozaiProductionMasterDialog({this.item});

  final Map<String, dynamic>? item;

  @override
  State<_SozaiProductionMasterDialog> createState() =>
      _SozaiProductionMasterDialogState();
}

class _SozaiProductionMasterDialogState
    extends State<_SozaiProductionMasterDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _itemNumberController;
  late final TextEditingController _productNameController;
  late final TextEditingController _offsetAccountController;

  @override
  void initState() {
    super.initState();
    _itemNumberController = TextEditingController(
      text: widget.item?['itemNumber']?.toString() ?? '',
    );
    _productNameController = TextEditingController(
      text: widget.item?['productName']?.toString() ?? '',
    );
    _offsetAccountController = TextEditingController(
      text: widget.item?['offsetAccount']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _itemNumberController.dispose();
    _productNameController.dispose();
    _offsetAccountController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop({
      'itemNumber': _itemNumberController.text.trim(),
      'productName': _productNameController.text.trim(),
      'offsetAccount': _offsetAccountController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return DesktopModalShell(
      title: widget.item == null ? 'Tambah Item Sozai' : 'Edit Item Sozai',
      subtitle: 'Tentukan item dan offset account sisa produksi.',
      icon: Icons.inventory_2_outlined,
      maxWidth: 540,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Simpan'),
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _itemNumberController,
              decoration: const InputDecoration(
                labelText: 'Item Number',
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Item number wajib diisi'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Produk',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nama produk wajib diisi'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _offsetAccountController,
              decoration: const InputDecoration(
                labelText: 'Offset Account',
                prefixIcon: Icon(Icons.account_balance_outlined),
                hintText: 'Contoh: 504000000',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Offset account wajib diisi'
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:inventory_bkm_desktop/services/api_service.dart';

class MonitorDevicesScreen extends StatefulWidget {
  const MonitorDevicesScreen({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<MonitorDevicesScreen> createState() => _MonitorDevicesScreenState();
}

class _MonitorDevicesScreenState extends State<MonitorDevicesScreen> {
  late Future<List<dynamic>> _devicesFuture;

  @override
  void initState() {
    super.initState();
    _devicesFuture = widget.apiService.listMonitorDevices();
  }

  void _reload() {
    setState(() => _devicesFuture = widget.apiService.listMonitorDevices());
  }

  Future<void> _addDevice() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _AddMonitorDeviceDialog(),
    );
    if (result == null) return;

    try {
      await widget.apiService.createMonitorDevice(
        name: result['name']!,
        ipAddress: result['ipAddress']!,
        location: result['location'] ?? '',
      );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perangkat berhasil ditambahkan.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _removeDevice(Map<String, dynamic> device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus perangkat?'),
        content: Text('${device['name']} (${device['ipAddress']}) akan dihapus dari daftar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.apiService.deleteMonitorDevice(device['id'].toString());
      if (!mounted) return;
      _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monitor Perangkat', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 5),
                  Text(
                    'Daftar perangkat kasir dan kesiapan koneksi agent.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _reload,
              tooltip: 'Muat ulang',
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _addDevice,
              icon: const Icon(Icons.add),
              label: const Text('Tambah perangkat'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.tertiaryContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Live view belum aktif. Setiap PC memerlukan agent yang terpasang dan disetujui sebelum layarnya dapat ditampilkan.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _devicesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _MessageState(
                  icon: Icons.cloud_off_outlined,
                  message: snapshot.error.toString().replaceFirst('Exception: ', ''),
                  action: TextButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba lagi'),
                  ),
                );
              }

              final devices = snapshot.data ?? [];
              if (devices.isEmpty) {
                return const _MessageState(
                  icon: Icons.desktop_windows_outlined,
                  message: 'Belum ada perangkat terdaftar.',
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1250
                      ? 3
                      : constraints.maxWidth >= 760
                          ? 2
                          : 1;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: columns == 1 ? 1.5 : 1.18,
                    ),
                    itemCount: devices.length,
                    itemBuilder: (context, index) => _DeviceTile(
                      device: Map<String, dynamic>.from(devices[index]),
                      onRemove: () => _removeDevice(Map<String, dynamic>.from(devices[index])),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.onRemove});

  final Map<String, dynamic> device;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: const Color(0xFF20272B),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.desktop_access_disabled_outlined, size: 34, color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(height: 9),
                  const Text('Menunggu agent', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text('Live view belum tersedia', style: TextStyle(color: Colors.white.withValues(alpha: 0.68), fontSize: 12)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device['name']?.toString() ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(
                          [device['ipAddress'], device['location']].where((value) => value != null && value.toString().trim().isNotEmpty).join('  ·  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onRemove,
                    tooltip: 'Hapus perangkat',
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        ),
      );
}

class _AddMonitorDeviceDialog extends StatefulWidget {
  const _AddMonitorDeviceDialog();

  @override
  State<_AddMonitorDeviceDialog> createState() => _AddMonitorDeviceDialogState();
}

class _AddMonitorDeviceDialogState extends State<_AddMonitorDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool _isPrivateIPv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    final octets = parts.map(int.tryParse).toList();
    if (octets.any((part) => part == null || part < 0 || part > 255)) return false;
    final first = octets[0]!;
    final second = octets[1]!;
    return first == 10 ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Tambah perangkat'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Nama perangkat', counterText: ''),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Nama wajib diisi.' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ipController,
                  decoration: const InputDecoration(labelText: 'IP lokal', hintText: '192.168.1.20'),
                  validator: (value) => value == null || !_isPrivateIPv4(value.trim())
                      ? 'Masukkan IPv4 lokal (10.x, 172.16-31.x, atau 192.168.x).'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Lokasi (opsional)', counterText: ''),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'ipAddress': _ipController.text.trim(),
                'location': _locationController.text.trim(),
              });
            },
            child: const Text('Tambah'),
          ),
        ],
      );
}
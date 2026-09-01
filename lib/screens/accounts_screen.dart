import 'package:flutter/material.dart';
import 'package:inventory_bkm_desktop/services/api_service.dart';
import 'package:inventory_bkm_desktop/widgets/desktop_modal_shell.dart';
import 'package:inventory_bkm_desktop/widgets/primary_button.dart';
import 'package:inventory_bkm_desktop/widgets/section_card.dart';

class AccountsScreen extends StatefulWidget {
  final ApiService apiService;

  const AccountsScreen({super.key, required this.apiService});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late Future<List<dynamic>> _usersFuture;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'viewer';
  bool _isActive = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers();
  }

  Future<List<dynamic>> _loadUsers() async {
    return widget.apiService.listUsers();
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _usersFuture = _loadUsers();
    });
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.apiService.createUser(
        username: _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        active: _isActive,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Akun berhasil dibuat')));
      await _refreshUsers();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showCreateDialog() async {
    _usernameController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _selectedRole = 'viewer';
    _isActive = true;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return DesktopModalShell(
          title: 'Tambah Akun',
          subtitle: 'Buat akses baru untuk aplikasi inventory.',
          icon: Icons.person_add_alt_1_outlined,
          maxWidth: 520,
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal')),
            PrimaryButton(
                label: 'Simpan',
                leading: const Icon(Icons.save_outlined),
                onPressed: _createUser,
                isLoading: _isSubmitting),
          ],
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Username wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor HP',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nomor HP wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Password wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'edp', child: Text('EDP')),
                      DropdownMenuItem(value: 'editor', child: Text('Editor')),
                      DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                      DropdownMenuItem(
                          value: 'accounting', child: Text('Accounting')),
                      DropdownMenuItem(value: 'user', child: Text('User')),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedRole = value ?? 'viewer'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Akun aktif'),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    tileColor: const Color(0xFFF5F7EF),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> user) async {
    String selectedRole = user['role'] ?? 'viewer';
    bool isActive = user['active'] ?? true;
    final phoneController = TextEditingController(
      text: user['phoneNumber']?.toString() ?? '',
    );

    try {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) => DesktopModalShell(
              title: 'Edit Akun',
              subtitle: user['username']?.toString() ?? '-',
              icon: Icons.manage_accounts_outlined,
              maxWidth: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor HP',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'edp', child: Text('EDP')),
                      DropdownMenuItem(value: 'editor', child: Text('Editor')),
                      DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                      DropdownMenuItem(
                          value: 'accounting', child: Text('Accounting')),
                      DropdownMenuItem(value: 'user', child: Text('User')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => selectedRole = value ?? 'viewer'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Akun aktif'),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    tileColor: const Color(0xFFF5F7EF),
                    value: isActive,
                    onChanged: (value) =>
                        setDialogState(() => isActive = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal')),
                PrimaryButton(
                  label: 'Simpan',
                  leading: const Icon(Icons.save_outlined),
                  onPressed: () async {
                    try {
                      await widget.apiService.updateUser(user['id'],
                          role: selectedRole,
                          active: isActive,
                          phoneNumber: phoneController.text.trim());
                      if (!mounted) return;
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Data akun berhasil diperbarui')));
                      await _refreshUsers();
                    } catch (error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())));
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } finally {
      phoneController.dispose();
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DesktopModalShell(
        title: 'Hapus Akun',
        subtitle: 'Aksi ini tidak bisa dibatalkan.',
        icon: Icons.delete_outline,
        maxWidth: 430,
        child: Text('Yakin ingin menghapus akun ${user['username'] ?? '-'}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal')),
          PrimaryButton(
              label: 'Hapus',
              leading: const Icon(Icons.delete_outline),
              onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.apiService.deleteUser(user['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Akun berhasil dihapus')));
      await _refreshUsers();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final users = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: _refreshUsers,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Manajemen Akun',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 32,
                                color: const Color(0xFF1D2B38),
                              ),
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: PrimaryButton(
                      label: 'Tambah',
                      leading: const Icon(Icons.person_add_alt_1_outlined),
                      onPressed: _showCreateDialog,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              SectionCard(
                title: 'Daftar akun',
                actions: [
                  OutlinedButton.icon(
                    onPressed: _refreshUsers,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
                child: users.isEmpty
                    ? const SizedBox(
                        height: 200,
                        child: Center(child: Text('Belum ada akun')),
                      )
                    : Column(
                        children: users.map((raw) {
                          final user = Map<String, dynamic>.from(raw as Map);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildAccountCard(user),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> user) {
    final isActive = user['active'] != false;
    final role = user['role']?.toString().toUpperCase() ?? '-';
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 680;
        final profile = Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF2E7D32).withOpacity(0.14),
              child: Text(
                (user['username']?.toString().isNotEmpty ?? false)
                    ? user['username'].toString()[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Color(0xFF2E7D32), fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['username']?.toString() ?? '-',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D2B38))),
                  const SizedBox(height: 4),
                  Text(user['phoneNumber']?.toString().trim().isEmpty ?? true
                      ? 'Nomor HP belum diisi'
                      : user['phoneNumber'].toString(),
                      style: const TextStyle(color: Color(0xFF68777A))),
                ],
              ),
            ),
          ],
        );
        final actions = Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildAccountBadge(role, const Color(0xFF2E7D32)),
            _buildAccountBadge(
              isActive ? 'AKTIF' : 'NONAKTIF',
              isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
            IconButton(
                tooltip: 'Edit',
                onPressed: () => _showEditDialog(user),
                icon: const Icon(Icons.edit_outlined)),
            IconButton(
                tooltip: 'Hapus',
                onPressed: () => _deleteUser(user),
                icon:
                    const Icon(Icons.delete_outline, color: Color(0xFFE5484D))),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5EBDD)),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    profile,
                    const SizedBox(height: 12),
                    actions,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: profile),
                    const SizedBox(width: 12),
                    actions,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildAccountBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_bkm_desktop/services/api_service.dart';
import 'package:inventory_bkm_desktop/theme/app_theme.dart';
import 'package:inventory_bkm_desktop/widgets/desktop_modal_shell.dart';
import 'package:inventory_bkm_desktop/widgets/section_card.dart';

class InventoryDeadlineScreen extends StatefulWidget {
  const InventoryDeadlineScreen({
    super.key,
    required this.apiService,
  });

  final ApiService apiService;

  @override
  State<InventoryDeadlineScreen> createState() =>
      _InventoryDeadlineScreenState();
}

class _InventoryDeadlineScreenState extends State<InventoryDeadlineScreen> {
  late Future<List<dynamic>> _deadlinesFuture;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _deadlinesFuture = widget.apiService.listInventoryDeadlines();
  }

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  List<DateTime?> _calendarDays() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateUtils.getDaysInMonth(_visibleMonth.year, _visibleMonth.month);
    final leadingDays = first.weekday - DateTime.monday;
    final days = <DateTime?>[
      ...List<DateTime?>.filled(leadingDays, null),
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(_visibleMonth.year, _visibleMonth.month, day),
    ];
    while (days.length < 42) {
      days.add(null);
    }
    return days;
  }

  void _refresh() {
    setState(
        () => _deadlinesFuture = widget.apiService.listInventoryDeadlines());
  }

  void _shiftMonth(int offset) {
    setState(() {
      _visibleMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + offset);
      _selectedDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    });
  }

  Future<void> _editDeadline({Map<String, dynamic>? deadline}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _InventoryDeadlineDialog(
        deadline: deadline,
        initialDate: deadline == null ? _selectedDay : null,
      ),
    );
    if (result == null) return;

    try {
      if (deadline == null) {
        await widget.apiService.createInventoryDeadline(result);
      } else {
        await widget.apiService.updateInventoryDeadline(
          deadline['id'].toString(),
          result,
        );
      }
      if (!mounted) return;
      setState(() {
        final date = DateTime.parse(result['deadlineDate'].toString());
        _visibleMonth = DateTime(date.year, date.month);
        _selectedDay = date;
        _deadlinesFuture = widget.apiService.listInventoryDeadlines();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deadline == null
              ? 'Deadline berhasil ditambahkan'
              : 'Deadline berhasil diperbarui'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan deadline: $error')),
      );
    }
  }

  Future<void> _deleteDeadline(Map<String, dynamic> deadline) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DesktopModalShell(
        title: 'Hapus Deadline',
        subtitle: deadline['title']?.toString() ?? '',
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
        child: const Text('Deadline ini akan dihapus permanen.'),
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.apiService
          .deleteInventoryDeadline(deadline['id'].toString());
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deadline berhasil dihapus')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus deadline: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _deadlinesFuture,
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
                Text('Gagal memuat deadline: ${snapshot.error}'),
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

        final deadlines = List<Map<String, dynamic>>.from(
          (snapshot.data ?? [])
              .map((item) => Map<String, dynamic>.from(item as Map)),
        );
        return _buildCalendar(deadlines);
      },
    );
  }

  Widget _buildCalendar(List<Map<String, dynamic>> deadlines) {
    final byDate = <String, List<Map<String, dynamic>>>{};
    for (final deadline in deadlines) {
      final key = deadline['deadlineDate']?.toString() ?? '';
      if (key.isEmpty) continue;
      byDate.putIfAbsent(key, () => []).add(deadline);
    }
    final selectedDeadlines = byDate[_dateKey(_selectedDay)] ?? [];
    final days = _calendarDays();

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
                          'Deadline Inventory',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Jadwal dan pengingat inventory',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Muat ulang',
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _editDeadline(),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Deadline'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SectionCard(
                title: 'Kalender',
                actions: [
                  IconButton(
                    tooltip: 'Bulan sebelumnya',
                    onPressed: () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    DateFormat('MMMM yyyy', 'id_ID').format(_visibleMonth),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    tooltip: 'Bulan berikutnya',
                    onPressed: () => _shiftMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  TextButton(
                    onPressed: () {
                      final today = DateTime.now();
                      setState(() {
                        _visibleMonth = DateTime(today.year, today.month);
                        _selectedDay = today;
                      });
                    },
                    child: const Text('Hari ini'),
                  ),
                ],
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final day in const [
                          'Sen',
                          'Sel',
                          'Rab',
                          'Kam',
                          'Jum',
                          'Sab',
                          'Min'
                        ])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Center(
                                child: Text(
                                  day,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    for (var row = 0; row < 6; row++)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var column = 0; column < 7; column++)
                            Expanded(
                              child: _buildDayCell(
                                days[row * 7 + column],
                                byDate,
                                compact: compact,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionCard(
                title:
                    'Deadline ${DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDay)}',
                actions: [
                  TextButton.icon(
                    onPressed: () => _editDeadline(),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah di tanggal ini'),
                  ),
                ],
                child: selectedDeadlines.isEmpty
                    ? const SizedBox(
                        height: 72,
                        child: Center(
                          child: Text('Belum ada deadline pada tanggal ini.'),
                        ),
                      )
                    : Column(
                        children: [
                          for (final item in selectedDeadlines)
                            _buildDeadlineRow(item),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayCell(
    DateTime? day,
    Map<String, List<Map<String, dynamic>>> byDate, {
    required bool compact,
  }) {
    if (day == null) {
      return Container(
        height: compact ? 78 : 94,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8F7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFECEFED)),
        ),
      );
    }

    final items = byDate[_dateKey(day)] ?? [];
    final selected = _dateKey(day) == _dateKey(_selectedDay);
    final today = _dateKey(day) == _dateKey(DateTime.now());
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: selected
            ? const Color(0xFFFFF0E6)
            : Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _selectedDay = day),
          child: Container(
            height: compact ? 78 : 94,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? AppTheme.primary
                    : today
                        ? AppTheme.accent.withValues(alpha: 0.6)
                        : AppTheme.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      day.day.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color:
                            selected ? AppTheme.primary : AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (items.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          items.length.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                for (final item in items.take(compact ? 1 : 2))
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['title']?.toString() ?? 'Deadline',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF9B4A17),
                          fontSize: compact ? 8 : 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (items.length > (compact ? 1 : 2))
                  Text(
                    '+${items.length - (compact ? 1 : 2)} lainnya',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeadlineRow(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1D8C7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_note_outlined, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title']?.toString() ?? 'Deadline',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((item['notes']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item['notes'].toString(),
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit deadline',
            onPressed: () => _editDeadline(deadline: item),
            icon: const Icon(Icons.edit_outlined, size: 19),
          ),
          IconButton(
            tooltip: 'Hapus deadline',
            onPressed: () => _deleteDeadline(item),
            icon: const Icon(Icons.delete_outline, size: 19),
          ),
        ],
      ),
    );
  }
}

class _InventoryDeadlineDialog extends StatefulWidget {
  const _InventoryDeadlineDialog({this.deadline, this.initialDate});

  final Map<String, dynamic>? deadline;
  final DateTime? initialDate;

  @override
  State<_InventoryDeadlineDialog> createState() =>
      _InventoryDeadlineDialogState();
}

class _InventoryDeadlineDialogState extends State<_InventoryDeadlineDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late DateTime _deadlineDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.deadline?['title']?.toString() ?? '',
    );
    _notesController = TextEditingController(
      text: widget.deadline?['notes']?.toString() ?? '',
    );
    _deadlineDate = DateTime.tryParse(
          widget.deadline?['deadlineDate']?.toString() ?? '',
        ) ??
        widget.initialDate ??
        DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadlineDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih tanggal deadline',
    );
    if (picked != null) setState(() => _deadlineDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return DesktopModalShell(
      title: widget.deadline == null ? 'Tambah Deadline' : 'Edit Deadline',
      subtitle: 'Judul akan ditampilkan pada tanggal di kalender.',
      icon: Icons.event_available_outlined,
      maxWidth: 540,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop({
              'title': _titleController.text.trim(),
              'deadlineDate': DateFormat('yyyy-MM-dd').format(_deadlineDate),
              'notes': _notesController.text.trim(),
            });
          },
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
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Judul deadline',
                hintText: 'Contoh: Cek stok gudang',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Judul deadline wajib diisi'
                  : null,
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal deadline',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                child: Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                    .format(_deadlineDate)),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

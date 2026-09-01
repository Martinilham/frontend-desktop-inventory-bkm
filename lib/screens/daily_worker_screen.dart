import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventory_bkm_desktop/services/api_service.dart';
import 'package:inventory_bkm_desktop/widgets/desktop_action_dialog.dart';
import 'package:inventory_bkm_desktop/widgets/desktop_modal_shell.dart';
import 'package:inventory_bkm_desktop/widgets/primary_button.dart';
import 'package:inventory_bkm_desktop/widgets/section_card.dart';

class DailyWorkerScreen extends StatefulWidget {
  const DailyWorkerScreen({
    super.key,
    required this.apiService,
    required this.onLogout,
  });

  final ApiService apiService;
  final Future<void> Function() onLogout;

  @override
  State<DailyWorkerScreen> createState() => _DailyWorkerScreenState();
}

class _DailyWorkerScreenState extends State<DailyWorkerScreen> {
  static const _statusOrder = [
    'backlog',
    'todo',
    'in_progress',
    'blocked',
    'review',
    'done',
  ];

  static const _categoryOrder = [
    'asset',
    'ticket',
    'maintenance',
    'disposal',
    'documentation',
  ];

  static const _statusLabels = {
    'backlog': 'Backlog',
    'todo': 'To Do',
    'in_progress': 'In Progress',
    'blocked': 'Blocked',
    'review': 'Review',
    'done': 'Done',
  };

  static const _categoryLabels = {
    'asset': 'Asset',
    'ticket': 'Ticket',
    'maintenance': 'Maintenance',
    'disposal': 'Disposal',
    'documentation': 'Documentation',
  };

  static const _statusColors = {
    'backlog': Color(0xFF94A3B8),
    'todo': Color(0xFF2563EB),
    'in_progress': Color(0xFFEA580C),
    'blocked': Color(0xFFDC2626),
    'review': Color(0xFF7C3AED),
    'done': Color(0xFF16A34A),
  };

  static const _categoryColors = {
    'asset': Color(0xFF0F766E),
    'ticket': Color(0xFF7C3AED),
    'maintenance': Color(0xFFB45309),
    'disposal': Color(0xFFDC2626),
    'documentation': Color(0xFF0EA5E9),
  };

  static const _views = [
    'month',
    'day',
    'kanban',
    'tasks',
    'template',
    'report',
  ];

  late Future<Map<String, dynamic>> _future;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime.now();
  String _activeView = 'kanban';
  String _search = '';
  String _statusFilter = 'all';
  String _categoryFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _kanbanScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _kanbanScrollController.dispose();
    super.dispose();
  }

  String _monthKey(DateTime value) =>
      DateFormat('yyyy-MM').format(DateTime(value.year, value.month));

  String _dayKey(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

  DateTime _parseDate(String value, {DateTime? fallback}) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null || parsed.year < 2000) return fallback ?? DateTime.now();
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  List<Map<String, dynamic>> _tasksFrom(dynamic value) {
    return List<dynamic>.from(value ?? [])
        .map((task) => Map<String, dynamic>.from(task as Map))
        .toList();
  }

  Future<Map<String, dynamic>> _load() async {
    final dashboard = await widget.apiService.getDailyWorkerDashboard(
      monthKey: _monthKey(_selectedMonth),
    );
    final templates = await widget.apiService.listDailyWorkerTemplates();
    dashboard['templates'] = templates;
    return dashboard;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _showMessage({
    required String title,
    required String message,
    bool success = true,
  }) {
    return DesktopActionDialog.show(
      context,
      title: title,
      message: message,
      success: success,
    );
  }

  Future<void> _handleAuthError() async {
    await widget.onLogout();
  }

  List<Map<String, dynamic>> _filterTasks(List<Map<String, dynamic>> tasks) {
    return tasks.where((task) {
      if (_search.isNotEmpty) {
        final haystack = [
          task['title'],
          task['description'],
          task['assignee'],
          task['blockedReason'],
          task['recapNote'],
          (task['linkedItems'] as List<dynamic>?)
                  ?.map((item) => item is Map ? item['label'] : null)
                  .whereType<String>()
                  .join(' ') ??
              '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(_search.toLowerCase())) return false;
      }

      if (_statusFilter != 'all' && task['status']?.toString() != _statusFilter) {
        return false;
      }

      if (_categoryFilter != 'all' &&
          task['category']?.toString() != _categoryFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  Map<String, Map<String, dynamic>> _summaryDayMap(
      List<dynamic> summaryDayList) {
    return {
      for (final item in summaryDayList)
        item['date']?.toString() ?? '': Map<String, dynamic>.from(item as Map),
    };
  }

  List<DateTime?> _monthGrid() {
    final first = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final totalDays = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final blanks = first.weekday - 1;
    final cells = <DateTime?>[
      ...List<DateTime?>.filled(blanks, null),
      for (var day = 1; day <= totalDays; day++)
        DateTime(_selectedMonth.year, _selectedMonth.month, day),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih bulan kerja',
    );
    if (picked == null) return;
    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
      _selectedDay = DateTime(picked.year, picked.month, 1);
      _future = _load();
    });
  }

  Future<void> _shiftMonth(int offset) async {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
      _selectedDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      _future = _load();
    });
  }

  List<Map<String, dynamic>> _parseLinkedItemsText(String raw) {
    final result = <Map<String, dynamic>>[];
    for (final chunk in raw.split(RegExp(r'[;\n]'))) {
      final trimmed = chunk.trim();
      if (trimmed.isEmpty) continue;
      final pieces = trimmed.split('|').map((item) => item.trim()).toList();
      result.add({
        'type': pieces.isNotEmpty ? pieces[0].toLowerCase() : 'asset',
        'recordId': pieces.length > 1 ? pieces[1] : '',
        'label': pieces.length > 2
            ? pieces[2]
            : (pieces.length > 1 ? pieces[1] : pieces[0]),
        'url': '',
      });
    }
    return result;
  }

  String _linkedItemsLabel(List<dynamic> linkedItems) {
    if (linkedItems.isEmpty) return '-';
    return linkedItems.map((item) {
      final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
      final type = map['type']?.toString() ?? 'item';
      final recordId = map['recordId']?.toString() ?? '';
      final label = map['label']?.toString() ?? '';
      return [type, if (recordId.isNotEmpty) recordId, if (label.isNotEmpty) label]
          .join(' | ');
    }).join('\n');
  }

  String _historyPreview(List<dynamic> history) {
    if (history.isEmpty) return '-';
    final latest = Map<String, dynamic>.from(history.last as Map);
    final action = latest['action']?.toString() ?? 'updated';
    final note = latest['note']?.toString() ?? '';
    final fromStatus = latest['fromStatus']?.toString() ?? '';
    final toStatus = latest['toStatus']?.toString() ?? '';
    final label = action.replaceAll('_', ' ').toUpperCase();
    final transition = fromStatus.isNotEmpty || toStatus.isNotEmpty
        ? ' ($fromStatus -> $toStatus)'
        : '';
    return note.isEmpty ? '$label$transition' : '$label$transition - $note';
  }

  Future<void> _saveTask({
    Map<String, dynamic>? task,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DailyWorkerTaskDialog(
        task: task,
        selectedDay: _selectedDay,
        selectedMonth: _selectedMonth,
      ),
    );

    if (result == null) return;

    try {
      if (task == null) {
        await widget.apiService.createDailyWorkerTask(result);
      } else {
        await widget.apiService.updateDailyWorkerTask(task['id']?.toString() ?? '', result);
      }
      if (!mounted) return;
      await _showMessage(
        title: 'Berhasil',
        message: task == null
            ? 'Task harian berhasil dibuat'
            : 'Task harian berhasil diperbarui',
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      if (error is AuthException) {
        await _handleAuthError();
        return;
      }
      await _showMessage(
        title: 'Gagal',
        message: error.toString(),
        success: false,
      );
    }
  }

  Future<void> _saveTemplate({Map<String, dynamic>? template}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DailyWorkerTemplateDialog(template: template),
    );

    if (result == null) return;

    try {
      if (template == null) {
        await widget.apiService.createDailyWorkerTemplate(result);
      } else {
        // For now, templates are recreated from scratch when edited.
        await widget.apiService.deleteDailyWorkerTemplate(template['id'].toString());
        await widget.apiService.createDailyWorkerTemplate(result);
      }
      if (!mounted) return;
      await _showMessage(
        title: 'Berhasil',
        message: template == null
            ? 'Template berhasil dibuat'
            : 'Template berhasil diperbarui',
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      if (error is AuthException) {
        await _handleAuthError();
        return;
      }
      await _showMessage(
        title: 'Gagal',
        message: error.toString(),
        success: false,
      );
    }
  }

  Future<void> _applyTemplate(Map<String, dynamic> template) async {
    try {
      await widget.apiService.applyDailyWorkerTemplate(
        template['id'].toString(),
        {
          'workDate': _dayKey(_selectedDay),
          'monthKey': _monthKey(_selectedMonth),
          'sameDayDeadline': true,
        },
      );
      await _refresh();
      if (!mounted) return;
      await _showMessage(
        title: 'Berhasil',
        message: 'Task dari template berhasil ditambahkan',
      );
    } catch (error) {
      if (error is AuthException) {
        await _handleAuthError();
        return;
      }
      if (!mounted) return;
      await _showMessage(
        title: 'Gagal',
        message: error.toString(),
        success: false,
      );
    }
  }

  Future<void> _deleteTemplate(Map<String, dynamic> template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DesktopModalShell(
        title: 'Hapus Template',
        subtitle: 'Template akan dihapus permanen.',
        icon: Icons.delete_outline,
        maxWidth: 460,
        child: const Text('Yakin ingin menghapus template ini?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.apiService.deleteDailyWorkerTemplate(template['id'].toString());
      await _refresh();
      if (!mounted) return;
      await _showMessage(
        title: 'Berhasil',
        message: 'Template berhasil dihapus',
      );
    } catch (error) {
      if (error is AuthException) {
        await _handleAuthError();
        return;
      }
      if (!mounted) return;
      await _showMessage(
        title: 'Gagal',
        message: error.toString(),
        success: false,
      );
    }
  }

  Future<void> _changeStatus(
    Map<String, dynamic> task,
    String nextStatus,
  ) async {
    try {
      await widget.apiService.changeDailyWorkerTaskStatus(
        task['id'].toString(),
        {
          'status': nextStatus,
          'note': '',
          'blockedReason': nextStatus == 'blocked'
              ? task['blockedReason']?.toString() ?? ''
              : '',
          'overdueReason': task['overdueReason']?.toString() ?? '',
        },
      );
      await _refresh();
    } catch (error) {
      if (error is AuthException) {
        await _handleAuthError();
        return;
      }
      if (!mounted) return;
      await _showMessage(
        title: 'Gagal',
        message: error.toString(),
        success: false,
      );
    }
  }

  Future<void> _deleteTask(Map<String, dynamic> task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DesktopModalShell(
        title: 'Hapus Task',
        subtitle: 'Task ini akan dihapus dari histori kerja.',
        icon: Icons.delete_outline,
        maxWidth: 460,
        child: const Text('Yakin ingin menghapus task ini?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.apiService.deleteDailyWorkerTask(task['id'].toString());
      await _refresh();
      if (!mounted) return;
      await _showMessage(
        title: 'Berhasil',
        message: 'Task harian berhasil dihapus',
      );
    } catch (error) {
      if (error is AuthException) {
        await _handleAuthError();
        return;
      }
      if (!mounted) return;
      await _showMessage(
        title: 'Gagal',
        message: error.toString(),
        success: false,
      );
    }
  }

  Widget _buildHero(Map<String, dynamic> data) {
    final summary = Map<String, dynamic>.from(data['summary'] ?? {});
    final total = summary['total']?.toString() ?? '0';
    final done = summary['completed']?.toString() ?? '0';
    final overdue = summary['overdue']?.toString() ?? '0';
    final dueToday = summary['dueToday']?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF123524), Color(0xFF2E7D32), Color(0xFF5C8D4E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
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
                      'Daily Worker',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Month -> Day -> Kanban -> Task',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.88),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.35)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _heroChip('Total Task', total, Icons.task_alt_outlined),
              _heroChip('Done', done, Icons.check_circle_outline),
              _heroChip('Overdue', overdue, Icons.warning_amber_outlined),
              _heroChip('Due Today', dueToday, Icons.today_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SectionCard(
      title: 'Kontrol Tampilan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final view in _views)
                ChoiceChip(
                  label: Text(view.toUpperCase()),
                  selected: _activeView == view,
                  onSelected: (_) => setState(() => _activeView = view),
                ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 850;
              final fields = [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Cari task',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _search = value.trim()),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('Semua Status')),
                      ..._statusOrder.map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(_statusLabels[status] ?? status),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _statusFilter = value ?? 'all'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _categoryFilter,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('Semua Kategori')),
                      ..._categoryOrder.map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(_categoryLabels[category] ?? category),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _categoryFilter = value ?? 'all'),
                  ),
                ),
              ];

              if (narrow) {
                return Column(
                  children: [
                    fields[0],
                    const SizedBox(height: 14),
                    fields[2],
                    const SizedBox(height: 14),
                    fields[4],
                  ],
                );
              }

              return Row(children: fields);
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickMonth,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(DateFormat('MMMM yyyy').format(_selectedMonth)),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _saveTask(),
                  icon: const Icon(Icons.add),
                  label: const Text('Task Baru'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () => _saveTemplate(),
                  icon: const Icon(Icons.library_add_outlined),
                  label: const Text('Template Baru'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(Map<String, dynamic> summary) {
    final statusCounts = Map<String, dynamic>.from(summary['statusCounts'] ?? {});

    Widget metricCard(String label, String value, Color color, IconData icon) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EBDD)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Color(0xFF68777A))),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1D2B38),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 1100
            ? (constraints.maxWidth - 36) / 4
            : constraints.maxWidth >= 700
                ? (constraints.maxWidth - 18) / 2
                : constraints.maxWidth;
        final cards = [
          metricCard('Backlog', statusCounts['backlog']?.toString() ?? '0',
              const Color(0xFF94A3B8), Icons.inventory_2_outlined),
          metricCard('On Track', statusCounts['in_progress']?.toString() ?? '0',
              const Color(0xFFEA580C), Icons.timelapse_outlined),
          metricCard('Blocked', statusCounts['blocked']?.toString() ?? '0',
              const Color(0xFFDC2626), Icons.block_outlined),
          metricCard('Done', statusCounts['done']?.toString() ?? '0',
              const Color(0xFF16A34A), Icons.check_circle_outline),
        ];

        return Wrap(
          spacing: 18,
          runSpacing: 18,
          children: cards.map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
    );
  }

  Widget _buildMonthView(
    List<Map<String, dynamic>> tasks,
    Map<String, Map<String, dynamic>> daySummary,
  ) {
    final cells = _monthGrid();
    return SectionCard(
      title: 'Month View',
      actions: [
        TextButton.icon(
          onPressed: () => _shiftMonth(-1),
          icon: const Icon(Icons.chevron_left),
          label: const Text('Prev'),
        ),
        TextButton.icon(
          onPressed: () => _pickMonth(),
          icon: const Icon(Icons.date_range_outlined),
          label: const Text('Pick'),
        ),
        TextButton.icon(
          onPressed: () => _shiftMonth(1),
          icon: const Icon(Icons.chevron_right),
          label: const Text('Next'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(child: Text('Mon')),
              Expanded(child: Text('Tue')),
              Expanded(child: Text('Wed')),
              Expanded(child: Text('Thu')),
              Expanded(child: Text('Fri')),
              Expanded(child: Text('Sat')),
              Expanded(child: Text('Sun')),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final date = cells[index];
              if (date == null) {
                return const SizedBox.shrink();
              }
              final key = _dayKey(date);
              final summaryItem = daySummary[key];
              final total = summaryItem?['total']?.toString() ?? '0';
              final overdue = summaryItem?['overdue']?.toString() ?? '0';
              final isSelected = _dayKey(date) == _dayKey(_selectedDay);
              final isToday = _dayKey(date) == _dayKey(DateTime.now());
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _selectedDay = date),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isSelected
                        ? const Color(0xFF2E7D32).withOpacity(0.10)
                        : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFE5EBDD),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: isToday
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF1D2B38),
                            ),
                          ),
                          const Spacer(),
                          if (isToday)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '$total task',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF68777A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$overdue overdue',
                        style: TextStyle(
                          fontSize: 11,
                          color: overdue == '0'
                              ? const Color(0xFF68777A)
                              : const Color(0xFFDC2626),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Selected day: ${DateFormat('EEEE, dd MMMM yyyy').format(_selectedDay)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D2B38),
            ),
          ),
          const SizedBox(height: 12),
          ..._filterTasks(tasks.where((task) => task['workDate']?.toString() == _dayKey(_selectedDay)).toList())
              .map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TaskCard(
                      task: task,
                      statusLabels: _statusLabels,
                      categoryLabels: _categoryLabels,
                      statusColors: _statusColors,
                      categoryColors: _categoryColors,
                      onEdit: () => _saveTask(task: task),
                      onDelete: () => _deleteTask(task),
                      onChangeStatus: (status) => _changeStatus(task, status),
                    ),
                  )),
          if (_filterTasks(tasks.where((task) => task['workDate']?.toString() == _dayKey(_selectedDay)).toList()).isEmpty)
            const SizedBox(
              height: 120,
              child: Center(
                child: Text('Belum ada task pada hari ini'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKanbanView(List<Map<String, dynamic>> tasks) {
    return SectionCard(
      title: 'Kanban',
      actions: [
        TextButton.icon(
          onPressed: () => _saveTask(),
          icon: const Icon(Icons.add),
          label: const Text('Task Baru'),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnWidth = constraints.maxWidth < 980 ? 300.0 : 260.0;
          final totalWidth = (_statusOrder.length * columnWidth) +
              ((_statusOrder.length - 1) * 14) +
              24;
          return Scrollbar(
            controller: _kanbanScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _kanbanScrollController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: totalWidth),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _statusOrder.map((status) {
                final items = tasks.where((task) => task['status']?.toString() == status).toList();
                return DragTarget<Map<String, dynamic>>(
                  onWillAccept: (task) =>
                      task != null && task['status']?.toString() != status,
                  onAccept: (task) => _changeStatus(task, status),
                  builder: (context, candidateData, rejectedData) {
                    final isHovering = candidateData.isNotEmpty;
                    return Container(
                      width: columnWidth,
                      margin: const EdgeInsets.only(right: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isHovering
                            ? const Color(0xFFEAF5EA)
                            : const Color(0xFFF8FAF6),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isHovering
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE5EBDD),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _statusColors[status] ??
                                      const Color(0xFF2E7D32),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_statusLabels[status] ?? status} (${items.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1D2B38),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...items.map((task) {
                            final card = _TaskCard(
                              task: task,
                              statusLabels: _statusLabels,
                              categoryLabels: _categoryLabels,
                              statusColors: _statusColors,
                              categoryColors: _categoryColors,
                              onEdit: () => _saveTask(task: task),
                              onDelete: () => _deleteTask(task),
                              onChangeStatus: (nextStatus) =>
                                  _changeStatus(task, nextStatus),
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: LongPressDraggable<Map<String, dynamic>>(
                                data: task,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: SizedBox(
                                    width: columnWidth - 28,
                                    child: Opacity(
                                      opacity: 0.95,
                                      child: card,
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.35,
                                  child: card,
                                ),
                                child: card,
                              ),
                            );
                          }),
                          if (items.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE5EBDD),
                                ),
                              ),
                              child: const Text('Belum ada task'),
                            ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskListView(List<Map<String, dynamic>> tasks) {
    return SectionCard(
      title: 'Task List',
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Task')),
                DataColumn(label: Text('Day')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Priority')),
                DataColumn(label: Text('Assignee')),
                DataColumn(label: Text('Due')),
                DataColumn(label: Text('Action')),
              ],
              rows: tasks.map((task) {
                final status = task['status']?.toString() ?? '';
                final category = task['category']?.toString() ?? '';
                return DataRow(
                  cells: [
                    DataCell(Text(task['title']?.toString() ?? '-')),
                    DataCell(Text(task['workDate']?.toString() ?? '-')),
                    DataCell(Text(_categoryLabels[category] ?? category)),
                    DataCell(Text(_statusLabels[status] ?? status)),
                    DataCell(Text(task['priority']?.toString() ?? '-')),
                    DataCell(Text(task['assignee']?.toString() ?? '-')),
                    DataCell(Text(task['dueDate']?.toString() ?? '-')),
                    DataCell(
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') _saveTask(task: task);
                          if (value == 'delete') _deleteTask(task);
                          if (_statusOrder.contains(value)) {
                            _changeStatus(task, value);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          ..._statusOrder.map(
                            (status) => PopupMenuItem(
                              value: status,
                              child: Text('Move to ${_statusLabels[status]}'),
                            ),
                          ),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateView(List<dynamic> templates) {
    final items = templates
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return SectionCard(
      title: 'Template',
      actions: [
        TextButton.icon(
          onPressed: () => _saveTemplate(),
          icon: const Icon(Icons.add),
          label: const Text('Template Baru'),
        ),
      ],
      child: items.isEmpty
          ? const SizedBox(
              height: 140,
              child: Center(child: Text('Belum ada template.')),
            )
          : Wrap(
              spacing: 14,
              runSpacing: 14,
              children: items.map((template) {
                final linkedItems = List<dynamic>.from(template['linkedItems'] ?? []);
                final tags = List<dynamic>.from(template['tags'] ?? []);
                return SizedBox(
                  width: 320,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE5EBDD)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template['title']?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1D2B38),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          template['description']?.toString().isNotEmpty == true
                              ? template['description'].toString()
                              : 'Tidak ada deskripsi.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF68777A)),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Chip(
                              label: _categoryLabels[template['category']?.toString() ?? ''] ??
                                  (template['category']?.toString() ?? '-'),
                              color: _categoryColors[template['category']?.toString() ?? ''] ??
                                  const Color(0xFF0F766E),
                            ),
                            _Chip(
                              label: _statusLabels[template['status']?.toString() ?? ''] ??
                                  (template['status']?.toString() ?? '-'),
                              color: _statusColors[template['status']?.toString() ?? ''] ??
                                  const Color(0xFF2E7D32),
                            ),
                            _Chip(
                              label: template['priority']?.toString() ?? 'medium',
                              color: const Color(0xFF334155),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Relasi: ${_dailyWorkerLinkedItemsLabel(linkedItems)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Tags: ${tags.join(', ')}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _applyTemplate(template),
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => _deleteTemplate(template),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildReportView(Map<String, dynamic> summary, List<Map<String, dynamic>> tasks) {
    final blockedReasons = List<dynamic>.from(summary['blockedReasonSummary'] ?? []);
    final daySummary = List<dynamic>.from(summary['daySummary'] ?? []);
    final overdueTasks = tasks.where((task) => task['overdue'] == true).toList();

    return Column(
      children: [
        SectionCard(
          title: 'Monthly Recap',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bulan ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text('Total task: ${summary['total'] ?? 0}'),
              Text('Selesai: ${summary['completed'] ?? 0}'),
              Text('Overdue: ${summary['overdue'] ?? 0}'),
              Text('Due today: ${summary['dueToday'] ?? 0}'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 980) {
              return Column(
                children: [
                  _buildReportTable('Blocked Reasons', blockedReasons),
                  const SizedBox(height: 18),
                  _buildReportTable('Day Summary', daySummary),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildReportTable('Blocked Reasons', blockedReasons)),
                const SizedBox(width: 18),
                Expanded(child: _buildReportTable('Day Summary', daySummary)),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Overdue Task',
          child: overdueTasks.isEmpty
              ? const Text('Tidak ada task overdue.')
              : Column(
                  children: overdueTasks
                      .map(
                        (task) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.warning_amber_outlined, color: Color(0xFFDC2626)),
                          title: Text(task['title']?.toString() ?? '-'),
                          subtitle: Text(
                            '${task['dueDate'] ?? '-'} | ${_statusLabels[task['status']?.toString()] ?? task['status']?.toString() ?? '-'}',
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildReportTable(String title, List<dynamic> rows) {
    return SectionCard(
      title: title,
      child: rows.isEmpty
          ? const Text('Belum ada data.')
          : Column(
              children: rows.take(10).map((row) {
                final map = Map<String, dynamic>.from(row as Map);
                final left = map['reason']?.toString() ??
                    map['date']?.toString() ??
                    map['group']?.toString() ??
                    map['status']?.toString() ??
                    '-';
                final right = map['count']?.toString() ??
                    map['total']?.toString() ??
                    map['totalAbsDifference']?.toString() ??
                    map['overdue']?.toString() ??
                    '0';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5EBDD)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(left)),
                      Text(
                        right,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          if (snapshot.error is AuthException) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _handleAuthError());
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: Text(
              snapshot.error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB42318)),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final tasks = _tasksFrom(data['tasks']);
        final filteredTasks = _filterTasks(tasks);
        final templates = List<dynamic>.from(data['templates'] ?? []);
        final summary = Map<String, dynamic>.from(data['summary'] ?? {});
        final daySummary = _summaryDayMap(List<dynamic>.from(summary['daySummary'] ?? []));

        final dayTasks = filteredTasks
            .where((task) => task['workDate']?.toString() == _dayKey(_selectedDay))
            .toList();

        final content = ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _buildHero(data),
            const SizedBox(height: 18),
            _buildFilters(),
            const SizedBox(height: 18),
            _buildMetrics(summary),
            const SizedBox(height: 18),
            if (_activeView == 'month') _buildMonthView(filteredTasks, daySummary),
            if (_activeView == 'day')
              SectionCard(
                title: 'Day View',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(_selectedDay),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...dayTasks
                        .map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TaskCard(
                              task: task,
                              statusLabels: _statusLabels,
                              categoryLabels: _categoryLabels,
                              statusColors: _statusColors,
                              categoryColors: _categoryColors,
                              onEdit: () => _saveTask(task: task),
                              onDelete: () => _deleteTask(task),
                              onChangeStatus: (status) => _changeStatus(task, status),
                            ),
                          ),
                        )
                        .toList(),
                    if (dayTasks.isEmpty)
                      const SizedBox(
                        height: 120,
                        child: Center(child: Text('Belum ada task untuk hari ini')),
                      ),
                  ],
                ),
              ),
            if (_activeView == 'kanban') _buildKanbanView(filteredTasks),
            if (_activeView == 'tasks') _buildTaskListView(filteredTasks),
            if (_activeView == 'template') _buildTemplateView(templates),
            if (_activeView == 'report') _buildReportView(summary, filteredTasks),
          ],
        );

        return RefreshIndicator(
          onRefresh: _refresh,
          child: content,
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.statusLabels,
    required this.categoryLabels,
    required this.statusColors,
    required this.categoryColors,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeStatus,
  });

  final Map<String, dynamic> task;
  final Map<String, String> statusLabels;
  final Map<String, String> categoryLabels;
  final Map<String, Color> statusColors;
  final Map<String, Color> categoryColors;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final status = task['status']?.toString() ?? '';
    final category = task['category']?.toString() ?? '';
    final linkedItems = List<dynamic>.from(task['linkedItems'] ?? []);
    final history = List<dynamic>.from(task['history'] ?? []);
    final overdue = task['overdue'] == true;
    final description = task['description']?.toString() ?? '';
    final dueDate = task['dueDate']?.toString() ?? '-';
    final workDate = task['workDate']?.toString() ?? '-';
    final assignee = task['assignee']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: overdue ? const Color(0xFFDC2626) : const Color(0xFFE5EBDD),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task['title']?.toString() ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF1D2B38),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                  if (statusLabels.containsKey(value)) onChangeStatus(value);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  ...statusLabels.entries.map(
                    (entry) => PopupMenuItem(
                      value: entry.key,
                      child: Text('Move to ${entry.value}'),
                    ),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description.isNotEmpty ? description : 'Tidak ada deskripsi.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF68777A)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                label: categoryLabels[category] ?? category,
                color: categoryColors[category] ?? const Color(0xFF0F766E),
              ),
              _Chip(
                label: statusLabels[status] ?? status,
                color: statusColors[status] ?? const Color(0xFF2E7D32),
              ),
              _Chip(
                label: task['priority']?.toString() ?? 'medium',
                color: const Color(0xFF334155),
              ),
              if (overdue)
                const _Chip(
                  label: 'Overdue',
                  color: Color(0xFFDC2626),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Day: $workDate  |  Due: $dueDate',
            style: const TextStyle(color: Color(0xFF68777A), fontSize: 12),
          ),
          if (assignee.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('PIC: $assignee',
                style: const TextStyle(color: Color(0xFF68777A), fontSize: 12)),
          ],
          const SizedBox(height: 8),
          Text(
            'Relasi: ${_dailyWorkerLinkedItemsLabel(linkedItems)}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Histori: ${_dailyWorkerHistoryPreview(history)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: 'Move status',
                onSelected: onChangeStatus,
                itemBuilder: (context) => statusLabels.entries
                    .map(
                      (entry) => PopupMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF2E7D32)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _dailyWorkerLinkedItemsLabel(List<dynamic> linkedItems) {
  if (linkedItems.isEmpty) return '-';
  return linkedItems.map((item) {
    final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
    final type = map['type']?.toString() ?? 'item';
    final recordId = map['recordId']?.toString() ?? '';
    final label = map['label']?.toString() ?? '';
    return [type, if (recordId.isNotEmpty) recordId, if (label.isNotEmpty) label]
        .join(' | ');
  }).join(' | ');
}

String _dailyWorkerHistoryPreview(List<dynamic> history) {
  if (history.isEmpty) return '-';
  final latest = Map<String, dynamic>.from(history.last as Map);
  final action = latest['action']?.toString() ?? 'updated';
  final fromStatus = latest['fromStatus']?.toString() ?? '';
  final toStatus = latest['toStatus']?.toString() ?? '';
  final note = latest['note']?.toString() ?? '';
  final transition = fromStatus.isNotEmpty || toStatus.isNotEmpty
      ? ' ($fromStatus -> $toStatus)'
      : '';
  final head = action.replaceAll('_', ' ').toUpperCase();
  return note.isEmpty ? '$head$transition' : '$head$transition - $note';
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DailyWorkerTemplateDialog extends StatefulWidget {
  const _DailyWorkerTemplateDialog({this.template});

  final Map<String, dynamic>? template;

  @override
  State<_DailyWorkerTemplateDialog> createState() =>
      _DailyWorkerTemplateDialogState();
}

class _DailyWorkerTemplateDialogState extends State<_DailyWorkerTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _assigneeController;
  late final TextEditingController _linkedItemsController;
  late final TextEditingController _tagsController;
  String _category = 'maintenance';
  String _status = 'todo';
  String _priority = 'medium';

  @override
  void initState() {
    super.initState();
    final template = widget.template ?? const <String, dynamic>{};
    _titleController =
        TextEditingController(text: template['title']?.toString() ?? '');
    _descriptionController =
        TextEditingController(text: template['description']?.toString() ?? '');
    _assigneeController =
        TextEditingController(text: template['assignee']?.toString() ?? '');
    _linkedItemsController = TextEditingController(
      text: _serializeLinkedItems(List<dynamic>.from(template['linkedItems'] ?? [])),
    );
    _tagsController = TextEditingController(
      text: List<String>.from(template['tags'] ?? []).join(', '),
    );
    _category = template['category']?.toString() ?? _category;
    _status = template['status']?.toString() ?? _status;
    _priority = template['priority']?.toString() ?? _priority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assigneeController.dispose();
    _linkedItemsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  String _serializeLinkedItems(List<dynamic> linkedItems) {
    if (linkedItems.isEmpty) return '';
    return linkedItems.map((item) {
      final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
      return [
        map['type']?.toString() ?? 'asset',
        map['recordId']?.toString() ?? '',
        map['label']?.toString() ?? '',
      ].join('|');
    }).join('; ');
  }

  List<Map<String, dynamic>> _parseLinkedItems(String raw) {
    final result = <Map<String, dynamic>>[];
    for (final chunk in raw.split(RegExp(r'[;\n]'))) {
      final trimmed = chunk.trim();
      if (trimmed.isEmpty) continue;
      final pieces = trimmed.split('|').map((item) => item.trim()).toList();
      result.add({
        'type': pieces.isNotEmpty ? pieces[0].toLowerCase() : 'asset',
        'recordId': pieces.length > 1 ? pieces[1] : '',
        'label': pieces.length > 2
            ? pieces[2]
            : (pieces.length > 1 ? pieces[1] : pieces[0]),
        'url': '',
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final categories = const ['asset', 'ticket', 'maintenance', 'disposal', 'documentation'];
    final statuses = const ['backlog', 'todo', 'in_progress', 'blocked', 'review', 'done'];
    final priorities = const ['low', 'medium', 'high', 'urgent'];

    return DesktopModalShell(
      title: widget.template == null ? 'Buat Template' : 'Edit Template',
      subtitle: 'Template ini akan dipakai untuk membuat task cepat.',
      icon: Icons.library_add_outlined,
      maxWidth: 780,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Nama Template'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: [
                        for (final item in categories)
                          DropdownMenuItem(
                            value: item,
                            child: Text(item.toUpperCase()),
                          ),
                      ],
                      onChanged: (value) => setState(() => _category = value ?? _category),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status Default'),
                      items: [
                        for (final item in statuses)
                          DropdownMenuItem(
                            value: item,
                            child: Text(item.replaceAll('_', ' ').toUpperCase()),
                          ),
                      ],
                      onChanged: (value) => setState(() => _status = value ?? _status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(labelText: 'Prioritas Default'),
                      items: [
                        for (final item in priorities)
                          DropdownMenuItem(
                            value: item,
                            child: Text(item.toUpperCase()),
                          ),
                      ],
                      onChanged: (value) => setState(() => _priority = value ?? _priority),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _assigneeController,
                      decoration: const InputDecoration(labelText: 'PIC Default'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _linkedItemsController,
                decoration: const InputDecoration(
                  labelText: 'Relasi Default',
                  hintText: 'asset|AS-001|Laptop; ticket|TK-12|Printer error',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'urgent, daily, edp',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        PrimaryButton(
          label: 'Simpan Template',
          leading: const Icon(Icons.save_outlined),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop({
              'title': _titleController.text.trim(),
              'description': _descriptionController.text.trim(),
              'category': _category,
              'status': _status,
              'priority': _priority,
              'assignee': _assigneeController.text.trim(),
              'linkedItems': _parseLinkedItems(_linkedItemsController.text.trim()),
              'tags': _tagsController.text
                  .split(',')
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toList(),
            });
          },
        ),
      ],
    );
  }
}

class _DailyWorkerTaskDialog extends StatefulWidget {
  const _DailyWorkerTaskDialog({
    required this.selectedDay,
    required this.selectedMonth,
    this.task,
  });

  final DateTime selectedDay;
  final DateTime selectedMonth;
  final Map<String, dynamic>? task;

  @override
  State<_DailyWorkerTaskDialog> createState() => _DailyWorkerTaskDialogState();
}

class _DailyWorkerTaskDialogState extends State<_DailyWorkerTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _assigneeController;
  late final TextEditingController _dueDateController;
  late final TextEditingController _linkedItemsController;
  late final TextEditingController _tagsController;
  late final TextEditingController _blockedReasonController;
  late final TextEditingController _overdueReasonController;
  late final TextEditingController _recapNoteController;
  String _category = 'maintenance';
  String _status = 'todo';
  String _priority = 'medium';
  late DateTime _workDate;

  @override
  void initState() {
    super.initState();
    final task = widget.task ?? const <String, dynamic>{};
    _titleController = TextEditingController(text: task['title']?.toString() ?? '');
    _descriptionController =
        TextEditingController(text: task['description']?.toString() ?? '');
    _assigneeController = TextEditingController(text: task['assignee']?.toString() ?? '');
    _dueDateController = TextEditingController(text: task['dueDate']?.toString() ?? '');
    _linkedItemsController = TextEditingController(
      text: _serializeLinkedItems(List<dynamic>.from(task['linkedItems'] ?? [])),
    );
    _tagsController = TextEditingController(
      text: List<String>.from(task['tags'] ?? []).join(', '),
    );
    _blockedReasonController =
        TextEditingController(text: task['blockedReason']?.toString() ?? '');
    _overdueReasonController =
        TextEditingController(text: task['overdueReason']?.toString() ?? '');
    _recapNoteController = TextEditingController(text: task['recapNote']?.toString() ?? '');
    _category = task['category']?.toString() ?? _category;
    _status = task['status']?.toString() ?? _status;
    _priority = task['priority']?.toString() ?? _priority;
    if (!const ['asset', 'ticket', 'maintenance', 'disposal', 'documentation']
        .contains(_category)) {
      _category = 'maintenance';
    }
    if (!const ['backlog', 'todo', 'in_progress', 'blocked', 'review', 'done']
        .contains(_status)) {
      _status = 'todo';
    }
    if (!const ['low', 'medium', 'high', 'urgent'].contains(_priority)) {
      _priority = 'medium';
    }
    _workDate = task['workDate'] != null
        ? DateTime.tryParse(task['workDate'].toString()) ?? widget.selectedDay
        : widget.selectedDay;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assigneeController.dispose();
    _dueDateController.dispose();
    _linkedItemsController.dispose();
    _tagsController.dispose();
    _blockedReasonController.dispose();
    _overdueReasonController.dispose();
    _recapNoteController.dispose();
    super.dispose();
  }

  String _serializeLinkedItems(List<dynamic> linkedItems) {
    if (linkedItems.isEmpty) return '';
    return linkedItems.map((item) {
      final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
      return [
        map['type']?.toString() ?? 'asset',
        map['recordId']?.toString() ?? '',
        map['label']?.toString() ?? '',
      ].join('|');
    }).join('; ');
  }

  @override
  Widget build(BuildContext context) {
    final categories = const ['asset', 'ticket', 'maintenance', 'disposal', 'documentation'];
    final statuses = const ['backlog', 'todo', 'in_progress', 'blocked', 'review', 'done'];
    final priorities = const ['low', 'medium', 'high', 'urgent'];

    return DesktopModalShell(
      title: widget.task == null ? 'Buat Task' : 'Edit Task',
      subtitle: 'Task dipetakan ke bulan dan hari kerja.',
      icon: Icons.task_alt_outlined,
      maxWidth: 820,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Task'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: [
                        for (final item in categories)
                          DropdownMenuItem(
                            value: item,
                            child: Text(item.toUpperCase()),
                          ),
                      ],
                      onChanged: (value) => setState(() => _category = value ?? _category),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: [
                        for (final item in statuses)
                          DropdownMenuItem(
                            value: item,
                            child: Text(item.replaceAll('_', ' ').toUpperCase()),
                          ),
                      ],
                      onChanged: (value) => setState(() => _status = value ?? _status),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(labelText: 'Prioritas'),
                      items: [
                        for (final item in priorities)
                          DropdownMenuItem(
                            value: item,
                            child: Text(item.toUpperCase()),
                          ),
                      ],
                      onChanged: (value) => setState(() => _priority = value ?? _priority),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _assigneeController,
                      decoration: const InputDecoration(labelText: 'Assignee'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dueDateController,
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        hintText: 'YYYY-MM-DD',
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      initialValue: DateFormat('yyyy-MM-dd').format(_workDate),
                      decoration: const InputDecoration(
                        labelText: 'Work Date',
                        hintText: 'YYYY-MM-DD',
                      ),
                      onChanged: (value) {
                        final parsed = DateTime.tryParse(value.trim());
                        if (parsed != null) {
                          _workDate = DateTime(parsed.year, parsed.month, parsed.day);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _linkedItemsController,
                decoration: const InputDecoration(
                  labelText: 'Relasi Tugas',
                  hintText: 'asset|AS-001|Laptop; ticket|TK-12|Printer error',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'urgent, weekly, edp',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _blockedReasonController,
                decoration: const InputDecoration(labelText: 'Alasan Blocked'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _overdueReasonController,
                decoration: const InputDecoration(labelText: 'Alasan Overdue'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _recapNoteController,
                decoration: const InputDecoration(labelText: 'Catatan Recap'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        PrimaryButton(
          label: widget.task == null ? 'Simpan' : 'Update',
          leading: const Icon(Icons.save_outlined),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final linkedItems = _parseLinkedItems(_linkedItemsController.text.trim());
            final tags = _tagsController.text
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList();
            Navigator.of(context).pop({
              'title': _titleController.text.trim(),
              'description': _descriptionController.text.trim(),
              'category': _category,
              'status': _status,
              'priority': _priority,
              'assignee': _assigneeController.text.trim(),
              'workDate': DateFormat('yyyy-MM-dd').format(_workDate),
              'dueDate': _dueDateController.text.trim(),
              'linkedItems': linkedItems,
              'tags': tags,
              'blockedReason': _blockedReasonController.text.trim(),
              'overdueReason': _overdueReasonController.text.trim(),
              'recapNote': _recapNoteController.text.trim(),
            });
          },
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _parseLinkedItems(String raw) {
    final result = <Map<String, dynamic>>[];
    for (final chunk in raw.split(RegExp(r'[;\n]'))) {
      final trimmed = chunk.trim();
      if (trimmed.isEmpty) continue;
      final pieces = trimmed.split('|').map((item) => item.trim()).toList();
      result.add({
        'type': pieces.isNotEmpty ? pieces[0].toLowerCase() : 'asset',
        'recordId': pieces.length > 1 ? pieces[1] : '',
        'label': pieces.length > 2
            ? pieces[2]
            : (pieces.length > 1 ? pieces[1] : pieces[0]),
        'url': '',
      });
    }
    return result;
  }
}

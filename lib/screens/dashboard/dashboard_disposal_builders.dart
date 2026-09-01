// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, unused_element
part of '../dashboard_screen.dart';

extension DashboardDisposalBuilders on _DashboardScreenState {
  Widget _buildDataPanel(
      BuildContext context,
      List<dynamic> disposals,
      List<dynamic> users,
      List<dynamic> audits,
      List<dynamic> files,
      Color backgroundColor) {
    return Column(
      children: [
        SectionCard(
          title: 'Upload Data',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 16, runSpacing: 16, children: [
                _metricCard('Disposal', disposals.length.toString(),
                    Icons.inventory_2_outlined),
                _metricCard(
                    'Pengguna', users.length.toString(), Icons.group_outlined),
                _metricCard(
                    'Audit', audits.length.toString(), Icons.history_outlined),
                _metricCard('File', files.length.toString(),
                    Icons.folder_open_outlined),
              ]),
              const SizedBox(height: 24),
              _buildDisposalPanel(disposals.take(4).toList()),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildUploadPanel(),
      ],
    );
  }

  Widget _buildAnalysisCard(List<dynamic> disposals) {
    final filteredDisposals = _filterAnalysisTrendDisposals(disposals);
    final counts = _buildDivisionDisposalCounts(filteredDisposals);
    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    return SectionCard(
      title: 'Analisa Tren',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _analysisSummaryPill(
                  'Total Pembuangan', total.toString(), Icons.delete_outline),
              _analysisSummaryPill(
                'Divisi Aktif',
                counts.values.where((value) => value > 0).length.toString(),
                Icons.storefront_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildAnalysisTrendFilters(),
          const SizedBox(height: 18),
          if (total == 0)
            Container(
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7EF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5EBDD)),
              ),
              child: const Text('Belum ada data pembuangan.'),
            )
          else
            SizedBox(
              height: 230,
              child: _buildDivisionTrendChart(counts),
            ),
        ],
      ),
    );
  }

  List<dynamic> _filterAnalysisTrendDisposals(List<dynamic> disposals) {
    return disposals.where((item) {
      final map = item as Map<String, dynamic>;
      final date = DateTime.tryParse(map['date']?.toString() ?? '');
      if (date == null) return false;
      final sameYear = date.year == _analysisTrendYear;
      final sameMonth = date.month == _analysisTrendDate.month;
      if (_analysisTrendMode == TrendFilterMode.monthly) {
        return sameYear && sameMonth;
      }
      return sameYear && sameMonth && date.day == _analysisTrendDate.day;
    }).toList();
  }

  Widget _buildAnalysisTrendFilters() {
    final currentYear = DateTime.now().year;
    final years = [
      for (var year = currentYear - 5; year <= currentYear + 1; year++) year,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EBDD)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<TrendFilterMode>(
            segments: const [
              ButtonSegment(
                value: TrendFilterMode.monthly,
                icon: Icon(Icons.calendar_view_month_outlined, size: 18),
                label: Text('Bulanan'),
              ),
              ButtonSegment(
                value: TrendFilterMode.daily,
                icon: Icon(Icons.today_outlined, size: 18),
                label: Text('Tanggal'),
              ),
            ],
            selected: {_analysisTrendMode},
            onSelectionChanged: (selection) {
              setState(() => _analysisTrendMode = selection.first);
            },
          ),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<int>(
              initialValue: _analysisTrendDate.month,
              decoration: const InputDecoration(
                labelText: 'Bulan',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              items: [
                for (var month = 1; month <= 12; month++)
                  DropdownMenuItem(
                    value: month,
                    child: Text(DateFormat('MMMM').format(DateTime(2026, month))),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                final day = _analysisTrendDate.day.clamp(
                  1,
                  DateUtils.getDaysInMonth(_analysisTrendYear, value),
                ).toInt();
                setState(() {
                  _analysisTrendDate =
                      DateTime(_analysisTrendYear, value, day);
                });
              },
            ),
          ),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<int>(
              initialValue: years.contains(_analysisTrendYear)
                  ? _analysisTrendYear
                  : currentYear,
              decoration: const InputDecoration(
                labelText: 'Tahun',
                prefixIcon: Icon(Icons.event_outlined),
              ),
              items: years
                  .map((year) => DropdownMenuItem(
                      value: year, child: Text(year.toString())))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                final day = _analysisTrendDate.day.clamp(
                  1,
                  DateUtils.getDaysInMonth(value, _analysisTrendDate.month),
                ).toInt();
                setState(() {
                  _analysisTrendYear = value;
                  _analysisTrendDate = DateTime(
                    value,
                    _analysisTrendDate.month,
                    day,
                  );
                });
              },
            ),
          ),
          if (_analysisTrendMode == TrendFilterMode.daily)
            SizedBox(
              width: 210,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Color(0xFFD8DEE8)),
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _analysisTrendDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(currentYear + 1, 12, 31),
                  );
                  if (picked == null) return;
                  setState(() {
                    _analysisTrendDate = picked;
                    _analysisTrendYear = picked.year;
                  });
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      DateFormat('dd MMM yyyy').format(_analysisTrendDate)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivisionTrendChart(Map<String, int> counts) {
    final entries = counts.entries.toList();
    final maxCount = entries.fold<int>(
        0, (max, entry) => entry.value > max ? entry.value : max);
    final maxY = (maxCount + 4).toDouble();

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY <= 4 ? 5 : maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Color(0xFFE5EBDD),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1D2B38),
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = entries[group.x.toInt()];
              return BarTooltipItem(
                '${_divisionDisplayLabel(entry.key)}\n${entry.value} data',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: _chartInterval(maxCount),
              getTitlesWidget: (value, meta) {
                if (value < 0 || value > maxY) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Color(0xFF68777A),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 58,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= entries.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _divisionChartLabel(entries[index].key),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF1D2B38),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var index = 0; index < entries.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entries[index].value.toDouble(),
                  width: 24,
                  color: const Color(0xFF2E7D32),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY <= 4 ? 5 : maxY,
                    color: const Color(0xFFE5EBDD),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  double _chartInterval(int maxCount) {
    if (maxCount <= 5) return 1;
    if (maxCount <= 20) return 5;
    if (maxCount <= 50) return 10;
    return 20;
  }

  Map<String, int> _buildDivisionDisposalCounts(List<dynamic> disposals) {
    final counts = {
      'GROCERY': 0,
      'SOZAI': 0,
      'SOZAI (SISA PRODUKSI)': 0,
      'FISH': 0,
      'F&V': 0,
      'MEAT': 0,
    };

    for (final item in disposals) {
      final map = item as Map<String, dynamic>;
      final division = (map['division']?.toString() ?? '').toUpperCase();
      if (counts.containsKey(division)) {
        counts[division] = counts[division]! + 1;
      }
    }
    return counts;
  }

  String _divisionDisplayLabel(String division) {
    final match = _disposalDivisions.firstWhere(
      (item) => item['apiValue'] == division,
      orElse: () => {'label': division},
    );
    return match['label']!.toUpperCase();
  }

  String _divisionChartLabel(String division) {
    switch (division) {
      case 'GROCERY':
        return 'Grocery';
      case 'SOZAI':
        return 'Sozai';
      case 'SOZAI (SISA PRODUKSI)':
        return 'Sozai\nSisa';
      case 'F&V':
        return 'F&V';
      case 'MEAT':
        return 'Meat';
      default:
        return division;
    }
  }

  Widget _analysisSummaryPill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7EF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5EBDD)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Color(0xFF68777A))),
          const SizedBox(width: 10),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF1D2B38), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _divisionTrendRow({
    required String label,
    required int count,
    required int maxCount,
  }) {
    final ratio = maxCount == 0 ? 0.0 : count / maxCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1D2B38),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 14,
                value: ratio,
                backgroundColor: const Color(0xFFE5EBDD),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 58,
            child: Text(
              '$count data',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF1D2B38),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisposalFilterCard(
      BuildContext context, List<dynamic> disposals) {
    return SectionCard(
      title: 'Filter Data Pembuangan',
      actions: [
        PrimaryButton(
          label: 'Download Semua PDF',
          leading: const Icon(Icons.picture_as_pdf_outlined),
          onPressed: disposals.isEmpty
              ? null
              : () => _showFilteredDisposalsDialog(disposals),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildFilterDateField(context, 'Dari tanggal', true),
              _buildFilterDateField(context, 'Sampai tanggal', false),
              _buildDivisionFilter(context),
            ],
          ),
          const SizedBox(height: 20),
          Text(
              'Pilih range tanggal dan divisi lalu tekan tombol untuk menampilkan data.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildFilterDateField(
      BuildContext context, String label, bool isStart) {
    final selectedDate = isStart ? _filterStartDate : _filterEndDate;
    return SizedBox(
      width: 260,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFFFFFF),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: const BorderSide(color: Color(0xFFE5EBDD)),
        ),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
          );
          if (picked == null) return;
          setState(() {
            if (isStart) {
              _filterStartDate = picked;
            } else {
              _filterEndDate = picked;
            }
          });
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            selectedDate == null
                ? label
                : '$label: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildDivisionFilter(BuildContext context) {
    final selectedValue = _normalizeDivisionFilterValue(_disposalFilterDivision);
    return SizedBox(
      width: 260,
      child: DropdownButtonFormField<String>(
        initialValue: selectedValue,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          prefixIcon: const Icon(Icons.storefront_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5EBDD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5EBDD)),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        items: [
          const DropdownMenuItem(value: 'all', child: Text('Semua Divisi')),
          ..._disposalDivisions.map((division) => DropdownMenuItem(
                value: division['value'],
                child: Text(division['label']!),
              )),
        ],
        onChanged: (value) =>
            setState(() => _disposalFilterDivision = value ?? 'all'),
      ),
    );
  }

  String _normalizeDivisionFilterValue(String value) {
    final normalized = value.toLowerCase();
    if (normalized == 'all') return 'all';
    if (_disposalDivisions.any((division) => division['value'] == normalized)) {
      return normalized;
    }
    final byApiValue = _disposalDivisions.firstWhere(
      (division) => division['apiValue']!.toLowerCase() == normalized,
      orElse: () => const {},
    );
    if (byApiValue.isNotEmpty) return byApiValue['value']!;
    return 'all';
  }

  String _divisionFilterApiValue(String filterValue) {
    final normalized = _normalizeDivisionFilterValue(filterValue);
    if (normalized == 'all') return 'all';
    final match = _disposalDivisions.firstWhere(
      (division) => division['value'] == normalized,
      orElse: () => const {'apiValue': 'all'},
    );
    return match['apiValue']!;
  }
}

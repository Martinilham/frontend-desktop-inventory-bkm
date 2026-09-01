// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, unused_element
part of '../dashboard_screen.dart';

extension DashboardLayoutBuilders on _DashboardScreenState {
  Widget _buildSidebar({required bool compact}) {
    return Container(
      width: compact ? 92 : 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 88,
            child: Center(
              child: compact
                  ? const Text(
                      'DS',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Nunito Sans',
                        ),
                        children: [
                          TextSpan(
                            text: 'Dash',
                            style: TextStyle(color: Color(0xFF2E7D32)),
                          ),
                          TextSpan(
                            text: 'Stack',
                            style: TextStyle(color: Color(0xFF1D2B38)),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
              children: [
                _buildSidebarItem(
                    Icons.dashboard_outlined, 'Dashboard', DashboardSection.home,
                    compact: compact),
                _buildSidebarItem(Icons.inventory_2_outlined, 'Data Pembuangan',
                    DashboardSection.disposalData,
                    compact: compact),
                _buildSidebarItem(Icons.analytics_outlined, 'Analisa',
                    DashboardSection.analysis,
                    compact: compact),
                _buildSidebarItem(Icons.storefront_outlined, 'GrabMerch',
                    DashboardSection.grabMerch,
                    compact: compact),
                _buildSidebarItem(Icons.view_kanban_outlined, 'Daily Worker',
                    DashboardSection.dailyWorker,
                    compact: compact),
                _buildSidebarItem(Icons.document_scanner_outlined, 'Baca Data',
                    DashboardSection.readData,
                    compact: compact),
                _buildSidebarItem(Icons.fact_check_outlined, 'Absensi Cek',
                    DashboardSection.absenceCheck,
                    compact: compact),
                _buildSidebarItem(Icons.receipt_long_outlined, 'Log Aktivitas',
                    DashboardSection.auditLogs,
                    compact: compact),
                const SizedBox(height: 22),
                const Divider(height: 1),
                if (!compact)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 20, 24, 10),
                    child: Text(
                      'PAGES',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                _buildSidebarItem(Icons.manage_accounts_outlined, 'Akun',
                    DashboardSection.accounts,
                    compact: compact),
                _buildSidebarCommand(Icons.refresh_rounded, 'Refresh',
                    _refreshDashboard,
                    compact: compact),
                _buildSidebarCommand(
                  Icons.logout_rounded,
                  'Logout',
                  () async => await widget.onLogout(),
                  compact: compact,
                  danger: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String label,
    DashboardSection section, {
    required bool compact,
  }) {
    final isSelected = _selectedSection == section;
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 24, 4, compact ? 16 : 24, 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isSelected)
            Positioned(
              left: compact ? -16 : -24,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(8),
                  ),
                ),
              ),
            ),
          Material(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => setState(() => _selectedSection = section),
              child: SizedBox(
                height: 54,
                child: compact
                    ? Tooltip(
                        message: label,
                        child: Icon(
                          icon,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1D2B38),
                        ),
                      )
                    : Row(
                      children: [
                        const SizedBox(width: 18),
                        Icon(
                          icon,
                          size: 21,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1D2B38),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            label,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF1D2B38),
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarCommand(
    IconData icon,
    String label,
    VoidCallback onTap, {
    required bool compact,
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFE11D48) : const Color(0xFF1D2B38);
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 24, 4, compact ? 16 : 24, 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: SizedBox(
            height: 54,
            child: compact
                ? Tooltip(
                    message: label,
                    child: Icon(icon, color: color),
                  )
                : Row(
                    children: [
                      const SizedBox(width: 18),
                      Icon(icon, size: 21, color: color),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, {required bool compact}) {
    return Container(
      height: 88,
      padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 300 : 492),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF68777A)),
                filled: true,
                fillColor: const Color(0xFFFAFBF7),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFE5EBDD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFE5EBDD)),
                ),
              ),
            ),
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _TopBarIconButton(
                icon: Icons.notifications_outlined,
                backgroundColor: Colors.transparent,
                foregroundColor: const Color(0xFF2E7D32),
                onTap: _refreshDashboard,
                tooltip: 'Notifikasi',
              ),
              Positioned(
                right: 10,
                top: 7,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF477E),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '6',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(width: 18),
            Container(
              width: 34,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: const Text(
                'EN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'English',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF68777A),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF68777A)),
          ],
          const SizedBox(width: 22),
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFE9D5FF),
            child: Icon(Icons.person, color: Color(0xFFB45309)),
          ),
          if (!compact) ...[
            const SizedBox(width: 14),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin BKM',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1D2B38),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text('Admin', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
          const SizedBox(width: 10),
          _TopBarIconButton(
            icon: Icons.logout_rounded,
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF68777A),
            onTap: () async => await widget.onLogout(),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  EdgeInsets _contentPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 900) return const EdgeInsets.all(18);
    if (width < 1300) return const EdgeInsets.all(28);
    return const EdgeInsets.all(40);
  }

  Widget _buildMainContent(BuildContext context) {
    if (_selectedSection == DashboardSection.accounts) {
      return Padding(
        padding: _contentPadding(context),
        child: AccountsScreen(apiService: widget.apiService),
      );
    }

    if (_selectedSection == DashboardSection.home) {
      return FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? {};
          return Padding(
            padding: _contentPadding(context),
            child: _buildHomeDashboard(context, data),
          );
        },
      );
    }

    if (_selectedSection == DashboardSection.grabMerch) {
      return FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            if (snapshot.error is AuthException) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => widget.onLogout());
              return const Center(child: CircularProgressIndicator());
            }
          }

          final data = snapshot.data ?? {};
          final grabMerchItems = List<dynamic>.from(data['grabmerch'] ?? []);
          return Padding(
            padding: _contentPadding(context),
            child: _buildGrabMerchPanel(context, grabMerchItems),
          );
        },
      );
    }

    if (_selectedSection == DashboardSection.dailyWorker) {
      return Padding(
        padding: _contentPadding(context),
        child: DailyWorkerScreen(
          apiService: widget.apiService,
          onLogout: widget.onLogout,
        ),
      );
    }

    if (_selectedSection == DashboardSection.absenceCheck) {
      return FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            if (snapshot.error is AuthException) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => widget.onLogout());
              return const Center(child: CircularProgressIndicator());
            }
          }

          final data = snapshot.data ?? {};
          final items = List<dynamic>.from(data['absenceDocuments'] ?? []);
          return Padding(
            padding: _contentPadding(context),
            child: _buildAbsenceCheckPanel(context, items),
          );
        },
      );
    }

    if (_selectedSection == DashboardSection.readData) {
      return FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            if (snapshot.error is AuthException) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => widget.onLogout());
              return const Center(child: CircularProgressIndicator());
            }
          }

          final data = snapshot.data ?? {};
          final items = List<dynamic>.from(data['readData'] ?? []);
          return Padding(
            padding: _contentPadding(context),
            child: _buildReadDataPanel(context, items),
          );
        },
      );
    }

    if (_selectedSection == DashboardSection.analysis) {
      return FutureBuilder<Map<String, dynamic>>(
        future: _analysisFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            if (snapshot.error is AuthException) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => widget.onLogout());
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

          final analysis = snapshot.data ?? {};
          return Padding(
            padding: _contentPadding(context),
            child: _buildDailyProductAnalysisPanel(context, analysis),
          );
        },
      );
    }

    if (_selectedSection == DashboardSection.auditLogs) {
      return FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? {};
          final audits = List<dynamic>.from(data['audit'] ?? []);
          return Padding(
            padding: _contentPadding(context),
            child: _buildAuditLogPage(audits),
          );
        },
      );
    }

    if (_selectedSection != DashboardSection.disposalData) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            if (snapshot.error is AuthException) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => widget.onLogout());
              return const Center(child: CircularProgressIndicator());
            }
          }

          final data = snapshot.data ?? {};
          final audits = List<dynamic>.from(data['audit'] ?? []);
          final disposals = List<dynamic>.from(data['disposals'] ?? []);
          final users = List<dynamic>.from(data['users'] ?? []);
          final files = List<dynamic>.from(data['files'] ?? []);
          final displayDisposals = disposals;

          return ListView(
            padding: _contentPadding(context),
            children: [
              Text(
                'Data Pembuangan',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 32,
                      color: const Color(0xFF1D2B38),
                    ),
              ),
              const SizedBox(height: 34),
              LayoutBuilder(
                builder: (context, constraints) {
                  final sidePanel = Column(
                    children: [
                      SizedBox(
                        height: constraints.maxWidth < 980 ? 460 : 540,
                        child: _buildAnalysisCard(displayDisposals),
                      ),
                      const SizedBox(height: 24),
                      _buildDisposalFilterCard(context, displayDisposals),
                    ],
                  );
                  if (constraints.maxWidth < 980) {
                    return Column(
                      children: [
                        _buildDataPanel(context, displayDisposals, users,
                            audits, files, const Color(0xFFFAFBF7)),
                        const SizedBox(height: 24),
                        sidePanel,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildDataPanel(context, displayDisposals, users,
                            audits, files, const Color(0xFFFAFBF7)),
                      ),
                      const SizedBox(width: 24),
                      Expanded(child: sidePanel),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPremiumMetricCard(String title, String value, Color background,
      Color textColor, IconData icon) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: textColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: textColor.withOpacity(0.95), fontSize: 12))),
            ],
          ),
          const SizedBox(height: 20),
          Text(value,
              style: TextStyle(
                  color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHomeDashboard(BuildContext context, Map<String, dynamic> data) {
    final disposals = List<dynamic>.from(data['disposals'] ?? []);
    final users = List<dynamic>.from(data['users'] ?? []);
    final audits = List<dynamic>.from(data['audit'] ?? []);
    final absenceDocuments = List<dynamic>.from(data['absenceDocuments'] ?? []);
    final readData = List<dynamic>.from(data['readData'] ?? []);
    final latestDisposals = disposals.take(4).toList();

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 32,
                        color: const Color(0xFF1D2B38),
                      ),
                ),
              ),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _refreshDashboard,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 1200
                  ? (constraints.maxWidth - 72) / 4
                  : constraints.maxWidth >= 760
                      ? (constraints.maxWidth - 24) / 2
                      : constraints.maxWidth;
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _homeStatCard('Total Disposal', disposals.length.toString(),
                      Icons.inventory_2_outlined, const Color(0xFF2E7D32),
                      width: width),
                  _homeStatCard('Total Akun', users.length.toString(),
                      Icons.group_outlined, const Color(0xFFFFB74D),
                      width: width),
                  _homeStatCard('Total Absensi',
                      absenceDocuments.length.toString(),
                      Icons.fact_check_outlined, const Color(0xFF8CC63F),
                      width: width),
                  _homeStatCard('Total OCR', readData.length.toString(),
                      Icons.document_scanner_outlined, const Color(0xFFFFB74D),
                      width: width),
                ],
              );
            },
          ),
          const SizedBox(height: 34),
          LayoutBuilder(
            builder: (context, constraints) {
              final disposalPanel = SectionCard(
                title: 'Disposal Terbaru',
                child: latestDisposals.isEmpty
                    ? const SizedBox(
                        height: 140,
                        child: Center(child: Text('Belum ada disposal')),
                      )
                    : Column(
                        children: latestDisposals
                            .map((item) => _homeActivityRow(
                                  icon: Icons.inventory_2_outlined,
                                  title:
                                      (item as Map)['division']?.toString() ??
                                          '-',
                                  subtitle: item['date']?.toString() ?? '-',
                                ))
                            .toList(),
                      ),
              );
              final activityPanel = SectionCard(
                title: 'Aktivitas Terbaru',
                child: audits.isEmpty
                    ? const SizedBox(
                        height: 140,
                        child: Center(child: Text('Belum ada aktivitas')),
                      )
                    : Column(
                        children: _homeAuditLogs(audits)
                            .map((item) => _homeActivityRow(
                                  icon: Icons.history_outlined,
                                  title: _auditLogTitle(item),
                                  subtitle: _auditLogSubtitle(item),
                                ))
                            .toList(),
                      ),
              );
              if (constraints.maxWidth < 980) {
                return Column(
                  children: [
                    disposalPanel,
                    const SizedBox(height: 24),
                    activityPanel,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: disposalPanel),
                  const SizedBox(width: 24),
                  Expanded(child: activityPanel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _homeStatCard(
    String label,
    String value,
    IconData icon,
    Color accentColor, {
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF68777A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: accentColor, size: 30),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1D2B38),
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.trending_up_rounded,
                    size: 18, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Text(
                  'Updated today',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF68777A),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _auditLogTitle(Map<String, dynamic> item) {
    final user = item['userUsername']?.toString() ?? '-';
    final action = item['action']?.toString() ?? '-';
    return '$user - $action';
  }

  List<Map<String, dynamic>> _homeAuditLogs(List<dynamic> audits) {
    final mapped = audits
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final mobile = mapped.where(_isMobileAuditLog).take(4).toList();
    final fallback = mapped
        .where((item) => !mobile.any((mobileItem) => mobileItem['id'] == item['id']))
        .take(4 - mobile.length)
        .toList();
    return [...mobile, ...fallback];
  }

  bool _isMobileAuditLog(Map<String, dynamic> item) {
    final device = (item['device']?.toString() ?? '').toLowerCase();
    return device.contains('android') ||
        device.contains('ios') ||
        device.contains('iphone') ||
        device.contains('ipad');
  }

  String _auditLogSubtitle(Map<String, dynamic> item) {
    final details = item['details'];
    final detailMap =
        details is Map ? Map<String, dynamic>.from(details) : <String, dynamic>{};
    final method =
        detailMap['method']?.toString() ?? item['method']?.toString() ?? '';
    final path = detailMap['accessedPath']?.toString() ??
        item['path']?.toString() ??
        '';
    final device = item['device']?.toString() ?? '';
    final parts = [
      if (method.isNotEmpty || path.isNotEmpty) '$method $path'.trim(),
      if (device.isNotEmpty) device,
    ];
    return parts.isEmpty ? (details?.toString() ?? '-') : parts.join(' - ');
  }

  Widget _homeActivityRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Color(0xFF1D2B38))),
                const SizedBox(height: 3),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF68777A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, color: foregroundColor),
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, unused_element
part of '../dashboard_screen.dart';

extension DashboardLayoutBuilders on _DashboardScreenState {
  Widget _buildSidebar({required bool compact}) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: compact ? 92 : 240,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.76),
            border: const Border(
              right: BorderSide(color: Color(0xBFE5E7EB)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 88,
                child: Center(
                  child: ClipRect(
                    child: SizedBox(
                      width: compact ? 72 : 204,
                      height: 68,
                      child: Image.asset(
                        'assets/logos/logo_papaya.png',
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
                  children: [
                    _buildSidebarItem(Icons.dashboard_outlined, 'Dashboard',
                        DashboardSection.home,
                        compact: compact),
                    _buildDisposalSidebarGroup(compact: compact),
                    _buildSidebarItem(
                        Icons.event_note_outlined,
                        'Deadline Inventory',
                        DashboardSection.inventoryDeadlines,
                        compact: compact),
                    _buildSidebarItem(
                        Icons.swap_horiz_rounded,
                        'Inventory Transaction',
                        DashboardSection.inventoryTransactions,
                        compact: compact),
                    _buildSidebarItem(Icons.storefront_outlined, 'GrabMerch',
                        DashboardSection.grabMerch,
                        compact: compact),
                    _buildSidebarItem(Icons.view_kanban_outlined,
                        'Daily Worker', DashboardSection.dailyWorker,
                        compact: compact),
                    _buildSidebarItem(Icons.document_scanner_outlined,
                        'Baca Data', DashboardSection.readData,
                        compact: compact),
                    _buildDocumentationSidebarGroup(compact: compact),
                    _buildSidebarItem(Icons.receipt_long_outlined,
                        'Log Aktivitas', DashboardSection.auditLogs,
                        compact: compact),
                    const SizedBox(height: 22),
                    const Divider(height: 1),
                    if (!compact)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 20, 24, 10),
                        child: Text(
                          'PAGES',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    _buildSidebarItem(Icons.manage_accounts_outlined, 'Akun',
                        DashboardSection.accounts,
                        compact: compact),
                    _buildSidebarCommand(
                        Icons.refresh_rounded, 'Refresh', _refreshDashboard,
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
        ),
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
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(8),
                  ),
                ),
              ),
            ),
          Material(
            color: isSelected ? AppTheme.primary : Colors.transparent,
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
                              ? Theme.of(context).colorScheme.onPrimary
                              : AppTheme.textPrimary,
                        ),
                      )
                    : Row(
                        children: [
                          const SizedBox(width: 18),
                          Icon(
                            icon,
                            size: 21,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : AppTheme.textPrimary,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              label,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                        : AppTheme.textPrimary,
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

  Widget _buildDisposalSidebarGroup({required bool compact}) {
    final isSelected = _selectedSection == DashboardSection.disposalInput ||
        _selectedSection == DashboardSection.disposalStatistics;
    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: PopupMenuButton<DashboardSection>(
          tooltip: 'Data Pembuangan',
          icon: Icon(Icons.inventory_2_outlined,
              color: isSelected ? AppTheme.primary : AppTheme.textPrimary),
          onSelected: (section) {
            setState(() => _selectedSection = section);
            if (section == DashboardSection.disposalInput) {
              _refreshDashboard();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
                value: DashboardSection.disposalInput,
                child: Text('Input Pembuangan')),
            PopupMenuItem(
                value: DashboardSection.disposalStatistics,
                child: Text('Statistik Pembuangan')),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
      child: Column(children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              setState(() {
                _disposalMenuExpanded = !_disposalMenuExpanded;
                if (!isSelected) {
                  _selectedSection = DashboardSection.disposalInput;
                }
              });
              if (!isSelected) _refreshDashboard();
            },
            child: SizedBox(
              height: 54,
              child: Row(children: [
                const SizedBox(width: 18),
                Icon(Icons.inventory_2_outlined,
                    size: 21,
                    color:
                        isSelected ? AppTheme.primary : AppTheme.textPrimary),
                const SizedBox(width: 14),
                Expanded(
                    child: Text('Data Pembuangan',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                            fontWeight: FontWeight.w700))),
                AnimatedRotation(
                  turns: _disposalMenuExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeInOutCubic,
                  child: Icon(Icons.expand_more,
                      color:
                          isSelected ? AppTheme.primary : AppTheme.textPrimary),
                ),
                const SizedBox(width: 12),
              ]),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            opacity: _disposalMenuExpanded ? 1 : 0,
            child: Column(children: [
              if (_disposalMenuExpanded) ...[
                _buildDisposalSubItem(
                    'Input Pembuangan', DashboardSection.disposalInput),
                _buildDisposalSubItem('Statistik Pembuangan',
                    DashboardSection.disposalStatistics),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildDisposalSubItem(String label, DashboardSection section) {
    final selected = _selectedSection == section;
    return Padding(
      padding: const EdgeInsets.only(left: 30, top: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            setState(() => _selectedSection = section);
            if (section == DashboardSection.disposalInput) {
              _refreshDashboard();
            }
          },
          child: SizedBox(
              height: 42,
              child: Row(children: [
                Icon(
                    section == DashboardSection.disposalInput
                        ? Icons.add_box_outlined
                        : Icons.bar_chart_outlined,
                    size: 18,
                    color:
                        selected ? AppTheme.primary : AppTheme.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600))),
              ])),
        ),
      ),
    );
  }

  Widget _buildDocumentationSidebarGroup({required bool compact}) {
    const entries = <(String, DashboardSection, IconData)>[
      (
        'FORM UPDATE DATA CUSTOMER',
        DashboardSection.customerUpdateForms,
        Icons.people_alt_outlined
      ),
      (
        'TANDA TERIMA',
        DashboardSection.docsReceipt,
        Icons.receipt_long_outlined
      ),
      ('FILE', DashboardSection.docsFiles, Icons.folder_open_outlined),
      ('ABSENSI', DashboardSection.docsAbsence, Icons.fact_check_outlined),
      ('LEMBURAN', DashboardSection.docsOvertime, Icons.more_time_outlined),
      (
        'ADJUSTMENT STOK',
        DashboardSection.docsStockAdjustment,
        Icons.inventory_outlined
      ),
    ];
    final sections = entries.map((entry) => entry.$2).toSet();
    final isSelected = sections.contains(_selectedSection);

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: PopupMenuButton<DashboardSection>(
          tooltip: 'Dokumentasi',
          icon: Icon(Icons.folder_copy_outlined,
              color: isSelected ? AppTheme.primary : AppTheme.textPrimary),
          onSelected: (section) => setState(() => _selectedSection = section),
          itemBuilder: (_) => entries
              .map((entry) => PopupMenuItem<DashboardSection>(
                    value: entry.$2,
                    child: Text(entry.$1),
                  ))
              .toList(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
      child: Column(children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => setState(() {
              _documentationMenuExpanded = !_documentationMenuExpanded;
              if (!isSelected) _selectedSection = DashboardSection.docsReceipt;
            }),
            child: SizedBox(
              height: 54,
              child: Row(children: [
                const SizedBox(width: 18),
                Icon(Icons.folder_copy_outlined,
                    size: 21,
                    color:
                        isSelected ? AppTheme.primary : AppTheme.textPrimary),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Dokumentasi',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          )),
                ),
                AnimatedRotation(
                  turns: _documentationMenuExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeInOutCubic,
                  child: Icon(Icons.expand_more,
                      color:
                          isSelected ? AppTheme.primary : AppTheme.textPrimary),
                ),
                const SizedBox(width: 12),
              ]),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _documentationMenuExpanded ? 1 : 0,
            child: Column(
              children: _documentationMenuExpanded
                  ? entries
                      .map((entry) => _buildDocumentationSubItem(
                          entry.$1, entry.$2, entry.$3))
                      .toList()
                  : const [],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildDocumentationSubItem(
      String label, DashboardSection section, IconData icon) {
    final selected = _selectedSection == section;
    return Padding(
      padding: const EdgeInsets.only(left: 30, top: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => setState(() => _selectedSection = section),
          child: SizedBox(
            height: 42,
            child: Row(children: [
              Icon(icon,
                  size: 18,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                        )),
              ),
            ]),
          ),
        ),
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
    final color = danger ? const Color(0xFFE11D48) : AppTheme.textPrimary;
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 88,
          padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            border: const Border(
              bottom: BorderSide(color: Color(0xBFE5E7EB)),
            ),
          ),
          child: Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 300 : 492),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon:
                        const Icon(Icons.search, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.68),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: AppTheme.border),
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
                    foregroundColor: AppTheme.primary,
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
                    color: AppTheme.primary,
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
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary),
              ],
              const SizedBox(width: 22),
              const CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.tableHeader,
                child: Icon(Icons.person, color: AppTheme.primary),
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
                            color: AppTheme.textPrimary,
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
                foregroundColor: AppTheme.textSecondary,
                onTap: () async => await widget.onLogout(),
                tooltip: 'Logout',
              ),
            ],
          ),
        ),
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
    if (_selectedSection == DashboardSection.monitorDevices) {
      return Padding(
        padding: _contentPadding(context),
        child: MonitorDevicesScreen(apiService: widget.apiService),
      );
    }

    if (_selectedSection == DashboardSection.inventoryDeadlines) {
      return Padding(
        padding: _contentPadding(context),
        child: InventoryDeadlineScreen(apiService: widget.apiService),
      );
    }

    if (_selectedSection == DashboardSection.inventoryTransactions) {
      return Padding(
        padding: _contentPadding(context),
        child: InventoryTransactionScreen(apiService: widget.apiService),
      );
    }

    if (_selectedSection == DashboardSection.sozaiProductionMaster) {
      return Padding(
        padding: _contentPadding(context),
        child: SozaiProductionMasterScreen(apiService: widget.apiService),
      );
    }

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

    final isDocumentationSection = switch (_selectedSection) {
      DashboardSection.docsReceipt ||
      DashboardSection.docsFiles ||
      DashboardSection.docsAbsence ||
      DashboardSection.docsOvertime ||
      DashboardSection.docsStockAdjustment =>
        true,
      _ => false,
    };

    if (isDocumentationSection ||
        _selectedSection == DashboardSection.absenceCheck) {
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
          final absenceItems =
              List<dynamic>.from(data['absenceDocuments'] ?? []);
          final files = List<dynamic>.from(
            _receiptFilesOverride ?? data['files'] ?? [],
          );
          if (_selectedSection == DashboardSection.docsAbsence ||
              _selectedSection == DashboardSection.docsOvertime ||
              _selectedSection == DashboardSection.absenceCheck) {
            final isOvertime =
                _selectedSection == DashboardSection.docsOvertime;
            final items = absenceItems.where((raw) {
              final item = Map<String, dynamic>.from(raw as Map);
              final isOvertimeRecord =
                  item['documentType']?.toString() == 'lemburan';
              return isOvertime ? isOvertimeRecord : !isOvertimeRecord;
            }).toList();
            return Padding(
              padding: _contentPadding(context),
              child: _buildAbsenceCheckPanel(
                context,
                items,
                title:
                    isOvertime ? 'Dokumentasi Lemburan' : 'Dokumentasi Absensi',
                listTitle: isOvertime ? 'Data Lemburan' : 'Data Absensi',
                description: isOvertime
                    ? 'Dokumentasi surat lemburan.'
                    : 'Dokumentasi izin, sakit, cuti, dan pulang cepat.',
              ),
            );
          }

          final isReceipt = _selectedSection == DashboardSection.docsReceipt;
          final isStockAdjustment =
              _selectedSection == DashboardSection.docsStockAdjustment;
          final visibleFiles = files.where((raw) {
            if (!isReceipt && !isStockAdjustment) return true;
            final file = Map<String, dynamic>.from(raw as Map);
            final searchable = '${file['originalName'] ?? ''} '
                    '${file['storedName'] ?? ''} ${file['folder'] ?? ''}'
                .toLowerCase();
            if (isReceipt) {
              return searchable.contains('tanda terima') ||
                  searchable.contains('tanda_terima') ||
                  searchable.contains('receipt');
            }
            return searchable.contains('adjustment stok') ||
                searchable.contains('adjustment_stok') ||
                searchable.contains('adjustment') ||
                searchable.contains('stok');
          }).toList();
          final title = switch (_selectedSection) {
            DashboardSection.docsReceipt => 'Dokumentasi Tanda Terima',
            DashboardSection.docsStockAdjustment =>
              'Dokumentasi Adjustment Stok',
            _ => 'Dokumentasi File',
          };
          return Padding(
            padding: _contentPadding(context),
            child: ListView(
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 32,
                          color: AppTheme.textPrimary,
                        )),
                const SizedBox(height: 24),
                if (isReceipt) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _isUploadingReceiptAttachment ? null : _uploadReceiptAttachment,
                      icon: _isUploadingReceiptAttachment
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload_file),
                      label: const Text('Tambah Lampiran'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildFilePanel(
                  visibleFiles,
                  title: title,
                  emptyMessage: isReceipt
                      ? 'Belum ada file tanda terima.'
                      : isStockAdjustment
                          ? 'Belum ada file adjustment stok.'
                          : 'Belum ada file di repository.',
                ),
              ],
            ),
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

    if (_selectedSection == DashboardSection.customerUpdateForms) {
      return FutureBuilder<Map<String, dynamic>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items =
              List<dynamic>.from(snapshot.data?['formPhotoDocuments'] ?? []);
          return Padding(
            padding: _contentPadding(context),
            child: _buildCustomerUpdateFormPanel(context, items),
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

    final isDisposalInput = _selectedSection == DashboardSection.disposalInput;
    final isDisposalStatistics =
        _selectedSection == DashboardSection.disposalStatistics;
    if (!isDisposalInput && !isDisposalStatistics) {
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
                isDisposalInput ? 'Input Pembuangan' : 'Statistik Pembuangan',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 32,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 34),
              if (isDisposalInput)
                _buildDataPanel(context, displayDisposals, users, audits, files,
                    AppTheme.background),
              if (isDisposalStatistics) ...[
                LayoutBuilder(
                  builder: (context, constraints) => Column(
                    children: [
                      SizedBox(
                        height: constraints.maxWidth < 980 ? 460 : 540,
                        child: _buildAnalysisCard(displayDisposals),
                      ),
                      const SizedBox(height: 24),
                      _buildDisposalFilterCard(context, displayDisposals),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildDisposalTrendComparison(displayDisposals),
              ],
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
                        color: AppTheme.textPrimary,
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
                      Icons.inventory_2_outlined, AppTheme.primary,
                      width: width),
                  _homeStatCard('Total Akun', users.length.toString(),
                      Icons.group_outlined, AppTheme.accent,
                      width: width),
                  _homeStatCard(
                      'Total Absensi',
                      absenceDocuments.length.toString(),
                      Icons.fact_check_outlined,
                      AppTheme.primary,
                      width: width),
                  _homeStatCard('Total OCR', readData.length.toString(),
                      Icons.document_scanner_outlined, AppTheme.accent,
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
                      color: AppTheme.textSecondary,
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
                color: AppTheme.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.trending_up_rounded,
                    size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Updated today',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
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
    final mapped =
        audits.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    final mobile = mapped.where(_isMobileAuditLog).take(4).toList();
    final fallback = mapped
        .where((item) =>
            !mobile.any((mobileItem) => mobileItem['id'] == item['id']))
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
    final detailMap = details is Map
        ? Map<String, dynamic>.from(details)
        : <String, dynamic>{};
    final method =
        detailMap['method']?.toString() ?? item['method']?.toString() ?? '';
    final path =
        detailMap['accessedPath']?.toString() ?? item['path']?.toString() ?? '';
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
        color: AppTheme.tableHeader,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 18),
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
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 3),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary)),
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

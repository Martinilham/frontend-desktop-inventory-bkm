import 'dart:io';
import 'dart:math' as math;

import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:inventory_bkm_desktop/screens/accounts_screen.dart';
import 'package:inventory_bkm_desktop/screens/daily_worker_screen.dart';
import 'package:inventory_bkm_desktop/services/api_service.dart';
import 'package:inventory_bkm_desktop/widgets/desktop_action_dialog.dart';
import 'package:inventory_bkm_desktop/widgets/desktop_modal_shell.dart';
import 'package:inventory_bkm_desktop/widgets/landscape_image_frame.dart';
import 'package:inventory_bkm_desktop/widgets/primary_button.dart';
import 'package:inventory_bkm_desktop/widgets/section_card.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

part 'dashboard/dashboard_layout_builders.dart';
part 'dashboard/dashboard_disposal_builders.dart';
part 'dashboard/dashboard_disposal_list_builders.dart';
part 'dashboard/dashboard_disposal_dialogs.dart';
part 'dashboard/dashboard_disposal_exports.dart';
part 'dashboard/dashboard_disposal_panels.dart';
part 'dashboard/dashboard_read_data_builders.dart';
part 'dashboard/dashboard_audit_media_builders.dart';
part 'dashboard/dashboard_grabmerch_builders.dart';
part 'dashboard/dashboard_absence_builders.dart';

enum DashboardSection {
  home,
  disposalData,
  analysis,
  grabMerch,
  dailyWorker,
  readData,
  absenceCheck,
  auditLogs,
  accounts
}

enum DisposalSortOption {
  newestDate,
  oldestDate,
  journalNumberAsc,
  journalNumberDesc,
}

enum TrendFilterMode {
  monthly,
  daily,
}

const List<Map<String, String>> _disposalDivisions = [
  {'value': 'grocery', 'apiValue': 'GROCERY', 'label': 'Grocery'},
  {'value': 'sozai', 'apiValue': 'SOZAI', 'label': 'Sozai'},
  {
    'value': 'sozai_sisa_produksi',
    'apiValue': 'SOZAI (SISA PRODUKSI)',
    'label': 'Sozai (Sisa Produksi)'
  },
  {'value': 'fish', 'apiValue': 'FISH', 'label': 'Fish'},
  {'value': 'f&v', 'apiValue': 'F&V', 'label': 'F&V'},
  {'value': 'meat', 'apiValue': 'MEAT', 'label': 'Meat'},
];

class DashboardScreen extends StatefulWidget {
  final ApiService apiService;
  final Future<void> Function() onLogout;

  const DashboardScreen(
      {super.key, required this.apiService, required this.onLogout});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardSection _selectedSection = DashboardSection.home;
  late Future<Map<String, dynamic>> _dashboardFuture;
  late Future<Map<String, dynamic>> _analysisFuture;
  String _selectedDivision = 'grocery';
  DateTime _selectedDate = DateTime.now();
  List<String> _photoPaths = [];
  String? _scannedPdfPath;
  bool _isUploading = false;
  final TextEditingController _journalController = TextEditingController();
  final TextEditingController _absenceNameController = TextEditingController();
  String _selectedAbsenceType = 'izin';
  String? _absenceProofPath;
  bool _isUploadingAbsence = false;

  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  DateTime _analysisTrendDate = DateTime.now();
  int _analysisTrendYear = DateTime.now().year;
  TrendFilterMode _analysisTrendMode = TrendFilterMode.monthly;
  int _analysisPage = 0;
  int _analysisRowsPerPage = 15;
  String _analysisGroupFilter = 'all';
  String _disposalFilterDivision = 'all';
  DisposalSortOption _disposalSortOption = DisposalSortOption.newestDate;
  bool _isExportingPdf = false;
  final Map<String, int> _photoQuarterTurns = {};
  final Set<String> _dirtyPhotoRotations = {};
  final ValueNotifier<int> _photoRotationVersion = ValueNotifier<int>(0);
  final TextEditingController _disposalSearchController =
      TextEditingController();

  static const List<Map<String, String>> _absenceDocumentTypes = [
    {'value': 'izin', 'label': 'Surat Izin'},
    {'value': 'sakit', 'label': 'Surat Sakit'},
    {'value': 'cuti', 'label': 'Surat Cuti'},
    {'value': 'lemburan', 'label': 'Surat Lemburan'},
    {'value': 'pulang_cepat', 'label': 'Surat Pulang Cepat'},
  ];

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboardData();
    _analysisFuture = widget.apiService.getDailyProductAnalysis();
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    try {
      final me = await widget.apiService.getMe();
      final users = await widget.apiService.listUsers();
      final audit = await widget.apiService.listAudit();
      final disposals = await widget.apiService.listDisposals();
      final files = await widget.apiService.listFiles();

      return {
        'me': me['user'],
        'users': users,
        'audit': audit,
        'disposals': disposals,
        'grabmerch': await widget.apiService.listGrabMerch(),
        'absenceDocuments': await widget.apiService.listAbsenceDocuments(),
        'readData': await widget.apiService.listReadData(),
        'files': files,
      };
    } on AuthException catch (_) {
      await widget.onLogout();
      throw Exception('Sesi telah berakhir. Silakan login kembali.');
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _dashboardFuture = _loadDashboardData();
      _analysisFuture = widget.apiService.getDailyProductAnalysis();
    });
  }

  String _readDataName(Map<String, dynamic> item) {
    final name = item['name']?.toString().trim() ?? '';
    return name.isEmpty ? '-' : name.toUpperCase();
  }

  Future<void> _showActionPopup({
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

  Future<void> _pickPhotos() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _photoPaths = result.paths.whereType<String>().toList();
      });
    }
  }

  Future<void> _pickScannedPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        _scannedPdfPath = result.paths.first;
      });
    }
  }

  Future<void> _pickAbsenceProof() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        _absenceProofPath = result.paths.first;
      });
    }
  }

  Future<void> _exportSingleReadDataToExcel(Map<String, dynamic> item) async {
    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) return;

    final excel = xls.Excel.createExcel();
    final sheet = excel['Ringkasan'];
    excel.setDefaultSheet('Ringkasan');
    sheet.appendRow([
      xls.TextCellValue('No'),
      xls.TextCellValue('Nama'),
      xls.TextCellValue('Foto'),
      xls.TextCellValue('Hasil OCR'),
      xls.TextCellValue('Tanggal Input'),
    ]);

    final createdAt = DateTime.tryParse(item['createdAt']?.toString() ?? '') ??
        DateTime.now();
    sheet.appendRow([
      xls.IntCellValue(1),
      xls.TextCellValue(_readDataName(item)),
      xls.TextCellValue(
          item['imageUrl']?.toString() ?? item['photoPath']?.toString() ?? '-'),
      xls.TextCellValue(item['recognizedText']?.toString() ?? ''),
      xls.TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(createdAt)),
    ]);
    _buildReadDataLayoutSheet(excel, item);

    final bytes = excel.encode();
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat file Excel.')));
      return;
    }

    final safeName =
        _readDataName(item).replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final fileName =
        '${safeName}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('$directoryPath${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Excel disimpan: $fileName')));
  }

  void _buildReadDataLayoutSheet(xls.Excel excel, Map<String, dynamic> item) {
    final layoutSheet = excel['Layout OCR'];
    final rawSheet = excel['Raw OCR'];
    final lines = List<dynamic>.from(item['ocrLines'] ?? []);
    rawSheet.appendRow(
        [xls.TextCellValue(item['recognizedText']?.toString() ?? '')]);

    layoutSheet.appendRow([
      xls.TextCellValue('Nama'),
      xls.TextCellValue(_readDataName(item)),
    ]);
    layoutSheet.appendRow([
      xls.TextCellValue('Foto'),
      xls.TextCellValue(item['imageUrl']?.toString() ?? '-'),
    ]);
    layoutSheet.appendRow([]);

    if (lines.isEmpty) {
      layoutSheet.appendRow([
        xls.TextCellValue(
            'Data lama belum memiliki posisi OCR. Scan ulang dari mobile agar layout mengikuti gambar.'),
      ]);
      return;
    }

    final normalized = lines
        .map((line) => {
              'text': line['text']?.toString() ?? '',
              'left': (line['left'] as num?)?.toDouble() ?? 0,
              'top': (line['top'] as num?)?.toDouble() ?? 0,
              'right': (line['right'] as num?)?.toDouble() ?? 0,
              'bottom': (line['bottom'] as num?)?.toDouble() ?? 0,
            })
        .where((line) => (line['text'] as String).trim().isNotEmpty)
        .toList()
      ..sort((a, b) {
        final topCompare = (a['top'] as double).compareTo(b['top'] as double);
        if (topCompare != 0) return topCompare;
        return (a['left'] as double).compareTo(b['left'] as double);
      });

    final minLeft = normalized
        .map((line) => line['left'] as double)
        .reduce((a, b) => a < b ? a : b);
    final maxRight = normalized
        .map((line) => line['right'] as double)
        .reduce((a, b) => a > b ? a : b);
    final width = (maxRight - minLeft).clamp(1, double.infinity);
    const rowThreshold = 14.0;
    const columnCount = 18;
    final rows = <List<Map<String, Object>>>[];

    for (final line in normalized) {
      final top = line['top'] as double;
      var rowIndex = rows.indexWhere(
          (row) => ((row.first['top'] as double) - top).abs() <= rowThreshold);
      if (rowIndex == -1) {
        rows.add([line]);
      } else {
        rows[rowIndex].add(line);
      }
    }

    var outputRow = 4;
    final occupiedCells = <String, String>{};
    for (final row in rows) {
      row.sort((a, b) => (a['left'] as double).compareTo(b['left'] as double));
      for (final line in row) {
        final left = line['left'] as double;
        final relative = ((left - minLeft) / width).clamp(0, 1);
        final columnIndex = (relative * (columnCount - 1)).round();
        final key = '$outputRow-$columnIndex';
        final text = line['text']?.toString() ?? '';
        occupiedCells[key] =
            occupiedCells[key] == null ? text : '${occupiedCells[key]}  $text';
      }
      outputRow++;
    }

    for (final entry in occupiedCells.entries) {
      final parts = entry.key.split('-');
      final rowIndex = int.parse(parts[0]);
      final columnIndex = int.parse(parts[1]);
      layoutSheet
          .cell(xls.CellIndex.indexByColumnRow(
              columnIndex: columnIndex, rowIndex: rowIndex))
          .value = xls.TextCellValue(entry.value);
    }
  }

  Future<void> _submitAbsenceUpload() async {
    final employeeName = _absenceNameController.text.trim();
    if (employeeName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nama wajib diisi')));
      return;
    }
    if (_absenceProofPath == null || _absenceProofPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto bukti wajib dipilih')));
      return;
    }

    setState(() => _isUploadingAbsence = true);

    try {
      await widget.apiService.uploadAbsenceDocument(
        employeeName: employeeName,
        documentType: _selectedAbsenceType,
        proofPhotoPath: _absenceProofPath!,
      );

      if (!mounted) return;
      await _showActionPopup(
          title: 'Berhasil', message: 'Dokumentasi absensi berhasil diunggah');
      if (!mounted) return;
      setState(() {
        _absenceNameController.clear();
        _selectedAbsenceType = 'izin';
        _absenceProofPath = null;
      });
      await _refreshDashboard();
    } catch (error) {
      if (!mounted) return;
      if (error is AuthException) {
        await widget.onLogout();
        return;
      }
      await _showActionPopup(
          title: 'Upload Gagal', message: error.toString(), success: false);
    } finally {
      if (mounted) setState(() => _isUploadingAbsence = false);
    }
  }

  @override
  void dispose() {
    _journalController.dispose();
    _absenceNameController.dispose();
    _disposalSearchController.dispose();
    _photoRotationVersion.dispose();
    super.dispose();
  }

  Future<void> _submitUpload() async {
    setState(() => _isUploading = true);

    try {
      final division = _disposalDivisions.firstWhere(
        (item) => item['value'] == _selectedDivision,
        orElse: () => _disposalDivisions.first,
      );
      await widget.apiService.uploadDisposal(
        division: division['apiValue']!,
        date: _selectedDate,
        photoPaths: _photoPaths,
        scannedPdfPath: _scannedPdfPath,
        journal: _journalController.text,
      );

      if (!mounted) return;
      await _showActionPopup(
          title: 'Berhasil',
          message: 'Upload disposal berhasil dikirim ke backend');
      if (!mounted) return;
      setState(() {
        _photoPaths = [];
        _scannedPdfPath = null;
        _journalController.clear();
      });
      await _refreshDashboard();
    } catch (error) {
      if (!mounted) return;
      if (error is AuthException) {
        await widget.onLogout();
        return;
      }
      await _showActionPopup(
          title: 'Upload Gagal', message: error.toString(), success: false);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBF7),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compactSidebar = constraints.maxWidth < 1100;
          return Row(
            children: [
              _buildSidebar(compact: compactSidebar),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(context, compact: constraints.maxWidth < 900),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: const Color(0xFFFAFBF7),
                        child: _buildMainContent(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

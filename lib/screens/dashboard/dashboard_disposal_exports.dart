// ignore_for_file: invalid_use_of_protected_member, library_private_types_in_public_api, unused_element
part of '../dashboard_screen.dart';

extension DashboardDisposalExports on _DashboardScreenState {
  static const double _pdfScanImageWidth = 500;
  static const double _pdfScanImageHeight = 600;
  static const double _pdfPhotoWidth = 220;
  static const double _pdfPhotoHeight = 160;
  static const double _pdfPhotoPadding = 0;

  Future<void> _exportAnalysisToExcel(
    List<Map<String, dynamic>> items,
    String dateFrom,
    String dateTo, {
    String filePrefix = 'analisa_selisih',
  }) async {
    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) return;

    final excel = xls.Excel.createExcel();
    final sheet = excel['Analisa Selisih'];
    excel.setDefaultSheet('Analisa Selisih');
    sheet.appendRow([
      xls.TextCellValue('Tanggal'),
      xls.TextCellValue('Kategori'),
      xls.TextCellValue('Item Number'),
      xls.TextCellValue('Nama Barang'),
      xls.TextCellValue('Unit'),
      xls.TextCellValue('PO/BO/TO IN'),
      xls.TextCellValue('Sales'),
      xls.TextCellValue('Selisih'),
      xls.TextCellValue('Note'),
    ]);

    for (final item in items) {
      sheet.appendRow([
        xls.TextCellValue(item['date']?.toString() ?? '-'),
        xls.TextCellValue(item['group']?.toString() ?? '-'),
        xls.TextCellValue(item['itemNumber']?.toString() ?? '-'),
        xls.TextCellValue(item['itemName']?.toString() ?? '-'),
        xls.TextCellValue(item['unit']?.toString() ?? '-'),
        xls.DoubleCellValue((item['poBoToIn'] as num?)?.toDouble() ?? 0),
        xls.DoubleCellValue((item['sales'] as num?)?.toDouble() ?? 0),
        xls.DoubleCellValue((item['difference'] as num?)?.toDouble() ?? 0),
        xls.TextCellValue(item['note']?.toString() ?? '-'),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) return;
    final fileName =
        '${filePrefix}_${dateFrom}_sd_${dateTo}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('$directoryPath${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Excel disimpan: $fileName')));
  }

  Future<void> _exportAnalysisToPdf(
    List<Map<String, dynamic>> items,
    String dateFrom,
    String dateTo, {
    String title = 'Analisa Selisih Produk Harian',
    String filePrefix = 'analisa_selisih',
  }) async {
    final pdf = pw.Document();
    final rows = items
        .map((item) => [
              item['date']?.toString() ?? '-',
              item['group']?.toString() ?? '-',
              item['itemNumber']?.toString() ?? '-',
              item['itemName']?.toString() ?? '-',
              ((item['poBoToIn'] as num?)?.toDouble() ?? 0)
                  .toStringAsFixed(2),
              ((item['sales'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
              ((item['difference'] as num?)?.toDouble() ?? 0)
                  .toStringAsFixed(2),
              item['note']?.toString() ?? '-',
            ])
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(title,
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('$dateFrom sampai $dateTo',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 14),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Tanggal',
              'Kategori',
              'Item Number',
              'Nama Barang',
              'PO/BO/TO IN',
              'Sales',
              'Selisih',
              'Note'
            ],
            data: rows,
            headerStyle:
                pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    final fileName =
        '${filePrefix}_${dateFrom}_sd_${dateTo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await _savePdfFile(fileName, await pdf.save());
  }

  Future<void> _exportAnalysisProductsToExcel(
    List<Map<String, dynamic>> products,
    String dateFrom,
    String dateTo, {
    required String group,
    required String filePrefix,
  }) async {
    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) return;

    final excel = xls.Excel.createExcel();
    final sheet = excel['Ringkasan $group'];
    excel.setDefaultSheet('Ringkasan $group');
    sheet.appendRow([
      xls.TextCellValue('Item Number'),
      xls.TextCellValue('Nama Produk'),
      xls.TextCellValue('Unit'),
      xls.TextCellValue('Total Selisih'),
      xls.TextCellValue('Tanggal'),
      xls.TextCellValue('PO/BO/TO IN'),
      xls.TextCellValue('Sales'),
      xls.TextCellValue('Selisih'),
      xls.TextCellValue('Note'),
    ]);

    for (final product in products) {
      final dates = List<Map<String, dynamic>>.from(product['dates'] ?? [])
        ..sort((a, b) => (a['date']?.toString() ?? '')
            .compareTo(b['date']?.toString() ?? ''));
      for (var index = 0; index < dates.length; index++) {
        final item = dates[index];
        sheet.appendRow([
          xls.TextCellValue(index == 0
              ? product['itemNumber']?.toString() ?? '-'
              : ''),
          xls.TextCellValue(
              index == 0 ? product['itemName']?.toString() ?? '-' : ''),
          xls.TextCellValue(index == 0 ? product['unit']?.toString() ?? '-' : ''),
          index == 0
              ? xls.DoubleCellValue(
                  (product['totalDifference'] as num?)?.toDouble() ?? 0)
              : xls.TextCellValue(''),
          xls.TextCellValue(item['date']?.toString() ?? '-'),
          xls.DoubleCellValue((item['poBoToIn'] as num?)?.toDouble() ?? 0),
          xls.DoubleCellValue((item['sales'] as num?)?.toDouble() ?? 0),
          xls.DoubleCellValue((item['difference'] as num?)?.toDouble() ?? 0),
          xls.TextCellValue(item['note']?.toString() ?? '-'),
        ]);
      }
      sheet.appendRow([]);
    }

    final bytes = excel.encode();
    if (bytes == null) return;
    final fileName =
        '${filePrefix}_${dateFrom}_sd_${dateTo}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('$directoryPath${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Excel disimpan: $fileName')));
  }

  Future<void> _exportAnalysisProductsToPdf(
    List<Map<String, dynamic>> products,
    String dateFrom,
    String dateTo, {
    required String group,
    required String filePrefix,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text('Ringkasan Selisih Kategori $group',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('$dateFrom sampai $dateTo',
              style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 14),
          for (final product in products) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: const PdfColor(0.95, 0.97, 0.99),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${product['itemNumber'] ?? '-'} - ${product['itemName'] ?? '-'}',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Unit ${product['unit'] ?? '-'} | Total selisih ${((product['totalDifference'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Tanggal',
                'PO/BO/TO IN',
                'Sales',
                'Selisih',
                'Note'
              ],
              data: (List<Map<String, dynamic>>.from(product['dates'] ?? [])
                    ..sort((a, b) => (a['date']?.toString() ?? '')
                        .compareTo(b['date']?.toString() ?? '')))
                  .map((item) => [
                        item['date']?.toString() ?? '-',
                        ((item['poBoToIn'] as num?)?.toDouble() ?? 0)
                            .toStringAsFixed(2),
                        ((item['sales'] as num?)?.toDouble() ?? 0)
                            .toStringAsFixed(2),
                        ((item['difference'] as num?)?.toDouble() ?? 0)
                            .toStringAsFixed(2),
                        item['note']?.toString() ?? '-',
                      ])
                  .toList(),
              headerStyle:
                  pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );

    final fileName =
        '${filePrefix}_${dateFrom}_sd_${dateTo}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await _savePdfFile(fileName, await pdf.save());
  }

  Future<void> _exportFilteredDisposalsToPdf(List<dynamic> disposals) async {
    setState(() => _isExportingPdf = true);
    try {
      final pdf = await _buildPdfDocument(
          disposals.cast<Map<String, dynamic>>().toList());
      final bytes = await pdf.save();
      final fileName =
          'disposal_filtered_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await _savePdfFile(fileName, bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF berhasil disimpan: $fileName')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e')));
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _exportSingleDisposalToPdf(Map<String, dynamic> disposal) async {
    try {
      final pdf = await _buildPdfDocument([disposal]);
      final bytes = await pdf.save();
      final fileName =
          'disposal_${disposal['division'] ?? 'data'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await _savePdfFile(fileName, bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF berhasil disimpan: $fileName')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e')));
    }
  }

  Future<pw.Document> _buildPdfDocument(
      List<Map<String, dynamic>> disposals) async {
    final pdf = pw.Document();
    final papayaLogo = await _loadPdfAssetImage('assets/logos/logo_papaya.png');

    for (var index = 0; index < disposals.length; index++) {
      final disposal = disposals[index];
      final content = await _buildPdfDisposalContent(disposal, index + 1);

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 42),
        footer: (context) => _buildPdfFooter(papayaLogo),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Laporan Data Pembuangan',
                      style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor(0.10, 0.18, 0.30))),
                  pw.SizedBox(height: 4),
                  pw.Text('Data pembuangan dengan dokumentasi lengkap',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColor(0.35, 0.39, 0.45))),
                ],
              ),
              pw.Text('Data ${index + 1} dari ${disposals.length}',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor(0.12, 0.30, 0.55))),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(height: 2, color: const PdfColor(0.10, 0.18, 0.30)),
          pw.SizedBox(height: 14),
          ...content,
        ],
      ));
    }
    return pdf;
  }

  pw.Widget _buildPdfFooter(pw.MemoryImage? papayaLogo) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          if (papayaLogo != null)
            pw.Image(papayaLogo, width: 44, fit: pw.BoxFit.contain)
          else
            pw.Text('papaya',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor(0.40, 0.62, 0.28))),
          pw.SizedBox(height: 2),
          pw.Text(
            'COPYRIGHT ${DateTime.now().year} EDP MELAWAI-PAPAYA FRESH GALLERY',
            style: const pw.TextStyle(
                fontSize: 7, color: PdfColor(0.25, 0.36, 0.28)),
          ),
        ],
      ),
    );
  }

  Future<List<pw.Widget>> _buildPdfDisposalContent(
      Map<String, dynamic> disposal, int number) async {
    final summaryCard = await _buildPdfDisposalCard(disposal, number);
    final scannedPdf = disposal['scannedPdf']?.toString() ?? '';
    final scannedPages = await _loadScannedPdfPageImages(scannedPdf);

    return [
      summaryCard,
      if (scannedPdf.trim().isNotEmpty) ...[
        if (scannedPages.isNotEmpty) pw.NewPage(),
        _pdfSectionTitle('Preview Scan PDF'),
        pw.SizedBox(height: 8),
        if (scannedPages.isEmpty)
          pw.Text('PDF scan tidak dapat dirender ke laporan.',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColor(0.45, 0.49, 0.55)))
        else
          for (var pageIndex = 0; pageIndex < scannedPages.length; pageIndex++)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: const PdfColor(0.86, 0.88, 0.9)),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Halaman Scan ${pageIndex + 1}',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor(0.35, 0.39, 0.45))),
                  pw.SizedBox(height: 6),
                  pw.Center(
                    child: pw.SizedBox(
                      width: _pdfScanImageWidth,
                      height: _pdfScanImageHeight,
                      child: pw.Image(
                        scannedPages[pageIndex],
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
      pw.SizedBox(height: 8),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
            'Dicetak ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColor(0.45, 0.49, 0.55))),
      ),
    ];
  }

  Future<pw.MemoryImage?> _loadPdfAssetImage(String assetPath) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<pw.Widget> _buildPdfDisposalCard(
      Map<String, dynamic> disposal, int number) async {
    final photos = List<String>.from(disposal['photos'] ?? []);
    final photoWidgets = <pw.Widget>[];

    for (final photo in photos.take(4)) {
      final image = await _loadPdfImage(photo);
      if (image == null) continue;
      final turns = _photoQuarterTurns[photo] ?? _storedPhotoRotation(disposal, photo);
      photoWidgets.add(
        pw.Container(
          width: _pdfPhotoWidth,
          height: _pdfPhotoHeight,
          padding: const pw.EdgeInsets.all(_pdfPhotoPadding),
          decoration: pw.BoxDecoration(
            color: const PdfColor(0.98, 0.98, 0.98),
            border: pw.Border.all(color: const PdfColor(0.86, 0.88, 0.90)),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 4,
            verticalRadius: 4,
            child: _rotatedPdfImage(
              image,
              turns,
              width: _pdfPhotoWidth - (_pdfPhotoPadding * 2),
              height: _pdfPhotoHeight - (_pdfPhotoPadding * 2),
            ),
          ),
        ),
      );
    }
    final hiddenPhotoCount = photos.length - photoWidgets.length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: const PdfColor(1, 1, 1),
        border: pw.Border.all(color: const PdfColor(0.84, 0.87, 0.91)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Data Pembuangan #$number',
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor(0.10, 0.18, 0.30))),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: const PdfColor(0.91, 0.95, 1.00),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(20)),
                ),
                child: pw.Text(disposal['division']?.toString() ?? '-',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor(0.12, 0.30, 0.55))),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: const PdfColor(0.97, 0.98, 0.99),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                _pdfTextRow('Tanggal', disposal['date']?.toString() ?? '-'),
                _pdfTextRow(
                    'Jurnal',
                    (disposal['journal']?.toString() ?? '').trim().isEmpty
                        ? '-'
                        : disposal['journal'].toString()),
                _pdfTextRow(
                    'Uploaded By', disposal['uploadedBy']?.toString() ?? '-'),
                _pdfTextRow(
                    'Created At', disposal['createdAt']?.toString() ?? '-'),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          _pdfSectionTitle('Foto Dokumentasi'),
          pw.SizedBox(height: 8),
          if (photoWidgets.isEmpty)
            pw.Text('Tidak ada foto yang dapat dimuat.',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColor(0.45, 0.49, 0.55)))
          else
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Wrap(spacing: 8, runSpacing: 8, children: photoWidgets),
                if (hiddenPhotoCount > 0) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                      '+$hiddenPhotoCount foto lainnya tersimpan di data pembuangan.',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColor(0.45, 0.49, 0.55))),
                ],
              ],
            ),
        ],
      ),
    );
  }

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Text(title,
        style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
            color: const PdfColor(0.10, 0.18, 0.30)));
  }

  pw.Widget _pdfTextRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 88,
            child: pw.Text('$label:',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    color: const PdfColor(0.20, 0.24, 0.30))),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColor(0.20, 0.24, 0.30))),
          ),
        ],
      ),
    );
  }

  Future<List<pw.MemoryImage>> _loadScannedPdfPageImages(
      String relativePath) async {
    if (relativePath.trim().isEmpty) return [];
    try {
      final bytes = await _loadNetworkFile(_storageUrl(relativePath));
      final pages = <pw.MemoryImage>[];
      await for (final page in Printing.raster(bytes, dpi: 110)) {
        pages.add(pw.MemoryImage(await page.toPng()));
      }
      return pages;
    } catch (_) {
      return [];
    }
  }

  Future<pw.MemoryImage?> _loadPdfImage(String relativePath) async {
    try {
      final response = await http.get(Uri.parse(_storageUrl(relativePath)));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }
      return pw.MemoryImage(response.bodyBytes);
    } catch (_) {
      return null;
    }
  }

  pw.Widget _rotatedPdfImage(
    pw.MemoryImage image,
    int quarterTurns, {
    required double width,
    required double height,
  }) {
    final normalizedTurns = quarterTurns % 4;
    final picture = pw.SizedBox(
      width: normalizedTurns.isOdd ? height : width,
      height: normalizedTurns.isOdd ? width : height,
            child: pw.Image(image, fit: pw.BoxFit.contain),
    );
    if (normalizedTurns == 0) return picture;
    return pw.Center(
      child: pw.Transform.rotate(
        angle: normalizedTurns * math.pi / 2,
        child: picture,
      ),
    );
  }

  Future<String?> _chooseExportDirectory() async {
    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Penyimpanan dibatalkan.')));
      return null;
    }
    return directoryPath;
  }

  Future<void> _savePdfFile(String fileName, Uint8List bytes) async {
    final directoryPath = await _chooseExportDirectory();
    if (directoryPath == null) return;
    final file = File('$directoryPath/$fileName');
    await file.writeAsBytes(bytes);
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF disimpan di: $directoryPath')));
  }

  Future<void> _confirmDeleteDisposal(Map<String, dynamic> disposal) async {
    final id = disposal['id']?.toString() ?? disposal['_id']?.toString();
    if (id == null || id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data disposal tidak memiliki ID.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF17212B).withOpacity(0.46),
      builder: (context) => DesktopModalShell(
        title: 'Hapus Disposal',
        subtitle: 'Data yang sudah dihapus tidak bisa dikembalikan.',
        icon: Icons.delete_outline,
        maxWidth: 430,
        child: const Text(
          'Apakah Anda yakin ingin menghapus data pembuangan ini?',
          style: TextStyle(color: Color(0xFF68777A), height: 1.35),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5484D),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus')),
        ],
      ),
    );

    if (confirmed != true) return;
    await _deleteDisposal(id);
  }

  Future<void> _deleteDisposal(String id) async {
    try {
      await widget.apiService.deleteDisposal(id);
      if (!mounted) return;
      Navigator.of(context).pop();
      await _showActionPopup(
          title: 'Berhasil', message: 'Data disposal berhasil dihapus.');
      if (!mounted) return;
      await _refreshDashboard();
    } catch (e) {
      if (!mounted) return;
      await _showActionPopup(
          title: 'Hapus Gagal',
          message: 'Gagal menghapus data: $e',
          success: false);
    }
  }

  Future<void> _printDisposal(Map<String, dynamic> disposal) async {
    try {
      final pdf = await _buildPdfDocument([disposal]);
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'disposal_print_${disposal['division'] ?? 'data'}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka dialog printer: $e')));
    }
  }
}

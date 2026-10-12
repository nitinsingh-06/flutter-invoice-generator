import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/invoice_model.dart';
import '../../services/hive_service.dart';
import '../../services/pdf_service.dart';

/// Displays the generated invoice PDF with Print, Share, and Download
/// actions — the final step of the "Generate Invoice" flow, and also
/// reachable from Invoice History via "Print Again" / "Share Again".
class PdfPreviewScreen extends StatefulWidget {
  const PdfPreviewScreen({super.key, required this.invoice});

  final InvoiceModel invoice;

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _buildPdf();
  }

  /// Reads the company profile, then delegates PDF generation to
  /// [PdfService]. This screen owns loading/error UI state only — all
  /// actual PDF construction logic lives in the service, not here.
  Future<void> _buildPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final company = HiveService.getCompanyProfile();

    if (company == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Company profile not found. Please complete Company Settings first.';
      });
      return;
    }

    try {
      final bytes = await PdfService.generateInvoicePdf(
        invoice: widget.invoice,
        company: company,
      );
      if (!mounted) return;
      setState(() {
        _pdfBytes = bytes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to generate PDF: $e';
      });
    }
  }

  String get _fileName => 'Invoice_${widget.invoice.invoiceNumber}.pdf';

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    await Printing.layoutPdf(onLayout: (_) async => _pdfBytes!);
  }

  /// Shares the PDF via the OS share sheet. `share_plus` requires a real
  /// file path (not raw bytes) to attach a document, so we first write the
  /// bytes to a temporary file.
  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$_fileName');
    await file.writeAsBytes(_pdfBytes!);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Invoice ${widget.invoice.invoiceNumber}',
    );
  }

  /// Saves a permanent copy of the PDF to the app's documents directory
  /// (fulfilling "Save PDF" / "Download button" from the brief). Since the
  /// app is fully offline, this is a local save rather than a network
  /// download.
  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_fileName');
    await file.writeAsBytes(_pdfBytes!);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to ${file.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${widget.invoice.invoiceNumber}'),
      ),
      body: _buildBody(),
      bottomNavigationBar: _pdfBytes == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _printPdf,
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Print'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _sharePdf,
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _downloadPdf,
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }
    return PdfPreview(
      build: (_) async => _pdfBytes!,
      allowPrinting: false, // We provide our own explicit Print button below.
      allowSharing: false, // Likewise, our own explicit Share button.
      canChangeOrientation: false,
      canChangePageFormat: false,
    );
  }
}

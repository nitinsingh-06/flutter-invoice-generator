import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/company_model.dart';
import '../models/invoice_model.dart';
import '../utils/currency_formatter.dart';

/// Generates a professional, A4-sized invoice PDF matching the layout of
/// the reference invoice template:
///   Header (logo + company name + GST/contact) → "INVOICE" title →
///   Customer details → Item table → Totals block → Signature/Bank
///   details → Footer (logo + company name + branch address + GST/contact)
///
/// Kept entirely separate from any screen — this service takes plain data
/// in and returns PDF bytes out, so it can be tested independently of the
/// UI and reused by both the preview screen and any future "quick share"
/// action elsewhere in the app.
class PdfService {
  PdfService._();

  /// Builds the complete invoice PDF document and returns it as bytes,
  /// ready to be previewed, printed, shared, or saved to disk.
  static Future<Uint8List> generateInvoicePdf({
    required InvoiceModel invoice,
    required CompanyModel company,
  }) async {
    final doc = pw.Document();

    // Images are loaded once up front (not inside the page builder) since
    // reading from disk is async and page builders in the `pdf` package
    // must be synchronous.
    pw.MemoryImage? logoImage;
    pw.MemoryImage? signatureImage;

    if (company.logoPath != null && company.logoPath!.isNotEmpty) {
      final file = File(company.logoPath!);
      if (await file.exists()) {
        logoImage = pw.MemoryImage(await file.readAsBytes());
      }
    }
    if (company.signaturePath != null && company.signaturePath!.isNotEmpty) {
      final file = File(company.signaturePath!);
      if (await file.exists()) {
        signatureImage = pw.MemoryImage(await file.readAsBytes());
      }
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(company, logoImage),
              pw.SizedBox(height: 10),
              _buildInvoiceTitle(),
              pw.SizedBox(height: 10),
              _buildCustomerAndInvoiceInfo(invoice),
              pw.SizedBox(height: 12),
              _buildItemTable(invoice),
              pw.SizedBox(height: 4),
              _buildTotalsBlock(invoice),
              pw.SizedBox(height: 24),
              _buildSignatureAndBankSection(company, signatureImage),
              pw.Spacer(),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              _buildFooter(company, logoImage),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // -----------------------------------------------------------------------
  // Header: logo (left) + company name/GST/contact (right)
  // -----------------------------------------------------------------------
  static pw.Widget _buildHeader(CompanyModel company, pw.MemoryImage? logo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logo != null)
          pw.Container(
            width: 56,
            height: 56,
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          )
        else
          pw.Container(width: 56, height: 56),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                company.companyName.isNotEmpty ? company.companyName : 'Your Company Name',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('GST NO: ${company.gstNumber}', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('CONTACT NO: ${company.phone}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceTitle() {
    return pw.Container(
      width: double.infinity,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(width: 1, color: PdfColors.black),
          bottom: pw.BorderSide(width: 1, color: PdfColors.black),
        ),
      ),
      child: pw.Text(
        'INVOICE',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, letterSpacing: 2),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Customer name/address/date/invoice number block
  // -----------------------------------------------------------------------
  static pw.Widget _buildCustomerAndInvoiceInfo(InvoiceModel invoice) {
    final dateStr = DateFormat('dd/MM/yyyy').format(invoice.invoiceDate);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _labelValueRow('CUSTOMER NAME:', invoice.customer.name),
          if (invoice.customer.address.isNotEmpty)
            _labelValueRow('ADDRESS:', invoice.customer.address),
          _labelValueRow('DATE:', dateStr),
          _labelValueRow('INVOICE NO:', invoice.invoiceNumber),
        ],
      ),
    );
  }

  static pw.Widget _labelValueRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 9))),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Item table: S.N | ITEM NAME | HSN CODE | QTY | UNIT PRICE | TOTAL
  // -----------------------------------------------------------------------
  static pw.Widget _buildItemTable(InvoiceModel invoice) {
    final headerStyle = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
    const cellStyle = pw.TextStyle(fontSize: 9);
    final borderColor = PdfColors.grey400;

    pw.Widget cell(String text, {pw.TextStyle? style, pw.Alignment align = pw.Alignment.centerLeft}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        alignment: align,
        child: pw.Text(text, style: style ?? cellStyle),
      );
    }

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          cell('S.N', style: headerStyle, align: pw.Alignment.center),
          cell('ITEM NAME', style: headerStyle),
          cell('HSN CODE', style: headerStyle, align: pw.Alignment.center),
          cell('QTY', style: headerStyle, align: pw.Alignment.center),
          cell('UNIT PRICE', style: headerStyle, align: pw.Alignment.centerRight),
          cell('TOTAL', style: headerStyle, align: pw.Alignment.centerRight),
        ],
      ),
    ];

    for (var i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      rows.add(
        pw.TableRow(
          children: [
            cell('${i + 1}', align: pw.Alignment.center),
            cell(item.itemName),
            cell(item.hsnCode, align: pw.Alignment.center),
            cell(_trimZero(item.quantity), align: pw.Alignment.center),
            cell(CurrencyFormatter.formatPlain(item.unitPrice), align: pw.Alignment.centerRight),
            cell(CurrencyFormatter.formatPlain(item.total), align: pw.Alignment.centerRight),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.6),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(1.3),
        3: pw.FlexColumnWidth(0.8),
        4: pw.FlexColumnWidth(1.3),
        5: pw.FlexColumnWidth(1.3),
      },
      children: rows,
    );
  }

  static String _trimZero(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  // -----------------------------------------------------------------------
  // Totals: Subtotal / GST / Grand Total — right-aligned under the table
  // -----------------------------------------------------------------------
  static pw.Widget _buildTotalsBlock(InvoiceModel invoice) {
    pw.Widget row(String label, String value, {bool bold = false}) {
      return pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.6)),
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ],
        ),
      );
    }

    final gstLabel = 'GST @${invoice.gstPercent.toStringAsFixed(invoice.gstPercent % 1 == 0 ? 0 : 1)}%';

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 220,
        child: pw.Column(
          children: [
            row('TOTAL', CurrencyFormatter.formatPlain(invoice.subtotal)),
            if (invoice.discount > 0)
              row('DISCOUNT', '- ${CurrencyFormatter.formatPlain(invoice.discount)}'),
            row(gstLabel, CurrencyFormatter.formatPlain(invoice.gstAmount)),
            row('GRAND TOTAL', CurrencyFormatter.formatPlain(invoice.grandTotal), bold: true),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Signature (left) + Bank details (right)
  // -----------------------------------------------------------------------
  static pw.Widget _buildSignatureAndBankSection(CompanyModel company, pw.MemoryImage? signature) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (signature != null)
                pw.Container(height: 40, child: pw.Image(signature, fit: pw.BoxFit.contain))
              else
                pw.SizedBox(height: 40),
              pw.SizedBox(height: 4),
              pw.Container(width: 140, child: pw.Divider(thickness: 0.6, color: PdfColors.grey600)),
              pw.Text('AUTHORIZED SIGNATORY', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('BANK DETAILS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 3),
              if (company.bankName.isNotEmpty) _bankRow('BANK NAME:', company.bankName),
              if (company.accountNumber.isNotEmpty) _bankRow('A/C NO:', company.accountNumber),
              if (company.ifscCode.isNotEmpty) _bankRow('IFSC CODE:', company.ifscCode),
              if (company.upiId.isNotEmpty) _bankRow('UPI ID:', company.upiId),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _bankRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 70, child: pw.Text(label, style: const pw.TextStyle(fontSize: 8))),
          pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Footer: logo + bold company name + branch address + GST/contact
  // -----------------------------------------------------------------------
  static pw.Widget _buildFooter(CompanyModel company, pw.MemoryImage? logo) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Container(width: 34, height: 34, child: pw.Image(logo, fit: pw.BoxFit.contain))
          else
            pw.SizedBox(width: 34, height: 34),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  company.companyName.isNotEmpty ? company.companyName : 'Your Company Name',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                if (company.address.isNotEmpty || company.branchAddress.isNotEmpty)
                  pw.Text(
                    [company.address, company.branchAddress].where((s) => s.isNotEmpty).join('   '),
                    style: const pw.TextStyle(fontSize: 7.5),
                    textAlign: pw.TextAlign.center,
                  ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('GST NO: ${company.gstNumber}', style: const pw.TextStyle(fontSize: 7.5)),
                    pw.SizedBox(width: 16),
                    pw.Text('CONTACT NO: ${company.phone}', style: const pw.TextStyle(fontSize: 7.5)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

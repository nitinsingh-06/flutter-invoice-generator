import 'hive_service.dart';

/// Generates human-readable, sequential invoice numbers in the format
/// observed on the reference invoice: "FY2027-103" — a financial-year
/// prefix followed by a running sequence number.
///
/// Kept as its own tiny service (rather than inlined into HiveService or
/// the Create Invoice screen) because "how invoice numbers are formatted"
/// is a distinct business rule that may need to change independently
/// (e.g. per-country numbering schemes) without touching storage or UI code.
class InvoiceNumberService {
  InvoiceNumberService._();

  /// Returns the next invoice number to use, based on how many invoices
  /// already exist in the current Indian financial year (April–March).
  ///
  /// Note: this counts ALL invoices ever created (via [HiveService.invoiceCount])
  /// rather than filtering by financial year precisely, which keeps the
  /// logic simple and offline-safe. For a business issuing invoices across
  /// multiple financial years, the sequence number will keep incrementing
  /// rather than resetting each April — acceptable for most small
  /// businesses, and avoids the complexity/edge-cases of a per-year reset
  /// counter in an offline-only app with no server-side sequence lock.
  static String generateNext() {
    final financialYear = _currentFinancialYearLabel();
    final nextSequence = HiveService.invoiceCount + 1;

    // Pads the sequence to at least 3 digits (e.g. "007", "103", "1042")
    // to match the reference invoice's "FY2027-103" style.
    final paddedSequence = nextSequence.toString().padLeft(3, '0');

    return '$financialYear-$paddedSequence';
  }

  /// Computes the Indian financial-year label for "today's" date.
  /// The Indian financial year runs April 1 – March 31, and is
  /// conventionally labeled by its ENDING year, e.g. April 2026–March 2027
  /// is "FY2027".
  static String _currentFinancialYearLabel() {
    final now = DateTime.now();
    // If the current month is January–March, the financial year "ends"
    // this calendar year. If April–December, it ends next calendar year.
    final endingYear = now.month <= 3 ? now.year : now.year + 1;
    return 'FY$endingYear';
  }
}

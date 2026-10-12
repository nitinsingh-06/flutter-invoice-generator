import 'package:intl/intl.dart';

/// Centralized currency formatting so every screen and the PDF generator
/// display amounts identically (same symbol, same decimal places, same
/// thousands separators) instead of each screen rolling its own
/// `toStringAsFixed(2)` calls with subtly different results.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Indian Rupee formatter — matches the reference invoice's style
  /// (e.g. "11200/-" in the source image uses a simpler style, but for
  /// on-screen UI a proper ₹ symbol with thousands separators reads more
  /// professionally: "₹11,200.00"). The PDF template can independently
  /// choose to mimic the "/-" suffix style if an exact visual match to
  /// the reference is desired there.
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  /// Formats without the currency symbol — useful inside PDF cells where
  /// the symbol may be added separately or omitted per the template design.
  static String formatPlain(double amount) {
    return NumberFormat('#,##0.00', 'en_IN').format(amount);
  }
}

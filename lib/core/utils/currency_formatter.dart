import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrDecimalsFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _pdfInrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  static final NumberFormat _pdfInrDecimalsFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs. ',
    decimalDigits: 2,
  );

  /// Formats amount to Indian currency standard (e.g. ₹25,000)
  static String format(double amount, {bool showDecimals = false}) {
    if (showDecimals && (amount % 1 != 0)) {
      return _inrDecimalsFormatter.format(amount);
    }
    return _inrFormatter.format(amount);
  }

  /// Formats amount for PDF documents where standard fonts do not support the Unicode ₹ glyph (e.g. Rs. 25,000)
  static String formatPdf(double amount, {bool showDecimals = false}) {
    if (showDecimals && (amount % 1 != 0)) {
      return _pdfInrDecimalsFormatter.format(amount);
    }
    return _pdfInrFormatter.format(amount);
  }

  /// Compact format for large numbers (e.g. ₹1.5L, ₹25K)
  static String formatCompact(double amount) {
    if (amount >= 100000) {
      final inLakhs = amount / 100000;
      return '₹${inLakhs.toStringAsFixed(inLakhs.truncateToDouble() == inLakhs ? 0 : 1)}L';
    } else if (amount >= 1000) {
      final inThousands = amount / 1000;
      return '₹${inThousands.toStringAsFixed(inThousands.truncateToDouble() == inThousands ? 0 : 1)}k';
    }
    return format(amount);
  }
}

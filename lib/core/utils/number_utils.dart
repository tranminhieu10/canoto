import 'package:intl/intl.dart';

/// Utility class for number formatting
class NumberUtils {
  static final NumberFormat weightFormat = NumberFormat('#,##0.0', 'vi_VN');
  static final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );
  static final NumberFormat numberFormat = NumberFormat('#,##0', 'vi_VN');

  /// Format weight in kg
  static String formatWeight(double weight) {
    return '${weightFormat.format(weight)} kg';
  }

  /// Format currency
  static String formatCurrency(double amount) {
    return currencyFormat.format(amount);
  }

  /// Format number with thousand separator
  static String formatNumber(num number) {
    return numberFormat.format(number);
  }

  /// Parse formatted number string
  static double? parseNumber(String numberStr) {
    try {
      return numberFormat.parse(numberStr).toDouble();
    } catch (e) {
      return null;
    }
  }

  /// Calculate net weight
  static double calculateNetWeight(double grossWeight, double tareWeight) {
    return grossWeight - tareWeight;
  }

  /// Round to decimal places
  static double roundTo(double value, int decimalPlaces) {
    final factor = 10.0 * decimalPlaces;
    return (value * factor).round() / factor;
  }
}

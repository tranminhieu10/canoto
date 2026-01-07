import 'package:intl/intl.dart';

/// Utility class for date/time formatting
class DateTimeUtils {
  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat timeFormat = DateFormat('HH:mm:ss');
  static final DateFormat dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
  static final DateFormat fileNameFormat = DateFormat('yyyyMMdd_HHmmss');

  /// Format DateTime to date string
  static String formatDate(DateTime dateTime) {
    return dateFormat.format(dateTime);
  }

  /// Format DateTime to time string
  static String formatTime(DateTime dateTime) {
    return timeFormat.format(dateTime);
  }

  /// Format DateTime to full datetime string
  static String formatDateTime(DateTime dateTime) {
    return dateTimeFormat.format(dateTime);
  }

  /// Format DateTime for file names
  static String formatForFileName(DateTime dateTime) {
    return fileNameFormat.format(dateTime);
  }

  /// Parse date string to DateTime
  static DateTime? parseDate(String dateStr) {
    try {
      return dateFormat.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
}

// date_formatter.dart
import 'package:intl/intl.dart';

class DateFormatter {
  static String formatShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatLong(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatShortString(String dateString) {
    try {
      final parsed = DateTime.parse(dateString);
      return formatShort(parsed);
    } catch (_) {
      return dateString;
    }
  }
}

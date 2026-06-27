// money_formatter.dart
import 'package:intl/intl.dart';

class MoneyFormatter {
  static String format(double amount, {String currency = 'S/'}) {
    final formatter = NumberFormat.currency(locale: 'es_PE', symbol: currency);
    return formatter.format(amount);
  }
}

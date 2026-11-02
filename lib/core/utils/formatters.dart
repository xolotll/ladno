import 'package:intl/intl.dart';

String formatMoney(num value, String currency) => NumberFormat.currency(
      locale: 'ru_RU', symbol: currency, decimalDigits: 0).format(value);
String formatMonth(DateTime date) => DateFormat('LLLL yyyy', 'ru').format(date);
String formatShortDate(DateTime date) => DateFormat('d MMM', 'ru').format(date);
double parseAmount(String value) => double.tryParse(value.trim().replaceAll(' ', '').replaceAll(',', '.')) ?? 0;

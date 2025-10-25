import 'package:intl/intl.dart';

class DateFormatter {
  static String formatTime(DateTime date) => DateFormat('h:mm a').format(date);

  static String formatFullDate(DateTime date) =>
      DateFormat('MMMM d, yyyy').format(date);

  static String formatForGrouping(DateTime date) =>
      DateFormat('MMMM d, yyyy').format(date);
}

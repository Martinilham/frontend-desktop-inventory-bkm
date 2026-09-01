import 'package:intl/intl.dart';

class DateUtilsX {
  static String formatDisplay(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
}

import 'package:intl/intl.dart';

class DateHelper {
  static final _displayFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _displayWithTime = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

  static String formatDisplay(DateTime date) => _displayFormat.format(date);

  static String formatWithTime(DateTime date) => _displayWithTime.format(date);

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return 'há ${diff.inDays}d';
    if (diff.inHours >= 1) return 'há ${diff.inHours}h';
    if (diff.inMinutes >= 1) return 'há ${diff.inMinutes}min';
    return 'agora';
  }

  static int daysUntil(DateTime date) => date.difference(DateTime.now()).inDays;
}

import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _shortDate = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _timeOnly = DateFormat('hh:mm a');
  static final DateFormat _dayDate = DateFormat('EEEE, dd MMM');

  static String formatDate(DateTime? date) {
    if (date == null) return 'Never';
    return _shortDate.format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return 'Never';
    return _dateTime.format(date);
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '--:--';
    return _timeOnly.format(date);
  }

  static String formatDayDate(DateTime date) {
    return _dayDate.format(date);
  }

  static String relativeVisitTime(DateTime? date) {
    if (date == null) return 'Not visited yet';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes <= 1) return 'Just now';
        return '${difference.inMinutes} mins ago';
      }
      return 'Today at ${_timeOnly.format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return _shortDate.format(date);
    }
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

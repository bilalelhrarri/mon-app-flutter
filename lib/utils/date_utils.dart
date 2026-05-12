import 'package:intl/intl.dart';

class AppDateUtils {
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final _timeOnly = DateFormat('HH:mm');
  static final _dateOnly = DateFormat('dd/MM/yyyy');

  static String formatDateTime(DateTime dt) => _dateTime.format(dt);
  static String formatTime(DateTime dt)     => _timeOnly.format(dt);
  static String formatDate(DateTime dt)     => _dateOnly.format(dt);

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0)    return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0)   return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }

  static String formatDwell(DateTime entryTime) {
    final diff = DateTime.now().difference(entryTime);
    return '${diff.inHours}س ${diff.inMinutes % 60}د';
  }
}
import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(dt);
  }

  static String formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
  }

  static String formatTime(DateTime dt) {
    return DateFormat('HH:mm', 'id_ID').format(dt);
  }

  static String formatShort(DateTime dt) {
    return DateFormat('dd MMM yyyy • HH:mm').format(dt);
  }

  static String timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}

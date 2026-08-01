import 'package:intl/intl.dart';

class DateFormatter {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  static DateTime parseToWita(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);

      // Extract actual timezone offset from string (e.g., "+07:00" or "-08:00")
      final offsetMatch = RegExp(r'[+-]\d{2}:\d{2}$').firstMatch(dateStr);

      if (offsetMatch != null) {
        final offsetStr = offsetMatch.group(0)!;
        final sign = offsetStr[0] == '+' ? 1 : -1;
        final hours = int.parse(offsetStr.substring(1, 3));
        final minutes = int.parse(offsetStr.substring(4, 6));
        final sourceOffset = Duration(hours: hours, minutes: sign * minutes);
        const witaOffset = Duration(hours: 8);
        return dt.add(witaOffset - sourceOffset);
      }

      // Fallback: assume source is UTC, convert to WITA
      return dt.add(const Duration(hours: 8));
    } catch (e) {
      // If parsing fails, return current time as fallback
      return DateTime.now();
    }
  }

  static String formatWita(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = _months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute WITA';
  }

  static String formatWitaTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
  }

  static String formatDateForApi(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else {
      return formatDate(dateTime);
    }
  }
}

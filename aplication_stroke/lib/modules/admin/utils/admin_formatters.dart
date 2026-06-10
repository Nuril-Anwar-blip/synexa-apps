import 'package:intl/intl.dart';

/// Format tanggal aman untuk halaman admin (locale id_ID opsional).
class AdminFormatters {
  AdminFormatters._();

  static String date(DateTime? value) {
    if (value == null) return '-';
    try {
      return DateFormat('dd MMM yyyy', 'id_ID').format(value.toLocal());
    } catch (_) {
      return DateFormat('dd/MM/yyyy').format(value.toLocal());
    }
  }

  static String dateTime(DateTime? value) {
    if (value == null) return '-';
    try {
      return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(value.toLocal());
    } catch (_) {
      return DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
    }
  }

  static String initial(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }
}

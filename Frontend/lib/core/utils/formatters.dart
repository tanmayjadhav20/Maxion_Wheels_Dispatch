import 'package:intl/intl.dart';

final DateFormat _dfDate = DateFormat('dd MMM yyyy');
final DateFormat _dfDateTime = DateFormat('dd MMM yyyy, HH:mm');
final DateFormat _dfTime24 = DateFormat('HH:mm:ss');
final NumberFormat _nfInr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

String formatDate(dynamic dateStr) {
  if (dateStr == null || dateStr.toString().isEmpty) return '-';
  try {
    final dt = DateTime.parse(dateStr.toString());
    return _dfDate.format(dt);
  } catch (_) {
    return dateStr.toString();
  }
}

String formatDateTime(dynamic dateStr) {
  if (dateStr == null || dateStr.toString().isEmpty) return '-';
  try {
    final dt = DateTime.parse(dateStr.toString());
    return _dfDateTime.format(dt);
  } catch (_) {
    return dateStr.toString();
  }
}

String formatTime24(dynamic dateStr) {
  if (dateStr == null || dateStr.toString().isEmpty) return '-';
  try {
    final dt = DateTime.parse(dateStr.toString());
    return _dfTime24.format(dt);
  } catch (_) {
    return dateStr.toString();
  }
}

String inr(num value) => _nfInr.format(value);

String pctText(num pct) => '${pct.toStringAsFixed(1)}%';

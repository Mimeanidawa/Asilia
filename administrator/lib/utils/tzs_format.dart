import 'package:intl/intl.dart';

/// Formats amounts in Tanzanian Shillings (TZS).
class TzsFormat {
  static final _compact = NumberFormat.compact(locale: 'en');
  static final _full = NumberFormat('#,##0', 'en_US');

  static String compact(num value) => 'TZS ${_compact.format(value)}';

  static String full(num value) => 'TZS ${_full.format(value)}';

  static String chart(num value) => 'TZS ${value.toStringAsFixed(0)}';
}

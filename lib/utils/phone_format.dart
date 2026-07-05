/// Tanzania phone normalization — matches backend `normalizePhone`.
String? normalizePhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) digits = '255${digits.substring(1)}';
  if (digits.length == 9) digits = '255$digits';
  if (!digits.startsWith('255') || digits.length < 12) return null;
  return digits;
}

String formatPhoneForApi(String raw) {
  final trimmed = raw.trim();
  return normalizePhone(trimmed) ?? trimmed;
}

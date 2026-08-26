/// Sanitizes strings for Flutter text rendering (rejects unpaired UTF-16).
String safeDisplayText(String? input) {
  if (input == null || input.isEmpty) return '';

  final units = input.codeUnits;
  final out = StringBuffer();
  for (var i = 0; i < units.length; i++) {
    final u = units[i];
    if (u >= 0xD800 && u <= 0xDBFF) {
      if (i + 1 < units.length) {
        final low = units[i + 1];
        if (low >= 0xDC00 && low <= 0xDFFF) {
          out.writeCharCode(u);
          out.writeCharCode(low);
          i++;
          continue;
        }
      }
      continue;
    }
    if (u >= 0xDC00 && u <= 0xDFFF) continue;
    out.writeCharCode(u);
  }
  return out.toString();
}

/// First safe grapheme for avatars / covers — never returns a lone surrogate.
String safeInitial(String? input, {String fallback = ''}) {
  final text = safeDisplayText(input).trim();
  if (text.isEmpty) return fallback;
  return String.fromCharCode(text.runes.first).toUpperCase();
}

/// Utility to clean and extract health/disease topics from makala titles
/// to provide smart, context-aware medicine purchasing and Mwalimu inquiries.
class DiseaseExtractor {
  static final List<RegExp> _prefixPatterns = [
    RegExp(r'^(jinsi ya kutibu|jinsi ya kuponya|jinsi ya kuondoa|jinsi ya kuzuia)\s+', caseSensitive: false),
    RegExp(r'^(tiba asili ya|tiba ya asili ya|tiba ya|tiba mbadala ya)\s+', caseSensitive: false),
    RegExp(r'^(dawa asili ya|dawa ya asili ya|dawa ya|dawa za)\s+', caseSensitive: false),
    RegExp(r'^(namna ya kutibu|namna ya kuponya|namna ya kuondoa|namna ya kudhibiti)\s+', caseSensitive: false),
    RegExp(r'^(faida za\s+.+?\s+(kwa|katika)\s+(ajili ya\s+)?)', caseSensitive: false),
    RegExp(r'^(matumizi ya\s+.+?\s+(kwa|katika)\s+(ajili ya\s+)?)', caseSensitive: false),
    RegExp(r'^(mbinu za kutibu|mbinu za kuondoa|mbinu za kuzuia)\s+', caseSensitive: false),
    RegExp(r'^(dalili na tiba ya|dalili za|fahamu kuhusu|elimu kuhusu)\s+', caseSensitive: false),
    RegExp(r'^(jifunze kuhusu|fahamu namna ya kutibu)\s+', caseSensitive: false),
    RegExp(r'^(njia bora za kutibu|njia za kutibu|njia za asili za kutibu)\s+', caseSensitive: false),
  ];

  static final List<RegExp> _suffixPatterns = [
    RegExp(r'\s+(na dalili zake|na chanzo chake|na tiba yake|na namna ya kuitibu)$', caseSensitive: false),
    RegExp(r'\s+(kwa njia ya asili|nyumbani|bila madhara|kwa urahisi|kwa usahihi)$', caseSensitive: false),
    RegExp(r'\s*[:\-–—].*$', caseSensitive: false),
  ];

  /// Extracts the main disease or condition topic from a post title.
  static String extractTopic(String rawTitle, [String? category]) {
    if (rawTitle.isEmpty) {
      if (category != null && category.trim().isNotEmpty && category != 'general') {
        return category.trim();
      }
      return 'Tatizo Hili';
    }

    var text = rawTitle.trim();

    for (final p in _prefixPatterns) {
      if (p.hasMatch(text)) {
        text = text.replaceFirst(p, '').trim();
        break;
      }
    }

    for (final p in _suffixPatterns) {
      text = text.replaceAll(p, '').trim();
    }

    if (text.length < 3) {
      if (category != null && category.trim().isNotEmpty && category != 'general') {
        return category.trim();
      }
      return rawTitle.trim();
    }

    // Capitalize first letter of string
    if (text.isNotEmpty) {
      text = text[0].toUpperCase() + text.substring(1);
    }

    return text;
  }

  /// Builds prefilled message for Mwalimu inquiry
  static String formatMwalimuInquiry(String topic) {
    final clean = topic.trim();
    return 'Habari Mwalimu, nauliza dawa ya $clean kama inapatikana?';
  }
}

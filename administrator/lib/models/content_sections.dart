import '../utils/content_tag_style.dart';

/// Section & category constants — must stay in sync with the user app
/// (`lib/models/content_models.dart` → `ContentSections`).
class AdminContentSections {
  static const dodoso = 'dodoso';
  static const chaguaMada = 'chagua_mada';
  static const vyakulaMatunda = 'vyakula_matunda';
  static const jifunze = 'jifunze';

  static const sections = [
    (dodoso, 'Dodoso'),
    (chaguaMada, 'Chagua Mada'),
    (vyakulaMatunda, 'Vyakula na Matunda'),
    (jifunze, 'Jifunze'),
  ];

  /// Categories available when publishing makala per section.
  /// Slugs match user-app filters so published posts appear under the right tile.
  static const categoriesBySection = <String, List<String>>{
    // Home Dodoso tiles (darasa_huru is lessons, not makala)
    dodoso: ['mizizi', 'miti', 'matunda', 'mimea'],
    // Home Chagua Mada tiles
    chaguaMada: ['mimea', 'wanawake', 'watoto', 'wanaume'],
    // Vyakula na Matunda feed
    vyakulaMatunda: ['matunda', 'mizizi', 'miti', 'mimea', 'vyakula'],
    // Learn / Jifunze chips
    jifunze: ['matunda', 'mizizi', 'miti', 'mimea', 'vyakula'],
  };

  static List<String> categoriesFor(String section) =>
      List<String>.from(categoriesBySection[section] ?? const <String>[]);

  /// User-facing label for a category (matches home / learn tiles where possible).
  static String categoryLabel(String category, {String? section}) {
    if (section == dodoso) {
      switch (category) {
        case 'mizizi':
          return 'Mizizi';
        case 'miti':
          return 'Mimea'; // Home Dodoso tile label
        case 'matunda':
          return 'Matunda';
        case 'mimea':
          return 'Lishe'; // Home Dodoso tile label
      }
    }
    return ContentTagStyle.displayLabel(category);
  }

  static String sectionLabel(String section) {
    for (final s in sections) {
      if (s.$1 == section) return s.$2;
    }
    return section;
  }
}

import '../config/app_config.dart';

/// Formats makala share payloads for Mwalimu chat — parsed by the user app.
class MakalaShare {
  MakalaShare._();

  static String publicUrl(String id) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base/makala/$id';
  }

  /// `[MAKALA:id|title|imageUrl]` plus a public link line users can tap.
  static String formatMessage({
    required String id,
    required String title,
    String? imageUrl,
    String? note,
  }) {
    final safeTitle = title.replaceAll('|', '·').replaceAll(']', ')');
    final img = (imageUrl ?? '').trim();
    final tag = img.isNotEmpty
        ? '[MAKALA:$id|$safeTitle|$img]'
        : '[MAKALA:$id|$safeTitle]';
    final buffer = StringBuffer(tag);
    if (note != null && note.trim().isNotEmpty) {
      buffer.write('\n\n${note.trim()}');
    }
    buffer.write('\n${publicUrl(id)}');
    return buffer.toString();
  }
}

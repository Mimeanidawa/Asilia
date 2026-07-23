import '../config/app_config.dart';

/// Normalizes image URLs and builds display URLs for network images.
class ImageUrl {
  ImageUrl._();

  static String tidy(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('//')) url = 'https:$url';
    return unwrapProxy(url);
  }

  static String unwrapProxy(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (uri.path.toLowerCase().contains('/api/images/proxy')) {
      final target = uri.queryParameters['url'];
      if (target != null && target.trim().isNotEmpty) return target.trim();
    }
    return url;
  }

  static String proxied(String raw) {
    final url = tidy(raw);
    if (url.isEmpty) return '';

    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (!(uri.isScheme('http') || uri.isScheme('https'))) {
      if (url.startsWith('/api/media/') || url.startsWith('/api/images/')) {
        final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
        return '$base$url';
      }
      return url;
    }

    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    if (url.startsWith('$base/api/media/') ||
        url.startsWith('$base/api/images/proxy')) {
      return url;
    }

    return Uri.parse('$base/api/images/proxy').replace(
      queryParameters: {'url': url},
    ).toString();
  }

  static String display(String raw) => proxied(raw);
}

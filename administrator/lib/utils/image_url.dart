import '../config/app_config.dart';

/// Normalizes image URLs and routes them through the Asilia API image proxy.
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

  static bool needsResolution(String raw) {
    final url = tidy(raw);
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (host == 'ibb.co') return true;
    if (host == 'postimg.cc' || host == 'postimages.org') return true;
    if (host == 'i.postimg.cc') {
      final name = uri.path.split('/').last.toLowerCase();
      if (name.startsWith('file-00000000') ||
          RegExp(r'^file-[0-9a-f]{20,}').hasMatch(name)) {
        return true;
      }
    }
    return false;
  }

  /// Display URL: always via API proxy for remote http(s) images.
  static String proxied(String raw) {
    final url = tidy(raw);
    if (url.isEmpty) return '';

    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (!(uri.isScheme('http') || uri.isScheme('https'))) return url;

    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    if (url.startsWith('$base/api/images/proxy')) return url;

    return Uri.parse('$base/api/images/proxy').replace(
      queryParameters: {'url': url},
    ).toString();
  }

  static String display(String raw) => proxied(raw);
}

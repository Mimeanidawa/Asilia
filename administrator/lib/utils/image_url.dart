import '../config/app_config.dart';

/// Normalizes image URLs and builds display URLs for network images.
class ImageUrl {
  ImageUrl._();

  static final _directImagePath = RegExp(
    r'\.(png|jpe?g|gif|webp|avif|bmp)(\?.*)?$',
    caseSensitive: false,
  );

  static String tidy(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('//')) url = 'https:$url';
    return unwrapProxy(url);
  }

  static String unwrapProxy(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final path = uri.path.toLowerCase();
    if (path.contains('/api/images/proxy')) {
      final target = uri.queryParameters['url'];
      if (target != null && target.trim().isNotEmpty) return target.trim();
    }
    return url;
  }

  static String normalize(String raw) {
    final url = tidy(raw);
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (host == 'i.postimg.cc') {
      final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        final file = parts.last.toLowerCase();
        if (!file.startsWith('image.')) {
          final ext = file.contains('.') ? file.split('.').last : 'jpg';
          final safeExt = {'png', 'jpg', 'jpeg', 'webp', 'gif'}.contains(ext)
              ? (ext == 'jpeg' ? 'jpg' : ext)
              : 'jpg';
          return '${uri.scheme}://${uri.host}/${parts.first}/image.$safeExt';
        }
      }
    }
    return url;
  }

  static bool looksLikeDirectImage(String raw) {
    final url = tidy(raw);
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return false;
    }
    final host = uri.host.toLowerCase();
    if (host == 'i.ibb.co' || host.contains('imgur.com')) return true;
    if (host == 'i.postimg.cc') {
      final name = uri.path.split('/').last.toLowerCase();
      return name.startsWith('image.') || _directImagePath.hasMatch(uri.path);
    }
    return _directImagePath.hasMatch(uri.path);
  }

  static String proxied(String raw) {
    final url = normalize(raw);
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

  static String display(String raw) {
    final url = tidy(raw);
    if (isApiMediaUrl(url)) return url;
    return proxied(raw);
  }

  static bool isApiMediaUrl(String raw) {
    final url = tidy(raw);
    if (url.isEmpty) return false;
    if (url.contains('/api/media/')) return true;
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
    if (base.isNotEmpty && url.startsWith('$base/api/')) return true;
    return false;
  }
}

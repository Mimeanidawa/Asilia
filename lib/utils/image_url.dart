import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Normalizes image URLs and builds display URLs for network images.
class ImageUrl {
  ImageUrl._();

  static final _directImagePath = RegExp(
    r'\.(png|jpe?g|gif|webp|avif|bmp)(\?.*)?$',
    caseSensitive: false,
  );

  /// Quick sync tidy (trim, https). Does not hit the network.
  static String tidy(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('//')) url = 'https:$url';
    return unwrapProxy(url);
  }

  /// If [url] is already an Asilia proxy URL, return the original target.
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

  static bool needsResolution(String raw) {
    final url = tidy(raw);
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (host == 'ibb.co') return true;
    if (host == 'postimg.cc' || host == 'postimages.org') return true;
    if (host == 'i.postimg.cc' && _looksLikeBlockedPostimgPath(uri.path)) {
      return true;
    }
    return false;
  }

  static bool _looksLikeBlockedPostimgPath(String path) {
    final name = path.split('/').last.toLowerCase();
    return name.startsWith('file-00000000') ||
        RegExp(r'^file-[0-9a-f]{20,}').hasMatch(name);
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
      if (_looksLikeBlockedPostimgPath(uri.path)) return false;
      return name.startsWith('image.') || _directImagePath.hasMatch(uri.path);
    }
    return _directImagePath.hasMatch(uri.path);
  }

  /// Proxy URL through the Asilia API (needed for Flutter web CORS).
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

  /// Best first-choice display URL for the current platform.
  static String display(String raw) {
    final url = tidy(raw);
    if (url.isEmpty) return '';
    return kIsWeb ? proxied(url) : url;
  }
}

import '../config/app_config.dart';
import '../services/api_client.dart';

/// Resolves remote image URLs to stable API media URLs via the backend cache.
class ImageResolveService {
  ImageResolveService._();

  static final _cache = <String, String>{};
  static final _pending = <String, Future<String?>>{};

  static Future<String?> resolve(String raw) async {
    final key = ImageUrl.normalize(ImageUrl.tidy(raw));
    if (key.isEmpty) return null;
    if (_cache.containsKey(key)) return _cache[key];
    if (ImageUrl.isApiMediaUrl(key)) {
      _cache[key] = key;
      return key;
    }

    return _pending.putIfAbsent(key, () async {
      try {
        final api = ApiClient();
        final data = await api.get(
          '/api/images/resolve?url=${Uri.encodeComponent(key)}',
        );
        var url = data['url'] as String? ?? '';
        if (url.isEmpty) return null;

        if (!url.startsWith('http')) {
          final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
          url = '$base$url';
        }

        final display = ImageUrl.forceHttps(
          ImageUrl.isApiMediaUrl(url) ? url : ImageUrl.proxied(url),
        );
        _cache[key] = display;
        return display;
      } catch (_) {
        return null;
      } finally {
        _pending.remove(key);
      }
    });
  }

  static void remember(String raw, String displayUrl) {
    final key = ImageUrl.normalize(ImageUrl.tidy(raw));
    if (key.isNotEmpty && displayUrl.isNotEmpty) {
      _cache[key] = displayUrl;
    }
  }
}

/// Normalizes image URLs and builds display URLs for network images.
class ImageUrl {
  ImageUrl._();

  static final _directImagePath = RegExp(
    r'\.(png|jpe?g|gif|webp|avif|bmp)(\?.*)?$',
    caseSensitive: false,
  );

  static String forceHttps(String raw) {
    final url = raw.trim();
    if (url.startsWith('http://') &&
        !url.contains('localhost') &&
        !url.contains('127.0.0.1')) {
      return 'https://${url.substring(7)}';
    }
    return url;
  }

  static String tidy(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('//')) url = 'https:$url';
    url = unwrapProxy(url);
    return forceHttps(url);
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

  /// Rewrite Postimages paths to canonical `image.ext` form (matches backend).
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

  static bool needsResolution(String raw) {
    final url = normalize(raw);
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (host == 'ibb.co') return true;
    if (host == 'postimg.cc' || host == 'postimages.org') return true;
    if (host == 'i.postimg.cc') {
      final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
      final file = parts.length >= 2 ? parts[1].toLowerCase() : '';
      if (!file.startsWith('image.')) return true;
      return file.startsWith('file-00000000') ||
          RegExp(r'^file-[0-9a-f]{20,}').hasMatch(file);
    }
    return false;
  }

  /// Hosts that hotlink-block mobile clients with a tiny HTTP 200 placeholder.
  /// Always load these via `/api/images/proxy` (same as admin UrlImage).
  static bool requiresProxy(String raw) {
    final url = normalize(raw);
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    return host == 'i.postimg.cc' ||
        host == 'postimg.cc' ||
        host == 'postimages.org' ||
        host == 'i.ibb.co' ||
        host == 'ibb.co' ||
        host.contains('imgur.com');
  }

  static bool looksLikeDirectImage(String raw) {
    final url = normalize(raw);
    if (url.isEmpty) return false;
    if (requiresProxy(url)) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return false;
    }
    return _directImagePath.hasMatch(uri.path);
  }

  static String _apiBase() => AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');

  static String proxied(String raw) {
    final url = normalize(raw);
    if (url.isEmpty) return '';

    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final base = _apiBase();

    if (!(uri.isScheme('http') || uri.isScheme('https'))) {
      if (url.startsWith('/api/media/') || url.startsWith('/api/images/')) {
        return '$base$url';
      }
      return url;
    }

    if (isApiMediaUrl(url)) return forceHttps(url);

    return Uri.parse('$base/api/images/proxy').replace(
      queryParameters: {'url': url},
    ).toString();
  }

  static String display(String raw) {
    final url = normalize(raw);
    if (url.isEmpty) return '';
    if (isApiMediaUrl(url)) return forceHttps(url);
    return proxied(url);
  }

  /// True when [raw] is already a stable API media or proxied URL.
  static bool isApiMediaUrl(String raw) {
    final url = tidy(raw);
    if (url.isEmpty) return false;
    if (url.contains('/api/media/')) return true;
    if (url.contains('/api/images/proxy')) return true;
    final base = _apiBase();
    if (base.isEmpty) return false;
    final httpsBase = forceHttps(base);
    final httpBase = httpsBase.replaceFirst('https://', 'http://');
    return url.startsWith('$httpsBase/api/') || url.startsWith('$httpBase/api/');
  }
}

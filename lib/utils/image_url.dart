import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Normalizes and resolves cover image URLs so share-page links (e.g. ibb.co)
/// become direct image URLs that [CachedNetworkImage] can load.
class ImageUrl {
  ImageUrl._();

  static final _resolved = <String, String>{};
  static final _resolving = <String, Future<String>>{};

  static final _ogImage = RegExp(
    r'''(?:property|name)=["']og:image["'][^>]*content=["']([^"']+)["']'''
    r'''|'''
    r'''content=["']([^"']+)["'][^>]*(?:property|name)=["']og:image["']''',
    caseSensitive: false,
  );
  static final _directImagePath = RegExp(
    r'\.(png|jpe?g|gif|webp|avif|bmp)(\?.*)?$',
    caseSensitive: false,
  );

  /// Quick sync tidy (trim, https). Does not hit the network.
  static String tidy(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('//')) url = 'https:$url';
    return url;
  }

  /// True when [url] looks like an album/share page, not a binary image.
  static bool needsResolution(String raw) {
    final url = tidy(raw);
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (host == 'ibb.co') return true;
    if (host == 'postimg.cc' || host == 'postimages.org') return true;
    // Some i.postimg.cc links keep an AI/export filename that is blocked;
    // resolve via the share page to the canonical `image.ext` URL.
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

  /// Prefer the postimg share page so we can read `og:image`.
  static String _sharePageCandidate(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (host != 'i.postimg.cc') return url;
    final parts = uri.path.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return url;
    return 'https://postimg.cc/${parts.first}';
  }

  static bool looksLikeDirectImage(String raw) {
    final url = tidy(raw);
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return false;
    }
    final host = uri.host.toLowerCase();
    if (host == 'i.ibb.co' || host.contains('imgur.com')) {
      return true;
    }
    if (host == 'i.postimg.cc') {
      // Prefer canonical image.* names from the share page.
      final name = uri.path.split('/').last.toLowerCase();
      if (_looksLikeBlockedPostimgPath(uri.path)) return false;
      return name.startsWith('image.') || _directImagePath.hasMatch(uri.path);
    }
    return _directImagePath.hasMatch(uri.path);
  }

  /// Returns a display URL, resolving share pages when needed.
  static Future<String> resolve(String raw) async {
    final url = tidy(raw);
    if (url.isEmpty) return '';
    if (_resolved.containsKey(url)) return _resolved[url]!;
    if (!needsResolution(url)) {
      _resolved[url] = url;
      return url;
    }
    return _resolving.putIfAbsent(url, () => _resolveSharePage(_sharePageCandidate(url), original: url));
  }

  static Future<String> _resolveSharePage(String pageUrl, {required String original}) async {
    try {
      final response = await http.get(
        Uri.parse(pageUrl),
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 400) {
        final html = response.body;
        final og = _ogImage.firstMatch(html);
        final candidate = tidy(og?.group(1) ?? og?.group(2) ?? '');
        if (candidate.isNotEmpty && looksLikeDirectImage(candidate)) {
          _resolved[original] = candidate;
          return candidate;
        }

        final ibb = RegExp(r'https://i\.ibb\.co/[^\s"<>]+').firstMatch(html);
        if (ibb != null) {
          final found = tidy(ibb.group(0)!);
          _resolved[original] = found;
          return found;
        }
        final post = RegExp(r'https://i\.postimg\.cc/[A-Za-z0-9]+/image\.[a-zA-Z0-9]+')
            .firstMatch(html);
        if (post != null) {
          final found = tidy(post.group(0)!);
          _resolved[original] = found;
          return found;
        }
      }
    } catch (e) {
      debugPrint('ImageUrl.resolve failed for $pageUrl: $e');
    }

    // Last-ditch rewrite: .../CODE/file-....png -> .../CODE/image.png
    final rewritten = _rewritePostimgFilename(original);
    _resolved[original] = rewritten;
    return rewritten;
  }

  static String _rewritePostimgFilename(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (host != 'i.postimg.cc' || !_looksLikeBlockedPostimgPath(uri.path)) {
      return url;
    }
    final parts = uri.path.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length < 2) return url;
    final ext = parts.last.contains('.') ? parts.last.split('.').last : 'png';
    return '${uri.scheme}://${uri.host}/${parts.first}/image.$ext';
  }

  /// Drop cached resolutions (tests / after URL corrections).
  static void clearCache() {
    _resolved.clear();
    _resolving.clear();
  }
}

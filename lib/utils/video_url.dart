enum VideoSourceKind { direct, youtube, vimeo, dailymotion, unknown }

class ParsedVideoUrl {
  const ParsedVideoUrl({
    required this.kind,
    required this.originalUrl,
    this.videoId,
    this.directUrl,
  });

  final VideoSourceKind kind;
  final String originalUrl;
  final String? videoId;
  final String? directUrl;

  String? get embedUrl => switch (kind) {
        VideoSourceKind.youtube when videoId != null =>
          'https://www.youtube-nocookie.com/embed/$videoId?playsinline=1&rel=0&modestbranding=1&autoplay=0',
        VideoSourceKind.vimeo when videoId != null =>
          'https://player.vimeo.com/video/$videoId?autoplay=0',
        VideoSourceKind.dailymotion when videoId != null =>
          'https://www.dailymotion.com/embed/video/$videoId',
        VideoSourceKind.direct => directUrl,
        _ => null,
      };

  bool get isPlayable => embedUrl != null;
  bool get isEmbed => kind == VideoSourceKind.youtube || kind == VideoSourceKind.vimeo || kind == VideoSourceKind.dailymotion;
}

class VideoUrlParser {
  VideoUrlParser._();

  static final _directExt = RegExp(r'\.(mp4|m3u8|webm|mov|mkv|avi)(\?.*)?$', caseSensitive: false);

  static ParsedVideoUrl parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return ParsedVideoUrl(kind: VideoSourceKind.unknown, originalUrl: trimmed);
    }

    var work = trimmed;
    if (!work.contains('://') && work.contains('youtu')) {
      work = 'https://$work';
    }

    final uri = Uri.tryParse(work);
    if (uri == null || !uri.hasScheme) {
      return ParsedVideoUrl(kind: VideoSourceKind.unknown, originalUrl: trimmed);
    }

    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    final path = uri.path;

    final youtubeId = _youtubeId(host, path, uri);
    if (youtubeId != null) {
      return ParsedVideoUrl(kind: VideoSourceKind.youtube, originalUrl: trimmed, videoId: youtubeId);
    }

    final vimeoId = _vimeoId(host, path);
    if (vimeoId != null) {
      return ParsedVideoUrl(kind: VideoSourceKind.vimeo, originalUrl: trimmed, videoId: vimeoId);
    }

    final dailymotionId = _dailymotionId(host, path);
    if (dailymotionId != null) {
      return ParsedVideoUrl(kind: VideoSourceKind.dailymotion, originalUrl: trimmed, videoId: dailymotionId);
    }

    if (_directExt.hasMatch(path) || uri.scheme == 'file') {
      return ParsedVideoUrl(kind: VideoSourceKind.direct, originalUrl: trimmed, directUrl: trimmed);
    }

    if (host.contains('cloudfront') ||
        host.contains('googleusercontent') ||
        host.contains('blob.core') ||
        host.contains('fbcdn') ||
        host.contains('tiktokcdn')) {
      return ParsedVideoUrl(kind: VideoSourceKind.direct, originalUrl: trimmed, directUrl: trimmed);
    }

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return ParsedVideoUrl(kind: VideoSourceKind.direct, originalUrl: trimmed, directUrl: trimmed);
    }

    return ParsedVideoUrl(kind: VideoSourceKind.unknown, originalUrl: trimmed);
  }

  static String? _youtubeId(String host, String path, Uri uri) {
    if (host == 'youtu.be') {
      final id = path.replaceFirst('/', '').split('/').first.split('?').first;
      return id.isNotEmpty ? id : null;
    }
    if (host == 'youtube.com' ||
        host == 'm.youtube.com' ||
        host == 'music.youtube.com' ||
        host == 'youtube-nocookie.com') {
      if (path.startsWith('/embed/') || path.startsWith('/v/')) {
        final id = path.split('/').where((s) => s.isNotEmpty).elementAtOrNull(1);
        return id != null && id.isNotEmpty ? id.split('?').first : null;
      }
      if (path.startsWith('/shorts/')) {
        final id = path.split('/').where((s) => s.isNotEmpty).elementAtOrNull(1);
        return id != null && id.isNotEmpty ? id.split('?').first : null;
      }
      final id = uri.queryParameters['v'];
      return id != null && id.isNotEmpty ? id : null;
    }
    return null;
  }

  static String? _vimeoId(String host, String path) {
    if (host == 'vimeo.com' || host == 'player.vimeo.com') {
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();
      final id = segments.isNotEmpty ? segments.last.split('?').first : null;
      if (id != null && RegExp(r'^\d+$').hasMatch(id)) return id;
    }
    return null;
  }

  static String? _dailymotionId(String host, String path) {
    if (host.contains('dailymotion.com')) {
      final match = RegExp(r'/video/([a-zA-Z0-9]+)').firstMatch(path);
      return match?.group(1);
    }
    return null;
  }
}

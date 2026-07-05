enum VideoSourceKind { direct, youtube, vimeo, unknown }

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
          'https://www.youtube.com/embed/$videoId?playsinline=1&rel=0&modestbranding=1',
        VideoSourceKind.vimeo when videoId != null => 'https://player.vimeo.com/video/$videoId',
        VideoSourceKind.direct => directUrl,
        _ => null,
      };

  bool get isPlayable => embedUrl != null;
}

class VideoUrlParser {
  VideoUrlParser._();

  static final _directExt = RegExp(r'\.(mp4|m3u8|webm|mov|mkv)(\?.*)?$', caseSensitive: false);

  static ParsedVideoUrl parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return ParsedVideoUrl(kind: VideoSourceKind.unknown, originalUrl: trimmed);
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      return ParsedVideoUrl(kind: VideoSourceKind.unknown, originalUrl: trimmed);
    }

    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    final path = uri.path;

    if (host == 'youtu.be') {
      final id = path.replaceFirst('/', '').split('/').first;
      if (id.isNotEmpty) {
        return ParsedVideoUrl(kind: VideoSourceKind.youtube, originalUrl: trimmed, videoId: id);
      }
    }

    if (host == 'youtube.com' || host == 'm.youtube.com') {
      if (path.startsWith('/embed/')) {
        final id = path.split('/').where((s) => s.isNotEmpty).elementAtOrNull(1);
        if (id != null && id.isNotEmpty) {
          return ParsedVideoUrl(kind: VideoSourceKind.youtube, originalUrl: trimmed, videoId: id);
        }
      }
      if (path.startsWith('/shorts/')) {
        final id = path.split('/').where((s) => s.isNotEmpty).elementAtOrNull(1);
        if (id != null && id.isNotEmpty) {
          return ParsedVideoUrl(kind: VideoSourceKind.youtube, originalUrl: trimmed, videoId: id);
        }
      }
      final id = uri.queryParameters['v'];
      if (id != null && id.isNotEmpty) {
        return ParsedVideoUrl(kind: VideoSourceKind.youtube, originalUrl: trimmed, videoId: id);
      }
    }

    if (host == 'vimeo.com' || host == 'player.vimeo.com') {
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();
      final id = segments.isNotEmpty ? segments.last : null;
      if (id != null && RegExp(r'^\d+$').hasMatch(id)) {
        return ParsedVideoUrl(kind: VideoSourceKind.vimeo, originalUrl: trimmed, videoId: id);
      }
    }

    if (_directExt.hasMatch(path) || uri.scheme == 'file') {
      return ParsedVideoUrl(kind: VideoSourceKind.direct, originalUrl: trimmed, directUrl: trimmed);
    }

    if (host.contains('cloudfront') || host.contains('googleusercontent') || host.contains('blob.core')) {
      return ParsedVideoUrl(kind: VideoSourceKind.direct, originalUrl: trimmed, directUrl: trimmed);
    }

    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return ParsedVideoUrl(kind: VideoSourceKind.direct, originalUrl: trimmed, directUrl: trimmed);
    }

    return ParsedVideoUrl(kind: VideoSourceKind.unknown, originalUrl: trimmed);
  }
}

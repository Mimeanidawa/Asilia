import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/admin_colors.dart';
import '../utils/video_url.dart';

class EmbeddedVideoPlayer extends StatefulWidget {
  const EmbeddedVideoPlayer({
    super.key,
    required this.url,
    this.borderRadius = 12,
    this.backgroundColor = AdminColors.forest,
  });

  final String url;
  final double borderRadius;
  final Color backgroundColor;

  @override
  State<EmbeddedVideoPlayer> createState() => _EmbeddedVideoPlayerState();
}

class _EmbeddedVideoPlayerState extends State<EmbeddedVideoPlayer> {
  late ParsedVideoUrl _parsed;
  VideoPlayerController? _controller;
  WebViewController? _webController;
  bool _ready = false;
  bool _error = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _parsed = VideoUrlParser.parse(widget.url);
    _initPlayer();
  }

  @override
  void didUpdateWidget(EmbeddedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url.trim() != widget.url.trim()) {
      _disposePlayer();
      _parsed = VideoUrlParser.parse(widget.url);
      _ready = false;
      _error = false;
      _errorMessage = null;
      _initPlayer();
    }
  }

  void _disposePlayer() {
    _controller?.dispose();
    _controller = null;
    _webController = null;
  }

  Future<void> _initPlayer() async {
    if (!_parsed.isPlayable) {
      if (mounted) {
        setState(() {
          _error = true;
          _errorMessage = 'URL ya video si sahihi. Tumia YouTube au mp4.';
        });
      }
      return;
    }

    if (_parsed.kind == VideoSourceKind.direct) {
      try {
        final c = VideoPlayerController.networkUrl(Uri.parse(_parsed.directUrl!));
        await c.initialize();
        if (mounted) {
          setState(() {
            _controller = c;
            _ready = true;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _error = true;
            _errorMessage = 'Video haipatikani. Angalia URL.';
          });
        }
      }
      return;
    }

    final embed = _parsed.embedUrl!;
    final html = '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
  iframe { width: 100%; height: 100%; border: 0; }
</style>
</head>
<body>
<iframe
  src="$embed"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
  allowfullscreen
  referrerpolicy="strict-origin-when-cross-origin">
</iframe>
</body>
</html>
''';

    final web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _ready = true);
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() {
                _error = true;
                _errorMessage = 'Imeshindwa kupakia video.';
              });
            }
          },
        ),
      )
      ..loadHtmlString(html);

    if (mounted) {
      setState(() {
        _webController = web;
        _ready = true;
      });
    }
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
      } else {
        c.play();
      }
    });
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.trim().isEmpty) return const SizedBox.shrink();

    final aspectRatio = _controller?.value.isInitialized == true
        ? _controller!.value.aspectRatio
        : 16 / 9;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: _error
            ? _ErrorPanel(message: _errorMessage ?? 'Video haipatikani', backgroundColor: widget.backgroundColor)
            : !_ready
                ? ColoredBox(
                    color: widget.backgroundColor,
                    child: const Center(child: CircularProgressIndicator(color: AdminColors.emerald, strokeWidth: 2)),
                  )
                : _parsed.kind == VideoSourceKind.direct && _controller != null
                    ? GestureDetector(
                        onTap: _togglePlay,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _controller!.value.size.width,
                                  height: _controller!.value.size.height,
                                  child: VideoPlayer(_controller!),
                                ),
                              ),
                            ),
                            if (!_controller!.value.isPlaying)
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                              ),
                          ],
                        ),
                      )
                    : _webController != null
                        ? WebViewWidget(controller: _webController!)
                        : _ErrorPanel(message: 'Video haipatikani', backgroundColor: widget.backgroundColor),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.backgroundColor});

  final String message;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 32),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

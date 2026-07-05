import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../theme/app_colors.dart';
import '../utils/video_url.dart';
import 'fullscreen_video_player.dart';

/// Plays YouTube/Vimeo/Dailymotion embeds and direct video URLs inside the app.
class EmbeddedVideoPlayer extends StatefulWidget {
  const EmbeddedVideoPlayer({
    super.key,
    required this.url,
    this.borderRadius = 16,
    this.backgroundColor = AppColors.forest,
    this.caption,
    this.fullscreen = false,
  });

  final String url;
  final double borderRadius;
  final Color backgroundColor;
  final String? caption;
  final bool fullscreen;

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
          _errorMessage = 'URL ya video si sahihi. Tumia YouTube, Vimeo au mp4.';
        });
      }
      return;
    }

    if (_parsed.kind == VideoSourceKind.direct) {
      try {
        final c = VideoPlayerController.networkUrl(Uri.parse(_parsed.directUrl!));
        await c.initialize();
        c.setLooping(false);
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
      );

    if (web.platform is AndroidWebViewController) {
      final android = web.platform as AndroidWebViewController;
      android.setMediaPlaybackRequiresUserGesture(false);
    }

    await web.loadRequest(Uri.parse(embed));

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

  void _openFullscreen() {
    if (widget.fullscreen) return;
    openFullscreenVideo(context, widget.url, caption: widget.caption);
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

    final player = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: _error
            ? _ErrorPanel(message: _errorMessage ?? 'Video haipatikani', backgroundColor: widget.backgroundColor)
            : !_ready
                ? ColoredBox(
                    color: widget.backgroundColor,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  )
                : _parsed.kind == VideoSourceKind.direct && _controller != null
                    ? GestureDetector(
                        onTap: _togglePlay,
                        onDoubleTap: _openFullscreen,
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
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                              ),
                            if (!widget.fullscreen) _expandButton(),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: VideoProgressIndicator(
                                _controller!,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: AppColors.emerald400,
                                  bufferedColor: Colors.white24,
                                  backgroundColor: Colors.white12,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: _openFullscreen,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_webController != null) WebViewWidget(controller: _webController!),
                            if (!widget.fullscreen) _expandButton(),
                          ],
                        ),
                      ),
      ),
    );

    return player;
  }

  Widget _expandButton() {
    return Positioned(
      top: 8,
      right: 8,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: _openFullscreen,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
          ),
        ),
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
          const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 36),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

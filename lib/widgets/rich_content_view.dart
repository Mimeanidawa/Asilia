import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import '../models/content_blocks.dart';
import '../theme/app_colors.dart';
import '../utils/content_tag_style.dart';

class RichContentView extends StatelessWidget {
  const RichContentView({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final body = RichContentBody.parse(content);
    if (body.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < body.blocks.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == body.blocks.length - 1 ? 0 : 16),
            child: _BlockWidget(block: body.blocks[i]),
          ),
      ],
    );
  }
}

class _BlockWidget extends StatelessWidget {
  const _BlockWidget({required this.block});

  final ContentBlock block;

  @override
  Widget build(BuildContext context) {
    return switch (block.type) {
      ContentBlockType.paragraph => _ParagraphBlock(text: block.text),
      ContentBlockType.tag => _TagBlock(name: block.text, caption: block.caption),
      ContentBlockType.heading => _Heading(text: block.text, level: block.level),
      ContentBlockType.image => _ImageBlock(url: block.url, caption: block.caption),
      ContentBlockType.video => _VideoBlock(url: block.url, caption: block.caption),
      ContentBlockType.audio => _AudioBlock(url: block.url, title: block.title),
      ContentBlockType.quote => _QuoteBlock(text: block.text),
      ContentBlockType.divider => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: AppColors.gray200, thickness: 1),
        ),
      ContentBlockType.list => _ListBlock(style: block.listStyle, items: block.items),
    };
  }
}

class _ParagraphBlock extends StatelessWidget {
  const _ParagraphBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tag = ContentBlock.parseHashtagLine(text);
    if (tag != null) {
      return _TagBlock(name: tag.text, caption: tag.caption);
    }

    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.gray600,
        height: 1.75,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _TagBlock extends StatelessWidget {
  const _TagBlock({required this.name, required this.caption});

  final String name;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final color = ContentTagStyle.colorFor(name);
    final label = ContentTagStyle.displayLabel(name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('#', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
              Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3),
              ),
            ],
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            caption,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.forest,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.text, required this.level});

  final String text;
  final int level;

  @override
  Widget build(BuildContext context) {
    final style = switch (level) {
      1 => const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: AppColors.forest,
          height: 1.25,
          letterSpacing: -0.5,
        ),
      2 => const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.forest,
          height: 1.3,
        ),
      _ => const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.emerald800,
          height: 1.35,
        ),
    };

    return Padding(
      padding: EdgeInsets.only(top: level == 1 ? 4 : 8, bottom: 4),
      child: Text(text, style: style),
    );
  }
}

class _ImageBlock extends StatelessWidget {
  const _ImageBlock({required this.url, required this.caption});

  final String url;
  final String caption;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 200,
              color: AppColors.emerald50,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.forest, strokeWidth: 2),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.emerald50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.broken_image_outlined, color: AppColors.gray400, size: 40),
            ),
          ),
        ),
        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              caption,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.gray400, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }
}

class _VideoBlock extends StatefulWidget {
  const _VideoBlock({required this.url, required this.caption});

  final String url;
  final String caption;

  @override
  State<_VideoBlock> createState() => _VideoBlockState();
}

class _VideoBlockState extends State<_VideoBlock> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.url.isEmpty) return;
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c.initialize();
      if (mounted) {
        setState(() {
          _controller = c;
          _ready = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: _ready && _controller != null ? _controller!.value.aspectRatio : 16 / 9,
            child: _error
                ? Container(
                    color: AppColors.forest,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 36),
                        const SizedBox(height: 8),
                        Text('Video haipatikani', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                      ],
                    ),
                  )
                : !_ready
                    ? Container(
                        color: AppColors.forest,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(_controller!),
                          if (!_controller!.value.isPlaying)
                            GestureDetector(
                              onTap: () => setState(() => _controller!.play()),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
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
          ),
        ),
        if (widget.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.caption,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.gray400, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }
}

class _AudioBlock extends StatefulWidget {
  const _AudioBlock({required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<_AudioBlock> createState() => _AudioBlockState();
}

class _AudioBlockState extends State<_AudioBlock> {
  final _player = AudioPlayer();
  bool _loading = true;
  bool _playing = false;
  bool _error = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _init();
    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _playing = state.playing);
    });
    _player.durationStream.listen((d) {
      if (d != null && mounted) setState(() => _duration = d);
    });
    _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  Future<void> _init() async {
    if (widget.url.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      await _player.setUrl(widget.url);
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.forest.withValues(alpha: 0.08), AppColors.emerald50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _error || _loading
                ? null
                : () => _playing ? _player.pause() : _player.play(),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.forest,
                shape: BoxShape.circle,
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(
                      _error ? Icons.error_outline : _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title.isNotEmpty ? widget.title : 'Sikiliza sauti',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 6),
                if (!_error && !_loading)
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: _duration.inMilliseconds > 0
                          ? _position.inMilliseconds / _duration.inMilliseconds
                          : 0,
                      onChanged: (v) {
                        final pos = Duration(milliseconds: (v * _duration.inMilliseconds).round());
                        _player.seek(pos);
                      },
                      activeColor: AppColors.forest,
                      inactiveColor: AppColors.gray200,
                    ),
                  ),
                if (!_error && !_loading)
                  Text(
                    '${_fmt(_position)} / ${_fmt(_duration)}',
                    style: TextStyle(fontSize: 11, color: AppColors.gray400),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: AppColors.forest, width: 4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: AppColors.forest,
          height: 1.6,
        ),
      ),
    );
  }
}

class _ListBlock extends StatelessWidget {
  const _ListBlock({required this.style, required this.items});

  final String style;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    style == 'numbered' ? '${i + 1}.' : '•',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forest,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i],
                    style: const TextStyle(fontSize: 15, color: AppColors.gray600, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

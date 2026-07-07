import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/content_blocks.dart';
import '../theme/app_colors.dart';
import '../utils/block_accent_style.dart';
import '../utils/content_tag_style.dart';
import '../utils/video_url.dart';
import 'embedded_video_player.dart';
import 'fullscreen_image_viewer.dart';

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
      ContentBlockType.heading => _Heading(text: block.text, level: block.level, accent: block.accent),
      ContentBlockType.image => _ImageBlock(url: block.url, caption: block.caption),
      ContentBlockType.video => EmbeddedVideoPlayer(
          url: block.url,
          caption: _videoDisplayCaption(block),
        ),
      ContentBlockType.audio => _AudioBlock(url: block.url, title: block.title),
      ContentBlockType.quote => _QuoteBlock(text: block.text),
      ContentBlockType.callout => _CalloutBlock(text: block.text, title: block.title, variant: block.accent),
      ContentBlockType.divider => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: AppColors.gray200, thickness: 1),
        ),
      ContentBlockType.list => _ListBlock(style: block.listStyle, items: block.items),
    };
  }

  /// Show caption only when it is real text, not a duplicate/raw video URL.
  String? _videoDisplayCaption(ContentBlock block) {
    final caption = block.caption.trim();
    if (caption.isEmpty) return null;
    if (caption == block.url.trim()) return null;

    final parsed = VideoUrlParser.parse(caption);
    if (parsed.isEmbed) return null;
    if (parsed.kind == VideoSourceKind.direct && VideoUrlParser.looksLikeDirectVideo(caption)) {
      return null;
    }

    return caption;
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

    if (ContentBlock.parseMediaUrlLine(text) != null) {
      return const SizedBox.shrink();
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
  const _Heading({required this.text, required this.level, required this.accent});

  final String text;
  final int level;
  final String accent;

  @override
  Widget build(BuildContext context) {
    final color = BlockAccentStyle.colorFor(accent);
    final style = switch (level) {
      1 => TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: color,
          height: 1.25,
          letterSpacing: -0.5,
        ),
      2 => TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: color,
          height: 1.3,
        ),
      _ => TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: color,
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
        GestureDetector(
          onTap: () => openFullscreenImage(context, url, caption: caption),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                CachedNetworkImage(
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
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_out_map_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Panua', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
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

class _CalloutBlock extends StatelessWidget {
  const _CalloutBlock({required this.text, required this.title, required this.variant});

  final String text;
  final String title;
  final String variant;

  @override
  Widget build(BuildContext context) {
    final color = BlockAccentStyle.colorFor(BlockAccentStyle.variantColorKey(variant));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BlockAccentStyle.backgroundFor(variant),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BlockAccentStyle.borderFor(variant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(BlockAccentStyle.iconForCallout(variant), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isNotEmpty ? title : BlockAccentStyle.labelForCallout(variant),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(fontSize: 15, color: AppColors.gray600, height: 1.65),
                ),
              ],
            ),
          ),
        ],
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
    final visible = items.where((i) => i.trim().isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == visible.length - 1 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.forest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      style == 'numbered' ? '${i + 1}' : '•',
                      style: TextStyle(
                        fontSize: style == 'numbered' ? 12 : 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        visible[i],
                        style: const TextStyle(fontSize: 15, color: AppColors.gray600, height: 1.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../utils/category_visual.dart';
import '../utils/safe_text.dart';
import 'herb_image.dart';

String darasaBadgeLabel(DailyLesson lesson) =>
    lesson.isToday ? 'Leo' : 'Darasa Huru';

/// Large auto-rotating Darasa Huru hero carousel.
class DarasaHuruCarousel extends StatefulWidget {
  const DarasaHuruCarousel({
    super.key,
    required this.lessons,
    required this.onOpen,
    this.autoPlay = true,
    this.shuffle = true,
    this.maxItems = 8,
    this.height = 320,
  });

  final List<DailyLesson> lessons;
  final void Function(DailyLesson lesson) onOpen;
  final bool autoPlay;
  final bool shuffle;
  final int maxItems;
  final double height;

  @override
  State<DarasaHuruCarousel> createState() => _DarasaHuruCarouselState();
}

class _DarasaHuruCarouselState extends State<DarasaHuruCarousel> {
  late final PageController _controller;
  Timer? _timer;
  double _page = 0;
  List<DailyLesson> _order = [];
  String _key = '';

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    _controller.addListener(() {
      final page = _controller.page;
      if (page != null && mounted) setState(() => _page = page);
    });
    _reshuffle(widget.lessons);
    if (widget.autoPlay) _start();
  }

  @override
  void didUpdateWidget(covariant DarasaHuruCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextKey = widget.lessons.map((l) => l.id).join('|');
    if (nextKey != _key) {
      _reshuffle(widget.lessons);
      if (_controller.hasClients) _controller.jumpToPage(0);
    }
  }

  void _reshuffle(List<DailyLesson> lessons) {
    var next = List<DailyLesson>.of(lessons);
    if (widget.shuffle) next.shuffle(Random());
    if (widget.maxItems > 0 && next.length > widget.maxItems) {
      next = next.take(widget.maxItems).toList();
    }
    _order = next;
    _key = lessons.map((l) => l.id).join('|');
    _page = 0;
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _order.length < 2) return;
      if (!_controller.hasClients) return;
      final next = (_page.round() + 1) % _order.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_order.isEmpty) return const SizedBox.shrink();

    final screenW = MediaQuery.sizeOf(context).width;
    final height = widget.height.clamp(280.0, screenW * 0.92);

    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: _order.length,
            padEnds: true,
            itemBuilder: (context, i) {
              final distance = (_page - i).abs().clamp(0.0, 1.0);
              final scale = 1.0 - (distance * 0.06);
              final opacity = 1.0 - (distance * 0.22);

              return AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: Opacity(
                  opacity: opacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _DarasaSlide(
                      lesson: _order[i],
                      onTap: () => widget.onOpen(_order[i]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_order.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Row(
              children: [
                for (var i = 0; i < _order.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    flex: i == _page.round() ? 3 : 1,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: i == _page.round()
                            ? AppColors.forest
                            : AppColors.forest.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _DarasaSlide extends StatelessWidget {
  const _DarasaSlide({required this.lesson, required this.onTap});

  final DailyLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = safeDisplayText(lesson.title);
    final excerpt = safeDisplayText(lesson.excerpt);
    final hasImage = lesson.imageUrl.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 14),
                spreadRadius: -8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  Positioned.fill(
                    child: HerbImage(
                      url: lesson.imageUrl,
                      borderRadius: 0,
                      fullWidth: true,
                      fit: BoxFit.cover,
                      fallbackLabel: title,
                      category: 'darasa_huru',
                    ),
                  )
                else
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: CategoryVisual.gradientFor('darasa_huru'),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.school_rounded,
                          color: Colors.white70,
                          size: 52,
                        ),
                      ),
                    ),
                  ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x55000000),
                          Color(0x14000000),
                          Color(0xCC0A1F1A),
                        ],
                        stops: [0, 0.38, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      _GlassChip(
                        child: Text(
                          darasaBadgeLabel(lesson),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (lesson.formattedDate.isNotEmpty)
                        _GlassChip(
                          child: Text(
                            lesson.formattedDate,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.18,
                          letterSpacing: -0.45,
                        ),
                      ),
                      if (excerpt.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          excerpt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Soma somo',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.forest,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: AppColors.forest,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: child,
        ),
      ),
    );
  }
}

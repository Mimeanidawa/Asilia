import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../utils/category_visual.dart';
import 'herb_image.dart';

String darasaBadgeLabel(DailyLesson lesson) =>
    lesson.isToday ? 'DARASA LA LEO' : 'DARASA HURU';

/// Shuffled, auto-rotating pager of Darasa Huru lessons.
class DarasaHuruCarousel extends StatefulWidget {
  const DarasaHuruCarousel({
    super.key,
    required this.lessons,
    required this.onOpen,
    this.autoPlay = true,
    this.shuffle = true,
    this.maxItems = 8,
    this.height = 318,
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
  int _page = 0;
  List<DailyLesson> _order = [];
  String _key = '';

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    _reshuffle(widget.lessons);
    if (widget.autoPlay) _start();
  }

  @override
  void didUpdateWidget(covariant DarasaHuruCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextKey = widget.lessons.map((l) => l.id).join('|');
    if (nextKey != _key) {
      _reshuffle(widget.lessons);
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
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
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || _order.length < 2) return;
      if (!_controller.hasClients) return;
      final next = (_page + 1) % _order.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeInOutCubic,
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

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: _order.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final lesson = _order[i];
              return Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
                child: _PagerCard(
                  lesson: lesson,
                  onTap: () => widget.onOpen(lesson),
                ),
              );
            },
          ),
        ),
        if (_order.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _order.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: i == _page ? 18 : 6,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? AppColors.forest
                          : AppColors.forest.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PagerCard extends StatelessWidget {
  const _PagerCard({required this.lesson, required this.onTap});

  final DailyLesson lesson;
  final VoidCallback onTap;

  static const _photo = 168.0;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.forest.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 10),
              spreadRadius: -6,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _photo,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HerbImage(
                    url: lesson.imageUrl,
                    height: _photo,
                    borderRadius: 0,
                    fullWidth: true,
                    fallbackLabel: lesson.title,
                    category: 'darasa_huru',
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: lesson.isToday ? AppColors.amber : AppColors.forest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        darasaBadgeLabel(lesson),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kIsWeb ? null : 'Playfair Display',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                        height: 1.2,
                      ),
                    ),
                    if (lesson.excerpt.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        lesson.excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          lesson.formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray400,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Soma',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.emerald700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: AppColors.emerald700,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 380.ms);
  }
}

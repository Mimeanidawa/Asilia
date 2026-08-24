import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/mwalimu_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_refresh.dart';
import '../utils/category_visual.dart';
import '../utils/responsive.dart';
import '../widgets/circle_back_button.dart';
import '../widgets/darasa_huru_carousel.dart';
import '../widgets/herb_image.dart';
import '../widgets/pull_to_refresh.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/screen_header.dart';

class DarasaHuruScreen extends StatefulWidget {
  const DarasaHuruScreen({super.key});

  @override
  State<DarasaHuruScreen> createState() => _DarasaHuruScreenState();
}

class _DarasaHuruScreenState extends State<DarasaHuruScreen> {
  DailyLesson? _activeLesson;
  List<DailyLesson> _shuffled = [];
  String _shuffleKey = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppProvider>();
      final id = app.selectedLessonId;
      if (id != null) {
        final lesson = app.lessonService.lessonById(id);
        if (lesson != null && mounted) {
          _openLesson(lesson);
        }
      }
    });
  }

  void _openLesson(DailyLesson lesson) {
    setState(() => _activeLesson = lesson);
    context.read<AppProvider>().setBottomNavSuppressed(true);
  }

  void _closeLesson() {
    setState(() => _activeLesson = null);
    context.read<AppProvider>().setBottomNavSuppressed(false);
  }

  void _shuffleLessons(List<DailyLesson> lessons, {bool force = false}) {
    final key = lessons.map((l) => l.id).join('|');
    if (!force && key == _shuffleKey && _shuffled.isNotEmpty) return;
    _shuffled = List<DailyLesson>.of(lessons)..shuffle();
    _shuffleKey = key;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final lessonService = app.lessonService;
    final lessons = lessonService.publishedLessons;
    final pendingLessonId = app.selectedLessonId;
    if (_activeLesson == null && pendingLessonId != null) {
      final pending = lessonService.lessonById(pendingLessonId);
      if (pending != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _activeLesson == null) _openLesson(pending);
        });
      }
    }
    final activeLessonStillPublished = _activeLesson != null &&
        lessons.any((lesson) => lesson.id == _activeLesson!.id);

    if (_activeLesson != null && !activeLessonStillPublished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _closeLesson();
      });
    }

    if (_activeLesson != null && activeLessonStillPublished) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _closeLesson();
        },
        child: _LessonReader(
          lesson: _activeLesson!,
          onClose: _closeLesson,
        ),
      );
    }

    final gutter = Responsive.horizontalGutter(context);
    _shuffleLessons(lessons);
    const featuredCount = 8;
    final featuredSet = _shuffled.take(featuredCount).toList();
    final featured = featuredSet.isNotEmpty ? featuredSet.first : null;
    final rest = _shuffled.length <= featuredSet.length
        ? const <DailyLesson>[]
        : _shuffled.skip(featuredSet.length).toList();

    return SizedBox.expand(
      child: Column(
        children: [
          _DarasaHeader(count: lessons.length, onBack: app.goBack),
          Expanded(
            child: lessonService.isSyncing && lessons.isEmpty
                ? const DarasaHuruLoadingSkeleton()
                : PullToRefresh(
                    onRefresh: () async {
                      await AppRefresh.catalog(context);
                      if (mounted) {
                        setState(() => _shuffleLessons(
                              context.read<AppProvider>().lessonService.publishedLessons,
                              force: true,
                            ));
                      }
                    },
                    child: lessons.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.sizeOf(context).height * 0.5,
                                child: _buildEmptyState(),
                              ),
                            ],
                          )
                        : CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              if (lessons.length > 1)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: DarasaHuruCarousel(
                                      lessons: featuredSet,
                                      shuffle: false,
                                      maxItems: featuredSet.length,
                                      onOpen: _openLesson,
                                    ),
                                  ),
                                )
                              else if (featured != null)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(gutter, 18, gutter, 8),
                                    child: _FeaturedLessonCard(
                                      lesson: featured,
                                      onRead: () => _openLesson(featured),
                                    ),
                                  ),
                                ),
                              if (rest.isNotEmpty)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(gutter + 4, 16, gutter, 10),
                                    child: Row(
                                      children: [
                                        const Text(
                                          'Masomo zaidi',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.forest,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${rest.length} masomo',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.gray400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  gutter,
                                  0,
                                  gutter,
                                  Responsive.scrollBottomPadding(context, extra: 12),
                                ),
                                sliver: SliverList.separated(
                                  itemCount: rest.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                                  itemBuilder: (context, i) => _LessonListTile(
                                    lesson: rest[i],
                                    index: i,
                                    onTap: () => _openLesson(rest[i]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.emerald50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 40,
                color: AppColors.emerald800,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hakuna masomo bado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.forest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Admin atachapisha masomo hivi karibuni.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarasaHeader extends StatelessWidget {
  const _DarasaHeader({required this.count, required this.onBack});

  final int count;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE8F2EC),
            AppColors.cream,
            AppColors.amberLight.withValues(alpha: 0.16),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.forest.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          CircleBackButton(onPressed: onBack),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: CategoryVisual.gradientFor('darasa_huru'),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Darasa Huru',
                  style: TextStyle(
                    fontFamily: kIsWeb ? null : 'Playfair Display',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forest,
                    height: 1.1,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Masomo mbalimbali kutoka kwa wataalamu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.gray500),
                ),
              ],
            ),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.forest.withValues(alpha: 0.08)),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.emerald800,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms);
  }
}

class _FeaturedLessonCard extends StatelessWidget {
  const _FeaturedLessonCard({
    required this.lesson,
    required this.onRead,
  });

  final DailyLesson lesson;
  final VoidCallback onRead;

  static const _photoHeight = 196.0;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onRead,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.forest.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 14),
              spreadRadius: -8,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: _photoHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HerbImage(
                    url: lesson.imageUrl,
                    height: _photoHeight,
                    borderRadius: 0,
                    fullWidth: true,
                    fallbackLabel: lesson.title,
                    category: 'darasa_huru',
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lesson.topicTag != null) ...[
                    Text(
                      lesson.topicTag!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.amber,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    lesson.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kIsWeb ? null : 'Playfair Display',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forest,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (lesson.excerpt.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      lesson.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.gray500),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (lesson.formattedDate.isNotEmpty)
                        Text(
                          lesson.formattedDate,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray400,
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.forest,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Anza somo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
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
    ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.04, curve: Curves.easeOutCubic);
  }
}

class _LessonListTile extends StatelessWidget {
  const _LessonListTile({
    required this.lesson,
    required this.onTap,
    this.index = 0,
  });

  final DailyLesson lesson;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.forest.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -6,
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HerbImage(
              url: lesson.imageUrl,
              width: 108,
              height: 108,
              borderRadius: 16,
              fallbackLabel: lesson.title,
              category: 'darasa_huru',
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.formattedDate.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gray400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lesson.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forest,
                      height: 1.22,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (lesson.excerpt.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      lesson.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppColors.gray500, height: 1.35),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
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
                        color: AppColors.emerald700.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (index * 45).ms, duration: 360.ms)
        .slideY(begin: 0.045, curve: Curves.easeOutCubic);
  }
}

class _LessonReader extends StatelessWidget {
  const _LessonReader({required this.lesson, required this.onClose});

  final DailyLesson lesson;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final paragraphs = lesson.content.split('\n\n');
    final authorName = context.watch<MwalimuService>().displayName;

    return SizedBox.expand(
      child: Column(
        children: [
          ScreenHeader(
            title: 'DARASA HURU',
            onBack: onClose,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.emerald800,
              letterSpacing: 1,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                HerbImage(
                  url: lesson.imageUrl,
                  height: 240,
                  borderRadius: 0,
                  fullWidth: true,
                  fallbackLabel: lesson.title,
                  category: 'darasa_huru',
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (lesson.isToday)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A017),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'DARASA LA LEO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      if (lesson.topicTag != null)
                        Text(
                          lesson.topicTag!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.amber,
                            letterSpacing: 1,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.forest,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.emerald50,
                            child: const Icon(
                              Icons.person_rounded,
                              size: 16,
                              color: AppColors.emerald800,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authorName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.forest,
                                  ),
                                ),
                                Text(
                                  lesson.formattedDate,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.gray400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.emerald50.withValues(alpha: 0.5),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(12),
                          ),
                          border: const Border(
                            left: BorderSide(
                              color: AppColors.emerald800,
                              width: 3.5,
                            ),
                          ),
                        ),
                        child: Text(
                          lesson.excerpt,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            color: AppColors.emerald900,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...paragraphs.map(_buildParagraph),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParagraph(String text) {
    if (text.startsWith('**') && text.contains(':**')) {
      final parts = text.split(':**');
      final heading = parts[0].replaceAll('**', '');
      final body = parts.length > 1 ? parts[1].trim() : '';
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.forest,
              ),
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                body,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray600,
                  height: 1.65,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (text.startsWith('•')) {
      final items = text.split('\n').where((l) => l.trim().isNotEmpty);
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.amber)),
                  Expanded(
                    child: Text(
                      item.replaceFirst('• ', ''),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.gray600,
          height: 1.65,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

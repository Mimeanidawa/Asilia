import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../utils/app_refresh.dart';
import '../widgets/herb_image.dart';
import '../widgets/pull_to_refresh.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_loading.dart';

class DarasaHuruScreen extends StatefulWidget {
  const DarasaHuruScreen({super.key});

  @override
  State<DarasaHuruScreen> createState() => _DarasaHuruScreenState();
}

class _DarasaHuruScreenState extends State<DarasaHuruScreen> {
  DailyLesson? _activeLesson;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppProvider>();
      final id = app.selectedLessonId;
      if (id != null) {
        final lesson = app.lessonService.lessonById(id);
        if (lesson != null && mounted) {
          setState(() => _activeLesson = lesson);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final lessonService = app.lessonService;
    final lessons = lessonService.publishedLessons;
    final today = lessonService.todayLesson;

    if (_activeLesson != null) {
      return _LessonReader(
        lesson: _activeLesson!,
        onClose: () => setState(() => _activeLesson = null),
      );
    }

    return SizedBox.expand(
      child: Column(
        children: [
          _buildHeader(context, app),
          Expanded(
            child: lessonService.isSyncing && lessons.isEmpty
                ? const DarasaHuruLoadingSkeleton()
                : PullToRefresh(
                    onRefresh: () => AppRefresh.catalog(context),
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
                        : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      if (today != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: _FeaturedLessonCard(
                            lesson: today,
                            onRead: () => setState(() => _activeLesson = today),
                          ),
                        ),
                      ],
                      SectionHeader(
                        title: 'Masomo ya Awali',
                        subtitle:
                            '${lessons.length} masomo yaliyochapishwa',
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                      ),
                      ...lessons.map(
                        (lesson) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: _LessonListTile(
                            lesson: lesson,
                            isToday: lesson.isToday,
                            onTap: () =>
                                setState(() => _activeLesson = lesson),
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

  Widget _buildHeader(BuildContext context, AppProvider app) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.forest.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.forest),
            onPressed: app.goBack,
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: AppColors.emerald800,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DARASA HURU',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.forest,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Masomo ya kila siku kutoka kwa wataalamu',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
              'Admin atachapisha darasa la leo hivi karibuni.',
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

class _FeaturedLessonCard extends StatelessWidget {
  const _FeaturedLessonCard({
    required this.lesson,
    required this.onRead,
  });

  final DailyLesson lesson;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onRead,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              fit: StackFit.passthrough,
              children: [
                HerbImage(
                  url: lesson.imageUrl,
                  height: 180,
                  borderRadius: 0,
                  fullWidth: true,
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'DARASA LA LEO',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 6),
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.forest,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lesson.excerpt,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.gray600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: AppColors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lesson.readTimeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.gray400,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: onRead,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.forest,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Anza somo',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 18),
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
    );
  }
}

class _LessonListTile extends StatelessWidget {
  const _LessonListTile({
    required this.lesson,
    required this.isToday,
    required this.onTap,
  });

  final DailyLesson lesson;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  HerbImage(url: lesson.imageUrl, width: 72, height: 72),
                  if (isToday)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.formattedDate.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: isToday ? AppColors.amber : AppColors.gray400,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forest,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.excerpt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.gray400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.gray400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonReader extends StatelessWidget {
  const _LessonReader({required this.lesson, required this.onClose});

  final DailyLesson lesson;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final paragraphs = lesson.content.split('\n\n');

    return SizedBox.expand(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.forest),
                  onPressed: onClose,
                ),
                const Expanded(
                  child: Text(
                    'DARASA HURU',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                HerbImage(
                  url: lesson.imageUrl,
                  height: 220,
                  borderRadius: 0,
                  fullWidth: true,
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
                            color: AppColors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'DARASA LA LEO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.amber,
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
                                  lesson.authorName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.forest,
                                  ),
                                ),
                                Text(
                                  '${lesson.formattedDate} · ${lesson.readTimeLabel}',
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

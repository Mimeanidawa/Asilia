import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../utils/content_search.dart';
import '../utils/premium_content_flow.dart';
import 'content_post_card.dart';
import 'herb_image.dart';

Future<void> showCarouselContentPicker(
  BuildContext context, {
  required CarouselSlide slide,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => _CarouselContentPickerSheet(slide: slide),
  );
}

class _CarouselContentPickerSheet extends StatelessWidget {
  const _CarouselContentPickerSheet({required this.slide});

  final CarouselSlide slide;

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentService>();
    final lessons = context.watch<AppProvider>().lessonService;
    final hits = ContentSearch.search(
      query: slide.title,
      subtitleHint: slide.subtitle,
      content: content,
      lessons: lessons,
      preferredId: slide.linkId,
    );

    return DraggableScrollableSheet(
      initialChildSize: hits.isEmpty ? 0.42 : 0.72,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chagua makala',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.forest,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Yanayolingana na "${slide.title}"',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray500,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: AppColors.gray400),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: hits.isEmpty
                    ? const _EmptyResults()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: hits.length,
                        itemBuilder: (context, index) {
                          final hit = hits[index];
                          return _SearchHitTile(
                            hit: hit,
                            onTap: () => _openHit(context, hit),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openHit(BuildContext context, ContentSearchHit hit) {
    Navigator.pop(context);
    final app = context.read<AppProvider>();

    switch (hit.kind) {
      case ContentSearchHitKind.post:
        openContentPost(context, hit.post!);
      case ContentSearchHitKind.lesson:
        app.navigate(AppScreen.darasaHuru, lessonId: hit.lesson!.id);
    }
  }
}

class _SearchHitTile extends StatelessWidget {
  const _SearchHitTile({required this.hit, required this.onTap});

  final ContentSearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (hit.kind == ContentSearchHitKind.post) {
      return ContentPostCard(
        post: hit.post!,
        showSectionLabel: true,
        compact: true,
        onTap: onTap,
      );
    }

    final lesson = hit.lesson!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.forest.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                if (lesson.imageUrl.isNotEmpty)
                  HerbImage(url: lesson.imageUrl, width: 120, height: 96, borderRadius: 0),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.emerald50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Darasa Huru',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.emerald800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lesson.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.forest,
                            height: 1.25,
                          ),
                        ),
                        if (lesson.excerpt.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            lesson.excerpt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: AppColors.gray500, height: 1.35),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_rounded, size: 48, color: AppColors.forest.withValues(alpha: 0.45)),
          const SizedBox(height: 12),
          const Text(
            'Makala hii itakujia hivi punde',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.forest,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

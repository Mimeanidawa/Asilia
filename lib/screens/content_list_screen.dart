import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../widgets/shimmer_loading.dart';

class ContentListScreen extends StatelessWidget {
  const ContentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final content = context.watch<ContentService>();
    final section = app.selectedContentSection ?? ContentSections.dodoso;
    final category = app.selectedContentCategory;

    final posts = content.postsForSection(section, category: category);
    final title = _sectionTitle(section, category);

    return SizedBox.expand(
      child: Column(
        children: [
          _header(context, title, app),
          Expanded(
            child: posts.isEmpty
                ? Center(
                    child: content.isLoading
                        ? const CircularProgressIndicator(color: AppColors.forest)
                        : Text('Hakuna maudhui bado', style: TextStyle(color: AppColors.gray400)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: posts.length,
                    itemBuilder: (context, i) => _PostCard(
                      post: posts[i],
                      index: i,
                      onTap: () => app.navigate(
                        AppScreen.contentDetail,
                        contentId: posts[i].id,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _sectionTitle(String section, String? category) {
    if (category != null) return ContentSections.categoryLabel(category);
    switch (section) {
      case ContentSections.dodoso: return 'Dodoso';
      case ContentSections.chaguaMada: return 'Chagua Mada';
      case ContentSections.vyakulaMatunda:
        return 'Vyakula na Matunda';
      case ContentSections.jifunze: return 'Jifunze';
      default: return 'Maudhui';
    }
  }

  Widget _header(BuildContext context, String title, AppProvider app) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: app.goBack,
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.forest, size: 18),
          ),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.forest,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.index, required this.onTap});

  final ContentPost post;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.forest.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                if (post.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SkeletonBox(width: 100, height: 100),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (post.isPremium)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'PREMIUM TZS ${post.price}',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: AppColors.amber,
                              ),
                            ),
                          ),
                        Text(
                          post.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.forest,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post.excerpt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: AppColors.gray500, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../providers/app_provider.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_refresh.dart';
import '../utils/premium_content_flow.dart';
import '../widgets/content_post_card.dart';
import '../widgets/pull_to_refresh.dart';
import '../widgets/responsive_content_list.dart';
import '../widgets/screen_header.dart';

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
    final subtitle = _sectionSubtitle(section, category);

    return SizedBox.expand(
      child: Column(
        children: [
          _header(context, title, app),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: AppColors.gray500, height: 1.35),
              ),
            ),
          Expanded(
            child: PullToRefresh(
              onRefresh: () => AppRefresh.catalog(context),
              child: posts.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.45,
                          child: Center(
                            child: content.isLoading
                                ? const CircularProgressIndicator(color: AppColors.forest)
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.article_outlined, size: 48, color: AppColors.gray400),
                                      const SizedBox(height: 12),
                                      Text(
                                        category != null
                                            ? 'Hakuna makala za ${ContentSections.categoryLabel(category)} bado'
                                            : 'Hakuna maudhui bado',
                                        style: TextStyle(
                                          color: AppColors.gray500,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Vuta chini kusasisha au rudi baadaye',
                                        style: TextStyle(color: AppColors.gray400, fontSize: 12),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    )
                  : ResponsiveContentList(
                      itemCount: posts.length,
                      mainAxisSpacing: 16,
                      itemBuilder: (context, i) => ContentPostCard(
                        post: posts[i],
                        showSectionLabel: section == ContentSections.allMakala ||
                            (category != null && ContentService.sharedCategories.contains(category)),
                        margin: EdgeInsets.zero,
                        animationIndex: i,
                        onTap: () => openContentPost(context, posts[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String? _sectionSubtitle(String section, String? category) {
    if (category != null && ContentService.sharedCategories.contains(category)) {
      return 'Makala zote za ${ContentSections.categoryLabel(category)} kutoka sehemu zote';
    }
    if (section == ContentSections.allMakala) {
      return 'Makala kutoka Dodoso, Chagua Mada, Vyakula na Jifunze';
    }
    return null;
  }

  String _sectionTitle(String section, String? category) {
    if (category != null) return ContentSections.categoryLabel(category);
    switch (section) {
      case ContentSections.dodoso: return 'Dodoso';
      case ContentSections.chaguaMada: return 'Chagua Mada';
      case ContentSections.vyakulaMatunda:
        return 'Vyakula na Matunda';
      case ContentSections.jifunze: return 'Jifunze';
      case ContentSections.allMakala: return 'Makala';
      default: return 'Maudhui';
    }
  }

  Widget _header(BuildContext context, String title, AppProvider app) {
    return ScreenHeader(
      title: title.toUpperCase(),
      onBack: app.goBack,
    );
  }
}

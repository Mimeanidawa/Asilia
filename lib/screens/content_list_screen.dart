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

    return SizedBox.expand(
      child: Column(
        children: [
          _header(context, title, app),
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
                                : Text('Hakuna maudhui bado', style: TextStyle(color: AppColors.gray400)),
                          ),
                        ),
                      ],
                    )
                  : ResponsiveContentList(
                      itemCount: posts.length,
                      mainAxisSpacing: 16,
                      itemBuilder: (context, i) => ContentPostCard(
                        post: posts[i],
                        showSectionLabel: section == ContentSections.allMakala,
                        margin: EdgeInsets.zero,
                        onTap: () => openContentPost(context, posts[i]),
                      ).animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.05),
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

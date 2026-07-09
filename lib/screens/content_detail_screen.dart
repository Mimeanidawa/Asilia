import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../providers/app_provider.dart';
import '../services/content_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_refresh.dart';
import '../utils/premium_content_flow.dart';
import '../widgets/premium_makala_gate.dart';
import '../widgets/pull_to_refresh.dart';
import '../widgets/rich_content_view.dart';
import '../widgets/fullscreen_image_viewer.dart';
import '../widgets/screen_header.dart';

class ContentDetailScreen extends StatefulWidget {
  const ContentDetailScreen({super.key});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  ContentPost? _post;
  bool _loading = true;
  bool _premiumModalShown = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final app = context.read<AppProvider>();
    final content = context.read<ContentService>();
    final user = context.read<UserService>();
    final id = app.selectedContentId;
    if (id == null) return;

    final post = await content.fetchPost(id, userToken: user.token);
    if (!mounted) return;

    setState(() {
      _post = post;
      _loading = false;
    });

    _maybeShowPremiumModal(post, user);
  }

  void _maybeShowPremiumModal(ContentPost? post, UserService user) {
    if (post == null || _premiumModalShown) return;
    if (!post.isPremium || user.canReadContent(post)) return;

    _premiumModalShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showPremiumMakalaModal(
        context,
        post: post,
        onUnlock: _purchase,
      );
    });
  }

  Future<void> _refresh() async {
    await AppRefresh.catalog(context);
    await _load();
  }

  Future<void> _purchase() async {
    final post = _post!;
    final ok = await purchasePremiumContent(
      context,
      post: post,
      onSuccess: _load,
    );
    if (ok && mounted) setState(() => _premiumModalShown = true);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = context.watch<UserService>();

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.forest));
    }

    if (_post == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Maudhui hayapatikani', style: TextStyle(color: AppColors.gray400)),
            TextButton(onPressed: app.goBack, child: const Text('Rudi')),
          ],
        ),
      );
    }

    final post = _post!;
    final canRead = user.canReadContent(post);

    return SizedBox.expand(
      child: Column(
        children: [
          _header(app),
          Expanded(
            child: PullToRefresh(
              onRefresh: _refresh,
              child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                if (post.imageUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => openFullscreenImage(context, post.imageUrl, caption: post.title),
                    child: CachedNetworkImage(
                      imageUrl: post.imageUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ).animate().fadeIn(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.category != null)
                        Text(
                          post.categoryLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppColors.emerald800,
                            letterSpacing: 1,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.forest,
                          height: 1.2,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 8),
                      Text(
                        '${post.readTimeLabel} • ${post.subtitle}',
                        style: TextStyle(fontSize: 12, color: AppColors.gray400),
                      ),
                      const SizedBox(height: 20),
                      if (post.isPremium && !canRead)
                        PremiumMakalaGate(
                          post: post,
                          onUnlock: _purchase,
                        )
                      else
                        RichContentView(content: post.content).animate().fadeIn(delay: 200.ms),
                    ],
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

  Widget _header(AppProvider app) {
    return ScreenHeader(
      title: 'SOMA ZAIDI',
      onBack: app.goBack,
    );
  }
}

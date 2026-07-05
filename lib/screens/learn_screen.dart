import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/content_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_refresh.dart';
import '../widgets/herb_image.dart';
import '../widgets/pull_to_refresh.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String _selectedCat = 'Zote';
  ContentPost? _activePost;

  static const _categories = [
    'Zote',
    'Matunda',
    'Mizizi',
    'Miti',
    'Mimea',
    'Vyakula',
  ];

  static const _catKeys = {
    'Matunda': 'matunda',
    'Mizizi': 'mizizi',
    'Miti': 'miti',
    'Mimea': 'mimea',
    'Vyakula': 'vyakula',
  };

  List<ContentPost> _filtered(ContentService content) {
    if (_selectedCat == 'Zote') return content.jifunzePosts;
    final key = _catKeys[_selectedCat];
    return content.jifunzePosts.where((p) => p.category == key).toList();
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentService>();
    final user = context.watch<UserService>();
    final filtered = _filtered(content);

    if (_activePost != null) {
      return _ArticleReader(
        post: _activePost!,
        user: user,
        onClose: () => setState(() => _activePost = null),
        onRefresh: () async {
          await AppRefresh.catalog(context);
          final full = await content.fetchPost(_activePost!.id, userToken: user.token);
          if (full != null && mounted) setState(() => _activePost = full);
        },
        onPurchase: () async {
          if (!user.isLoggedIn) {
            context.read<AppProvider>().navigate(AppScreen.auth);
            return;
          }
          final ok = await user.purchaseContent(_activePost!.id);
          if (ok && mounted) {
            final full = await content.fetchPost(_activePost!.id, userToken: user.token);
            if (full != null) setState(() => _activePost = full);
          }
        },
      );
    }

    final featured = filtered.isNotEmpty ? filtered.first : null;

    return SizedBox.expand(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            color: Colors.white,
            child: const Row(
              children: [
                Icon(Icons.menu_book, color: AppColors.emerald800, size: 20),
                SizedBox(width: 8),
                Text(
                  'JIFUNZE',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.forest),
                ),
              ],
            ),
          ),
          Container(
            height: 52,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: _categories.map((cat) {
                final selected = _selectedCat == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : AppColors.forest,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCat = cat),
                    backgroundColor: AppColors.emerald50.withValues(alpha: 0.5),
                    selectedColor: AppColors.forest,
                    showCheckmark: false,
                    side: BorderSide(color: AppColors.forest.withValues(alpha: 0.1)),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: content.jifunzePosts.isEmpty
                ? PullToRefresh(
                    onRefresh: () => AppRefresh.catalog(context),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.45,
                          child: Center(
                            child: content.isLoading
                                ? const CircularProgressIndicator(color: AppColors.forest)
                                : Text('Hakuna makala bado', style: TextStyle(color: AppColors.gray400)),
                          ),
                        ),
                      ],
                    ),
                  )
                : PullToRefresh(
                    onRefresh: () => AppRefresh.catalog(context),
                    child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          'Maktaba ya Maarifa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                      Text(
                        '  Makala za kina kuhusu matunda, mizizi, miti, mimea na vyakula',
                        style: TextStyle(fontSize: 12, color: AppColors.gray500),
                      ),
                      if (_selectedCat == 'Zote' && featured != null) ...[
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: _FeaturedCard(
                            post: featured,
                            onRead: () => _openPost(featured, user),
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: Text(
                          '${filtered.length} makala zinapatikana',
                          style: TextStyle(fontSize: 11, color: AppColors.gray400, fontWeight: FontWeight.w700),
                        ),
                      ),
                      ...filtered.map(
                        (post) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: _ArticleTile(
                            post: post,
                            onTap: () => _openPost(post, user),
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

  void _openPost(ContentPost post, UserService user) {
    if (!user.isLoggedIn) {
      context.read<AppProvider>().navigate(AppScreen.auth);
      return;
    }
    setState(() => _activePost = post);
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.post, required this.onRead});

  final ContentPost post;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onRead,
        child: Stack(
          children: [
            if (post.imageUrl.isNotEmpty)
              HerbImage(url: post.imageUrl, height: 200, borderRadius: 20),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.isPremium)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'PREMIUM TZS ${post.price}',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  Text(
                    post.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({required this.post, required this.onTap});

  final ContentPost post;
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (post.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (post.isPremium)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'TZS ${post.price}',
                              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.amber),
                            ),
                          ),
                        Text(
                          post.categoryLabel,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.emerald800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.forest),
                    ),
                    Text(
                      '${post.readTimeLabel} • ${post.excerpt}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleReader extends StatelessWidget {
  const _ArticleReader({
    required this.post,
    required this.user,
    required this.onClose,
    required this.onRefresh,
    required this.onPurchase,
  });

  final ContentPost post;
  final UserService user;
  final VoidCallback onClose;
  final Future<void> Function() onRefresh;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final canRead = !post.isPremium || user.canReadContent(post);

    return SizedBox.expand(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.forest, size: 18),
                ),
                Expanded(
                  child: Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.forest),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PullToRefresh(
              onRefresh: onRefresh,
              child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                if (post.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(imageUrl: post.imageUrl, height: 200, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 16),
                if (canRead)
                  Text(post.content, style: TextStyle(fontSize: 14, color: AppColors.gray600, height: 1.7))
                else ...[
                  Text(post.excerpt, style: TextStyle(fontSize: 14, color: AppColors.gray600, height: 1.7)),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: onPurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      ),
                      child: Text('Lipia TZS ${post.price}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}

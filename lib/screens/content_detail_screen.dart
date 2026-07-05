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
import '../utils/tzs_format.dart';
import '../services/payment_service.dart';
import '../widgets/pull_to_refresh.dart';
import '../widgets/sonicpesa_payment_sheet.dart';
import '../widgets/rich_content_view.dart';
import '../widgets/fullscreen_image_viewer.dart';

class ContentDetailScreen extends StatefulWidget {
  const ContentDetailScreen({super.key});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  ContentPost? _post;
  bool _loading = true;

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
    if (mounted) {
      setState(() {
        _post = post;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await AppRefresh.catalog(context);
    await _load();
  }

  Future<void> _purchase() async {
    final user = context.read<UserService>();
    if (!user.isLoggedIn) {
      context.read<AppProvider>().navigate(AppScreen.auth);
      return;
    }
    final post = _post!;
    final result = await showSonicPesaPayment(
      context,
      type: PaymentType.content,
      title: post.title,
      subtitle: 'Makala ya Premium — ufunguo wa milele kwa makala hii',
      amount: post.price,
      contentId: post.id,
    );
    if (result == SonicPesaPaymentResult.success && mounted) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Malipo yamekamilika! Sasa unaweza kusoma makala kamili.'),
          backgroundColor: AppColors.forest,
        ),
      );
    }
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
    final canRead = !post.isPremium
        ? user.isLoggedIn
        : user.canReadContent(post);

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
                      if (!user.isLoggedIn && !post.isPremium)
                        _loginPrompt(context)
                      else if (post.isPremium && !canRead)
                        _premiumPrompt(context, post)
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
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: app.goBack,
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.forest, size: 18),
          ),
          const Text(
            'SOMA ZAIDI',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.forest),
          ),
        ],
      ),
    );
  }

  Widget _loginPrompt(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.emerald50, Colors.white]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.forest, size: 36),
          const SizedBox(height: 12),
          const Text(
            'Jiunge ili kusoma makala kamili',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.forest),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<AppProvider>().navigate(AppScreen.auth),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Jiunge Sasa', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _premiumPrompt(BuildContext context, ContentPost post) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.amber.withValues(alpha: 0.1), Colors.white]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star_rounded, color: AppColors.amber, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Makala ya Premium',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.forest),
                    ),
                    Text(
                      'Lipia mara moja, soma milele',
                      style: TextStyle(fontSize: 11, color: AppColors.gray500, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.excerpt,
            style: TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_rounded, color: AppColors.emerald800, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bei: ${TzsFormat.full(post.price)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.forest),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _purchase,
            icon: const Icon(Icons.lock_open_rounded, size: 18),
            label: Text('Fungua kwa ${TzsFormat.full(post.price)}', style: const TextStyle(fontWeight: FontWeight.w900)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Malipo salama kupitia SonicPesa • M-Pesa, Tigo, Airtel, HaloPesa',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: AppColors.gray400, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

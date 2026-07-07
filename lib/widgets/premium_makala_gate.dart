import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../utils/tzs_format.dart';

/// Pro-level paywall for premium makala — inline card or modal sheet.
class PremiumMakalaGate extends StatelessWidget {
  const PremiumMakalaGate({
    super.key,
    required this.post,
    required this.onUnlock,
    this.showExcerptPreview = true,
  });

  final ContentPost post;
  final VoidCallback onUnlock;
  final bool showExcerptPreview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showExcerptPreview && post.excerpt.isNotEmpty) ...[
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.transparent],
              stops: [0.35, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: Text(
              post.excerpt,
              maxLines: 5,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.gray600,
                height: 1.65,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        _PremiumUnlockCard(post: post, onUnlock: onUnlock),
      ],
    );
  }
}

/// Shows a modern bottom-sheet modal for premium makala unlock.
Future<void> showPremiumMakalaModal(
  BuildContext context, {
  required ContentPost post,
  required VoidCallback onUnlock,
  VoidCallback? onSignUp,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => _PremiumMakalaSheet(
      post: post,
      onUnlock: onUnlock,
      onSignUp: onSignUp,
    ),
  );
}

class _PremiumMakalaSheet extends StatelessWidget {
  const _PremiumMakalaSheet({
    required this.post,
    required this.onUnlock,
    this.onSignUp,
  });

  final ContentPost post;
  final VoidCallback onUnlock;
  final VoidCallback? onSignUp;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  _PremiumUnlockCard(
                    post: post,
                    onUnlock: () {
                      Navigator.pop(context);
                      onUnlock();
                    },
                    compact: false,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (onSignUp != null) {
                            onSignUp!();
                          } else {
                            context.read<AppProvider>().navigate(AppScreen.auth);
                          }
                        },
                        child: const Text(
                          'Jiunge / Jisajili',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                      Text(
                        '·',
                        style: TextStyle(color: AppColors.gray400.withValues(alpha: 0.8)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Labda baadaye',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray500,
                          ),
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

class _PremiumUnlockCard extends StatelessWidget {
  const _PremiumUnlockCard({
    required this.post,
    required this.onUnlock,
    this.compact = true,
  });

  final ContentPost post;
  final VoidCallback onUnlock;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C2E1F), Color(0xFF113121), Color(0xFF1A4030)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.amber.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 22 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.amber.withValues(alpha: 0.95),
                              const Color(0xFFC9A227),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 5),
                            Text(
                              'PREMIUM',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Saidia Matabibu Wetu',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Lipa kwa makala hii tu — makala nyingine za Premium zinahitaji malipo yao pekee.',
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      color: Colors.white.withValues(alpha: 0.72),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Msaada wako unawasaidia wataalamu wetu kuendelea kutuletea makala bora zaidi za dawa asili — yenye utafiti, uzoefu na uangalifu.',
                    style: TextStyle(
                      fontSize: compact ? 13 : 14,
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soma makala kamili',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              TzsFormat.full(post.price),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFF5D78E),
                                height: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 6, bottom: 3),
                              child: Text(
                                'kwa makala hii',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ..._benefits.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.emerald400.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: AppColors.emerald400,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              b,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.amber.withValues(alpha: 0.95),
                            const Color(0xFFC9A227),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.amber.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onUnlock,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_open_rounded, color: AppColors.forest, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Fungua Makala — ${TzsFormat.full(post.price)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.forest,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_rounded, size: 13, color: Colors.white.withValues(alpha: 0.45)),
                      const SizedBox(width: 6),
                      Text(
                        'Malipo salama • SonicPesa • M-Pesa, Tigo, Airtel',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.45),
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

  static const _benefits = [
    'Itafunguliwa moja kwa moja — makala hii pekee',
    'Piga gumzo na mtabibu kuhusu makala hii',
    'Msaada wako unawasaidia matabibu wetu kuendelea',
  ];
}

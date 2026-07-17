import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/payment_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_makala_gate.dart';
import '../widgets/sonicpesa_payment_sheet.dart';

String premiumContentPaymentSubtitle(ContentPost post) =>
    'Msaada kwa matabibu wetu — itafunguliwa moja kwa moja: ${post.title}';

bool needsPremiumUnlock(UserService user, ContentPost post) =>
    post.isPremium && !user.canReadContent(post);

/// Opens a post — shows premium modal when locked, otherwise navigates to detail.
Future<void> openContentPost(BuildContext context, ContentPost post) async {
  final app = context.read<AppProvider>();
  final user = context.read<UserService>();

  if (!post.isPremium) {
    app.navigate(AppScreen.contentDetail, contentId: post.id);
    return;
  }

  if (user.canReadContent(post)) {
    app.navigate(AppScreen.contentDetail, contentId: post.id);
    return;
  }

  await showPremiumMakalaModal(
    context,
    post: post,
    onUnlock: () => purchasePremiumContent(
      context,
      post: post,
      onSuccess: () =>
          app.navigate(AppScreen.contentDetail, contentId: post.id),
    ),
    onSignUp: () => app.navigate(AppScreen.auth),
  );
}

/// Shows premium modal for inline readers (e.g. Jifunze) without route change.
Future<void> showPremiumUnlockForPost(
  BuildContext context, {
  required ContentPost post,
  required VoidCallback onUnlocked,
}) async {
  final user = context.read<UserService>();
  final app = context.read<AppProvider>();

  if (!needsPremiumUnlock(user, post)) {
    onUnlocked();
    return;
  }

  await showPremiumMakalaModal(
    context,
    post: post,
    onUnlock: () =>
        purchasePremiumContent(context, post: post, onSuccess: onUnlocked),
    onSignUp: () => app.navigate(AppScreen.auth),
  );
}

/// Runs Aurax Pay for a single premium makala (unlocks that item only).
Future<bool> purchasePremiumContent(
  BuildContext context, {
  required ContentPost post,
  VoidCallback? onSuccess,
}) async {
  final user = context.read<UserService>();
  final app = context.read<AppProvider>();

  if (!user.isLoggedIn) {
    app.navigate(AppScreen.auth);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Jisajili kwanza, kisha urudi kulipa na kusoma makala hii.',
          ),
          backgroundColor: AppColors.forest,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }

  final result = await showAuraxPayment(
    context,
    type: PaymentType.content,
    title: post.title,
    subtitle: premiumContentPaymentSubtitle(post),
    amount: post.price,
    contentId: post.id,
  );

  if (result != AuraxPaymentResult.success || !context.mounted) return false;

  await user.refreshProfile();
  onSuccess?.call();

  if (!context.mounted) return true;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text(
        'Makala imefunguliwa moja kwa moja! Unaweza pia kuuliza mtabibu kuhusu hii.',
      ),
      backgroundColor: AppColors.forest,
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Uliza Mtabibu',
        textColor: AppColors.cream,
        onPressed: () => app.navigate(AppScreen.askExpert),
      ),
    ),
  );

  return true;
}

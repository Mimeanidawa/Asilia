import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/mwalimu_service.dart';
import '../services/payment_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_refresh.dart';
import '../utils/tzs_format.dart';
import '../widgets/sonicpesa_payment_sheet.dart';

/// Opens Premium payment to remove all ads and unlock features.
Future<bool> openRemoveAdsPayment(BuildContext context) async {
  final user = context.read<UserService>();
  if (user.isLoggedIn && user.user?.isPremiumActive == true) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Premium tayari imeamilishwa — hakuna matangazo.'),
          backgroundColor: AppColors.forest,
        ),
      );
    }
    return false;
  }

  final mwalimu = context.read<MwalimuService>();
  await mwalimu.loadSettings();
  if (!context.mounted) return false;

  final price = mwalimu.settings.premiumPrice;
  final result = await showAuraxPayment(
    context,
    type: PaymentType.premium,
    title: 'Ondoa Matangazo Yote',
    subtitle:
        'Premium — hakuna matangazo, makala zote zilizofungwa, na mazungumzo bila kikomo na Mwalimu (siku 30).',
    amount: price,
  );

  if (result == AuraxPaymentResult.success && context.mounted) {
    await AppRefresh.afterPremiumPurchase(context);
    if (!context.mounted) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Asante! Matangazo yameondolewa na Premium imeamilishwa kwa ${TzsFormat.full(price)}.',
        ),
        backgroundColor: AppColors.forest,
      ),
    );
    return true;
  }
  return false;
}

/// Navigates to profile tab where payment options live.
void navigateToProfilePayments(BuildContext context) {
  context.read<AppProvider>().navigate(AppScreen.profile);
}

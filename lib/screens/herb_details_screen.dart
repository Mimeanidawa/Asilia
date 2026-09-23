import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/app_refresh.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/herb_image.dart';
import '../widgets/makala_ads.dart';
import '../services/dawa_order_service.dart';
import '../widgets/order_product_sheet.dart';
import '../widgets/pull_to_refresh.dart';
import '../widgets/screen_header.dart';

class HerbDetailsScreen extends StatelessWidget {
  const HerbDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final herb = app.selectedHerbId != null ? herbById(app.selectedHerbId!) : null;

    if (herb == null) {
      return SizedBox.expand(
        child: Column(
          children: [
            ScreenHeader(
              title: 'MAELEZO',
              onBack: app.goBack,
            ),
            Expanded(
              child: PullToRefresh(
                onRefresh: () => AppRefresh.catalog(context),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.45,
                      child: Center(
                        child: Text(
                          'Maudhui hayapatikani',
                          style: TextStyle(color: AppColors.gray400, fontSize: 14),
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

    final favorited = app.isFavorite(herb.id);

    return SizedBox.expand(
      child: Column(
      children: [
        ScreenHeader(
          title: 'MAELEZO YA MMEA',
          onBack: app.goBack,
          trailing: IconButton(
            icon: Icon(
              favorited ? Icons.favorite : Icons.favorite_border,
              color: favorited ? AppColors.red600 : AppColors.forest,
            ),
            onPressed: () => app.toggleFavorite(herb.id),
          ),
        ),
        Expanded(
          child: PullToRefresh(
            onRefresh: () => AppRefresh.catalog(context),
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Stack(
                children: [
                  HerbImage(
                    url: herb.imageUrl,
                    height: 220,
                    borderRadius: 0,
                  ),
                  Positioned(
                    bottom: 12,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.forest,
                        borderRadius: BorderRadius.circular(AppColors.radiusSm),
                      ),
                      child: const Text(
                        '100% ASILI',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            herb.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                        if (herb.localName != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emerald50,
                              borderRadius: BorderRadius.circular(AppColors.radiusSm),
                              border: Border.all(
                                color: AppColors.forest.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              herb.localName!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.forest,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      herb.scientificName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'MATUMIZI MAKUU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: herb.usedFor.map((use) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(AppColors.radiusSm),
                            border: Border.all(
                              color: AppColors.borderLight,
                            ),
                            boxShadow: AppColors.elevationSm,
                          ),
                          child: Text(
                            use,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.forest,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'KUHUSU MMEA HUU',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      herb.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'FAIDA ZA KIAFYA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...herb.benefits.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.check_circle,
                                size: 16,
                                color: AppColors.forest,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                b,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppColors.radiusMd),
                        border: Border.all(
                          color: AppColors.borderLight,
                        ),
                        boxShadow: AppColors.elevationSm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.science, size: 16, color: AppColors.forest),
                              SizedBox(width: 8),
                              Text(
                                'JINSI YA KUTUMIA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.forest,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            herb.howToUse,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const MakalaInlineBannerAd(),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.orange50,
                        borderRadius: BorderRadius.circular(AppColors.radiusMd),
                        border: Border.all(color: AppColors.orange200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Tahadhari: Mimea ya asili ina nguvu kubwa ya kibaolojia. Inashauriwa kuanza na kiasi kidogo ili kuona jinsi mwili unavyopokea, na kufuata mwongozo sahihi.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final product = context.read<DawaOrderService>().getProductForHerb(herb.name);
                        OrderProductSheet.show(context, product);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.emerald50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.emerald800.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.emerald800),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Agiza Dawa Asili ya ${herb.name} (Punguzo 50%)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.emerald800,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.emerald800),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => app.navigate(AppScreen.conditions),
                        icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.amber),
                        label: Text(
                          'Tazama Hali za Afya na Tiba Zaidi',
                          style: TextStyle(
                            fontSize: AppTypography.button,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppColors.radiusPill),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
        const MakalaBannerAd(),
        const AppBottomNav(),
      ],
    ),
    );
  }
}

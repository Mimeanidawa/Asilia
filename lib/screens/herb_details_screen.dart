import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../utils/app_refresh.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/herb_image.dart';
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
          title: 'HERB DETAILS',
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
                    height: 192,
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
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '100% NATURAL',
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
                              fontSize: 20,
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
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emerald100.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.forest.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Text(
                              herb.localName!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emerald900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      herb.scientificName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'USED FOR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gray400,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: herb.usedFor.map((use) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.forest.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            use,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.forest,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ABOUT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest.withValues(alpha: 0.5),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      herb.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'BENEFITS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gray400,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...herb.benefits.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppColors.emerald700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                b,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.forest,
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.forest.withValues(alpha: 0.04),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.science, size: 16, color: AppColors.amber),
                              SizedBox(width: 8),
                              Text(
                                'HOW TO USE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.amber,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            herb.howToUse,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.orange50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.orange200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '**Caution**: Herbal infusions are highly active naturally. Start with a smaller mug to check body compatibility. Consistently monitor symptoms.',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.gray500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => app.navigate(AppScreen.conditions),
                        icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.amber),
                        label: const Text(
                          'View More Remedies',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.forest,
                          foregroundColor: AppColors.cream,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
        const AppBottomNav(),
      ],
    ),
    );
  }
}

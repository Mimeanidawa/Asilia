import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/mwalimu_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/app_refresh.dart';
import '../utils/responsive.dart';
import '../widgets/condition_icon_widget.dart';
import '../widgets/herb_image.dart';
import '../widgets/makala_ads.dart';
import '../services/dawa_order_service.dart';
import '../widgets/order_product_sheet.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/pull_to_refresh.dart';

class ConditionsScreen extends StatefulWidget {
  const ConditionsScreen({super.key});

  @override
  State<ConditionsScreen> createState() => _ConditionsScreenState();
}

class _ConditionsScreenState extends State<ConditionsScreen> {
  String _search = '';
  Condition? _activeCondition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = context.read<AppProvider>().selectedConditionId;
      if (id != null) {
        setState(() => _activeCondition = conditionById(id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final q = _search.toLowerCase();

    final filtered = conditions.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.shortDesc.toLowerCase().contains(q) ||
          c.longDesc.toLowerCase().contains(q);
    }).toList();

    return SizedBox.expand(
      child: Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(AppColors.radiusSm),
                    ),
                    child: const Icon(Icons.monitor_heart_outlined, color: AppColors.forest, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Hali za Afya',
                    style: AppTypography.screen(
                      color: AppColors.forest,
                      size: AppTypography.screenTitle,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: AppColors.surfaceElevated,
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Tafuta hali ya afya au tatizo...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.forest,
                  ),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                    borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PullToRefresh(
                onRefresh: () => AppRefresh.catalog(context),
                child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  Responsive.scrollBottomPadding(context, extra: 8),
                ),
                children: [
                  const Text(
                    'VIPENGELE VYA KIAFYA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const HomeFeedBannerAd(),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            const Text(
                              'Hakuna vipengele vilivyolingana na utafutaji wako.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => setState(() => _search = ''),
                              child: const Text(
                                'Onyesha Zote',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.forest,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filtered.map(
                      (cond) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PressableScale(
                          onTap: () => setState(() => _activeCondition = cond),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(AppColors.radiusLg),
                              boxShadow: AppColors.elevationSm,
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.emerald50,
                                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                                    border: Border.all(
                                      color: AppColors.forest.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Center(
                                    child: ConditionIconWidget(type: cond.iconType),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cond.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.forest,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        cond.shortDesc,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.forest,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              ),
            ),
          ],
        ),
        if (_activeCondition != null)
          _ConditionSheet(
            condition: _activeCondition!,
            onClose: () => setState(() => _activeCondition = null),
            onHerbTap: (herbId) {
              setState(() => _activeCondition = null);
              app.navigate(AppScreen.herbDetails, herbId: herbId);
            },
            onAskExpert: () {
              setState(() => _activeCondition = null);
              app.navigate(AppScreen.askExpert);
            },
          ),
      ],
    ),
    );
  }
}

class _ConditionSheet extends StatelessWidget {
  const _ConditionSheet({
    required this.condition,
    required this.onClose,
    required this.onHerbTap,
    required this.onAskExpert,
  });

  final Condition condition;
  final VoidCallback onClose;
  final void Function(String herbId) onHerbTap;
  final VoidCallback onAskExpert;

  @override
  Widget build(BuildContext context) {
    final remedyHerbs = condition.remedies
        .map(herbById)
        .whereType<Herb>()
        .toList();
    final expertName = context.watch<MwalimuService>().displayName;

    return GestureDetector(
      onTap: onClose,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.4),
        child: GestureDetector(
          onTap: () {},
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppColors.radiusXl)),
                boxShadow: AppColors.elevationLg,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                shrinkWrap: true,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.emerald50,
                              borderRadius: BorderRadius.circular(AppColors.radiusMd),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Center(
                              child: ConditionIconWidget(type: condition.iconType),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                condition.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.forest,
                                ),
                              ),
                              const Text(
                                'UCHAMBUZI WA KINA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close, color: AppColors.forest),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MAELEZO NA UFAHAMU',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    condition.longDesc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () {
                      final product = context.read<DawaOrderService>().getProductForCondition(condition);
                      OrderProductSheet.show(context, product);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                              'Agiza Dawa ya ${condition.name} (Punguzo 50%)',
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
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: AppColors.amber),
                      SizedBox(width: 6),
                      Text(
                        'TIBA ASILI ZINAZOPENDEKEZWA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...remedyHerbs.map(
                    (herb) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PressableScale(
                        onTap: () => onHerbTap(herb.id),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(AppColors.radiusMd),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: AppColors.elevationSm,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              HerbImage(url: herb.imageUrl, width: 48, height: 48),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      herb.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.forest,
                                      ),
                                    ),
                                    Text(
                                      herb.scientificName,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.forest,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const MakalaInlineBannerAd(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onAskExpert,
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: Text(
                        'Jadili "${condition.name}" na $expertName',
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
          ),
        ),
      ),
    );
  }
}

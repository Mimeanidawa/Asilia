import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/condition_icon_widget.dart';
import '../widgets/herb_image.dart';

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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              color: Colors.white,
              child: const Row(
                children: [
                  Icon(Icons.monitor_heart_outlined, color: AppColors.emerald800, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'CONDITIONS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.forest,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search health conditions...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: AppColors.forest.withValues(alpha: 0.45),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.forest.withValues(alpha: 0.5),
                  ),
                  fillColor: AppColors.emerald50.withValues(alpha: 0.1),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  Text(
                    'TARGET HEALTH AREAS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gray400,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Text(
                              'No matched health categories found.',
                              style: TextStyle(color: AppColors.gray400),
                            ),
                            TextButton(
                              onPressed: () => setState(() => _search = ''),
                              child: const Text(
                                'Reset Filter',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.emerald800,
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
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => setState(() => _activeCondition = cond),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.emerald50.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(12),
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
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.forest,
                                          ),
                                        ),
                                        Text(
                                          cond.shortDesc,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.gray500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: AppColors.forest.withValues(alpha: 0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.emerald100,
                              borderRadius: BorderRadius.circular(12),
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
                              Text(
                                'CONDITION ANALYSIS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gray400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'HOLISTIC UNDERSTANDING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gray400,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    condition.longDesc,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray600,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: AppColors.amber),
                      SizedBox(width: 6),
                      Text(
                        'RECOMMENDED BOTANICAL REMEDIES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.emerald800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...remedyHerbs.map(
                    (herb) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onHerbTap(herb.id),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
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
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.forest,
                                        ),
                                      ),
                                      Text(
                                        herb.scientificName,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: AppColors.gray400,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.forest.withValues(alpha: 0.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAskExpert,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Discuss "${condition.name}" with Dr. Hassan',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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

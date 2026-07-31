import 'package:flutter/material.dart';

import '../utils/responsive.dart';

/// Single-column list on phones; multi-column grid on tablet and larger screens.
class ResponsiveContentList extends StatelessWidget {
  const ResponsiveContentList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 0),
    this.mainAxisSpacing = 14,
    this.crossAxisSpacing = 14,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsets padding;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.listColumns(context);
    final resolvedPadding = padding.copyWith(
      bottom: padding.bottom + Responsive.scrollBottomPadding(context, extra: 8),
    );

    if (columns == 1) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: resolvedPadding,
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(height: mainAxisSpacing),
        itemBuilder: itemBuilder,
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: resolvedPadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: 0.82,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

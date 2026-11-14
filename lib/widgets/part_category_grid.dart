import 'package:flutter/material.dart';

import '../models/part_category.dart';
import '../theme/app_theme.dart';

class PartCategoryGrid extends StatelessWidget {
  const PartCategoryGrid({
    required this.categories,
    required this.onCategorySelected,
    super.key,
  });

  final List<PartCategory> categories;
  final ValueChanged<PartCategory> onCategorySelected;

  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - _gap) / 2;
        // Two-column tiles; text space grows with the user's text size.
        final tileHeight =
            tileWidth * 0.78 + MediaQuery.textScalerOf(context).scale(52);

        Widget card(PartCategory category) =>
            _CategoryCard(category: category, onSelected: onCategorySelected);

        final rows = <Widget>[];
        for (var i = 0; i < categories.length; i += 2) {
          final hasPair = i + 1 < categories.length;
          rows.add(
            SizedBox(
              height: tileHeight,
              // An odd last tile spans the full row instead of leaving a gap.
              child: hasPair
                  ? Row(
                      children: [
                        Expanded(child: card(categories[i])),
                        const SizedBox(width: _gap),
                        Expanded(child: card(categories[i + 1])),
                      ],
                    )
                  : card(categories[i]),
            ),
          );
          if (i + 2 < categories.length) {
            rows.add(const SizedBox(height: _gap));
          }
        }
        return Column(children: rows);
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onSelected});

  final PartCategory category;
  final ValueChanged<PartCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onSelected(category),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Image.asset(
                  category.imageAsset,
                  cacheWidth: 420,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: AppType.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: AppType.caption,
                      ),
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

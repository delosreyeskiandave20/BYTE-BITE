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

  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - _gap) / 2;
        // Two-column tiles; text space grows with the user's text size.
        final tileHeight =
            tileWidth * 0.82 + MediaQuery.textScalerOf(context).scale(24);

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

  static const _radius = 18.0;

  @override
  Widget build(BuildContext context) {
    // Full-bleed photo with the name on a dark fade, so every card reads as
    // one picture instead of a photo stacked on a text box.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F22201E),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onSelected(category),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Ink.image(
                image: ResizeImage(AssetImage(category.imageAsset), width: 420),
                fit: BoxFit.cover,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00000000),
                      Color(0x14000000),
                      Color(0xD9161412),
                    ],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 11,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: AppType.cardTitle + 1,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            category.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xD9FFFFFF),
                              fontSize: AppType.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.ink,
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

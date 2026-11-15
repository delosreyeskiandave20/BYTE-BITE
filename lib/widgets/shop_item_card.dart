import 'package:flutter/material.dart';

import '../data/item_parts.dart';
import '../data/price_format.dart';
import '../models/shop.dart';
import '../theme/app_theme.dart';

/// "Fits: NMAX 155, Aerox 155 +3 more", or "Fits: All motorcycles".
String? fitsLine(ShopProduct product, {int show = 2}) {
  if (product.fitsAll) return 'Fits: All motorcycles';
  final models = product.motorcycles.map(motorcycleModel).toList();
  if (models.isEmpty) return null;
  final shown = models.take(show).join(', ');
  final more = models.length - show;
  return more > 0 ? 'Fits: $shown +$more more' : 'Fits: $shown';
}

/// Grey square shown when an item has no photo or its photo link broke.
class PhotoUnavailable extends StatelessWidget {
  const PhotoUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.noticeSoft,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_outlined, color: AppColors.faint),
          SizedBox(height: 6),
          Text(
            'Photo unavailable',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: AppType.micro,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The item's cover photo, or [PhotoUnavailable].
class ItemCover extends StatelessWidget {
  const ItemCover({required this.product, this.cacheWidth = 480, super.key});

  final ShopProduct product;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    if (!product.hasImage) return const PhotoUnavailable();
    return Image(
      image: ResizeImage(product.imageProvider, width: cacheWidth),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const PhotoUnavailable(),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// A green "✅ Fits your NMAX 155" badge.
class FitsYourBadge extends StatelessWidget {
  const FitsYourBadge({required this.motorcycle, super.key});

  final String motorcycle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '✅ Fits your ${motorcycleModel(motorcycle)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.success,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// A buyer-facing item card: large square cover, then name, price, tags,
/// what it fits and stock.
class ShopItemCard extends StatelessWidget {
  const ShopItemCard({
    required this.product,
    required this.onTap,
    this.myMotorcycle,
    super.key,
  });

  final ShopProduct product;
  final VoidCallback onTap;

  /// The buyer's motorcycle; shows a badge when the item fits it.
  final String? myMotorcycle;

  @override
  Widget build(BuildContext context) {
    final fits = fitsLine(product);
    final mine = myMotorcycle;
    return Material(
      key: ValueKey('item-card-${product.id}'),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(aspectRatio: 1, child: ItemCover(product: product)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.price > 0
                        ? formatPeso(product.price)
                        : 'Price not set',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _Tag(product.category),
                      if (product.condition.isNotEmpty)
                        _Tag(product.condition),
                    ],
                  ),
                  if (mine != null && product.fits(mine)) ...[
                    const SizedBox(height: 6),
                    FitsYourBadge(motorcycle: mine),
                  ],
                  if (fits != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      fits,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    product.isAvailable
                        ? '${product.quantity} in stock'
                        : 'Out of stock',
                    style: TextStyle(
                      color: product.isAvailable
                          ? AppColors.success
                          : AppColors.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
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

import 'package:flutter/material.dart';

import '../data/marketplace.dart';
import '../theme/app_theme.dart';

/// Bundled logo for [marketplace] (Shopee or Lazada).
String marketplaceLogoAsset(String marketplace) =>
    marketplace == Marketplaces.shopee
    ? 'assets/marketplaces/shopee.png'
    : 'assets/marketplaces/lazada.png';

/// The marketplace's logo, labelled for screen readers.
class MarketplaceLogo extends StatelessWidget {
  const MarketplaceLogo(this.marketplace, {this.height = 26, super.key});

  final String marketplace;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: marketplace,
      image: true,
      child: Image.asset(
        marketplaceLogoAsset(marketplace),
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => Text(
          marketplace,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

/// White button showing a marketplace logo, used wherever riders leave the
/// app to buy on Shopee or Lazada.
class MarketplaceLogoButton extends StatelessWidget {
  const MarketplaceLogoButton({
    required this.marketplace,
    required this.onPressed,
    super.key,
  });

  final String marketplace;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      key: ValueKey('marketplace-$marketplace'),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: MarketplaceLogo(marketplace),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new, size: 15, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
    // No visible "Search" word; screen readers still hear what it does.
    return Semantics(
      button: true,
      label: 'Search $marketplace',
      excludeSemantics: true,
      child: button,
    );
  }
}

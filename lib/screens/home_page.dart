import 'package:flutter/material.dart';

import '../data/design_catalog.dart';
import '../data/catalog_images.dart';
import '../data/home_catalog.dart';
import '../data/shop_store.dart';
import '../theme/app_theme.dart';
import '../widgets/buy_options_button.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/part_category_grid.dart';
import '../widgets/vehicle_lookup_card.dart';

class MotoScanHomePage extends StatefulWidget {
  const MotoScanHomePage({
    required this.onSearch,
    required this.onOwnerSignIn,
    required this.onCategorySelected,
    required this.onViewMotorcycles,
    required this.shopStore,
    this.scrollController,
    super.key,
  });

  final VoidCallback onSearch;
  final VoidCallback onOwnerSignIn;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback onViewMotorcycles;
  final ShopStore shopStore;

  /// Lets the shell scroll Home back to the top when the tab is re-selected.
  final ScrollController? scrollController;

  @override
  State<MotoScanHomePage> createState() => _MotoScanHomePageState();
}

class _MotoScanHomePageState extends State<MotoScanHomePage> {
  late final Future<Map<String, String>> _designImages = loadDesignImages();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: HomeAppBar(onSearch: widget.onSearch),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VehicleLookupCard(onViewMotorcycles: widget.onViewMotorcycles),
              const SizedBox(height: AppSpacing.xxl),
              const _SectionTitle('Browse parts'),
              const SizedBox(height: AppSpacing.md),
              PartCategoryGrid(
                categories: homeCategories,
                onCategorySelected: (category) =>
                    widget.onCategorySelected(category.id),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const _SectionTitle('Design ideas'),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Lighting, paint, decals and more. Swipe to see each group.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: AppType.caption + 1,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FutureBuilder<Map<String, String>>(
                future: _designImages,
                builder: (context, snapshot) => Column(
                  children: [
                    for (final group in designGroups)
                      _DesignGroupRow(
                        group: group,
                        images: snapshot.data ?? const {},
                        shopStore: widget.shopStore,
                        onOwnerSignIn: widget.onOwnerSignIn,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: AppType.section,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

/// One design group as a heading plus a sideways-scrolling row of cards, so
/// Home stays short instead of listing every design item vertically.
class _DesignGroupRow extends StatelessWidget {
  const _DesignGroupRow({
    required this.group,
    required this.images,
    required this.shopStore,
    required this.onOwnerSignIn,
  });

  final DesignGroup group;

  /// Bundled photos keyed by [designImageSlug].
  final Map<String, String> images;
  final ShopStore shopStore;
  final VoidCallback onOwnerSignIn;

  /// Shown on cards that have no photo yet, so each group looks distinct.
  static const _groupIcons = {
    'Lighting Designs': Icons.lightbulb_outline,
    'Stickers and Decals': Icons.sell_outlined,
    'Paint Designs': Icons.format_paint_outlined,
    'Vinyl Wrap Designs': Icons.layers_outlined,
    'Graphic and Pattern Designs': Icons.texture,
    'Seat Designs': Icons.event_seat_outlined,
    'Rim and Wheel Designs': Icons.trip_origin,
    'Mirror and Handlebar Designs': Icons.compare_arrows,
    'Decorative Designs': Icons.auto_awesome_outlined,
    'Windshield and Visor Designs': Icons.shield_outlined,
    'Motorcycle Style Themes': Icons.two_wheeler,
  };

  static const _cardWidth = 156.0;

  @override
  Widget build(BuildContext context) {
    // Card text grows with the user's text size, so the row grows with it.
    final textScaler = MediaQuery.textScalerOf(context);
    // Image (112) + up to two lines of name + Buy button + padding.
    final rowHeight = 114 + textScaler.scale(98);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  group.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: AppType.cardTitle + 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${group.items.length} options',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: AppType.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: rowHeight,
            child: ListView.separated(
              key: ValueKey('design-row-${group.title}'),
              // Let cards run to the screen edge so the row reads as
              // scrollable.
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              itemCount: group.items.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) => SizedBox(
                width: _cardWidth,
                child: _DesignItemCard(
                  item: group.items[index],
                  imageAsset: images[designImageSlug(group.items[index])],
                  fallbackIcon:
                      _groupIcons[group.title] ?? Icons.auto_awesome_outlined,
                  shopStore: shopStore,
                  onOwnerSignIn: onOwnerSignIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignItemCard extends StatelessWidget {
  const _DesignItemCard({
    required this.item,
    required this.imageAsset,
    required this.fallbackIcon,
    required this.shopStore,
    required this.onOwnerSignIn,
  });

  final String item;
  final String? imageAsset;
  final IconData fallbackIcon;
  final ShopStore shopStore;
  final VoidCallback onOwnerSignIn;

  @override
  Widget build(BuildContext context) {
    final imageAsset = this.imageAsset;
    final placeholder = ColoredBox(
      key: const ValueKey('design-image-placeholder'),
      color: AppColors.primarySoft,
      child: Icon(fallbackIcon, color: AppColors.primary, size: 30),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            key: ValueKey('design-image-$item'),
            height: 112,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.md - 1),
              ),
              child: imageAsset == null
                  // No photo yet: the group's icon, not a note to the owner.
                  ? placeholder
                  : ColoredBox(
                      color: Colors.white,
                      child: Image.asset(
                        imageAsset,
                        cacheWidth: 312,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) => placeholder,
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: AppType.body - 1,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                  BuyOptionsButton(
                    store: shopStore,
                    productQuery: item,
                    onOwnerSignIn: onOwnerSignIn,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

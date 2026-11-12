import 'package:flutter/material.dart';

import '../data/design_catalog.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: HomeAppBar(onSearch: widget.onSearch),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeSearchEntry(onTap: widget.onSearch),
              const SizedBox(height: 14),
              VehicleLookupCard(onViewMotorcycles: widget.onViewMotorcycles),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Text(
                      'Browse parts',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PartCategoryGrid(
                categories: homeCategories,
                onCategorySelected: (category) =>
                    widget.onCategorySelected(category.id),
              ),
              const SizedBox(height: 22),
              _DesignSection(
                shopStore: widget.shopStore,
                onOwnerSignIn: widget.onOwnerSignIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// In-body search entry for the Home tab. It navigates to [SearchPage] through
/// [onTap], matching the app-bar search shortcut without being a real field, so
/// typing always happens on the dedicated search screen.
class _HomeSearchEntry extends StatelessWidget {
  const _HomeSearchEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Search parts, brands, and shops',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          key: const ValueKey('home-search-entry'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.lineStrong),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.teal, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Search parts, brands, and shops',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: AppType.body,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tealSoft,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.tealBorder),
                  ),
                  child: const Text(
                    'Search',
                    style: TextStyle(
                      color: AppColors.teal,
                      fontSize: AppType.micro,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesignSection extends StatelessWidget {
  const _DesignSection({required this.shopStore, required this.onOwnerSignIn});

  final ShopStore shopStore;
  final VoidCallback onOwnerSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DISCOVER / VISUAL GUIDE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.25,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Design',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...designGroups.asMap().entries.map((entry) {
          final groupIndex = entry.key;
          final group = entry.value;
          return _DesignGroupCard(
            group: group,
            groupIndex: groupIndex,
            shopStore: shopStore,
            onOwnerSignIn: onOwnerSignIn,
          );
        }),
      ],
    );
  }
}

class _DesignGroupCard extends StatelessWidget {
  const _DesignGroupCard({
    required this.group,
    required this.groupIndex,
    required this.shopStore,
    required this.onOwnerSignIn,
  });

  final DesignGroup group;
  final int groupIndex;
  final ShopStore shopStore;
  final VoidCallback onOwnerSignIn;

  static const _imageColors = [
    Color(0xFFFCE7DA),
    Color(0xFFDDF2EE),
    Color(0xFFF7EBD1),
    Color(0xFFE3EAF6),
  ];
  static const _imageAssets = {
    'LED Headlight': 'assets/design/lighting_led_headlight.png',
    'LED Tail Light': 'assets/design/lighting_led_tail_light.png',
    'LED Signal Light': 'assets/design/lighting_led_signal_light.png',
    'LED Turn Signal': 'assets/design/lighting_led_turn_signal.png',
    'LED Daytime Running Light (DRL)': 'assets/design/lighting_led_drl.png',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.lineStrong, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF39342D).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE7DA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${groupIndex + 1}'.padLeft(2, '0'),
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${group.items.length} design options',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.paper,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Column(
              children: group.items.asMap().entries.map((entry) {
                final itemIndex = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: AppColors.tealBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DesignItemThumbnail(
                            key: ValueKey('design-image-$item'),
                            color:
                                _imageColors[itemIndex % _imageColors.length],
                            imageAsset: _imageAssets[item],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: const TextStyle(
                                          color: AppColors.ink,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: AppColors.teal,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '$item option. Browse visual references and check product measurements before buying.',
                                  key: ValueKey('design-description-$item'),
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                BuyOptionsButton(
                                  store: shopStore,
                                  productQuery: item,
                                  onOwnerSignIn: onOwnerSignIn,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignItemThumbnail extends StatelessWidget {
  const _DesignItemThumbnail({required this.color, this.imageAsset, super.key});

  final Color color;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    final image = imageAsset;

    // Fixed 92x112 tile for images, but the text-only placeholder grows with
    // the user's text scale instead of clipping its label.
    if (image != null) {
      return Container(
        width: 92,
        height: 112,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Image.asset(
          image,
          width: 92,
          height: 112,
          cacheWidth: 184,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 92,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 23, color: color),
          const SizedBox(height: 6),
          const Text(
            'Add an image to this choice',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

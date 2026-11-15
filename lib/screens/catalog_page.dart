import 'package:flutter/material.dart';

import '../data/accessories_maintenance_catalog.dart';
import '../data/catalog_images.dart';
import '../data/shop_store.dart';
import '../theme/app_theme.dart';
import '../widgets/buy_options_button.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    required this.type,
    this.shopStore,
    this.onOwnerSignIn,
    super.key,
  });

  final String type;
  final ShopStore? shopStore;
  final VoidCallback? onOwnerSignIn;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late final _shopStore = widget.shopStore ?? ShopStore.shared;
  String? _expandedGroup;

  /// Bundled photos keyed by [maintenanceImageSlug] or [accessoryImageSlug].
  Map<String, String> _photos = const {};

  bool get _isMaintenance => widget.type == 'maintenance';

  @override
  void initState() {
    super.initState();
    (_isMaintenance ? loadMaintenanceImages() : loadAccessoryImages()).then((
      photos,
    ) {
      if (mounted) setState(() => _photos = photos);
    });
  }

  List<CatalogGroup> get _groups =>
      _isMaintenance ? maintenanceGroups : accessoryGroups;

  /// The group whose choices are shown; the first one until another is picked.
  CatalogGroup get _selectedGroup => _groups.firstWhere(
    (group) => group.title == _expandedGroup,
    orElse: () => _groups.first,
  );

  @override
  Widget build(BuildContext context) {
    final title = _isMaintenance ? 'Maintenance' : 'Accessories';

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to home',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(title),
      ),
      // The group row stays put; only the choices below it scroll, so another
      // group is always one tap away.
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 0, 12),
            decoration: const BoxDecoration(
              color: AppColors.paper,
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: SingleChildScrollView(
              key: const ValueKey('catalog-group-row'),
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (final group in _groups)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        key: ValueKey('catalog-group-${group.title}'),
                        label: Text(group.title),
                        selected: group == _selectedGroup,
                        onSelected: (_) =>
                            setState(() => _expandedGroup = group.title),
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        side: BorderSide(
                          color: group == _selectedGroup
                              ? AppColors.primary
                              : AppColors.line,
                        ),
                        labelStyle: TextStyle(
                          color: group == _selectedGroup
                              ? Colors.white
                              : AppColors.inkSoft,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              key: const ValueKey('catalog-choice-list'),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _CatalogGroupCard(
                  key: ValueKey('catalog-group-card-${_selectedGroup.title}'),
                  group: _selectedGroup,
                  index: _groups.indexOf(_selectedGroup),
                  expanded: true,
                  showHeader: false,
                  isMaintenance: _isMaintenance,
                  photos: _photos,
                  shopStore: _shopStore,
                  onOwnerSignIn: widget.onOwnerSignIn,
                  onToggle: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogGroupCard extends StatelessWidget {
  const _CatalogGroupCard({
    super.key,
    this.showHeader = true,
    required this.group,
    required this.index,
    required this.expanded,
    required this.isMaintenance,
    required this.photos,
    required this.shopStore,
    required this.onOwnerSignIn,
    required this.onToggle,
  });

  final CatalogGroup group;
  final int index;
  final bool expanded;

  /// False when a chip row above already names the group.
  final bool showHeader;
  final bool isMaintenance;

  /// Bundled photos keyed by [maintenanceImageSlug] or [accessoryImageSlug].
  final Map<String, String> photos;
  final ShopStore shopStore;

  /// Shown on maintenance choices that have no photo yet, so each group
  /// looks distinct.
  static const _maintenanceIcons = {
    'Engine Oil': Icons.oil_barrel_outlined,
    'Oil Filter or Oil Strainer': Icons.filter_alt_outlined,
    'Gear Oil or Final-Drive Oil': Icons.settings_outlined,
    'Air Filter': Icons.air,
    'Spark Plug': Icons.bolt,
    'Coolant': Icons.ac_unit,
    'Brake Fluid': Icons.water_drop_outlined,
    'Brake Pads and Brake Shoes': Icons.album_outlined,
    'Drive Chain': Icons.link,
    'Sprockets': Icons.settings_suggest_outlined,
    'Chain Lubricant': Icons.opacity,
    'Scooter CVT Parts': Icons.moped_outlined,
    'Tires': Icons.tire_repair,
    'Battery': Icons.battery_charging_full,
    'Fork and Suspension Items': Icons.height,
    'Fuel-System Cleaners': Icons.local_gas_station_outlined,
    'Electrical Maintenance Items': Icons.electrical_services,
    'Grease and Protective Chemicals': Icons.science_outlined,
    'Cleaning Products': Icons.cleaning_services_outlined,
    'Electric Motorcycle Maintenance Items': Icons.ev_station_outlined,
  };

  /// Choice details with bundled photos filled in where the catalog has none.
  Map<String, CatalogChoiceDetails> _detailsWithPhotos(List<String> choices) {
    final base = isMaintenance
        ? maintenanceChoiceDetailsByGroup[group.title] ??
              const <String, CatalogChoiceDetails>{}
        : accessoryChoiceDetailsByGroup[group.title] ??
              const <String, CatalogChoiceDetails>{};
    if (photos.isEmpty) return base;

    return {
      for (final choice in choices)
        choice: () {
          final details = base[choice];
          final photo =
              photos[isMaintenance
                  ? maintenanceImageSlug(group.title, choice)
                  : accessoryImageSlug(group.title, choice)];
          if (photo == null || details?.imageAsset?.isNotEmpty == true) {
            return details ?? const CatalogChoiceDetails();
          }
          return CatalogChoiceDetails(
            description: details?.description,
            imageAsset: photo,
            imageUrl: details?.imageUrl,
          );
        }(),
    };
  }

  final VoidCallback? onOwnerSignIn;
  final VoidCallback onToggle;

  static const _itemColors = [
    Color(0xFFFCE7DA),
    AppColors.primarySoft,
    AppColors.warningSoft,
    Color(0xFFE3EAF6),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expanded && showHeader ? AppColors.primary : AppColors.line,
          width: expanded && showHeader ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (showHeader)
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(11),
                child: Row(
                  children: [
                    Container(
                      width: 37,
                      height: 37,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${index + 1}'.padLeft(2, '0'),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
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
                            '${(group.itemChoices[group.title] ?? group.items).length} choices',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.expand_more,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      border: showHeader
                          ? const Border(top: BorderSide(color: AppColors.line))
                          : null,
                    ),
                    child: group.itemChoices.containsKey(group.title)
                        ? _MaintenanceChoiceList(
                            choices: group.itemChoices[group.title]!,
                            shopStore: shopStore,
                            onOwnerSignIn: onOwnerSignIn,
                            details: _detailsWithPhotos(
                              group.itemChoices[group.title]!,
                            ),
                            fallbackIcon:
                                (isMaintenance
                                    ? _maintenanceIcons[group.title]
                                    : null) ??
                                Icons.image_outlined,
                          )
                        : Column(
                            children: group.items
                                .asMap()
                                .entries
                                .map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _CatalogItemThumbnail(
                                            color:
                                                _itemColors[entry.key %
                                                    _itemColors.length],
                                            icon: Icons.extension,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                width: 19,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2,
                                                      ),
                                                  child: Text(
                                                    '${entry.key + 1}',
                                                    style: const TextStyle(
                                                      color: AppColors.primary,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  entry.value,
                                                  style: const TextStyle(
                                                    color: AppColors.inkSoft,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 19,
                                            ),
                                            child: Text(
                                              'Browse ${entry.value.toLowerCase()} options, product details, and seller availability.',
                                              style: const TextStyle(
                                                color: AppColors.muted,
                                                fontSize: 11,
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          BuyOptionsButton(
                                            store: shopStore,
                                            productQuery: entry.value,
                                            onOwnerSignIn: onOwnerSignIn,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _CatalogItemThumbnail extends StatelessWidget {
  const _CatalogItemThumbnail({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 112,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: Icon(icon, size: 42, color: AppColors.primary)),
    );
  }
}

class _MaintenanceChoiceList extends StatelessWidget {
  const _MaintenanceChoiceList({
    required this.choices,
    required this.details,
    required this.fallbackIcon,
    required this.shopStore,
    required this.onOwnerSignIn,
  });

  final List<String> choices;
  final Map<String, CatalogChoiceDetails> details;
  final IconData fallbackIcon;
  final ShopStore shopStore;
  final VoidCallback? onOwnerSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AVAILABLE CHOICES',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 7),
        ...choices.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MaintenanceChoiceCard(
              name: entry.value,
              details: details[entry.value] ?? const CatalogChoiceDetails(),
              fallbackIcon: fallbackIcon,
              shopStore: shopStore,
              onOwnerSignIn: onOwnerSignIn,
            ),
          ),
        ),
      ],
    );
  }
}

class _MaintenanceChoiceCard extends StatelessWidget {
  const _MaintenanceChoiceCard({
    required this.name,
    required this.details,
    required this.fallbackIcon,
    required this.shopStore,
    required this.onOwnerSignIn,
  });

  final String name;
  final CatalogChoiceDetails details;
  final IconData fallbackIcon;
  final ShopStore shopStore;
  final VoidCallback? onOwnerSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('catalog-choice-$name'),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MaintenanceChoiceImage(details: details, fallbackIcon: fallbackIcon),
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
                        name,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 19,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  details.description?.trim().isNotEmpty == true
                      ? details.description!
                      : '$name option. Check the product specifications '
                            'before buying.',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                BuyOptionsButton(
                  store: shopStore,
                  productQuery: name,
                  onOwnerSignIn: onOwnerSignIn,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceChoiceImage extends StatelessWidget {
  const _MaintenanceChoiceImage({
    required this.details,
    required this.fallbackIcon,
  });

  final CatalogChoiceDetails details;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final imageAsset = details.imageAsset;
    final imageUrl = details.imageUrl;
    if (imageAsset != null && imageAsset.isNotEmpty) {
      return ColoredBox(
        color: Colors.white,
        child: Image.asset(
          imageAsset,
          width: 96,
          height: 126,
          cacheWidth: 192,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        ),
      );
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ColoredBox(
        color: Colors.white,
        child: Image.network(
          imageUrl,
          width: 96,
          height: 126,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  /// Shown when a choice has no photo yet. Shoppers see a quiet icon tile,
  /// not a note meant for whoever maintains the catalog.
  Widget _placeholder() {
    return Container(
      key: const ValueKey('choice-image-placeholder'),
      width: 96,
      height: 126,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(fallbackIcon, size: 28, color: AppColors.primary),
    );
  }
}

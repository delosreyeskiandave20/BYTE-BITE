import 'package:flutter/material.dart';

import '../data/shop_store.dart';
import '../data/vehicle_images.dart';
import '../data/motorcycle_specs.dart';
import '../data/part_descriptions.dart';
import '../data/vehicle_parts_catalog.dart';
import 'shop_page.dart';
import '../theme/app_theme.dart';
import '../widgets/zoomable_image.dart';

class MotorcyclePartsCatalogPage extends StatefulWidget {
  const MotorcyclePartsCatalogPage({
    this.catalogOverride,
    this.initialCategory,
    this.shopStore,
    this.onOwnerSignIn,
    super.key,
  });

  final Future<List<VehiclePartsVariant>>? catalogOverride;
  final String? initialCategory;
  final ShopStore? shopStore;
  final VoidCallback? onOwnerSignIn;

  @override
  State<MotorcyclePartsCatalogPage> createState() =>
      _MotorcyclePartsCatalogPageState();
}

class _MotorcyclePartsCatalogPageState
    extends State<MotorcyclePartsCatalogPage> {
  late final _shopStore = widget.shopStore ?? ShopStore.shared;
  late final Future<List<VehiclePartsVariant>> _catalogFuture =
      widget.catalogOverride ?? loadVehiclePartsCatalog();
  String? _selectedBrand;
  String? _selectedModel;
  String? _selectedVariant;
  late String? _selectedCategory = widget.initialCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // White page so part photos sit on a clean background.
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Back to home',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Parts by motorcycle'),
      ),
      body: FutureBuilder<List<VehiclePartsVariant>>(
        future: _catalogFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _CatalogError(error: snapshot.error!);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildCatalog(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildCatalog(List<VehiclePartsVariant> catalog) {
    final brands = catalog.map((vehicle) => vehicle.brand).toSet().toList();
    final brand = brands.contains(_selectedBrand)
        ? _selectedBrand!
        : brands.first;
    final models = catalog
        .where((vehicle) => vehicle.brand == brand)
        .map((vehicle) => vehicle.model)
        .toSet()
        .toList();
    final model = models.contains(_selectedModel)
        ? _selectedModel!
        : models.first;
    final variants = catalog
        .where((vehicle) => vehicle.brand == brand && vehicle.model == model)
        .toList(growable: false);
    final selected = variants.firstWhere(
      (vehicle) => vehicle.variant == _selectedVariant,
      orElse: () => variants.first,
    );
    // Keeps the chosen category when switching bikes, if the new one has it.
    final activeCategory = selected.categories.firstWhere(
      (category) => category.name == _selectedCategory,
      orElse: () => selected.categories.first,
    );
    final selectedImageAsset = vehiclePartsVariantImageAsset(
      brand: selected.brand,
      model: selected.model,
      variant: selected.variant,
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _BrandChoiceGrid(
                choices: brands,
                selected: brand,
                onSelected: (value) => setState(() {
                  _selectedBrand = value;
                  _selectedModel = null;
                  _selectedVariant = null;
                }),
              ),
              const SizedBox(height: 10),
              _VehicleSelection(
                label: 'MODEL',
                value: model,
                choices: models,
                imageAssetForChoice: (choice) {
                  final vehicle = catalog.firstWhere(
                    (vehicle) =>
                        vehicle.brand == brand && vehicle.model == choice,
                  );
                  return vehiclePartsVariantImageAsset(
                    brand: vehicle.brand,
                    model: vehicle.model,
                    variant: vehicle.variant,
                  );
                },
                onChanged: (value) => setState(() {
                  _selectedModel = value;
                  _selectedVariant = null;
                }),
              ),
              const SizedBox(height: 10),
              _VehicleChoiceGroup(
                label: 'VARIANT',
                choices: variants.map((vehicle) => vehicle.variant).toList(),
                selected: selected.variant,
                onSelected: (value) => setState(() => _selectedVariant = value),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 210,
                        child: selectedImageAsset == null
                            ? const ColoredBox(
                                color: Colors.white,
                                child: Icon(
                                  Icons.two_wheeler,
                                  color: AppColors.primary,
                                  size: 36,
                                ),
                              )
                            : Image.asset(
                                selectedImageAsset,
                                key: const ValueKey('motorcycle-preview-image'),
                                cacheWidth: 800,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${selected.brand} ${selected.model} ${selected.variant}',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
        // The category tabs stick to the top while the parts below scroll, so
        // another category is always one tap away.
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedBar(
            height: 60,
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    for (final category in selected.categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          key: ValueKey('part-category-${category.name}'),
                          label: Text(
                            category.name,
                          ),
                          selected: category == activeCategory,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = category.name),
                          showCheckmark: false,
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          side: BorderSide(
                            color: category == activeCategory
                                ? AppColors.primary
                                : AppColors.line,
                          ),
                          labelStyle: TextStyle(
                            color: category == activeCategory
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
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          sliver: SliverToBoxAdapter(
            child: Container(
              key: PageStorageKey(
                '${selected.brand}-${selected.model}-${selected.variant}-'
                '${activeCategory.name}',
              ),
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  for (final part in activeCategory.parts)
                    _VehiclePartTile(
                      brand: selected.brand,
                      model: selected.model,
                      variant: selected.variant,
                      category: activeCategory.name,
                      part: part,
                      shopStore: _shopStore,
                      onOwnerSignIn: widget.onOwnerSignIn,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fixed-height header that stays pinned at the top of a scroll view.
class _PinnedBar extends SliverPersistentHeaderDelegate {
  const _PinnedBar({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox.expand(child: child);

  @override
  bool shouldRebuild(_PinnedBar oldDelegate) => true;
}

class _VehiclePartTile extends StatelessWidget {
  const _VehiclePartTile({
    required this.brand,
    required this.model,
    required this.variant,
    required this.category,
    required this.part,
    required this.shopStore,
    required this.onOwnerSignIn,
  });

  final String brand;
  final String model;
  final String variant;
  final String category;
  final String part;
  final ShopStore shopStore;
  final VoidCallback? onOwnerSignIn;

  String get _vehicle => '$brand $model $variant';

  @override
  Widget build(BuildContext context) {
    final imageAsset = vehiclePartImageAsset(
      brand: brand,
      model: model,
      variant: variant,
      category: category,
      part: part,
    );

    return Container(
      key: PageStorageKey('$_vehicle-$category-$part'),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VehiclePartImage(
            key: ValueKey('part-image-$category-$part'),
            imageAsset: imageAsset,
            title: part,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part,
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _partDescription(part, category),
                  key: ValueKey('part-description-$category-$part'),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 7),
                FilledButton.icon(
                  key: ValueKey('go-to-shop-$part'),
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ShopPage(
                          store: shopStore,
                          onOwnerSignIn: onOwnerSignIn,
                          initialProductQuery: part,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.storefront_outlined, size: 17),
                  label: const Text('Go to shop'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _partDescription(String part, String category) {
    final base =
        partDescription(part) ??
        '$part for the ${category.toLowerCase()} system.';
    final size = _sizeFor(part);
    return size == null ? base : '$base $size';
  }

  /// The exact size for this bike, from the Sizes table, where known.
  String? _sizeFor(String part) {
    final spec = specFor(brand: brand, model: model, variant: variant);
    if (spec == null) return null;
    final key = part.toLowerCase();
    final (label, value) = switch (key) {
      'front tire' => ('Size for this model', spec.frontTire),
      'rear tire' => ('Size for this model', spec.rearTire),
      '12-v battery' => ('Battery for this model', spec.battery),
      'spark plug' ||
      'spark-plug set' => ('Plug for this model', spec.sparkPlug),
      'engine oil' => ('Oil capacity for this model', spec.engineOil),
      _ => ('', null),
    };
    return value == null ? null : '$label: $value.';
  }
}

class _VehiclePartImage extends StatelessWidget {
  const _VehiclePartImage({
    required this.imageAsset,
    required this.title,
    super.key,
  });

  final String? imageAsset;
  final String title;

  @override
  Widget build(BuildContext context) {
    final imageAsset = this.imageAsset;
    return SizedBox(
      key: ValueKey(
        'part-image-box-${imageAsset?.split('/').last ?? 'missing'}',
      ),
      width: 92,
      height: 92,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: ColoredBox(
          color: Colors.white,
          child: imageAsset == null
              ? _placeholder()
              : ZoomableImage(
                  imageAsset: imageAsset,
                  title: title,
                  child: Image.asset(
                    imageAsset,
                    cacheWidth: 276,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stackTrace) =>
                        _placeholder(),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 19, color: AppColors.primary),
          SizedBox(height: 3),
          Text(
            'Add image',
            style: TextStyle(color: AppColors.muted, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _VehicleSelection extends StatelessWidget {
  const _VehicleSelection({
    required this.label,
    required this.value,
    required this.choices,
    required this.imageAssetForChoice,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> choices;
  final String? Function(String choice) imageAssetForChoice;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 8, 13, 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          items: choices
              .map(
                (choice) => DropdownMenuItem<String>(
                  value: choice,
                  child: _ChoiceItem(
                    label: choice,
                    imageAsset: imageAssetForChoice(choice),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
          selectedItemBuilder: (context) => choices
              .map((_) {
                final imageAsset = imageAssetForChoice(value);
                return Row(
                  children: [
                    if (imageAsset != null) ...[
                      _ChoiceImage(imageAsset: imageAsset, size: 42),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            value,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _VehicleChoiceGroup extends StatelessWidget {
  const _VehicleChoiceGroup({
    required this.label,
    required this.choices,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<String> choices;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: choices
              .map((choice) {
                final isSelected = choice == selected;
                return ChoiceChip(
                  key: ValueKey('vehicle-$label-${choice.toLowerCase()}'),
                  label: Text(choice),
                  selected: isSelected,
                  onSelected: (_) => onSelected(choice),
                  showCheckmark: false,
                  selectedColor: AppColors.primarySoft,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.line,
                    width: isSelected ? 1.5 : 1,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _BrandChoiceGrid extends StatelessWidget {
  const _BrandChoiceGrid({
    required this.choices,
    required this.selected,
    required this.onSelected,
  });

  final List<String> choices;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'BRAND',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: choices
                .expand((choice) {
                  final isSelected = choice == selected;
                  return [
                    if (choice != choices.first) const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        key: ValueKey('vehicle-BRAND-${choice.toLowerCase()}'),
                        label: choice,
                        button: true,
                        selected: isSelected,
                        child: Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.line,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => onSelected(choice),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 44,
                                    child: Image.asset(
                                      'assets/brands/${choice.toLowerCase()}.png',
                                      cacheWidth: 200,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.medium,
                                      excludeFromSemantics: true,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.two_wheeler,
                                                color: AppColors.primary,
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ];
                })
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _ChoiceItem extends StatelessWidget {
  const _ChoiceItem({required this.label, required this.imageAsset});

  final String label;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (imageAsset != null) ...[
          _ChoiceImage(imageAsset: imageAsset!, size: 40),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceImage extends StatelessWidget {
  const _ChoiceImage({required this.imageAsset, required this.size});

  final String imageAsset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          imageAsset,
          cacheWidth: (size * 2).round(),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not load the motorcycle parts catalog: $error',
          style: const TextStyle(
            color: Color(0xFF735A2D),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

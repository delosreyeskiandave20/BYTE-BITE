import 'package:flutter/material.dart';

import '../data/shop_store.dart';
import '../data/vehicle_images.dart';
import '../data/vehicle_parts_catalog.dart';
import 'shop_page.dart';
import '../theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
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
    final selectedImageAsset = vehiclePartsVariantImageAsset(
      brand: selected.brand,
      model: selected.model,
      variant: selected.variant,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
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
              (vehicle) => vehicle.brand == brand && vehicle.model == choice,
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
            border: Border.all(color: AppColors.tealBorder),
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
                          color: AppColors.paper,
                          child: Icon(
                            Icons.two_wheeler,
                            color: AppColors.teal,
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
        const SizedBox(height: 12),
        ...selected.categories.map(
          (category) => Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: AppColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              key: PageStorageKey(
                '${selected.brand}-${selected.model}-${selected.variant}-${category.name}',
              ),
              initiallyExpanded: category.name == widget.initialCategory,
              title: Text(
                category.name,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              children: category.parts
                  .map(
                    (part) => _VehiclePartTile(
                      brand: selected.brand,
                      model: selected.model,
                      variant: selected.variant,
                      category: category.name,
                      part: part,
                      shopStore: _shopStore,
                      onOwnerSignIn: widget.onOwnerSignIn,
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'This list follows the supplied spreadsheet. Model year and OEM part numbers were not provided.',
          style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.45),
        ),
      ],
    );
  }
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VehiclePartImage(
            key: ValueKey('part-image-$category-$part'),
            imageAsset: imageAsset,
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
                    backgroundColor: AppColors.teal,
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
    final specificDescription = _specificPartDescriptions[part.toLowerCase()];
    if (specificDescription != null) return specificDescription;

    final system = switch (category) {
      'Engine' => 'engine and drivetrain',
      'Electrical' => 'electrical system',
      'Suspension' => 'suspension and steering system',
      'Wheels & Tires' => 'wheel, tire, and braking system',
      'Body' => 'body and exterior',
      _ => category.toLowerCase(),
    };
    return '$part is listed for the motorcycle $system. Confirm the exact '
        'specification and fit for the selected model before ordering.';
  }
}

const _specificPartDescriptions = {
  'engine oil':
      'Lubricates engine components and helps control heat. Match the oil '
      'viscosity and JASO/API rating specified in the owner’s manual.',
  'oil screen/filter':
      'Traps debris in the engine oil system. Check the service manual to '
      'confirm the correct screen or filter and replacement interval.',
  'oil filter/strainer':
      'Traps debris in the engine oil system. Check the service manual to '
      'confirm the correct strainer or filter and replacement interval.',
  'oil strainer/filter':
      'Traps debris in the engine oil system. Check the service manual to '
      'confirm the correct strainer or filter and replacement interval.',
  'drain-plug washer':
      'Seals the oil drain plug to help prevent leaks. Match the washer '
      'diameter and replace it when servicing the oil.',
  'air filter':
      'Filters dust from the air entering the engine. Match the filter shape '
      'and dimensions to the original part.',
  'spark plug':
      'Ignites the fuel-air mixture in the engine. Match the thread, reach, '
      'heat range, and gap specified for the motorcycle.',
  'spark-plug set':
      'Ignites the fuel-air mixture in the engine. Match the thread, reach, '
      'heat range, and gap specified for the motorcycle.',
  'cvt drive belt':
      'Transfers power through the scooter’s continuously variable transmission. '
      'Match the belt dimensions and service specification to the model.',
  'variator roller set':
      'Works in the CVT variator to change the transmission ratio. Confirm the '
      'roller dimensions and weight specified for the scooter.',
};

class _VehiclePartImage extends StatelessWidget {
  const _VehiclePartImage({required this.imageAsset, super.key});

  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('part-image-box-${imageAsset.split('/').last}'),
      width: 92,
      height: 92,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.asset(
          imageAsset,
          cacheWidth: 184,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 19, color: AppColors.teal),
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
                  selectedColor: AppColors.tealSoft,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? AppColors.teal : AppColors.line,
                    width: isSelected ? 1.5 : 1,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.teal : AppColors.muted,
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
        LayoutBuilder(
          builder: (context, constraints) => GridView.count(
            crossAxisCount: constraints.maxWidth >= 300 ? 3 : 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.55,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: choices
                .map((choice) {
                  final isSelected = choice == selected;
                  return Semantics(
                    key: ValueKey('vehicle-BRAND-${choice.toLowerCase()}'),
                    label: choice,
                    button: true,
                    selected: isSelected,
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                        side: BorderSide(
                          color: isSelected ? AppColors.teal : AppColors.line,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onSelected(choice),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            'assets/brands/${choice.toLowerCase()}.png',
                            cacheWidth: 240,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.two_wheeler,
                                  color: AppColors.teal,
                                  size: 28,
                                ),
                          ),
                        ),
                      ),
                    ),
                  );
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

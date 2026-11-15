import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

import 'package:url_launcher/url_launcher.dart';

import '../data/motorcycle_info.dart';
import '../data/parts_catalog.dart';
import '../data/price_format.dart';
import '../data/vehicle_images.dart';

Uri motorcycleGoogleSearchUri({
  required String brand,
  required String model,
  required String variant,
}) {
  return Uri.https('www.google.com', '/search', {
    'q': '$brand $model $variant motorcycle video review',
  });
}

class VehicleVariantCarousel extends StatefulWidget {
  const VehicleVariantCarousel({super.key});

  @override
  State<VehicleVariantCarousel> createState() => _VehicleVariantCarouselState();
}

class _VehicleVariantCarouselState extends State<VehicleVariantCarousel> {
  static final _vehicles = [
    for (final brand in vehicleCatalog.entries)
      for (final model in brand.value.entries)
        for (final variant in model.value)
          _VehicleVariant(brand: brand.key, model: model.key, variant: variant),
  ];

  int _currentIndex = 0;

  String get _selectedBrand => _currentVehicle.brand;

  List<_VehicleVariant> get _brandVehicles =>
      _vehicles.where((vehicle) => vehicle.brand == _selectedBrand).toList();

  _VehicleVariant get _currentVehicle => _vehicles[_currentIndex];

  void _showPrevious() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _vehicles.length) % _vehicles.length;
    });
  }

  void _showNext() {
    setState(() => _currentIndex = (_currentIndex + 1) % _vehicles.length);
  }

  void _selectBrand(String brand) {
    if (brand == _selectedBrand) return;
    setState(() {
      _currentIndex = _vehicles.indexWhere((vehicle) => vehicle.brand == brand);
    });
  }

  void _selectVariant(String variant) {
    final vehicle = _currentVehicle;
    setState(() {
      _currentIndex = _vehicles.indexWhere(
        (other) =>
            other.brand == vehicle.brand &&
            other.model == vehicle.model &&
            other.variant == variant,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _currentVehicle;
    final brandVehicles = _brandVehicles;
    final position = brandVehicles.indexOf(vehicle) + 1;
    final imageAsset = vehicleVariantImageAsset(
      vehicle.brand,
      vehicle.model,
      vehicle.variant,
    );
    final zoom = imageAsset == null
        ? null
        : () => _showZoomedImage(context, imageAsset);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Choose a brand'),
        const SizedBox(height: AppSpacing.sm),
        // Wraps instead of scrolling so every brand stays visible.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final brand in vehicleCatalog.keys)
              _BrandChip(
                brand: brand,
                selected: brand == _selectedBrand,
                onSelected: () => _selectBrand(brand),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F22201E),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.brand.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: AppType.micro,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            vehicle.model,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: AppType.screen,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vehicle.variant,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: AppType.body,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$position / ${brandVehicles.length}',
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          fontSize: AppType.micro,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 230,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: zoom,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _MotorcycleImage(
                              key: ValueKey(
                                '${vehicle.brand}-${vehicle.model}-'
                                '${vehicle.variant}',
                              ),
                              vehicle: vehicle,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _CarouselArrow(
                          tooltip: 'Previous motorcycle variant',
                          icon: Icons.chevron_left,
                          onPressed: _showPrevious,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _CarouselArrow(
                          tooltip: 'Next motorcycle variant',
                          icon: Icons.chevron_right,
                          onPressed: _showNext,
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: _CarouselArrow(
                          tooltip: imageAsset == null
                              ? 'No vehicle image available'
                              : 'Zoom motorcycle image',
                          icon: Icons.zoom_out_map,
                          onPressed: zoom,
                          small: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: position / brandVehicles.length,
                    minHeight: 4,
                    color: AppColors.primary,
                    backgroundColor: AppColors.paper,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _MotorcycleDetails(vehicle: vehicle, onSelectVariant: _selectVariant),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: AppType.micro,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({
    required this.brand,
    required this.selected,
    required this.onSelected,
  });

  final String brand;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      key: ValueKey('gallery-brand-$brand'),
      label: Text(brand),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.line),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.inkSoft,
        fontSize: AppType.caption,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _VehicleVariant {
  const _VehicleVariant({
    required this.brand,
    required this.model,
    required this.variant,
  });

  final String brand;
  final String model;
  final String variant;
}

class _MotorcycleImage extends StatelessWidget {
  const _MotorcycleImage({required this.vehicle, super.key});

  final _VehicleVariant vehicle;

  @override
  Widget build(BuildContext context) {
    final imageAsset = vehicleVariantImageAsset(
      vehicle.brand,
      vehicle.model,
      vehicle.variant,
    );

    // Side padding keeps the bike clear of the overlaid arrow buttons.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: imageAsset == null
          ? const _VehiclePlaceholder()
          : Image.asset(
              imageAsset,
              cacheWidth: 800,
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
    );
  }
}

class _VehiclePlaceholder extends StatelessWidget {
  const _VehiclePlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            size: 44,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          Text(
            'No vehicle image available',
            style: TextStyle(
              color: AppColors.ink.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Round button floating over the motorcycle photo.
class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.small = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 36.0 : 44.0;
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
      elevation: 2,
      shadowColor: const Color(0x3322201E),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: small ? 18 : 24),
        color: AppColors.ink,
        disabledColor: AppColors.faint,
        style: IconButton.styleFrom(
          minimumSize: Size(size, size),
          maximumSize: Size(size, size),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

void _showZoomedImage(BuildContext context, String imageAsset) {
  final screenSize = MediaQuery.sizeOf(context);

  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: screenSize.width,
        height: screenSize.height * 0.78,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: AppColors.paper,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const _VehiclePlaceholder(),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: 'Close zoomed image',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                color: AppColors.primary,
                style: IconButton.styleFrom(backgroundColor: AppColors.paper),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MotorcycleDetails extends StatelessWidget {
  const _MotorcycleDetails({
    required this.vehicle,
    required this.onSelectVariant,
  });

  final _VehicleVariant vehicle;
  final ValueChanged<String> onSelectVariant;

  Future<void> _openGoogleSearch(BuildContext context) async {
    final uri = motorcycleGoogleSearchUri(
      brand: vehicle.brand,
      model: vehicle.model,
      variant: vehicle.variant,
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the Google search link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final variants = vehicleCatalog[vehicle.brand]![vehicle.model]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Available variants',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: AppType.cardTitle,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                variants.length == 1
                    ? '1 variant'
                    : '${variants.length} variants',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: AppType.caption,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final variant in variants)
                ChoiceChip(
                  key: ValueKey('gallery-variant-$variant'),
                  label: Text(variant),
                  selected: variant == vehicle.variant,
                  onSelected: (_) => onSelectVariant(variant),
                  showCheckmark: false,
                  selectedColor: AppColors.primarySoft,
                  backgroundColor: AppColors.paper,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  side: BorderSide(
                    color: variant == vehicle.variant
                        ? AppColors.primaryBorder
                        : Colors.transparent,
                  ),
                  labelStyle: TextStyle(
                    color: variant == vehicle.variant
                        ? AppColors.primary
                        : AppColors.inkSoft,
                    fontSize: AppType.caption,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SpecsAndPrice(vehicle: vehicle),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openGoogleSearch(context),
              icon: const Icon(Icons.play_circle_outline, size: 18),
              label: const Text('Find videos & details on Google'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                textStyle: const TextStyle(
                  fontSize: AppType.body,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Key Specifications & Features" and "Pricing (Philippines)" for the
/// motorcycle shown in the gallery.
class _SpecsAndPrice extends StatelessWidget {
  const _SpecsAndPrice({required this.vehicle});

  final _VehicleVariant vehicle;

  @override
  Widget build(BuildContext context) {
    final info = motorcycleInfo(vehicle.brand, vehicle.model);
    final price = info?.srp[vehicle.variant];
    final priceText = price != null
        ? formatPeso(price).replaceAll('.00', '')
        : info?.srpRange ?? 'Not available yet';
    return Column(
      key: const ValueKey('gallery-specs'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DetailsHeading('Key Specifications & Features'),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              for (final (index, (label, value))
                  in (info?.specRows ?? const <(String, String?)>[])
                      .indexed) ...[
                if (index > 0)
                  const Divider(
                    height: 1,
                    indent: 60,
                    endIndent: 14,
                    color: AppColors.line,
                  ),
                _SpecRow(label: label, value: value),
              ],
              if (info == null)
                const _SpecRow(label: 'Specifications', value: null),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _DetailsHeading('Pricing (Philippines)'),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Suggested Retail Price (SRP)',
                  style: TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: AppType.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceText,
                    key: const ValueKey('gallery-srp'),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: price != null || info?.srpRange != null
                          ? AppColors.primary
                          : AppColors.faint,
                      fontSize: price != null
                          ? AppType.section
                          : AppType.caption,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (price != null || info?.srpRange != null)
                    const Text(
                      'as of $srpAsOf',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: AppType.micro,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailsHeading extends StatelessWidget {
  const _DetailsHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: AppType.cardTitle,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String? value;

  /// An icon matching the spec's topic.
  static IconData _iconFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('engine')) return Icons.settings_suggest_outlined;
    if (l.contains('power') || l.contains('torque')) return Icons.bolt_rounded;
    if (l.contains('transmission')) return Icons.sync_alt_rounded;
    if (l.contains('fuel')) return Icons.local_gas_station_outlined;
    if (l.contains('dimension') || l.contains('weight')) {
      return Icons.straighten_rounded;
    }
    if (l.contains('brake') || l.contains('wheel')) {
      return Icons.album_outlined;
    }
    if (l.contains('convenience') || l.contains('feature')) {
      return Icons.auto_awesome_outlined;
    }
    return Icons.info_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(label), size: 19, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: AppType.micro,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value ?? 'Not available yet',
                  style: TextStyle(
                    color: value == null ? AppColors.faint : AppColors.ink,
                    fontSize: AppType.body,
                    fontWeight: value == null
                        ? FontWeight.w500
                        : FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

import 'package:url_launcher/url_launcher.dart';

import '../data/parts_catalog.dart';
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

  @override
  Widget build(BuildContext context) {
    final vehicle = _currentVehicle;
    final brandVehicles = _brandVehicles;
    final imageAsset = vehicleVariantImageAsset(
      vehicle.brand,
      vehicle.model,
      vehicle.variant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MOTOSCAN / VEHICLE GUIDE',
                    style: TextStyle(
                      color: AppColors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Browse motorcycle variants',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 22,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${brandVehicles.indexOf(vehicle) + 1} / ${brandVehicles.length}',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'CHOOSE A BRAND',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: vehicleCatalog.keys.map((brand) {
              final selected = brand == _selectedBrand;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  key: ValueKey('gallery-brand-$brand'),
                  label: Text(brand),
                  selected: selected,
                  onSelected: (_) => _selectBrand(brand),
                  showCheckmark: false,
                  selectedColor: AppColors.tealSoft,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected ? AppColors.teal : AppColors.line,
                    width: selected ? 1.5 : 1,
                  ),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.teal : AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _MotorcycleImage(
                key: ValueKey(
                  '${vehicle.brand}-${vehicle.model}-${vehicle.variant}',
                ),
                vehicle: vehicle,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CarouselArrow(
                  tooltip: 'Previous motorcycle variant',
                  icon: Icons.chevron_left,
                  onPressed: _showPrevious,
                ),
                IconButton(
                  tooltip: imageAsset == null
                      ? 'No vehicle image available'
                      : 'Zoom motorcycle image',
                  onPressed: imageAsset == null
                      ? null
                      : () => _showZoomedImage(context, imageAsset),
                  icon: const Icon(Icons.zoom_in),
                  color: AppColors.teal,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.paper,
                    minimumSize: const Size(44, 44),
                    maximumSize: const Size(44, 44),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                _CarouselArrow(
                  tooltip: 'Next motorcycle variant',
                  icon: Icons.chevron_right,
                  onPressed: _showNext,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MotorcycleDetails(vehicle: vehicle),
      ],
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

    return SizedBox(
      width: double.infinity,
      height: 260,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: imageAsset == null
                    ? const _VehiclePlaceholder()
                    : Image.asset(
                        imageAsset,
                        cacheWidth: 800,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      ),
              ),
            ),
          ],
        ),
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
            color: AppColors.teal,
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

class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Material(
        color: AppColors.paper,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon),
          color: AppColors.teal,
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            maximumSize: const Size(44, 44),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
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
                color: AppColors.teal,
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
  const _MotorcycleDetails({required this.vehicle});

  final _VehicleVariant vehicle;

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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE9E5DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MOTORCYCLE DETAILS',
            style: TextStyle(
              color: AppColors.teal,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          _DetailRow(label: 'Brand', value: vehicle.brand),
          _DetailRow(label: 'Model', value: vehicle.model),
          _DetailRow(label: 'Current variant', value: vehicle.variant),
          const SizedBox(height: 9),
          const Text(
            'Available variants',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final variant in variants)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: variant == vehicle.variant
                        ? AppColors.tealSoft
                        : AppColors.paper,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    variant,
                    style: TextStyle(
                      color: variant == vehicle.variant
                          ? AppColors.teal
                          : const Color(0xFF4F4A44),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openGoogleSearch(context),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Find videos & details on Google'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                minimumSize: const Size.fromHeight(46),
                side: const BorderSide(color: AppColors.tealBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

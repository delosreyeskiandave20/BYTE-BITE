import 'package:flutter/material.dart';

import '../data/motorcycle_specs.dart';
import '../theme/app_theme.dart';
import '../widgets/zoomable_image.dart';

/// Lets a rider pick a motorcycle and see its tire, battery, plug and oil
/// sizes at a glance, with a photo of the chosen item.
class MotorcycleSpecsPage extends StatefulWidget {
  const MotorcycleSpecsPage({super.key});

  @override
  State<MotorcycleSpecsPage> createState() => _MotorcycleSpecsPageState();
}

IconData _iconFor(SpecItem item) => switch (item) {
  SpecItem.frontTire || SpecItem.rearTire => Icons.tire_repair,
  SpecItem.battery => Icons.battery_charging_full,
  SpecItem.sparkPlug => Icons.bolt,
  SpecItem.engineOil => Icons.oil_barrel_outlined,
  SpecItem.chainSprockets => Icons.link,
  SpecItem.fuelTank => Icons.local_gas_station_outlined,
  SpecItem.tirePressure => Icons.speed,
};

class _MotorcycleSpecsPageState extends State<MotorcycleSpecsPage> {
  MotorcycleSpec _bike = motorcycleSpecs.first;
  SpecItem _item = SpecItem.frontTire;

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
        title: const Text('Sizes'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
        children: [
          const _Label('Your motorcycle'),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 128,
            child: ListView.separated(
              key: const ValueKey('spec-bike-row'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: motorcycleSpecs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final bike = motorcycleSpecs[index];
                return _BikeCard(
                  bike: bike,
                  selected: bike == _bike,
                  onTap: () => setState(() => _bike = bike),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bike.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: AppType.screen,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tap a size to see a photo.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: AppType.caption,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Every size for this bike at a glance; the chosen one opens
                // below with its photo.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = (constraints.maxWidth - 10) / 2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final item in SpecItem.values)
                          SizedBox(
                            width: width,
                            child: _SizeTile(
                              item: item,
                              value: _bike.valueOf(item),
                              selected: item == _item,
                              onTap: () => setState(() => _item = item),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                _SpecResult(bike: _bike, item: _item),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: AppType.micro,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// One size in the at-a-glance grid; dark when it is the one shown below.
class _SizeTile extends StatelessWidget {
  const _SizeTile({
    required this.item,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final SpecItem item;
  final String? value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    final shown = value == null
        ? 'Not listed'
        : item == SpecItem.engineOil
        ? '$value oil'
        : value;
    return Material(
      key: ValueKey('spec-item-${item.label}'),
      color: selected ? AppColors.ink : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: selected ? AppColors.ink : AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected ? AppColors.orange : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconFor(item),
                  size: 18,
                  color: selected ? AppColors.ink : AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white70 : AppColors.muted,
                        fontSize: AppType.micro,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // A label for screen readers; the size itself is read
                    // from the result card to avoid saying it twice.
                    Text(
                      shown,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      semanticsLabel: '${item.label}: $shown',
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : value == null
                            ? AppColors.faint
                            : AppColors.ink,
                        fontSize: AppType.body,
                        fontWeight: FontWeight.w900,
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

class _BikeCard extends StatelessWidget {
  const _BikeCard({
    required this.bike,
    required this.selected,
    required this.onTap,
  });

  final MotorcycleSpec bike;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('spec-bike-${bike.name}'),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.line,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 136,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Image.asset(
                    bike.imageAsset,
                    cacheWidth: 280,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.two_wheeler, color: AppColors.primary),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                color: selected ? AppColors.primary : AppColors.paper,
                child: Text(
                  bike.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.ink,
                    fontSize: AppType.micro,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecResult extends StatelessWidget {
  const _SpecResult({required this.bike, required this.item});

  final MotorcycleSpec bike;
  final SpecItem item;

  @override
  Widget build(BuildContext context) {
    final value = bike.valueOf(item);
    final photo = value == null ? null : specImageAsset(item, value);
    return Container(
      key: const ValueKey('spec-result'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1422201E),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: value == null
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(_iconFor(item), color: AppColors.faint),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Text(
                      "Not listed for this motorcycle yet. Check the owner's "
                      'manual or ask a shop.',
                      style: TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: AppType.body,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (photo == null)
                  SizedBox(
                    height: 120,
                    child: Icon(
                      _iconFor(item),
                      size: 56,
                      color: AppColors.primary,
                    ),
                  )
                else
                  SizedBox(
                    height: 220,
                    child: ZoomableImage(
                      imageAsset: photo,
                      title: '${bike.name} · ${item.label}',
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Image.asset(
                          photo,
                          key: ValueKey('spec-image-$photo'),
                          cacheWidth: 700,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  color: AppColors.paper,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: AppType.micro,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item == SpecItem.engineOil ? 'Capacity: $value' : value,
                        key: const ValueKey('spec-value'),
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: AppType.screen,
                          fontWeight: FontWeight.w900,
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

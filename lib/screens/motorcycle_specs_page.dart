import 'package:flutter/material.dart';

import '../data/motorcycle_specs.dart';
import '../theme/app_theme.dart';

/// Lets a rider pick a motorcycle, then an item (tire, battery, plug, oil),
/// and shows that item's size or type with a photo.
class MotorcycleSpecsPage extends StatefulWidget {
  const MotorcycleSpecsPage({super.key});

  @override
  State<MotorcycleSpecsPage> createState() => _MotorcycleSpecsPageState();
}

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
        title: const Text('Tires, battery & oil'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
        children: [
          const _Label('1. Choose your motorcycle'),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 132,
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
          const _Label('2. Choose what you need'),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                for (final item in SpecItem.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: ValueKey('spec-item-${item.label}'),
                      label: Text(item.label),
                      selected: item == _item,
                      onSelected: (_) => setState(() => _item = item),
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      side: BorderSide(
                        color: item == _item
                            ? AppColors.primary
                            : AppColors.line,
                      ),
                      labelStyle: TextStyle(
                        color: item == _item ? Colors.white : AppColors.inkSoft,
                        fontSize: AppType.caption,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SpecResult(bike: _bike, item: _item),
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
      color: selected ? AppColors.primarySoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.line,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 140,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Expanded(
                  child: Image.asset(
                    bike.imageAsset,
                    cacheWidth: 280,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.two_wheeler, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bike.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.primary : AppColors.ink,
                    fontSize: AppType.micro,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
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

class _SpecResult extends StatelessWidget {
  const _SpecResult({required this.bike, required this.item});

  final MotorcycleSpec bike;
  final SpecItem item;

  @override
  Widget build(BuildContext context) {
    final value = bike.valueOf(item);
    return Container(
      key: const ValueKey('spec-result'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bike.name.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: AppType.micro,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: AppType.section,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (value == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Text(
                'Not listed for this motorcycle yet. Check the owner\'s '
                'manual or ask a shop.',
                style: TextStyle(
                  color: AppColors.inkSoft,
                  fontSize: AppType.body,
                  height: 1.4,
                ),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                width: double.infinity,
                height: 200,
                color: Colors.white,
                child: Image.asset(
                  specImageAsset(item, value),
                  key: ValueKey('spec-image-${specImageAsset(item, value)}'),
                  cacheWidth: 600,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
        ],
      ),
    );
  }
}

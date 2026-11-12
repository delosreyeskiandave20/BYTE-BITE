import 'parts_catalog.dart';

final vehicleVariantImageAssets = Map<String, String>.unmodifiable({
  for (final brand in vehicleCatalog.entries)
    for (final model in brand.value.entries)
      for (final variant in model.value)
        _vehicleImageKey(
          brand.key,
          model.key,
          variant,
        ): 'assets/motorcycles/${_vehicleImageName(brand.key, model.key, variant)}.png',
});

String? vehicleVariantImageAsset(String brand, String model, String variant) =>
    vehicleVariantImageAssets[_vehicleImageKey(brand, model, variant)];

String? vehiclePartsVariantImageAsset({
  required String brand,
  required String model,
  required String variant,
}) {
  final directMatch = vehicleVariantImageAsset(brand, model, variant);
  if (directMatch != null) return directMatch;

  final normalizedModel = _normalizeVehicleName(model);
  final normalizedVariant = _normalizeVehicleName(variant);
  final brandEntry = vehicleCatalog.entries.where(
    (entry) => _normalizeVehicleName(entry.key) == _normalizeVehicleName(brand),
  );
  if (brandEntry.isEmpty) return null;

  for (final modelEntry in brandEntry.first.value.entries) {
    final galleryModel = _normalizeVehicleName(modelEntry.key);
    if (galleryModel == normalizedModel) {
      for (final galleryVariant in modelEntry.value) {
        if (_normalizeVehicleName(galleryVariant) == normalizedVariant) {
          return vehicleVariantImageAsset(
            brandEntry.first.key,
            modelEntry.key,
            galleryVariant,
          );
        }
      }
    }

    for (final galleryVariant in modelEntry.value) {
      if (_normalizeVehicleName(galleryVariant) == normalizedModel) {
        return vehicleVariantImageAsset(
          brandEntry.first.key,
          modelEntry.key,
          galleryVariant,
        );
      }
    }
  }
  return null;
}

String _vehicleImageKey(String brand, String model, String variant) =>
    '$brand|$model|$variant';

String _normalizeVehicleName(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

String _vehicleImageName(String brand, String model, String variant) {
  var modelName = _slug(model);
  var variantName = _slug(variant);

  if (brand == 'Yamaha' && model == 'MT-15') {
    modelName = 'mt15';
  } else if (brand == 'Honda' && model == 'Rebel') {
    variantName = variantName.replaceFirst('rebel_', '');
  }

  return '${_slug(brand)}_${modelName}_$variantName';
}

String _slug(String value) => value
    .toLowerCase()
    .replaceAll('+', ' plus')
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

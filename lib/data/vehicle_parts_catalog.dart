import 'dart:convert';

import 'package:flutter/services.dart';

const vehiclePartsCatalogAssetPath = 'assets/motorcycle_parts_catalog.json';

Future<List<VehiclePartsVariant>>? _vehiclePartsCatalogFuture;

class VehiclePartsCategory {
  const VehiclePartsCategory({required this.name, required this.parts});

  final String name;
  final List<String> parts;

  factory VehiclePartsCategory.fromJson(Object? value) {
    final json = _jsonObject(value, 'category');
    final partsValue = json['parts'];
    if (partsValue is! List || partsValue.any((part) => part is! String)) {
      throw const FormatException(
        'Invalid parts list in motorcycle parts category.',
      );
    }
    return VehiclePartsCategory(
      name: _requiredString(json, 'name', 'category'),
      parts: partsValue.cast<String>().toList(growable: false),
    );
  }
}

class VehiclePartsVariant {
  const VehiclePartsVariant({
    required this.brand,
    required this.model,
    required this.variant,
    required this.categories,
  });

  final String brand;
  final String model;
  final String variant;
  final List<VehiclePartsCategory> categories;

  int get partCount =>
      categories.fold(0, (total, category) => total + category.parts.length);

  factory VehiclePartsVariant.fromJson(Object? value) {
    final json = _jsonObject(value, 'vehicle');
    final categoriesValue = json['categories'];
    if (categoriesValue is! List) {
      throw const FormatException(
        'Invalid categories list in motorcycle parts vehicle.',
      );
    }
    return VehiclePartsVariant(
      brand: _requiredString(json, 'brand', 'vehicle'),
      model: _requiredString(json, 'model', 'vehicle'),
      variant: _requiredString(json, 'variant', 'vehicle'),
      categories: categoriesValue
          .map(VehiclePartsCategory.fromJson)
          .toList(growable: false),
    );
  }
}

String vehiclePartImageAsset({
  required String category,
  required String part,
}) => 'assets/vehicle_parts/${_assetSlug(category)}/${_assetSlug(part)}.png';

Future<List<VehiclePartsVariant>> loadVehiclePartsCatalog() {
  return _vehiclePartsCatalogFuture ??= _readVehiclePartsCatalog();
}

Future<List<VehiclePartsVariant>> _readVehiclePartsCatalog() async {
  final json = jsonDecode(
    await rootBundle.loadString(vehiclePartsCatalogAssetPath),
  );
  if (json is! List) {
    throw const FormatException(
      'Motorcycle parts catalog must be a JSON list.',
    );
  }
  return json.map(VehiclePartsVariant.fromJson).toList(growable: false);
}

Map<String, dynamic> _jsonObject(Object? value, String context) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('Invalid $context entry in motorcycle parts catalog.');
}

String _requiredString(Map<String, dynamic> json, String key, String context) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Missing "$key" in motorcycle parts $context.');
}

String _assetSlug(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

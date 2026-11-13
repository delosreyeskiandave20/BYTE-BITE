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
  String? brand,
  String? model,
  String? variant,
}) {
  if (brand == 'Honda' && model == 'Beat' && variant == 'Playful') {
    final imageFile = _beatPlayfulPartImages[_assetSlug(part)];
    if (imageFile != null) {
      return 'assets/vehicle_parts/beat_playful/$imageFile';
    }
  }
  return 'assets/vehicle_parts/${_assetSlug(category)}/${_assetSlug(part)}.png';
}

const _beatPlayfulPartImages = <String, String>{
  'engine_oil': 'engine_oil.jpg',
  'oil_screen_filter': 'oil_screen_filter.jpg',
  'drain_plug_washer': 'drain_plug_washer.jpg',
  'air_filter': 'air_filter.jpg',
  'spark_plug': 'spark_plug.jpg',
  'cvt_drive_belt': 'cvt_drive_belt.png',
  'variator_roller_set': 'variator_roller_set.png',
  'cvt_slider_set': 'cvt_slider_set.jpg',
  'clutch_shoe_set': 'clutch_shoe_set.png',
  'final_drive_gear_oil': 'final_drive_gear_oil.png',
  '12_v_battery': '12_v_battery.jpg',
  'main_fuse': 'main_fuse.jpg',
  'starter_relay': 'starter_relay.jpg',
  'regulator_rectifier': 'regulator_rectifier.jpg',
  'spark_plug_cap': 'spark_plug_cap.png',
  'ignition_coil': 'ignition_coil.png',
  'ecu_pgm_fi_unit': 'ecu_pgm_fi_unit.png',
  'oxygen_sensor': 'oxygen_sensor.jpg',
  'brake_light_switch': 'brake_light_switch.png',
  'front_fork_oil': 'front_fork_oil.jpg',
  'fork_oil_seal': 'fork_oil_seal.jpg',
  'fork_dust_seal': 'fork_dust_seal.jpg',
  'fork_bushing': 'fork_bushing.jpg',
  'front_fork_spring': 'front_fork_spring.jpg',
  'rear_shock_absorber': 'rear_shock_absorber.webp',
  'rear_shock_bushing': 'rear_shock_bushing.jpg',
  'steering_head_bearing': 'steering_head_bearing.png',
  'swingarm_pivot_bushing': 'swingarm_pivot_bushing.jpg',
  'side_stand_switch': 'side_stand_switch.jpg',
  'front_tire': 'front_tire.jpg',
  'rear_tire': 'rear_tire.png',
  'front_wheel_bearing': 'front_wheel_bearing.jpg',
  'rear_wheel_bearing': 'rear_wheel_bearing.webp',
  'wheel_oil_seal': 'wheel_oil_seal.jpg',
  'front_axle_collar': 'front_axle_collar.jpg',
  'rear_axle_collar': 'rear_axle_collar.png',
  'tubeless_valve_stem': 'tubeless_valve_stem.jpg',
  'tire_pressure_valve_core': 'tire_pressure_valve_core.jpg',
  'leg_shield_floor_panel': 'leg_shield_floor_panel.jpg',
  'front_fender': 'front_fender.png',
  'rear_fender_mudguard': 'rear_fender_mudguard.jpg',
  'seat_assembly_seat_cover': 'seat_assembly.png',
  'grab_rail': 'grab_rail.png',
  'side_mirror': 'side_mirror.jpg',
  'headlight_assembly': 'headlight_assembly.jpg',
  'tail_light_turn_signal_assembly': 'tail_light_turn_signal_assembly.jpg',
};

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

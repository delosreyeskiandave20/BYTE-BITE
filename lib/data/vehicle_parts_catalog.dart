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

String? vehiclePartImageAsset({
  required String category,
  required String part,
  String? brand,
  String? model,
  String? variant,
}) {
  if (brand == 'Honda' &&
      model == 'Click125' &&
      (variant == 'Smart Edition' || variant == 'Street')) {
    const partsWithoutVariantImages = {
      'front_cowl_fairing',
      'leg_shield_floor_panel',
      'rear_fender_mudguard',
      'side_cover',
      'seat_assembly_seat_cover',
    };
    if (partsWithoutVariantImages.contains(_assetSlug(part))) {
      return null;
    }

    final imageFile = _click125StandardPartImages[_assetSlug(part)];
    if (imageFile != null) {
      final variantFolder = variant == 'Smart Edition'
          ? 'click125_smart_edition'
          : 'click125_street';
      return 'assets/vehicle_parts/$variantFolder/$imageFile';
    }
  }

  if (brand == 'Honda' && model == 'Click125' && variant == 'Standard') {
    final imageFile = _click125StandardPartImages[_assetSlug(part)];
    if (imageFile != null) {
      return 'assets/vehicle_parts/click125_standard/$imageFile';
    }
  }

  if (brand == 'Honda' &&
      model == 'Beat' &&
      (variant == 'Playful' || variant == 'Premium')) {
    final partSlug = _assetSlug(part);
    if (variant == 'Premium') {
      final premiumImageFile = _beatPremiumPartImages[partSlug];
      if (premiumImageFile != null) {
        return 'assets/vehicle_parts/beat_premium/$premiumImageFile';
      }
      if (_beatPremiumPartImageExclusions.contains(partSlug)) {
        return 'assets/vehicle_parts/${_assetSlug(category)}/$partSlug.png';
      }
    }

    final imageFile = _beatPlayfulPartImages[partSlug];
    if (imageFile != null) {
      return 'assets/vehicle_parts/beat_playful/$imageFile';
    }
  }
  if (brand == 'Honda' && model == 'Giorno+' && variant == 'Standard') {
    final imageFile = _giornoPlusStandardPartImages[_assetSlug(part)];
    if (imageFile != null) {
      return 'assets/vehicle_parts/giorno_plus_standard/$imageFile';
    }
  }
  return 'assets/vehicle_parts/${_assetSlug(category)}/${_assetSlug(part)}.png';
}

const _giornoPlusStandardPartImages = <String, String>{
  'engine_oil': 'engine_oil.jpg',
  'oil_screen_filter': 'oil_screen_filter.jpg',
  'drain_plug_washer': 'drain_plug_washer.jpg',
  'air_filter': 'air_filter.jpg',
  'spark_plug': 'spark_plug.jpg',
  'cvt_drive_belt': 'cvt_drive_belt.jpg',
  'clutch_shoe_set': 'clutch_shoe_set.jpg',
  'final_drive_gear_oil': 'final_drive_gear_oil.png',
  '12_v_battery': '12_v_battery.jpg',
  'main_fuse': 'main_fuse.jpg',
  'regulator_rectifier': 'regulator_rectifier.jpg',
  'stator_charging_coil': 'stator_charging_coil.webp',
  'spark_plug_cap': 'spark_plug_cap.webp',
  'ignition_coil': 'ignition_coil.jpg',
  'ecu_pgm_fi_unit': 'ecu_pgm_fi_unit.jpg',
  'oxygen_sensor': 'oxygen_sensor.jpg',
  'brake_light_switch': 'brake_light_switch.jpg',
  'front_fork_oil': 'front_fork_oil.png',
  'fork_oil_seal': 'fork_oil_seal.jpg',
  'fork_dust_seal': 'fork_dust_seal.jpg',
  'front_fork_spring': 'front_fork_spring.jpg',
  'rear_shock_absorber': 'rear_shock_absorber.webp',
  'swingarm_pivot_bushing': 'swingarm_pivot_bushing.jpg',
  'side_stand_switch': 'side_stand_switch.png',
  'front_tire': 'front_tire.webp',
  'rear_tire': 'rear_tire.jpg',
  'front_wheel_bearing': 'front_wheel_bearing.jpg',
  'rear_wheel_bearing': 'rear_wheel_bearing.jpg',
  'front_axle_collar': 'front_axle_collar.jpg',
  'tubeless_valve_stem': 'tubeless_valve_stem.jpg',
};

const _click125StandardPartImages = <String, String>{
  'engine_oil': 'engine_oil.png',
  'oil_screen_filter': 'oil_screen_filter.jpg',
  'drain_plug_washer': 'drain_plug_washer.png',
  'air_filter': 'air_filter.png',
  'spark_plug': 'spark_plug.webp',
  'cvt_drive_belt': 'cvt_drive_belt.jpg',
  'cvt_slider_set': 'cvt_slider_set.png',
  'clutch_shoe_set': 'clutch_shoe_set.png',
  'final_drive_gear_oil': 'final_drive_gear_oil.png',
  '12_v_battery': '12_v_battery.jpg',
  'main_fuse': 'main_fuse.png',
  'starter_relay': 'starter_relay.png',
  'regulator_rectifier': 'regulator_rectifier.png',
  'stator_charging_coil': 'stator_charging_coil.webp',
  'spark_plug_cap': 'spark_plug_cap.jpg',
  'ignition_coil': 'ignition_coil.png',
  'ecu_pgm_fi_unit': 'ecu_pgm_fi_unit.png',
  'oxygen_sensor': 'oxygen_sensor.png',
  'brake_light_switch': 'brake_light_switch.png',
  'front_fork_oil': 'front_fork_oil.jpg',
  'fork_oil_seal': 'fork_oil_seal.png',
  'fork_dust_seal': 'fork_dust_seal.png',
  'front_fork_spring': 'front_fork_spring.png',
  'rear_shock_absorber': 'rear_shock_absorber.png',
  'rear_shock_bushing': 'rear_shock_bushing.png',
  'steering_head_bearing': 'steering_head_bearing.png',
  'swingarm_pivot_bushing': 'swingarm_pivot_bushing.png',
  'side_stand_switch': 'side_stand_switch.png',
  'front_tire': 'front_tire.png',
  'rear_tire': 'rear_tire.png',
  'front_wheel_bearing': 'front_wheel_bearing.jpg',
  'rear_wheel_bearing': 'rear_wheel_bearing.png',
  'front_axle_collar': 'front_axle_collar.png',
  'rear_axle_collar': 'rear_axle_collar.png',
  'tubeless_valve_stem': 'tubeless_valve_stem.jpg',
  'brake_disc_or_drum': 'brake_disc_or_drum.png',
  'tire_pressure_valve_core': 'tire_pressure_valve_core.png',
  'front_cowl_fairing': 'front_cowl_fairing.png',
  'leg_shield_floor_panel': 'leg_shield_floor_panel.png',
  'front_fender': 'front_fender.jpg',
  'rear_fender_mudguard': 'rear_fender_mudguard.jpg',
  'side_cover': 'side_cover.png',
  'seat_assembly_seat_cover': 'seat_assembly_seat_cover.png',
  'side_mirror': 'side_mirror.png',
  'headlight_assembly': 'headlight_assembly.png',
  'tail_light_turn_signal_assembly': 'tail_light_turn_signal_assembly.png',
};

const _beatPlayfulPartImages = <String, String>{
  'engine_oil': 'engine_oil.jpg',
  'oil_screen_filter': 'oil_screen_filter.jpg',
  'drain_plug_washer': 'drain_plug_washer.jpg',
  'air_filter': 'air_filter.jpg',
  'spark_plug': 'spark_plug.jpg',
  'cvt_drive_belt': 'cvt_drive_belt.png',
  'variator_roller_set': 'variator_roller_set.png',
  'clutch_shoe_set': 'clutch_shoe_set.png',
  'final_drive_gear_oil': 'final_drive_gear_oil.png',
  '12_v_battery': '12_v_battery.jpg',
  'main_fuse': 'main_fuse.jpg',
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
  'steering_head_bearing': 'steering_head_bearing.png',
  'swingarm_pivot_bushing': 'swingarm_pivot_bushing.jpg',
  'side_stand_switch': 'side_stand_switch.jpg',
  'front_tire': 'front_tire.jpg',
  'rear_tire': 'rear_tire.png',
  'front_wheel_bearing': 'front_wheel_bearing.jpg',
  'rear_wheel_bearing': 'rear_wheel_bearing.webp',
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

const _beatPremiumPartImages = <String, String>{
  'front_fender': 'front_fender.jpg',
  'grab_rail': 'grab_rail.png',
  'side_mirror': 'side_mirror.png',
  'headlight_assembly': 'headlight_assembly.jpg',
  'tail_light_turn_signal_assembly': 'tail_light_turn_signal_assembly.png',
  'brake_disc_or_drum': 'brake_disc_or_drum.png',
};

const _beatPremiumPartImageExclusions = <String>{
  'front_fender',
  'grab_rail',
  'side_mirror',
  'headlight_assembly',
  'tail_light_turn_signal_assembly',
  'brake_disc_or_drum',
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

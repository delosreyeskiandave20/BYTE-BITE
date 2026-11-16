import 'package:flutter/services.dart';

import 'image_slug.dart';

export 'image_slug.dart';

/// Folder that holds Design ideas photos, named by [designImageSlug].
const designImageFolder = 'assets/design/';

/// Folder that holds Maintenance choice photos, named by
/// [maintenanceImageSlug].
const maintenanceImageFolder = 'assets/maintenance/';

/// Folder that holds Accessories choice photos, named by
/// [accessoryImageSlug].
const accessoryImageFolder = 'assets/accessories/';

const _imageExtensions = {'.png', '.jpg', '.jpeg', '.webp'};

/// Photos bundled in [designImageFolder], keyed by file name without extension.
Future<Map<String, String>> loadDesignImages([AssetBundle? bundle]) =>
    loadFolderImages(designImageFolder, bundle);

/// Photos bundled in [maintenanceImageFolder], keyed by file name without
/// extension.
Future<Map<String, String>> loadMaintenanceImages([AssetBundle? bundle]) =>
    loadFolderImages(maintenanceImageFolder, bundle);

/// Photos bundled in [accessoryImageFolder], keyed by file name without
/// extension.
Future<Map<String, String>> loadAccessoryImages([AssetBundle? bundle]) =>
    loadFolderImages(accessoryImageFolder, bundle);

/// Folder that holds per-motorcycle part photos, one subfolder per variant.
const vehiclePartsImageFolder = 'assets/vehicle_parts/';

/// Every bundled part photo, grouped by folder and keyed by [imageSlug] of
/// the item name. Accessory and maintenance photos are also keyed by the
/// choice alone (the part after `-`), so "Aftermarket filter" finds
/// `air_filter-aftermarket_filter`.
class PartImageIndex {
  const PartImageIndex(this._byFolder);

  static const empty = PartImageIndex({});

  final Map<String, Map<String, String>> _byFolder;

  /// Asset path of a photo for [name], preferring the folder that matches
  /// [category] (one of the Add Item categories, e.g. "Maintenance").
  ///
  /// Tries the exact name first, then each alternative in names like
  /// "Exhaust / Muffler", then photos whose name contains it ("Brake
  /// caliper" finds `front_brake_caliper`), shortest name first.
  String? lookup(String name, String category) {
    final preferred = switch (category) {
      'Maintenance' => maintenanceImageFolder,
      'Accessories' => accessoryImageFolder,
      'Designs' => designImageFolder,
      _ => vehiclePartsImageFolder,
    };
    final folders = [
      preferred,
      ..._byFolder.keys.where((folder) => folder != preferred),
    ];
    final candidates = <String>{
      ?_imageAliases[imageSlug(name)],
      imageSlug(name),
      for (final part in name.split(RegExp(r'[/()&,]')))
        if (imageSlug(part).isNotEmpty) imageSlug(part),
    };
    // Singular forms: "Rollers" -> "roller", "Valves" -> "valve".
    candidates.addAll([
      for (final slug in candidates.toList())
        slug
            .split('_')
            .map(
              (w) => w.length > 3 && w.endsWith('s') && !w.endsWith('ss')
                  ? w.substring(0, w.length - 1)
                  : w,
            )
            .join('_'),
    ]);

    for (final slug in candidates) {
      for (final folder in folders) {
        final hit = _byFolder[folder]?[slug];
        if (hit != null) return hit;
      }
    }
    for (final slug in candidates) {
      for (final folder in folders) {
        final images = _byFolder[folder];
        if (images == null) continue;
        String? bestKey;
        for (final key in images.keys) {
          if (!'_${key}_'.contains('_${slug}_')) continue;
          if (bestKey == null || key.length < bestKey.length) bestKey = key;
        }
        if (bestKey != null) return images[bestKey];
      }
    }
    return null;
  }
}

/// Names whose photo is saved under a different file name, e.g. the parts
/// library's "Front mudguard panel" is the `front_fender` photo.
const _imageAliases = {
  'air_filter_element': 'air_filter',
  'clutch_friction_plate': 'clutch_plate_set',
  'front_brake_shoe_set': 'brake_shoe_set',
  'cdi_ignition_module': 'cdi_ecu_unit',
  'tubeless_tire_90_90_17': 'front_tire',
  'front_mudguard_panel': 'front_fender',
  'led_projector_headlight': 'led_headlight',
  'sport_rear_view_mirrors': 'side_mirrors',
  'universal_phone_holder': 'handlebar_phone_holder',
  // Engine valves, not the tire valve photos whose names also contain
  // "valve".
  'valves': 'valve_stem_seals',
  'motorcycle_cover': 'full_cover',
  // Parts list names pointed at the clearest photo already bundled.
  'front_fork_front_shock': 'front_fork_inner_tube',
  'swing_arm': 'swingarm',
  'steering_bearings': 'steering_head_bearings',
  'mags_rims': 'front_wheel_rim',
  'handle_switches': 'handlebar_switch_set',
  'brake_lever_set': 'handlebar_grip_set',
  'helmet': 'full_face_helmet',
  'emblem_logo': 'brand_logo_stickers',
  'full_wrap': 'custom_printed_wrap',
  'seat_design': 'carbon_look_seat_cover',
  'plate_holder': 'number_plate_frame',
  'raincoat': 'one_piece_rain_suit',
};

/// Builds a [PartImageIndex] from the asset manifest.
Future<PartImageIndex> loadPartImageIndex([AssetBundle? bundle]) async {
  final manifest = await AssetManifest.loadFromAssetBundle(
    bundle ?? rootBundle,
  );
  const folders = [
    vehiclePartsImageFolder,
    maintenanceImageFolder,
    accessoryImageFolder,
    designImageFolder,
  ];
  final byFolder = {for (final folder in folders) folder: <String, String>{}};
  final assets = manifest.listAssets().toList()..sort();
  for (final asset in assets) {
    final folder = folders.where(asset.startsWith).firstOrNull;
    if (folder == null) continue;
    final fileName = asset.substring(asset.lastIndexOf('/') + 1);
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0) continue;
    if (!_imageExtensions.contains(fileName.substring(dot).toLowerCase())) {
      continue;
    }
    final stem = fileName.substring(0, dot);
    final images = byFolder[folder]!;
    images.putIfAbsent(stem, () => asset);
    final dash = stem.lastIndexOf('-');
    if (dash >= 0) images.putIfAbsent(stem.substring(dash + 1), () => asset);
  }
  return PartImageIndex(byFolder);
}

/// Maps each photo directly inside [folder] to its asset path, keyed by file
/// name without extension.
///
/// Any photo saved there under the right name shows up in the app with no
/// code change. The asset bundle already caches the manifest, so repeat calls
/// are cheap.
Future<Map<String, String>> loadFolderImages(
  String folder, [
  AssetBundle? bundle,
]) async {
  final manifest = await AssetManifest.loadFromAssetBundle(
    bundle ?? rootBundle,
  );
  final images = <String, String>{};
  for (final asset in manifest.listAssets()) {
    if (!asset.startsWith(folder)) continue;
    final name = asset.substring(folder.length);
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || name.contains('/')) continue;
    if (!_imageExtensions.contains(name.substring(dot).toLowerCase())) {
      continue;
    }
    images[name.substring(0, dot)] = asset;
  }
  return images;
}

import 'package:flutter/services.dart';

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

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// A photo the seller picked for an item, held in memory until it is saved.
class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.extension});

  final Uint8List bytes;

  /// Lower-case file extension without the dot, e.g. "jpg".
  final String extension;

  String get contentType => switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'heic' => 'image/heic',
    _ => 'image/jpeg',
  };
}

/// Uploads item photos and returns their public https URLs.
abstract class ProductPhotoStorage {
  Future<String> upload({required String shopId, required PickedPhoto photo});
}

/// Stores photos in Firebase Storage under shops/{shopId}/products/.
/// storage.rules lets only the shop owner write there.
class FirebaseProductPhotoStorage implements ProductPhotoStorage {
  FirebaseProductPhotoStorage(this._storage);

  final FirebaseStorage _storage;

  @override
  Future<String> upload({
    required String shopId,
    required PickedPhoto photo,
  }) async {
    final name = '${DateTime.now().microsecondsSinceEpoch}.${photo.extension}';
    final ref = _storage.ref('shops/$shopId/products/$name');
    await ref.putData(
      photo.bytes,
      SettableMetadata(contentType: photo.contentType),
    );
    return ref.getDownloadURL();
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'product_photo_storage.dart';

/// Free photo storage on Cloudinary (no billing card needed).
///
/// To turn it on, create a free account at https://cloudinary.com, then:
///  1. Copy your **Cloud name** from the dashboard into [cloudinaryCloudName].
///  2. Settings → Upload → Upload presets → Add upload preset:
///     Signing mode **Unsigned**, Folder `motoscan`, allowed formats
///     `jpg,png,webp`, max file size 10 MB. Copy its name into
///     [cloudinaryUploadPreset].
///
/// Both can also be passed at build time instead:
///   flutter run --dart-define=CLOUDINARY_CLOUD_NAME=... \
///               --dart-define=CLOUDINARY_UPLOAD_PRESET=...
///
/// While either is empty the app keeps using Firebase Storage.
const cloudinaryCloudName = String.fromEnvironment(
  'CLOUDINARY_CLOUD_NAME',
  defaultValue: 'yuvfsypk',
);

/// Unsigned preset "motoscan_unsigned": public IDs are disallowed, so an
/// upload can never overwrite an existing photo.
const cloudinaryUploadPreset = String.fromEnvironment(
  'CLOUDINARY_UPLOAD_PRESET',
  defaultValue: 'motoscan_unsigned',
);

bool get isCloudinaryConfigured =>
    cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;

/// Uploads item photos to Cloudinary with an unsigned upload preset and
/// returns the photo's public https link.
class CloudinaryProductPhotoStorage implements ProductPhotoStorage {
  CloudinaryProductPhotoStorage({
    required this.cloudName,
    required this.uploadPreset,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String cloudName;
  final String uploadPreset;
  final http.Client _client;

  @override
  Future<String> upload({
    required String shopId,
    required PickedPhoto photo,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.https('api.cloudinary.com', '/v1_1/$cloudName/image/upload'),
          )
          ..fields['upload_preset'] = uploadPreset
          // One folder per shop keeps each shop's photos together.
          ..fields['folder'] = 'motoscan/shops/$shopId'
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              photo.bytes,
              // Cloudinary reads the image type from the file itself.
              filename: 'photo.${photo.extension}',
            ),
          );

    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    final Object? body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw StateError('Photo upload failed (${response.statusCode}).');
    }
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      String? message;
      if (body is Map<String, dynamic>) {
        final error = body['error'];
        if (error is Map<String, dynamic>) {
          message = error['message'] as String?;
        }
      }
      throw StateError(
        'Photo upload failed: ${message ?? 'error ${response.statusCode}'}',
      );
    }
    final url = body['secure_url'];
    if (url is! String || !url.startsWith('https://')) {
      throw StateError('Photo upload failed: no link was returned.');
    }
    return url;
  }
}

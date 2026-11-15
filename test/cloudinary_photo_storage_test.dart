import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_application_1/data/cloudinary_photo_storage.dart';
import 'package:flutter_application_1/data/product_photo_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _photo = PickedPhoto(
  bytes: Uint8List.fromList(const [1, 2, 3]),
  extension: 'png',
);

void main() {
  test('uploads to the shop folder and returns the https link', () async {
    late http.Request sent;
    final storage = CloudinaryProductPhotoStorage(
      cloudName: 'demo-cloud',
      uploadPreset: 'motoscan_unsigned',
      client: MockClient((request) async {
        sent = request;
        return http.Response(
          jsonEncode({
            'secure_url':
                'https://res.cloudinary.com/demo-cloud/image/upload/a.png',
          }),
          200,
        );
      }),
    );

    final url = await storage.upload(shopId: 'shop-1', photo: _photo);

    expect(url, 'https://res.cloudinary.com/demo-cloud/image/upload/a.png');
    expect(
      sent.url.toString(),
      'https://api.cloudinary.com/v1_1/demo-cloud/image/upload',
    );
    expect(sent.body, contains('motoscan_unsigned'));
    expect(sent.body, contains('motoscan/shops/shop-1'));
  });

  test('shows Cloudinary\'s own error message', () async {
    final storage = CloudinaryProductPhotoStorage(
      cloudName: 'demo-cloud',
      uploadPreset: 'wrong',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'Upload preset not found'},
          }),
          400,
        ),
      ),
    );

    expect(
      () => storage.upload(shopId: 'shop-1', photo: _photo),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          'Photo upload failed: Upload preset not found',
        ),
      ),
    );
  });
}

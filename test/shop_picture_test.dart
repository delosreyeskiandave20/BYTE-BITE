import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/shop_store.dart';
import 'package:flutter_application_1/screens/shop_owner_dashboard_page.dart';
import 'package:flutter_application_1/screens/shop_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_owner_auth.dart';

class _FakePhotoStorage implements ProductPhotoStorage {
  int count = 0;

  @override
  Future<String> upload({
    required String shopId,
    required PickedPhoto photo,
  }) async => 'https://photos.example.com/shop-${++count}.${photo.extension}';
}

const _owner = 'banner-owner@example.com';

Future<ShopStore> _storeWithShop({bool saveShop = true}) async {
  final store = ShopStore(
    ownerAuth: FakeOwnerAuth(),
    photoStorage: _FakePhotoStorage(),
  );
  await store.createOwner(
    name: 'Owner',
    email: _owner,
    password: 'temporary123',
  );
  if (saveShop) {
    await store.saveShop(
      ownerEmail: _owner,
      name: 'Banner Moto',
      location: 'Oroquieta City, Misamis Occidental',
      description: '',
    );
  }
  return store;
}

final _photo = PickedPhoto(
  bytes: Uint8List.fromList([1, 2, 3]),
  extension: 'png',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('owners can set, keep and remove their shop picture', () async {
    final store = await _storeWithShop();
    addTearDown(store.dispose);

    await store.setShopBanner(ownerEmail: _owner, photo: _photo);
    final shop = store.shopForOwner(_owner)!;
    expect(shop.bannerUrl, 'https://photos.example.com/shop-1.png');
    expect(shop.hasBanner, isTrue);

    // Saving the shop details again keeps the picture.
    await store.saveShop(
      ownerEmail: _owner,
      name: 'Banner Moto 2',
      location: 'Oroquieta City, Misamis Occidental',
      description: '',
    );
    expect(
      store.shopForOwner(_owner)!.bannerUrl,
      'https://photos.example.com/shop-1.png',
    );

    await store.setShopBanner(ownerEmail: _owner);
    expect(store.shopForOwner(_owner)!.hasBanner, isFalse);
  });

  testWidgets('the dashboard uploads a shop picture', (tester) async {
    final store = await _storeWithShop();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ShopOwnerDashboardPage(
          store: store,
          ownerEmail: _owner,
          onDone: () {},
          pickPhotos: (source, limit) async => [_photo],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shop picture'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('shop-picture-change')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shop-picture-change')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shop-picture-gallery')));
    await tester.pumpAndSettle();

    expect(find.text('Shop picture saved.'), findsOneWidget);
    expect(store.shopForOwner(_owner)!.hasBanner, isTrue);
    expect(find.text('Change picture'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('shop-picture-remove')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shop-picture-remove')));
    await tester.pumpAndSettle();
    expect(store.shopForOwner(_owner)!.hasBanner, isFalse);
    expect(find.text('Add picture'), findsOneWidget);
  });

  testWidgets('the Shop tab card shows the shop picture', (tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = await _storeWithShop();
    addTearDown(store.dispose);
    final shop = store.shopForOwner(_owner)!;

    await tester.pumpWidget(MaterialApp(home: ShopPage(store: store)));
    await tester.pumpAndSettle();
    // No picture yet: the storefront icon.
    expect(find.byKey(ValueKey('shop-avatar-${shop.id}')), findsNothing);

    await store.setShopBanner(ownerEmail: _owner, photo: _photo);
    await tester.pumpAndSettle();
    final picture = tester.widget<Image>(
      find.byKey(ValueKey('shop-avatar-${shop.id}')),
    );
    expect(
      (picture.image as NetworkImage).url,
      'https://photos.example.com/shop-1.png',
    );
  });

  testWidgets('a new shop must be saved before adding a picture', (
    tester,
  ) async {
    final store = await _storeWithShop(saveShop: false);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ShopOwnerDashboardPage(
          store: store,
          ownerEmail: _owner,
          onDone: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Save your shop details first, then add a picture.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('shop-picture-change')), findsNothing);
  });
}

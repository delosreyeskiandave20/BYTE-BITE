import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/marketplace.dart';
import 'package:flutter_application_1/data/marketplace_link.dart';
import 'package:flutter_application_1/data/shop_store.dart';
import 'package:flutter_application_1/screens/online_store_page.dart';
import 'package:flutter_application_1/screens/shop_page.dart';

import 'fake_owner_auth.dart';

const _owner = 'seller@motoscan.test';

Future<ShopStore> _sellerStore({String marketplaceUrl = ''}) async {
  final store = ShopStore(ownerAuth: FakeOwnerAuth());
  addTearDown(store.dispose);
  await store.createOwner(
    name: 'Seller',
    email: _owner,
    password: 'temporary123',
  );
  await store.saveShop(
    ownerEmail: _owner,
    name: 'Moto Seller PH',
    location: 'Davao City',
    description: 'Sells on Shopee.',
    marketplaceUrl: marketplaceUrl,
  );
  await store.addProduct(
    ownerEmail: _owner,
    name: 'Sintered brake pad',
    category: 'Brakes',
    price: 320,
    quantity: 5,
  );
  return store;
}

void main() {
  group('parseMarketplaceLink', () {
    test('reads Shopee and Lazada store links', () {
      final shopee = parseMarketplaceLink(
        'https://shopee.ph/motoseller.ph?smtt=0.0.9',
      );
      expect(shopee?.marketplace, Marketplaces.shopee);
      expect(shopee?.slug, 'motoseller.ph');
      expect(shopee?.url, 'https://shopee.ph/motoseller.ph');

      final lazada = parseMarketplaceLink('lazada.com.ph/shop/sh0pnstyle/');
      expect(lazada?.marketplace, Marketplaces.lazada);
      expect(lazada?.url, 'https://www.lazada.com.ph/shop/sh0pnstyle/');
    });

    test('rejects item links, numeric shop links and other sites', () {
      expect(
        parseMarketplaceLink('https://shopee.ph/Brake-pad-i.12.34'),
        isNull,
      );
      expect(parseMarketplaceLink('https://shopee.ph/shop/123456'), isNull);
      expect(parseMarketplaceLink('https://example.com/shop/x/'), isNull);
      expect(
        validateMarketplaceLink('https://shopee.ph/shop/123456'),
        'Use your shop page link, e.g. shopee.ph/yourshop',
      );
      expect(validateMarketplaceLink(''), isNull);
    });
  });

  test('saveShop stores the cleaned link and rejects bad ones', () async {
    final store = await _sellerStore(marketplaceUrl: 'shopee.ph/motoseller');
    final shop = store.shopForOwner(_owner)!;
    expect(shop.marketplaceUrl, 'https://shopee.ph/motoseller');
    // Local demo mode has no admin, so the link is live at once.
    expect(shop.liveMarketplaceLink?.slug, 'motoseller');

    expect(
      () => store.saveShop(
        ownerEmail: _owner,
        name: 'Moto Seller PH',
        location: 'Davao City',
        description: '',
        marketplaceUrl: 'https://example.com/me',
      ),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets('an approved seller is listed with the Shopee & Lazada stores', (
    tester,
  ) async {
    final store = await _sellerStore(marketplaceUrl: 'shopee.ph/motoseller');
    await tester.pumpWidget(MaterialApp(home: ShopPage(store: store)));
    await tester.pumpAndSettle();

    // Not shown again as a local shop.
    expect(
      find.byKey(ValueKey('shop-card-${store.shopForOwner(_owner)!.id}')),
      findsNothing,
    );
    final row = find.byKey(const ValueKey('online-store-motoseller'));
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Moto Seller PH'), findsOneWidget);
    expect(find.byTooltip('Seller on MotoScan'), findsOneWidget);

    final online = onlineStoreForShop(store.shopForOwner(_owner)!)!;
    expect(online.items.single.name, 'Sintered brake pad');
    expect(online.itemUri(online.items.single).host, 'shopee.ph');
  });

  testWidgets('a shop without a link stays a local shop', (tester) async {
    final store = await _sellerStore();
    await tester.pumpWidget(MaterialApp(home: ShopPage(store: store)));
    await tester.pumpAndSettle();

    final shop = store.shopForOwner(_owner)!;
    expect(onlineStoreForShop(shop), isNull);
    final card = find.byKey(ValueKey('shop-card-${shop.id}'));
    await tester.scrollUntilVisible(
      card,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(card, findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/shop_store.dart';
import 'package:flutter_application_1/data/vehicle_parts_catalog.dart';
import 'package:flutter_application_1/screens/motorcycle_parts_catalog_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_owner_auth.dart';

const _vehicle = VehiclePartsVariant(
  brand: 'Honda',
  model: 'Beat',
  variant: 'Playful',
  categories: [
    VehiclePartsCategory(name: 'Engine', parts: ['Engine oil', 'Air filter']),
    VehiclePartsCategory(name: 'Electrical', parts: ['12-V battery']),
  ],
);

Future<ShopStore> _storeSelling(
  String product, {
  required int quantity,
  List<String> moreProducts = const [],
}) async {
  const owner = 'oil-shop@example.com';
  final store = ShopStore(ownerAuth: FakeOwnerAuth());
  await store.createOwner(
    name: 'Owner',
    email: owner,
    password: 'temporary123',
  );
  await store.saveShop(
    ownerEmail: owner,
    name: 'Oil Depot',
    location: 'Oroquieta City',
    description: '',
  );
  await store.addProduct(
    ownerEmail: owner,
    name: product,
    price: 320,
    quantity: quantity,
  );
  await store.addProduct(
    ownerEmail: owner,
    name: 'Side mirror',
    price: 150,
    quantity: 3,
  );
  for (final name in moreProducts) {
    await store.addProduct(
      ownerEmail: owner,
      name: name,
      price: 1500,
      quantity: 2,
    );
  }
  return store;
}

Future<void> _tapFindInShop(WidgetTester tester, String part) async {
  final button = find.byKey(ValueKey('find-in-shop-$part'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _pumpCatalog(
  WidgetTester tester,
  ShopStore store, {
  String category = 'Engine',
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MotorcyclePartsCatalogPage(
        catalogOverride: Future.value([_vehicle]),
        initialCategory: category,
        shopStore: store,
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Find in shop opens the shops that have the part in stock', (
    tester,
  ) async {
    final store = await _storeSelling('Engine oil 10W-40', quantity: 4);
    addTearDown(store.dispose);

    await _pumpCatalog(tester, store);
    expect(find.text('Find in shop'), findsNWidgets(2));
    await _tapFindInShop(tester, 'Engine oil');

    // The shop page opens already searched for the part, showing the
    // matching in-stock listing and not the shop's other items.
    expect(find.bySemanticsLabel('MotoScan Shop'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Engine oil',
    );
    expect(find.text('Engine oil 10W-40'), findsOneWidget);
    expect(find.text('Side mirror'), findsNothing);
  });

  testWidgets('Find in shop says so when the part is sold out', (tester) async {
    final store = await _storeSelling('Engine oil 10W-40', quantity: 0);
    addTearDown(store.dispose);

    await _pumpCatalog(tester, store);
    await _tapFindInShop(tester, 'Engine oil');

    // The search page opens for the part instead of an empty shop page.
    expect(find.bySemanticsLabel('MotoScan Shop'), findsNothing);
    expect(find.text('Search parts'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Engine oil',
    );
    expect(
      find.text(
        'No items found in shops for "Engine oil". '
        'Matching parts are listed below.',
      ),
      findsOneWidget,
    );
    // Matching parts first, then every other part.
    expect(
      find.byKey(const ValueKey('search-all-other-items')),
      findsOneWidget,
    );
  });

  testWidgets('a part finds related listings, e.g. 12-V battery -> Battery', (
    tester,
  ) async {
    final store = await _storeSelling(
      'Battery',
      quantity: 2,
      moreProducts: ['Motolite Battery 12V', 'Brake pads'],
    );
    addTearDown(store.dispose);

    await _pumpCatalog(tester, store, category: 'Electrical');
    await _tapFindInShop(tester, '12-V battery');

    expect(find.bySemanticsLabel('MotoScan Shop'), findsOneWidget);
    expect(find.text('Battery'), findsOneWidget);
    expect(find.text('Motolite Battery 12V'), findsOneWidget);
    expect(find.text('Side mirror'), findsNothing);
    expect(find.text('Brake pads'), findsNothing);
  });
}

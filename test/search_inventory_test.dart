import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/shop_store.dart';
import 'package:flutter_application_1/screens/search_page.dart';

import 'fake_owner_auth.dart';

const _owner = 'demo@motoscan.test';

Future<ShopStore> _storeWithInventory() async {
  final store = ShopStore(ownerAuth: FakeOwnerAuth());
  await store.createOwner(
    name: 'Demo Owner',
    email: _owner,
    password: 'temporary123',
  );
  await store.saveShop(
    ownerEmail: _owner,
    name: 'Live Parts Shop',
    location: 'Cebu City',
    description: 'Live inventory for search tests.',
  );
  await store.addProduct(
    ownerEmail: _owner,
    name: 'Ceramic brake pad',
    category: 'Brakes',
    description: 'Sintered pad for wet weather.',
    price: 750,
    quantity: 4,
  );
  addTearDown(store.dispose);
  return store;
}

ShopProduct _productNamed(ShopStore store, String name) {
  return store
      .shopForOwner(_owner)!
      .products
      .firstWhere((product) => product.name == name);
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('search lists live shop inventory with shop, price and stock', (
    WidgetTester tester,
  ) async {
    final store = await _storeWithInventory();
    await tester.pumpWidget(MaterialApp(home: SearchPage(shopStore: store)));

    await _search(tester, 'ceramic');

    expect(find.text('Shop listings'), findsOneWidget);
    expect(find.text('Ceramic brake pad'), findsOneWidget);
    expect(find.text('Live Parts Shop · Cebu City'), findsOneWidget);
    expect(find.text('₱750.00'), findsOneWidget);
    expect(find.text('4 left'), findsOneWidget);
  });

  testWidgets('search reflects product edits without reopening the screen', (
    WidgetTester tester,
  ) async {
    final store = await _storeWithInventory();
    await tester.pumpWidget(MaterialApp(home: SearchPage(shopStore: store)));
    await _search(tester, 'ceramic');

    final product = _productNamed(store, 'Ceramic brake pad');
    await store.updateProduct(
      ownerEmail: _owner,
      productId: product.id,
      name: 'Ceramic brake pad pro',
      description: product.description,
      price: 999,
      quantity: 2,
    );
    await tester.pumpAndSettle();

    expect(find.text('Ceramic brake pad pro'), findsOneWidget);
    expect(find.text('₱999.00'), findsOneWidget);
    expect(find.text('2 left'), findsOneWidget);

    await store.addProduct(
      ownerEmail: _owner,
      name: 'Ceramic clutch plate',
      category: 'Engine',
      description: 'Added while search is open.',
      price: 1200,
      quantity: 6,
    );
    await tester.pumpAndSettle();
    expect(find.text('Ceramic clutch plate'), findsOneWidget);

    final added = _productNamed(store, 'Ceramic clutch plate');
    await store.updateProduct(
      ownerEmail: _owner,
      productId: added.id,
      description: added.description,
      price: added.price,
      quantity: 0,
    );
    await tester.pumpAndSettle();
    expect(find.text('Ceramic clutch plate'), findsNothing);
  });

  testWidgets('tapping a shop listing opens that shop', (
    WidgetTester tester,
  ) async {
    final store = await _storeWithInventory();
    await tester.pumpWidget(MaterialApp(home: SearchPage(shopStore: store)));
    await _search(tester, 'ceramic');

    await tester.tap(find.text('Ceramic brake pad'));
    await tester.pumpAndSettle();

    expect(find.text('MotoScan Shop'), findsOneWidget);
    expect(find.text('Ceramic brake pad'), findsWidgets);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/my_motorcycle.dart';
import 'package:flutter_application_1/data/shop_store.dart';
import 'package:flutter_application_1/screens/shop_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_owner_auth.dart';

void main() {
  testWidgets('"My Motorcycle" shows only parts that fit, plus Universal', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const owner = 'filter-owner@example.com';
    final store = ShopStore(ownerAuth: FakeOwnerAuth());
    addTearDown(store.dispose);
    await store.createOwner(
      name: 'Owner',
      email: owner,
      password: 'temporary123',
    );
    await store.saveShop(
      ownerEmail: owner,
      name: 'Fit Test Shop',
      location: 'Cebu City, Cebu',
      description: '',
    );
    await store.addProduct(
      ownerEmail: owner,
      name: 'NMAX brake pads',
      price: 300,
      quantity: 2,
      motorcycles: const ['Yamaha NMAX 155'],
    );
    await store.addProduct(
      ownerEmail: owner,
      name: 'BeAT side mirror',
      price: 150,
      quantity: 2,
      motorcycles: const ['Honda BeAT'],
    );
    await store.addProduct(
      ownerEmail: owner,
      name: 'Phone holder',
      price: 450,
      quantity: 2,
      fitsAll: true,
    );

    await myMotorcycle.choose('Yamaha NMAX 155');
    addTearDown(() => myMotorcycle.choose(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ShopPage(store: store, initialShopName: 'Fit Test Shop'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My motorcycle: NMAX 155'), findsOneWidget);
    expect(find.text('BeAT side mirror'), findsOneWidget);
    // Matching items carry a badge; Universal items count as a match.
    expect(find.text('✅ Fits your NMAX 155'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('my-motorcycle-only-fits')));
    await tester.pumpAndSettle();
    expect(find.text('NMAX brake pads'), findsOneWidget);
    expect(find.text('Phone holder'), findsOneWidget);
    expect(find.text('BeAT side mirror'), findsNothing);
  });
}

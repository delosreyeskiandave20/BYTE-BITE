import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/shop_store.dart';
import 'package:flutter_application_1/screens/shop_page.dart';

import 'fake_owner_auth.dart';

Future<ShopStore> _marketplaceStore() async {
  final store = ShopStore(ownerAuth: FakeOwnerAuth());
  await store.createOwner(
    name: 'Alpha Owner',
    email: 'alpha@example.com',
    password: 'temporary123',
  );
  await store.saveShop(
    ownerEmail: 'alpha@example.com',
    name: 'Alpha Parts',
    location: 'Cebu City',
    description: 'Brakes and service parts.',
  );
  await store.addProduct(
    ownerEmail: 'alpha@example.com',
    name: 'Front brake lever',
    category: 'Brakes',
    description: 'Forged aluminum lever.',
    price: 275,
    quantity: 3,
  );
  await store.addProduct(
    ownerEmail: 'alpha@example.com',
    name: 'Synthetic engine oil',
    category: 'Engine',
    description: 'Fully synthetic 10W-40.',
    price: 350,
    quantity: 0,
  );
  await store.createOwner(
    name: 'Beta Owner',
    email: 'beta@example.com',
    password: 'temporary123',
  );
  await store.saveShop(
    ownerEmail: 'beta@example.com',
    name: 'Beta Motors',
    location: 'Davao City',
    description: 'Engine and drivetrain specialist.',
  );
  await store.addProduct(
    ownerEmail: 'beta@example.com',
    name: 'Clutch cable',
    category: 'Engine',
    description: 'Long-life cable.',
    price: 190,
    quantity: 5,
  );
  addTearDown(store.dispose);
  return store;
}

Future<void> _pumpShop(WidgetTester tester, ShopStore store) async {
  await tester.pumpWidget(MaterialApp(home: ShopPage(store: store)));
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('public shop page shows saved shops before products are listed', (
    WidgetTester tester,
  ) async {
    final store = ShopStore(ownerAuth: FakeOwnerAuth());
    await store.createOwner(
      name: 'New Owner',
      email: 'new@example.com',
      password: 'temporary123',
    );
    await store.saveShop(
      ownerEmail: 'new@example.com',
      name: 'New Motorcycle Shop',
      location: 'Manila',
      description: 'Motorcycle parts and service.',
    );
    addTearDown(store.dispose);

    await _pumpShop(tester, store);
    await tester.scrollUntilVisible(
      find.text('New Motorcycle Shop'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('New Motorcycle Shop'), findsOneWidget);
    expect(find.text('No products listed yet.'), findsOneWidget);
  });

  testWidgets('shop search filters by location, product, and clear action', (
    WidgetTester tester,
  ) async {
    final store = await _marketplaceStore();
    await _pumpShop(tester, store);

    await _search(tester, 'davao');
    expect(find.text('Beta Motors'), findsOneWidget);
    expect(find.text('Alpha Parts'), findsNothing);
    expect(find.text('Available shops for davao'), findsOneWidget);
    expect(find.text('1 shop · 1 product'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Clear shop search'));
    await tester.tap(find.byTooltip('Clear shop search'));
    await tester.pumpAndSettle();
    expect(find.text('Available shops'), findsOneWidget);

    await _search(tester, 'synthetic');
    expect(find.text('Synthetic engine oil'), findsOneWidget);
    expect(find.text('Clutch cable'), findsNothing);
    expect(find.text('Front brake lever'), findsNothing);

    await tester.ensureVisible(find.byTooltip('Clear shop search'));
    await tester.tap(find.byTooltip('Clear shop search'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Beta Motors'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Alpha Parts'), findsOneWidget);
    expect(find.text('Beta Motors'), findsOneWidget);
  });

  testWidgets('in-stock items are listed before unavailable items', (
    WidgetTester tester,
  ) async {
    final store = await _marketplaceStore();
    await tester.pumpWidget(
      MaterialApp(
        home: ShopPage(store: store, initialShopName: 'Alpha Parts'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Front brake lever'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final availableY = tester.getTopLeft(find.text('Front brake lever')).dy;
    final unavailableY = tester
        .getTopLeft(find.text('Synthetic engine oil'))
        .dy;
    expect(availableY, lessThan(unavailableY));
  });

  testWidgets('shop search shows an empty state with a clear action', (
    WidgetTester tester,
  ) async {
    final store = await _marketplaceStore();
    await _pumpShop(tester, store);

    await _search(tester, 'nonexistentpart');
    expect(find.text('No live listings yet'), findsOneWidget);
    expect(find.textContaining('No shop listings match'), findsOneWidget);

    await tester.ensureVisible(find.text('Clear search'));
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('Available shops'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Alpha Parts'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Alpha Parts'), findsOneWidget);
  });
}

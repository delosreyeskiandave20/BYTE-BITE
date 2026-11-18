import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/shop_store.dart';
import 'package:flutter_application_1/screens/shop_browse_pages.dart';
import 'package:flutter_application_1/screens/shop_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_owner_auth.dart';

Future<ShopStore> _twoShops() async {
  final store = ShopStore(ownerAuth: FakeOwnerAuth());
  Future<void> addShop(
    String email,
    String shop,
    List<(String, int)> products,
  ) async {
    await store.createOwner(name: shop, email: email, password: 'temporary123');
    await store.saveShop(
      ownerEmail: email,
      name: shop,
      location: '$shop Street, Cebu City',
      description: '',
    );
    for (final (name, quantity) in products) {
      await store.addProduct(
        ownerEmail: email,
        name: name,
        price: 100,
        quantity: quantity,
      );
    }
  }

  await addShop('north@example.com', 'North Moto', [
    ('North brake pads', 4),
    ('North mirror', 0),
  ]);
  await addShop('south@example.com', 'South Moto', [('South side mirror', 2)]);
  await addShop('empty@example.com', 'Empty Moto', []);
  return store;
}

/// Adds a product as [email]'s owner; only the signed-in owner may edit.
Future<void> _addAs(
  ShopStore store,
  String email,
  String name, {
  int quantity = 1,
}) async {
  await store.signIn(email: email, password: 'temporary123');
  await store.addProduct(
    ownerEmail: email,
    name: name,
    price: 100,
    quantity: quantity,
  );
}

Shop _shop(ShopStore store, String name) =>
    store.shops.firstWhere((shop) => shop.name == name);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'the shop page shows only that shop\'s items in a 2-column grid',
    (tester) async {
      final store = await _twoShops();
      addTearDown(store.dispose);
      final north = _shop(store, 'North Moto');

      await tester.pumpWidget(
        MaterialApp(
          home: ShopDetailPage(store: store, shopId: north.id),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('North Moto'), findsWidgets);
      expect(find.text('North Moto Street, Cebu City'), findsOneWidget);
      expect(find.text('North brake pads'), findsOneWidget);
      expect(find.text('In stock: 4'), findsOneWidget);
      expect(find.text('Out of stock'), findsOneWidget);
      expect(find.text('South side mirror'), findsNothing);

      final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
    },
  );

  testWidgets('a shop with no items says so', (tester) async {
    final store = await _twoShops();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailPage(
          store: store,
          shopId: _shop(store, 'Empty Moto').id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No items in this shop yet'), findsOneWidget);
  });

  testWidgets('new and changed items appear without reopening the page', (
    tester,
  ) async {
    final store = await _twoShops();
    addTearDown(store.dispose);
    final north = _shop(store, 'North Moto');

    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailPage(store: store, shopId: north.id),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('North chain'), findsNothing);

    await _addAs(store, 'north@example.com', 'North chain', quantity: 7);
    await tester.pumpAndSettle();
    expect(find.text('North chain'), findsOneWidget);
    expect(find.text('In stock: 7'), findsOneWidget);
    // Another shop's new item never shows here.
    await _addAs(store, 'south@example.com', 'South chain');
    await tester.pumpAndSettle();
    expect(find.text('South chain'), findsNothing);
  });

  testWidgets('the header shrinks to a top bar with the name and back arrow', (
    tester,
  ) async {
    final store = await _twoShops();
    addTearDown(store.dispose);
    for (var i = 0; i < 12; i++) {
      await _addAs(store, 'north@example.com', 'Extra part $i');
    }
    final north = _shop(store, 'North Moto');

    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailPage(store: store, shopId: north.id),
      ),
    );
    await tester.pumpAndSettle();

    double barTitleOpacity() => tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byKey(const ValueKey('shop-detail-bar-title')),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;
    expect(barTitleOpacity(), 0);

    await tester.drag(
      find.byKey(const ValueKey('shop-detail-scroll')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(barTitleOpacity(), 1);
    expect(find.byKey(const ValueKey('shop-detail-back')), findsOneWidget);
  });

  testWidgets('the shop list opens a shop, and back returns to the list', (
    tester,
  ) async {
    final store = await _twoShops();
    addTearDown(store.dispose);
    final south = _shop(store, 'South Moto');

    await tester.pumpWidget(MaterialApp(home: ShopListPage(store: store)));
    await tester.pumpAndSettle();

    expect(find.text('North Moto'), findsOneWidget);
    expect(find.text('South Moto Street, Cebu City'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('shop-list-${south.id}')));
    await tester.pumpAndSettle();
    expect(find.text('South side mirror'), findsOneWidget);
    expect(find.text('North brake pads'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('shop-detail-back')));
    await tester.pumpAndSettle();
    expect(find.byType(ShopListPage), findsOneWidget);
  });

  testWidgets('the Shop tab opens the shop list and full-screen shop pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = await _twoShops();
    addTearDown(store.dispose);
    final north = _shop(store, 'North Moto');

    await tester.pumpWidget(MaterialApp(home: ShopPage(store: store)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey('visit-button-${north.id}')));
    await tester.pumpAndSettle();
    expect(find.byType(ShopDetailPage), findsOneWidget);
    expect(find.text('South side mirror'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('shop-see-all')));
    await tester.pumpAndSettle();
    expect(find.byType(ShopListPage), findsOneWidget);
  });
}

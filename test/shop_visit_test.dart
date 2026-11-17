import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/shop_store.dart';
import 'package:flutter_application_1/screens/shop_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_owner_auth.dart';

void main() {
  testWidgets('buyers can visit one shop and go back to all shops', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = ShopStore(ownerAuth: FakeOwnerAuth());
    addTearDown(store.dispose);

    Future<void> addShop(String email, String shop, String product) async {
      await store.createOwner(
        name: shop,
        email: email,
        password: 'temporary123',
      );
      await store.saveShop(
        ownerEmail: email,
        name: shop,
        location: 'Cebu City, Cebu',
        description: '',
      );
      await store.addProduct(
        ownerEmail: email,
        name: product,
        price: 100,
        quantity: 1,
      );
    }

    await addShop('north@example.com', 'North Moto', 'North brake pads');
    await addShop('south@example.com', 'South Moto', 'South side mirror');

    await tester.pumpWidget(MaterialApp(home: ShopPage(store: store)));
    await tester.pumpAndSettle();

    expect(find.text('Visit a shop'), findsOneWidget);
    expect(find.text('North brake pads'), findsOneWidget);
    expect(find.text('South side mirror'), findsOneWidget);

    final north = store.shops.firstWhere((shop) => shop.name == 'North Moto');

    // A chip opens the shop on its own page with all of its parts.
    await tester.tap(find.byKey(ValueKey('visit-shop-${north.id}')));
    await tester.pumpAndSettle();

    expect(find.text('All parts in this shop'), findsOneWidget);
    expect(find.text('North brake pads'), findsOneWidget);
    expect(find.text('South side mirror'), findsNothing);
    expect(find.text('Visit a shop'), findsNothing);
    expect(find.byKey(ValueKey('visit-button-${north.id}')), findsNothing);

    // Back returns to every shop.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('South side mirror'), findsOneWidget);

    // The card's own "Visit shop" button opens the same page.
    await tester.tap(find.byKey(ValueKey('visit-button-${north.id}')));
    await tester.pumpAndSettle();
    expect(find.text('All parts in this shop'), findsOneWidget);
    expect(find.text('South side mirror'), findsNothing);
  });
}

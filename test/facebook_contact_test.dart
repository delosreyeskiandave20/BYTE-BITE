import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/chat.dart';
import 'package:flutter_application_1/data/facebook_link.dart';
import 'package:flutter_application_1/data/shop_store.dart';
import 'package:flutter_application_1/screens/shop_item_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_owner_auth.dart';

const _product = ShopProduct(
  id: 'p1',
  name: 'Rear shock',
  category: 'Suspension',
  description: '',
  price: 250,
  quantity: 200,
);

Shop _shopWith(String contact) => Shop(
  id: 'seller-uid',
  ownerEmailHash: '',
  ownerName: 'Seller',
  name: 'TEST_SHOP',
  location: 'ORO',
  description: '',
  products: const [],
  contact: contact,
  isVerified: true,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('parseFacebookLink', () {
    test('accepts the usual ways owners paste their page', () {
      for (final (input, page, messenger) in [
        (
          'facebook.com/testshop.oro',
          'https://www.facebook.com/testshop.oro',
          'https://m.me/testshop.oro',
        ),
        (
          'https://www.facebook.com/testshop.oro/?ref=page',
          'https://www.facebook.com/testshop.oro',
          'https://m.me/testshop.oro',
        ),
        (
          'm.facebook.com/testshop.oro',
          'https://www.facebook.com/testshop.oro',
          'https://m.me/testshop.oro',
        ),
        (
          'fb.com/testshop.oro',
          'https://www.facebook.com/testshop.oro',
          'https://m.me/testshop.oro',
        ),
        (
          'm.me/testshop.oro',
          'https://www.facebook.com/testshop.oro',
          'https://m.me/testshop.oro',
        ),
        (
          'https://www.facebook.com/profile.php?id=100012345678901',
          'https://www.facebook.com/profile.php?id=100012345678901',
          'https://m.me/100012345678901',
        ),
      ]) {
        final link = parseFacebookLink(input);
        expect(link, isNotNull, reason: input);
        expect(link!.pageUrl, page, reason: input);
        expect(link.messengerUri.toString(), messenger, reason: input);
      }
    });

    test('refuses phone numbers and links that are not a page', () {
      for (final input in [
        '09708738338',
        'google.com/testshop',
        'facebook.com/',
        'facebook.com/groups/motoparts',
        'facebook.com/share/abc123',
        'facebook.com/marketplace/item/1',
      ]) {
        expect(parseFacebookLink(input), isNull, reason: input);
        expect(validateFacebookLink(input), isNotNull, reason: input);
      }
      expect(
        validateFacebookLink('09708738338'),
        contains('not a phone number'),
      );
      expect(validateFacebookLink(''), isNull, reason: 'optional');
    });
  });

  test('saving a shop stores a clean Facebook page link', () async {
    final store = ShopStore(ownerAuth: FakeOwnerAuth());
    addTearDown(store.dispose);
    const owner = 'fb-owner@example.com';
    await store.createOwner(
      name: 'Owner',
      email: owner,
      password: 'temporary123',
    );
    await store.saveShop(
      ownerEmail: owner,
      name: 'TEST_SHOP',
      location: 'ORO',
      description: '',
      contact: 'm.facebook.com/testshop.oro?ref=bookmarks',
    );
    expect(
      store.shopForOwner(owner)!.contact,
      'https://www.facebook.com/testshop.oro',
    );

    expect(
      () => store.saveShop(
        ownerEmail: owner,
        name: 'TEST_SHOP',
        location: 'ORO',
        description: '',
        contact: '09708738338',
      ),
      throwsStateError,
    );
  });

  testWidgets('buyers message the shop on Facebook from an item', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final opened = <Uri>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ShopItemPage(
          shop: _shopWith('https://www.facebook.com/testshop.oro'),
          product: _product,
          chatService: ChatService(InMemoryChatBackend()),
          openLink: (uri) async {
            opened.add(uri);
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('message-on-facebook')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('message-on-facebook')));
    await tester.tap(find.byKey(const ValueKey('view-facebook-page')));
    expect(opened.map((uri) => uri.toString()), [
      'https://m.me/testshop.oro',
      'https://www.facebook.com/testshop.oro',
    ]);
    // The phone-number fallback is not shown for Facebook pages.
    expect(find.byKey(const ValueKey('contact-seller-outside')), findsNothing);
  });

  testWidgets('older shops with a phone number still show Call or text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: ShopItemPage(
          shop: _shopWith('09708738338'),
          product: _product,
          chatService: ChatService(InMemoryChatBackend()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('message-seller')),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byKey(const ValueKey('message-on-facebook')), findsNothing);
    expect(find.text('Call or text: 09708738338'), findsOneWidget);
  });
}

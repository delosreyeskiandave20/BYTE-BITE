import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/chat.dart';
import 'package:flutter_application_1/models/shop.dart';
import 'package:flutter_application_1/screens/chat_pages.dart';
import 'package:flutter_application_1/screens/shop_item_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _shop = Shop(
  id: 'seller-uid',
  ownerEmailHash: '',
  ownerName: 'Seller',
  name: 'TEST_SHOP',
  location: 'ORO',
  description: '',
  products: [],
  isVerified: true,
);

const _product = ShopProduct(
  id: 'p1',
  name: 'Rear shock',
  category: 'Suspension',
  description: '',
  price: 250,
  quantity: 200,
);

void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a buyer messages the seller and the seller replies', (
    tester,
  ) async {
    _tallScreen(tester);
    final backend = InMemoryChatBackend();
    final chat = ChatService(backend);

    await tester.pumpWidget(
      MaterialApp(
        home: ShopItemPage(shop: _shop, product: _product, chatService: chat),
      ),
    );
    await tester.pumpAndSettle();

    // First time: the buyer is asked for a name.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('message-seller')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('message-seller')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('message-seller')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('chat-buyer-name')),
      'Kian',
    );
    await tester.tap(find.byKey(const ValueKey('chat-buyer-name-ok')));
    await tester.pumpAndSettle();

    expect(find.text('TEST_SHOP'), findsOneWidget);
    expect(find.text('About: Rear shock'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-empty')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('chat-input')),
      'Is the rear shock available?',
    );
    await tester.tap(find.byKey(const ValueKey('chat-send')));
    await tester.pumpAndSettle();
    expect(find.text('Is the rear shock available?'), findsOneWidget);

    final buyerUid = backend.currentUid!;
    final chatId = ChatThread.idFor('seller-uid', buyerUid);
    final stored = await backend.thread(chatId).first;
    expect(stored!.buyerName, 'Kian');
    expect(stored.sellerUnread, 1);
    expect(await chat.savedBuyerName(), 'Kian');

    // The seller sees the chat with one unread message, then replies.
    backend.currentUid = 'seller-uid';
    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('seller-app'),
        home: ChatInboxPage(shopId: 'seller-uid', service: chat),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kian'), findsOneWidget);
    expect(find.text('Is the rear shock available?'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('inbox-$chatId')));
    await tester.pumpAndSettle();
    expect((await backend.thread(chatId).first)!.sellerUnread, 0);

    await tester.enterText(
      find.byKey(const ValueKey('chat-input')),
      'Yes, 200 in stock.',
    );
    await tester.tap(find.byKey(const ValueKey('chat-send')));
    await tester.pumpAndSettle();
    expect((await backend.thread(chatId).first)!.buyerUnread, 1);

    // Back as the buyer: their inbox shows the reply as unread.
    backend.currentUid = buyerUid;
    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('buyer-app'),
        home: ChatInboxPage(service: chat),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('TEST_SHOP'), findsOneWidget);
    expect(find.text('Yes, 200 in stock.'), findsOneWidget);
  });

  testWidgets('the name is asked only once', (tester) async {
    _tallScreen(tester);
    SharedPreferences.setMockInitialValues({'chat_buyer_name': 'Kian'});
    final chat = ChatService(InMemoryChatBackend());

    await tester.pumpWidget(
      MaterialApp(
        home: ShopItemPage(shop: _shop, product: _product, chatService: chat),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('message-seller')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('message-seller')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('message-seller')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('chat-buyer-name')), findsNothing);
    expect(find.byKey(const ValueKey('chat-input')), findsOneWidget);
  });

  test('sellers cannot start a chat with their own shop', () async {
    final chat = ChatService(InMemoryChatBackend('seller-uid'));
    expect(
      () => chat.startChat(
        shopId: 'seller-uid',
        shopName: 'TEST_SHOP',
        buyerName: 'Seller',
      ),
      throwsA(isA<ChatException>()),
    );
  });

  test('long messages are refused', () async {
    final chat = ChatService(InMemoryChatBackend());
    final thread = await chat.startChat(
      shopId: 'seller-uid',
      shopName: 'TEST_SHOP',
      buyerName: 'Kian',
    );
    expect(
      () => chat.send(
        thread,
        'x' * (maxChatMessageLength + 1),
        asSeller: false,
        isNew: true,
      ),
      throwsA(isA<ChatException>()),
    );
  });
}

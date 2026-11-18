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

/// Like the server rules: listing messages of a chat that is not stored yet
/// fails, and loading can be made to fail on demand.
class _StrictBackend extends InMemoryChatBackend {
  bool failThread = false;

  @override
  Stream<ChatThread?> thread(String chatId) =>
      failThread ? Stream.error(StateError('offline')) : super.thread(chatId);

  @override
  Stream<List<ChatMessage>> messages(String chatId) async* {
    if (await super.thread(chatId).first == null) {
      throw StateError('permission-denied');
    }
    yield* super.messages(chatId);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a buyer messages the seller and the seller replies', (
    tester,
  ) async {
    _tallScreen(tester);
    final backend = InMemoryChatBackend();
    final chat = ChatService(backend);
    final openedItems = <String>[];

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
    // The item the buyer came from waits above the message box.
    expect(find.byKey(const ValueKey('chat-pending-item')), findsOneWidget);
    expect(find.text('Asking about this item'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-empty')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('chat-input')),
      'Is the rear shock available?',
    );
    await tester.tap(find.byKey(const ValueKey('chat-send')));
    await tester.pumpAndSettle();
    expect(find.text('Is the rear shock available?'), findsOneWidget);
    // Sent with the message as a card, and no longer pending.
    expect(find.byKey(const ValueKey('chat-item-p1')), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-pending-item')), findsNothing);

    final buyerUid = backend.currentUid!;
    final chatId = ChatThread.idFor('seller-uid', buyerUid);
    final stored = await backend.thread(chatId).first;
    expect(stored!.buyerName, 'Kian');
    expect(stored.sellerUnread, 1);
    expect(stored.productName, 'Rear shock');
    final sent = await backend.messages(chatId).first;
    expect(sent.single.item!.productId, 'p1');
    expect(sent.single.item!.price, 250);
    expect(await chat.savedBuyerName(), 'Kian');

    // The seller sees the chat with one unread message, then replies.
    backend.currentUid = 'seller-uid';
    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('seller-app'),
        home: ChatInboxPage(
          shopId: 'seller-uid',
          service: chat,
          openItem: (context, thread, item) => openedItems.add(item.productId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kian'), findsOneWidget);
    // The seller sees which item the buyer wants before opening the chat.
    expect(find.text('Item: Rear shock'), findsOneWidget);
    expect(find.text('Is the rear shock available?'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('inbox-$chatId')));
    await tester.pumpAndSettle();
    expect((await backend.thread(chatId).first)!.sellerUnread, 0);

    // Inside the chat the item card is shown and opens the item.
    expect(find.text('Rear shock'), findsOneWidget);
    expect(find.text('₱250.00'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('chat-item-p1')));
    await tester.pumpAndSettle();
    expect(openedItems, ['p1']);

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

  testWidgets('each item a buyer asks about shows as its own card', (
    tester,
  ) async {
    final backend = InMemoryChatBackend();
    final chat = ChatService(backend);
    final thread = await chat.startChat(
      shopId: 'seller-uid',
      shopName: 'TEST_SHOP',
      buyerName: 'Kian',
    );
    const shock = ChatItem(productId: 'p1', name: 'Rear shock', price: 250);
    const battery = ChatItem(productId: 'p2', name: 'Battery', price: 1200);
    await chat.send(
      thread,
      'Is this available?',
      asSeller: false,
      isNew: true,
      item: shock,
    );
    await chat.send(
      thread,
      'How about this one?',
      asSeller: false,
      isNew: false,
      item: battery,
    );
    await chat.send(thread, 'Thanks!', asSeller: false, isNew: false);

    final stored = await backend.thread(thread.id).first;
    expect(stored!.productName, 'Battery', reason: 'inbox shows the latest');

    backend.currentUid = 'seller-uid';
    await tester.pumpWidget(
      MaterialApp(
        home: ChatPage(service: chat, thread: stored, asSeller: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-item-p1')), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-item-p2')), findsOneWidget);
    expect(find.text('₱1,200.00'), findsOneWidget);
    // A message without an item has no card.
    expect(find.text('Thanks!'), findsOneWidget);
  });

  testWidgets('the buyer can remove the item before sending', (tester) async {
    final backend = InMemoryChatBackend();
    final chat = ChatService(backend);
    final thread = await chat.startChat(
      shopId: 'seller-uid',
      shopName: 'TEST_SHOP',
      buyerName: 'Kian',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChatPage(
          service: chat,
          thread: thread,
          asSeller: false,
          attachedItem: const ChatItem(
            productId: 'p1',
            name: 'Rear shock',
            price: 250,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('chat-pending-item-remove')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('chat-input')), 'Hello');
    await tester.tap(find.byKey(const ValueKey('chat-send')));
    await tester.pumpAndSettle();

    final sent = await backend.messages(thread.id).first;
    expect(sent.single.item, isNull);
  });

  testWidgets('a new chat opens, then shows the whole conversation', (
    tester,
  ) async {
    final backend = _StrictBackend();
    final chat = ChatService(backend);
    final thread = await chat.startChat(
      shopId: 'seller-uid',
      shopName: 'TEST_SHOP',
      buyerName: 'Kian',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChatPage(service: chat, thread: thread, asSeller: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Can't load messages"), findsNothing);
    expect(find.byKey(const ValueKey('chat-empty')), findsOneWidget);

    for (final text in ['Hello', 'Is it available?']) {
      await tester.enterText(find.byKey(const ValueKey('chat-input')), text);
      await tester.tap(find.byKey(const ValueKey('chat-send')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Is it available?'), findsOneWidget);

    // Opening the chat again later shows the earlier messages.
    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('reopened'),
        home: ChatPage(service: chat, thread: thread, asSeller: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Is it available?'), findsOneWidget);
  });

  testWidgets('a load error explains itself and can be retried', (
    tester,
  ) async {
    final backend = _StrictBackend()..failThread = true;
    final chat = ChatService(backend);
    final thread = await chat.startChat(
      shopId: 'seller-uid',
      shopName: 'TEST_SHOP',
      buyerName: 'Kian',
    );
    await chat.send(thread, 'Earlier message', asSeller: false, isNew: true);

    await tester.pumpWidget(
      MaterialApp(
        home: ChatPage(service: chat, thread: thread, asSeller: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Can't load messages"), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-load-error')), findsOneWidget);

    backend.failThread = false;
    await tester.tap(find.byKey(const ValueKey('chat-retry')));
    await tester.pumpAndSettle();
    expect(find.text('Earlier message'), findsOneWidget);
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

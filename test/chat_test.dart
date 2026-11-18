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

  testWidgets('My messages lists every conversation and opens the full chat', (
    tester,
  ) async {
    final backend = InMemoryChatBackend();
    final chat = ChatService(backend);

    // Nobody is signed in yet: the inbox is empty, then fills in live.
    await tester.pumpWidget(MaterialApp(home: ChatInboxPage(service: chat)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('inbox-empty')), findsOneWidget);

    // "me" asks another shop as a buyer...
    backend.currentUid = 'me';
    final asBuyer = await chat.startChat(
      shopId: 'other-shop',
      shopName: 'Other Moto',
      buyerName: 'Me',
    );
    await chat.send(
      asBuyer,
      'Do you have tires?',
      asSeller: false,
      isNew: true,
    );
    await chat.send(asBuyer, 'Size 90/90', asSeller: false, isNew: false);

    // ...and a customer messages "me"'s own shop.
    backend.currentUid = 'customer';
    final asShop = await chat.startChat(
      shopId: 'me',
      shopName: 'My Shop',
      buyerName: 'Ana',
    );
    await chat.send(
      asShop,
      'Is the battery new?',
      asSeller: false,
      isNew: true,
    );
    backend.currentUid = 'me';
    await tester.pumpAndSettle();

    expect(find.text('Other Moto'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    // The customer's unread message shows on their row.
    expect(find.text('1'), findsOneWidget);

    // Tapping a row opens the whole conversation.
    await tester.tap(find.byKey(ValueKey('inbox-${asBuyer.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Do you have tires?'), findsOneWidget);
    expect(find.text('Size 90/90'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('inbox-${asShop.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Is the battery new?'), findsOneWidget);
    // Opened as the shop, so the customer's message is marked read.
    expect((await backend.thread(asShop.id).first)!.sellerUnread, 0);
  });

  testWidgets('one row per buyer, with the last message and unread total', (
    tester,
  ) async {
    final backend = InMemoryChatBackend();
    final chat = ChatService(backend);

    Future<void> buyerSays(String uid, String name, List<String> texts) async {
      backend.currentUid = uid;
      final thread = await chat.startChat(
        shopId: 'seller-uid',
        shopName: 'TEST_SHOP',
        buyerName: name,
      );
      for (final (index, text) in texts.indexed) {
        await chat.send(thread, text, asSeller: false, isNew: index == 0);
      }
    }

    await buyerSays('guest-a', 'Kian', [
      'Hi',
      'Is the shock new?',
      'Any battery?',
    ]);
    await buyerSays('guest-c', 'Ana', ['Hello']);

    backend.currentUid = 'seller-uid';
    await tester.pumpWidget(
      MaterialApp(
        home: ChatInboxPage(shopId: 'seller-uid', service: chat),
      ),
    );
    await tester.pumpAndSettle();

    // One row per buyer.
    expect(find.text('Kian'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
    // Kian's row: their newest message, and all 3 unread in one red badge.
    expect(find.text('Any battery?'), findsOneWidget);
    expect(find.text('Is the shock new?'), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // Opening the row shows the whole conversation, in order, and reads it.
    await tester.tap(find.text('Kian'));
    await tester.pumpAndSettle();
    expect(find.text('Hi'), findsOneWidget);
    expect(find.text('Is the shock new?'), findsOneWidget);
    expect(find.text('Any battery?'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Hi')).dy,
      lessThan(tester.getTopLeft(find.text('Any battery?')).dy),
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('3'), findsNothing);
    expect(find.text('1'), findsOneWidget, reason: "Ana's is still unread");
  });

  testWidgets('a stranger using the same name gets their own row', (
    tester,
  ) async {
    final backend = InMemoryChatBackend();
    final chat = ChatService(backend);
    for (final (uid, text) in [
      ('real-kian', 'Can you hold the shock for me?'),
      ('impostor', 'Send me your address'),
    ]) {
      backend.currentUid = uid;
      final thread = await chat.startChat(
        shopId: 'seller-uid',
        shopName: 'TEST_SHOP',
        buyerName: 'Kian',
      );
      await chat.send(thread, text, asSeller: false, isNew: true);
    }

    backend.currentUid = 'seller-uid';
    await tester.pumpWidget(
      MaterialApp(
        home: ChatInboxPage(shopId: 'seller-uid', service: chat),
      ),
    );
    await tester.pumpAndSettle();

    // Two separate rows, so the seller never replies into the wrong chat.
    expect(find.text('Kian'), findsNWidgets(2));
    await tester.tap(find.text('Can you hold the shock for me?'));
    await tester.pumpAndSettle();
    expect(find.text('Can you hold the shock for me?'), findsOneWidget);
    expect(find.text('Send me your address'), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('chat-input')), 'Yes');
    await tester.tap(find.byKey(const ValueKey('chat-send')));
    await tester.pumpAndSettle();
    final impostorChat = ChatThread.idFor('seller-uid', 'impostor');
    final impostorMessages = await backend.messages(impostorChat).first;
    expect(impostorMessages.map((m) => m.text), ['Send me your address']);
  });

  testWidgets('buyer chats stay after a seller signs in and out', (
    tester,
  ) async {
    // Two separate sign-ins to the same chats, like the app's buyer-chat
    // Firebase app (guest) and default app (shop owner).
    final guest = InMemoryChatBackend();
    final owner = InMemoryChatBackend.sharedWith(guest);
    final chat = ChatService(guest, sellerBackend: owner);

    final asBuyer = await chat.startChat(
      shopId: 'other-shop',
      shopName: 'Other Moto',
      buyerName: 'Kian',
    );
    await chat.send(
      asBuyer,
      'Do you have tires?',
      asSeller: false,
      isNew: true,
    );

    // A customer writes to the owner's shop.
    final customer = InMemoryChatBackend.sharedWith(guest, 'customer');
    final customerChat = ChatService(customer);
    final toMyShop = await customerChat.startChat(
      shopId: 'my-shop',
      shopName: 'My Shop',
      buyerName: 'Ana',
    );
    await customerChat.send(
      toMyShop,
      'Is the battery new?',
      asSeller: false,
      isNew: true,
    );

    await tester.pumpWidget(MaterialApp(home: ChatInboxPage(service: chat)));
    await tester.pumpAndSettle();
    expect(find.text('Other Moto'), findsOneWidget);
    expect(find.text('Ana'), findsNothing);

    // The owner signs in: their customers appear next to the buyer chats.
    owner.currentUid = 'my-shop';
    await tester.pumpAndSettle();
    expect(find.text('Other Moto'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);

    // The owner signs out: the buyer's chats are still there.
    owner.currentUid = null;
    await tester.pumpAndSettle();
    expect(find.text('Other Moto'), findsOneWidget);
    expect(find.text('Ana'), findsNothing);
    expect(chat.currentUid, isNotNull, reason: 'guest account kept');

    // And the whole conversation still opens.
    await tester.tap(find.text('Other Moto'));
    await tester.pumpAndSettle();
    expect(find.text('Do you have tires?'), findsOneWidget);
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

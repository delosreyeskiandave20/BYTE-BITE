import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_bootstrap.dart';

/// Longest chat message, kept in sync with firestore.rules.
const maxChatMessageLength = 1000;

/// Longest buyer display name, kept in sync with firestore.rules.
const maxChatNameLength = 60;

/// One conversation between a buyer and a shop. Stored at `chats/{id}` where
/// the id is `{shopId}_{buyerUid}`, so a buyer has one chat per shop.
@immutable
class ChatThread {
  const ChatThread({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.buyerUid,
    required this.buyerName,
    this.productName = '',
    this.lastMessage = '',
    this.lastSenderUid = '',
    this.updatedAt = 0,
    this.buyerUnread = 0,
    this.sellerUnread = 0,
  });

  static String idFor(String shopId, String buyerUid) => '${shopId}_$buyerUid';

  factory ChatThread.fromMap(String id, Map<String, dynamic> map) {
    int toInt(Object? value) => (value as num?)?.toInt() ?? 0;
    return ChatThread(
      id: id,
      shopId: map['shopId'] as String? ?? '',
      shopName: map['shopName'] as String? ?? '',
      buyerUid: map['buyerUid'] as String? ?? '',
      buyerName: map['buyerName'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      lastMessage: map['lastMessage'] as String? ?? '',
      lastSenderUid: map['lastSenderUid'] as String? ?? '',
      updatedAt: toInt(map['updatedAt']),
      buyerUnread: toInt(map['buyerUnread']),
      sellerUnread: toInt(map['sellerUnread']),
    );
  }

  final String id;

  /// The shop's document ID, which is also the owner's Firebase Auth UID.
  final String shopId;
  final String shopName;
  final String buyerUid;
  final String buyerName;

  /// The item the buyer asked about most recently, if any.
  final String productName;
  final String lastMessage;
  final String lastSenderUid;

  /// Epoch milliseconds of the last message.
  final int updatedAt;
  final int buyerUnread;
  final int sellerUnread;

  int unreadFor({required bool asSeller}) =>
      asSeller ? sellerUnread : buyerUnread;

  Map<String, dynamic> toMap() => {
    'shopId': shopId,
    'shopName': shopName,
    'buyerUid': buyerUid,
    'buyerName': buyerName,
    'productName': productName,
    'lastMessage': lastMessage,
    'lastSenderUid': lastSenderUid,
    'updatedAt': updatedAt,
    'buyerUnread': buyerUnread,
    'sellerUnread': sellerUnread,
  };

  ChatThread copyWith({
    String? productName,
    String? lastMessage,
    String? lastSenderUid,
    int? updatedAt,
    int? buyerUnread,
    int? sellerUnread,
  }) {
    return ChatThread(
      id: id,
      shopId: shopId,
      shopName: shopName,
      buyerUid: buyerUid,
      buyerName: buyerName,
      productName: productName ?? this.productName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSenderUid: lastSenderUid ?? this.lastSenderUid,
      updatedAt: updatedAt ?? this.updatedAt,
      buyerUnread: buyerUnread ?? this.buyerUnread,
      sellerUnread: sellerUnread ?? this.sellerUnread,
    );
  }
}

/// The shop item a message asks about, copied onto the message so the seller
/// sees it even if the listing later changes.
@immutable
class ChatItem {
  const ChatItem({
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl = '',
  });

  final String productId;
  final String name;
  final double price;

  /// Cover photo link; empty for bundled demo photos, which cannot be shared.
  final String imageUrl;

  static ChatItem? fromMap(Map<String, dynamic> map) {
    final productId = map['productId'];
    final name = map['productName'];
    if (productId is! String || productId.isEmpty) return null;
    if (name is! String || name.isEmpty) return null;
    return ChatItem(
      productId: productId,
      name: name,
      price: (map['productPrice'] as num?)?.toDouble() ?? 0,
      imageUrl: map['productImage'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': name,
    'productPrice': price,
    'productImage': imageUrl,
  };
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderUid,
    required this.text,
    required this.sentAt,
    this.item,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      senderUid: map['senderUid'] as String? ?? '',
      text: map['text'] as String? ?? '',
      sentAt: (map['sentAt'] as num?)?.toInt() ?? 0,
      item: ChatItem.fromMap(map),
    );
  }

  final String id;
  final String senderUid;
  final String text;

  /// Epoch milliseconds.
  final int sentAt;

  /// The item this message asks about, if the buyer sent it from an item.
  final ChatItem? item;

  Map<String, dynamic> toMap() => {
    'senderUid': senderUid,
    'text': text,
    'sentAt': sentAt,
    ...?item?.toMap(),
  };
}

/// Shown to people when chat cannot be used.
class ChatException implements Exception {
  const ChatException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Where chats are stored. [FirestoreChatBackend] in the app; the in-memory
/// one for tests and previews without Firebase.
abstract class ChatBackend {
  /// The signed-in user's UID, or null before [signInAsGuest].
  String? get currentUid;

  /// Signs in a guest account when nobody is signed in, and returns the UID.
  Future<String> signInAsGuest();

  /// The signed-in UID now and whenever it changes (sign-in, sign-out).
  Stream<String?> userChanges();

  Stream<List<ChatThread>> buyerThreads(String buyerUid);
  Stream<List<ChatThread>> shopThreads(String shopId);
  Stream<ChatThread?> thread(String chatId);
  Stream<List<ChatMessage>> messages(String chatId);

  /// Adds [text] from [senderUid], with the [item] it asks about; creates
  /// [thread] first when it is new.
  Future<void> send(
    ChatThread thread,
    String senderUid,
    String text, {
    required bool fromSeller,
    required bool isNew,
    ChatItem? item,
  });

  Future<void> markRead(String chatId, {required bool asSeller});
}

/// Chats in Cloud Firestore. Guests sign in with Firebase Anonymous Auth.
class FirestoreChatBackend implements ChatBackend {
  FirestoreChatBackend(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Stream<String?> userChanges() =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<String> signInAsGuest() async {
    final user = _auth.currentUser;
    if (user != null) return user.uid;
    try {
      final credential = await _auth.signInAnonymously();
      final uid = credential.user?.uid;
      if (uid == null) throw const ChatException('Could not start a chat.');
      return uid;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'operation-not-allowed' ||
          error.code == 'admin-restricted-operation') {
        throw const ChatException(
          'Chat is not switched on yet. The app admin needs to enable '
          'Anonymous sign-in in the Firebase console.',
        );
      }
      throw ChatException(
        'Could not start a chat. Check your connection and try again.',
      );
    }
  }

  List<ChatThread> _threads(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final threads = [
      for (final doc in snapshot.docs) ChatThread.fromMap(doc.id, doc.data()),
    ];
    // Sorted here so the query needs no composite index.
    threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return threads;
  }

  @override
  Stream<List<ChatThread>> buyerThreads(String buyerUid) =>
      _chats.where('buyerUid', isEqualTo: buyerUid).snapshots().map(_threads);

  @override
  Stream<List<ChatThread>> shopThreads(String shopId) =>
      _chats.where('shopId', isEqualTo: shopId).snapshots().map(_threads);

  @override
  Stream<ChatThread?> thread(String chatId) {
    // A chat this device is still creating is reported as not existing until
    // the server confirms it: the server refuses to list the messages of a
    // chat it does not have yet, and a refused listener never recovers.
    var confirmed = false;
    return _chats
        .doc(chatId)
        .snapshots(includeMetadataChanges: true)
        .map((doc) {
          final data = doc.data();
          if (data == null) return null;
          if (!doc.metadata.hasPendingWrites) confirmed = true;
          return confirmed ? ChatThread.fromMap(doc.id, data) : null;
        })
        .distinct(_sameThread);
  }

  /// Metadata-only changes emit again; skip them unless the chat changed.
  static bool _sameThread(ChatThread? a, ChatThread? b) {
    if (a == null || b == null) return a == b;
    return a.updatedAt == b.updatedAt &&
        a.buyerUnread == b.buyerUnread &&
        a.sellerUnread == b.sellerUnread &&
        a.lastMessage == b.lastMessage &&
        a.productName == b.productName;
  }

  @override
  Stream<List<ChatMessage>> messages(String chatId) => _chats
      .doc(chatId)
      .collection('messages')
      .orderBy('sentAt')
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs)
            ChatMessage.fromMap(doc.id, doc.data()),
        ],
      );

  @override
  Future<void> send(
    ChatThread thread,
    String senderUid,
    String text, {
    required bool fromSeller,
    required bool isNew,
    ChatItem? item,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final chatRef = _chats.doc(thread.id);
    final messageRef = chatRef.collection('messages').doc();
    final batch = _firestore.batch();
    // The summary names the new message and the server time, which the
    // security rules check (no faked previews, one message per second).
    final proof = {
      'lastMessageId': messageRef.id,
      'lastSentAt': FieldValue.serverTimestamp(),
    };
    if (isNew) {
      batch.set(chatRef, {
        ...thread
            .copyWith(
              productName: item?.name,
              lastMessage: text,
              lastSenderUid: senderUid,
              updatedAt: now,
              buyerUnread: fromSeller ? 1 : 0,
              sellerUnread: fromSeller ? 0 : 1,
            )
            .toMap(),
        ...proof,
      });
    } else {
      batch.update(chatRef, {
        'lastMessage': text,
        'lastSenderUid': senderUid,
        'updatedAt': now,
        'productName': ?item?.name,
        fromSeller ? 'buyerUnread' : 'sellerUnread': FieldValue.increment(1),
        ...proof,
      });
    }
    batch.set(
      messageRef,
      ChatMessage(
        id: messageRef.id,
        senderUid: senderUid,
        text: text,
        sentAt: now,
        item: item,
      ).toMap(),
    );
    await batch.commit();
  }

  @override
  Future<void> markRead(String chatId, {required bool asSeller}) {
    return _chats.doc(chatId).update({
      asSeller ? 'sellerUnread' : 'buyerUnread': 0,
    });
  }
}

/// Keeps chats in memory. Used by tests and by previews without Firebase.
class InMemoryChatBackend implements ChatBackend {
  InMemoryChatBackend([this._uid])
    : _threads = {},
      _messages = {},
      _changes = StreamController<void>.broadcast();

  /// Another sign-in to the same chats as [other], like a second Firebase app
  /// on the same project.
  InMemoryChatBackend.sharedWith(InMemoryChatBackend other, [this._uid])
    : _threads = other._threads,
      _messages = other._messages,
      _changes = other._changes;

  String? _uid;
  final Map<String, ChatThread> _threads;
  final Map<String, List<ChatMessage>> _messages;
  final StreamController<void> _changes;
  var _nextId = 0;

  /// Switches who is "signed in", e.g. to reply as the seller in a test.
  set currentUid(String? uid) {
    _uid = uid;
    _changes.add(null);
  }

  @override
  String? get currentUid => _uid;

  @override
  Future<String> signInAsGuest() async {
    if (_uid == null) currentUid = 'guest-${_nextId++}';
    return _uid!;
  }

  @override
  Stream<String?> userChanges() => _watch(() => _uid).distinct();

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  List<ChatThread> _sorted(bool Function(ChatThread) test) =>
      _threads.values.where(test).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Stream<List<ChatThread>> buyerThreads(String buyerUid) =>
      _watch(() => _sorted((t) => t.buyerUid == buyerUid));

  @override
  Stream<List<ChatThread>> shopThreads(String shopId) =>
      _watch(() => _sorted((t) => t.shopId == shopId));

  @override
  Stream<ChatThread?> thread(String chatId) => _watch(() => _threads[chatId]);

  @override
  Stream<List<ChatMessage>> messages(String chatId) =>
      _watch(() => List.unmodifiable(_messages[chatId] ?? const []));

  @override
  Future<void> send(
    ChatThread thread,
    String senderUid,
    String text, {
    required bool fromSeller,
    required bool isNew,
    ChatItem? item,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch + _nextId;
    final current = _threads[thread.id] ?? thread;
    _threads[thread.id] = current.copyWith(
      productName: item?.name,
      lastMessage: text,
      lastSenderUid: senderUid,
      updatedAt: now,
      buyerUnread: current.buyerUnread + (fromSeller ? 1 : 0),
      sellerUnread: current.sellerUnread + (fromSeller ? 0 : 1),
    );
    (_messages[thread.id] ??= []).add(
      ChatMessage(
        id: 'm-$senderUid-${_nextId++}',
        senderUid: senderUid,
        text: text,
        sentAt: now,
        item: item,
      ),
    );
    _changes.add(null);
  }

  @override
  Future<void> markRead(String chatId, {required bool asSeller}) async {
    final thread = _threads[chatId];
    if (thread == null) return;
    _threads[chatId] = asSeller
        ? thread.copyWith(sellerUnread: 0)
        : thread.copyWith(buyerUnread: 0);
    _changes.add(null);
  }
}

/// Chat between buyers and sellers: who is chatting, and the buyer's name.
class ChatService {
  /// [backend] is signed in as the buyer's guest account; [sellerBackend]
  /// as the shop owner. They are separate sign-ins, so an owner signing in or
  /// out never replaces the buyer's guest account. Tests may pass one backend
  /// for both.
  ChatService(this.backend, {ChatBackend? sellerBackend})
    : sellerBackend = sellerBackend ?? backend;

  /// Buyer side: the guest account that starts chats with shops.
  final ChatBackend backend;

  /// Seller side: the shop owner's account, which answers customers.
  final ChatBackend sellerBackend;

  /// The backend to read and write [asSeller]'s side of a chat with.
  ChatBackend backendFor({required bool asSeller}) =>
      asSeller ? sellerBackend : backend;

  /// The UID that sends messages on [asSeller]'s side.
  String? uidFor({required bool asSeller}) =>
      backendFor(asSeller: asSeller).currentUid;

  static const _buyerNameKey = 'chat_buyer_name';

  static ChatService? _shared;

  /// The app-wide service: Firestore when Firebase is set up, otherwise an
  /// in-memory one so previews still work. Buyers chat through the separate
  /// buyer-chat Firebase app; sellers through the default app they sign in
  /// to.
  static ChatService get shared => _shared ??= _createShared();

  static ChatService _createShared() {
    if (Firebase.apps.isEmpty) return ChatService(InMemoryChatBackend());
    final seller = FirestoreChatBackend(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
    final chatApp = FirebaseBootstrap.chatApp;
    final buyer = chatApp == null
        ? seller
        : FirestoreChatBackend(
            FirebaseFirestore.instanceFor(app: chatApp),
            FirebaseAuth.instanceFor(app: chatApp),
          );
    return ChatService(buyer, sellerBackend: seller);
  }

  String? get currentUid => backend.currentUid;

  /// The name this buyer chose before, or null the first time.
  Future<String?> savedBuyerName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_buyerNameKey)?.trim();
      return name == null || name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBuyerName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_buyerNameKey, name.trim());
    } catch (_) {
      // The name is asked again next time; chatting still works.
    }
  }

  /// The chat between the signed-in buyer and [shopId], signing in a guest
  /// first when needed. Not yet stored: it is saved with the first message.
  Future<ChatThread> startChat({
    required String shopId,
    required String shopName,
    required String buyerName,
    String productName = '',
  }) async {
    if (sellerBackend.currentUid == shopId) {
      throw const ChatException('This is your own shop.');
    }
    final uid = await backend.signInAsGuest();
    if (uid == shopId) {
      throw const ChatException('This is your own shop.');
    }
    return ChatThread(
      id: ChatThread.idFor(shopId, uid),
      shopId: shopId,
      shopName: shopName,
      buyerUid: uid,
      buyerName: buyerName.trim(),
      productName: productName,
    );
  }

  /// Every conversation on this device, newest first: the guest's chats
  /// with shops and, when a shop owner is signed in, chats from their
  /// customers. Follows both sign-ins, so it fills in once a guest account
  /// exists and keeps the guest's chats when an owner signs in or out.
  Stream<List<ChatThread>> myThreads() {
    late final StreamController<List<ChatThread>> controller;
    final subscriptions = <StreamSubscription<Object?>>[];
    StreamSubscription<List<ChatThread>>? buyerInner;
    StreamSubscription<List<ChatThread>>? shopInner;
    // Null until that side has reported once.
    List<ChatThread>? asBuyer;
    List<ChatThread>? asShop;

    void emit() {
      final buyer = asBuyer;
      final shop = asShop;
      if (buyer == null || shop == null) return;
      final byId = {
        for (final thread in [...buyer, ...shop]) thread.id: thread,
      };
      controller.add(
        byId.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
      );
    }

    controller = StreamController<List<ChatThread>>(
      onListen: () {
        subscriptions
          ..add(
            backend.userChanges().listen((uid) {
              buyerInner?.cancel();
              buyerInner = null;
              if (uid == null) {
                asBuyer = const [];
                emit();
                return;
              }
              buyerInner = backend.buyerThreads(uid).listen((threads) {
                asBuyer = threads;
                emit();
              }, onError: controller.addError);
            }, onError: controller.addError),
          )
          ..add(
            sellerBackend.userChanges().listen((uid) {
              shopInner?.cancel();
              shopInner = null;
              if (uid == null) {
                asShop = const [];
                emit();
                return;
              }
              shopInner = sellerBackend.shopThreads(uid).listen((threads) {
                asShop = threads;
                emit();
              }, onError: controller.addError);
            }, onError: controller.addError),
          );
      },
      onCancel: () async {
        await buyerInner?.cancel();
        await shopInner?.cancel();
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  /// Whether the signed-in user is the shop in [thread].
  bool isSellerIn(ChatThread thread) =>
      sellerBackend.currentUid != null &&
      sellerBackend.currentUid == thread.shopId;

  /// Sends [text] in [thread] from the signed-in user, with the [item] it
  /// asks about.
  Future<void> send(
    ChatThread thread,
    String text, {
    required bool asSeller,
    required bool isNew,
    ChatItem? item,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > maxChatMessageLength) {
      throw const ChatException(
        'Messages can be up to $maxChatMessageLength characters.',
      );
    }
    final sender = backendFor(asSeller: asSeller);
    final uid = sender.currentUid;
    if (uid == null) throw const ChatException('Sign in to send messages.');
    await sender.send(
      thread,
      uid,
      trimmed,
      fromSeller: asSeller,
      isNew: isNew,
      item: item,
    );
  }
}

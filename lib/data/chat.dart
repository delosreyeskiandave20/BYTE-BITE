import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// The item the buyer started the chat from, if any.
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
      productName: productName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSenderUid: lastSenderUid ?? this.lastSenderUid,
      updatedAt: updatedAt ?? this.updatedAt,
      buyerUnread: buyerUnread ?? this.buyerUnread,
      sellerUnread: sellerUnread ?? this.sellerUnread,
    );
  }
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderUid,
    required this.text,
    required this.sentAt,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      senderUid: map['senderUid'] as String? ?? '',
      text: map['text'] as String? ?? '',
      sentAt: (map['sentAt'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String senderUid;
  final String text;

  /// Epoch milliseconds.
  final int sentAt;

  Map<String, dynamic> toMap() => {
    'senderUid': senderUid,
    'text': text,
    'sentAt': sentAt,
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

  Stream<List<ChatThread>> buyerThreads(String buyerUid);
  Stream<List<ChatThread>> shopThreads(String shopId);
  Stream<ChatThread?> thread(String chatId);
  Stream<List<ChatMessage>> messages(String chatId);

  /// Adds [text] from [senderUid]; creates [thread] first when it is new.
  Future<void> send(
    ChatThread thread,
    String senderUid,
    String text, {
    required bool fromSeller,
    required bool isNew,
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
  Stream<ChatThread?> thread(String chatId) =>
      _chats.doc(chatId).snapshots().map((doc) {
        final data = doc.data();
        return data == null ? null : ChatThread.fromMap(doc.id, data);
      });

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
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final chatRef = _chats.doc(thread.id);
    final messageRef = chatRef.collection('messages').doc();
    final batch = _firestore.batch();
    if (isNew) {
      batch.set(
        chatRef,
        thread
            .copyWith(
              lastMessage: text,
              lastSenderUid: senderUid,
              updatedAt: now,
              buyerUnread: fromSeller ? 1 : 0,
              sellerUnread: fromSeller ? 0 : 1,
            )
            .toMap(),
      );
    } else {
      batch.update(chatRef, {
        'lastMessage': text,
        'lastSenderUid': senderUid,
        'updatedAt': now,
        fromSeller ? 'buyerUnread' : 'sellerUnread': FieldValue.increment(1),
      });
    }
    batch.set(
      messageRef,
      ChatMessage(
        id: messageRef.id,
        senderUid: senderUid,
        text: text,
        sentAt: now,
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
  InMemoryChatBackend([this._uid]);

  String? _uid;
  final _threads = <String, ChatThread>{};
  final _messages = <String, List<ChatMessage>>{};
  final _changes = StreamController<void>.broadcast();
  var _nextId = 0;

  /// Switches who is "signed in", e.g. to reply as the seller in a test.
  set currentUid(String? uid) => _uid = uid;

  @override
  String? get currentUid => _uid;

  @override
  Future<String> signInAsGuest() async => _uid ??= 'guest-${_nextId++}';

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
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch + _nextId;
    final current = _threads[thread.id] ?? thread;
    _threads[thread.id] = current.copyWith(
      lastMessage: text,
      lastSenderUid: senderUid,
      updatedAt: now,
      buyerUnread: current.buyerUnread + (fromSeller ? 1 : 0),
      sellerUnread: current.sellerUnread + (fromSeller ? 0 : 1),
    );
    (_messages[thread.id] ??= []).add(
      ChatMessage(
        id: 'm${_nextId++}',
        senderUid: senderUid,
        text: text,
        sentAt: now,
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
  ChatService(this.backend);

  final ChatBackend backend;

  static const _buyerNameKey = 'chat_buyer_name';

  static ChatService? _shared;

  /// The app-wide service: Firestore when Firebase is set up, otherwise an
  /// in-memory one so previews still work.
  static ChatService get shared => _shared ??= ChatService(
    Firebase.apps.isNotEmpty
        ? FirestoreChatBackend(
            FirebaseFirestore.instance,
            FirebaseAuth.instance,
          )
        : InMemoryChatBackend(),
  );

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
    final uid = await backend.signInAsGuest();
    if (uid == shopId) {
      throw const ChatException('This is your own shop.');
    }
    return ChatThread(
      id: ChatThread.idFor(shopId, uid),
      shopId: shopId,
      shopName: shopName,
      buyerUid: uid,
      buyerName: buyerName,
      productName: productName,
    );
  }

  /// Sends [text] in [thread] from the signed-in user.
  Future<void> send(
    ChatThread thread,
    String text, {
    required bool asSeller,
    required bool isNew,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > maxChatMessageLength) {
      throw const ChatException(
        'Messages can be up to $maxChatMessageLength characters.',
      );
    }
    final uid = backend.currentUid;
    if (uid == null) throw const ChatException('Sign in to send messages.');
    await backend.send(
      thread,
      uid,
      trimmed,
      fromSeller: asSeller,
      isNew: isNew,
    );
  }
}

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../data/chat.dart';
import '../data/price_format.dart';
import '../data/shop_store.dart';
import '../theme/app_theme.dart';
import 'shop_item_page.dart';

/// Opens the shop item a chat message asks about. Null leaves cards
/// untappable.
typedef ChatItemOpener = void Function(
  BuildContext context,
  ChatThread thread,
  ChatItem item,
);

/// Finds the item in [store] and opens its page, or says it is gone.
ChatItemOpener chatItemOpenerFor(ShopStore store) => (context, thread, item) {
  final shop = store.shops.where((s) => s.id == thread.shopId).firstOrNull;
  final product = shop?.products
      .where((p) => p.id == item.productId)
      .firstOrNull;
  if (shop == null || product == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This item is no longer listed.')),
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ShopItemPage(shop: shop, product: product),
    ),
  );
};

/// The item a buyer is asking about, from a shop listing.
ChatItem chatItemFor(ShopProduct product) {
  final cover = product.imageUrl.trim();
  return ChatItem(
    productId: product.id,
    name: product.name,
    price: product.price,
    imageUrl: cover.startsWith('https://') ? cover : '',
  );
}

/// Asks the buyer for their name the first time, then opens their chat with
/// the shop. Shows a message instead when chat cannot be started.
Future<void> openChatWithShop(
  BuildContext context, {
  required String shopId,
  required String shopName,
  ChatItem? item,
  ChatItemOpener? openItem,
  ChatService? service,
}) async {
  final chat = service ?? ChatService.shared;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  var name = await chat.savedBuyerName();
  if (name == null) {
    if (!context.mounted) return;
    name = await showDialog<String>(
      context: context,
      builder: (_) => const _BuyerNameDialog(),
    );
    if (name == null || name.trim().isEmpty) return;
    await chat.saveBuyerName(name);
  }
  try {
    final thread = await chat.startChat(
      shopId: shopId,
      shopName: shopName,
      buyerName: name,
      productName: item?.name ?? '',
    );
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(
          service: chat,
          thread: thread,
          asSeller: false,
          attachedItem: item,
          openItem: openItem,
        ),
      ),
    );
  } on ChatException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open the chat. Try again.')),
    );
  }
}

class _BuyerNameDialog extends StatefulWidget {
  const _BuyerNameDialog();

  @override
  State<_BuyerNameDialog> createState() => _BuyerNameDialogState();
}

class _BuyerNameDialogState extends State<_BuyerNameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your name'),
      content: TextField(
        key: const ValueKey('chat-buyer-name'),
        controller: _controller,
        autofocus: true,
        maxLength: maxChatNameLength,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Shown to the seller',
          counterText: '',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('chat-buyer-name-ok'),
          onPressed: _submit,
          child: const Text('Start chat'),
        ),
      ],
    );
  }
}

String _timeLabel(int millis) {
  if (millis <= 0) return '';
  final time = DateTime.fromMillisecondsSinceEpoch(millis);
  final now = DateTime.now();
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final clock =
      '$hour:${time.minute.toString().padLeft(2, '0')} '
      '${time.hour < 12 ? 'AM' : 'PM'}';
  if (time.year == now.year && time.month == now.month && time.day == now.day) {
    return clock;
  }
  return '${time.month}/${time.day} $clock';
}

/// One conversation. Messages update live; opening it marks them read.
class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.service,
    required this.thread,
    required this.asSeller,
    this.attachedItem,
    this.openItem,
    super.key,
  });

  final ChatService service;

  /// The item the buyer came from; sent with their next message.
  final ChatItem? attachedItem;

  /// Opens an item when its card is tapped.
  final ChatItemOpener? openItem;

  /// The chat, possibly not stored yet (a buyer's first message saves it).
  final ChatThread thread;

  /// True when the shop owner is replying.
  final bool asSeller;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  StreamSubscription<ChatThread?>? _threadSubscription;
  StreamSubscription<List<ChatMessage>>? _messageSubscription;

  /// Whether we know yet if the chat is stored.
  bool _threadLoaded = false;
  ChatThread? _stored;

  /// The conversation, oldest first; null until it has loaded.
  List<ChatMessage>? _messages;
  Object? _loadError;
  bool _sending = false;
  late ChatItem? _pendingItem = widget.attachedItem;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  /// Watches the chat. Its messages are only read once the chat is stored:
  /// a brand-new chat has none, and the server refuses to list messages of a
  /// chat that does not exist yet.
  void _listen() {
    _threadSubscription?.cancel();
    _messageSubscription?.cancel();
    _messageSubscription = null;
    final backend = widget.service.backend;
    _threadSubscription = backend
        .thread(widget.thread.id)
        .listen(
          (thread) {
            if (!mounted) return;
            setState(() {
              _threadLoaded = true;
              _stored = thread;
            });
            if (thread == null) return;
            _listenToMessages();
            // Keep this side's unread count at zero while the chat is open.
            if (thread.unreadFor(asSeller: widget.asSeller) > 0) {
              backend
                  .markRead(thread.id, asSeller: widget.asSeller)
                  .catchError((_) {});
            }
          },
          onError: (Object error) {
            debugPrint('Chat failed to load: $error');
            if (mounted) setState(() => _loadError = error);
          },
        );
  }

  void _listenToMessages() {
    if (_messageSubscription != null) return;
    _messageSubscription = widget.service.backend
        .messages(widget.thread.id)
        .listen(
          (messages) {
            if (mounted) setState(() => _messages = messages);
          },
          onError: (Object error) {
            debugPrint('Chat messages failed to load: $error');
            if (mounted) setState(() => _loadError = error);
          },
        );
  }

  void _retry() {
    setState(() {
      _loadError = null;
      _threadLoaded = false;
      _messages = null;
    });
    _listen();
  }

  String _loadErrorReason(Object error) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'The chat server is not set up yet. The app admin needs to '
          'deploy the latest Firestore rules.';
    }
    return 'Check your connection and try again.';
  }

  @override
  void dispose() {
    _threadSubscription?.cancel();
    _messageSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildConversation(ChatThread thread, String? me) {
    final error = _loadError;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, color: AppColors.muted),
              const SizedBox(height: 8),
              const Text(
                "Can't load messages",
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _loadErrorReason(error),
                key: const ValueKey('chat-load-error'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('chat-retry'),
                onPressed: _retry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    final messages = _messages;
    final stillLoading =
        !_threadLoaded || (_stored != null && messages == null);
    if (stillLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (messages == null || messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            widget.asSeller
                ? 'No messages yet.'
                : 'Say hello to ${thread.shopName}. Ask about price, stock '
                      'or fit.',
            key: const ValueKey('chat-empty'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ),
      );
    }
    // The whole conversation, newest at the bottom.
    return ListView.builder(
      key: const ValueKey('chat-messages'),
      reverse: true,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        final item = message.item;
        final openItem = widget.openItem;
        return _Bubble(
          message: message,
          mine: message.senderUid == me,
          onOpenItem: item == null || openItem == null
              ? null
              : () => openItem(context, thread, item),
        );
      },
    );
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.service.send(
        _stored ?? widget.thread,
        text,
        asSeller: widget.asSeller,
        isNew: _stored == null,
        item: _pendingItem,
      );
      _controller.clear();
      if (mounted) setState(() => _pendingItem = null);
    } on ChatException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Message not sent. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    final title = widget.asSeller ? thread.buyerName : thread.shopName;
    final me = widget.service.currentUid;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text(
          title.isEmpty ? 'Chat' : title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildConversation(thread, me)),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_pendingItem case final pending?) ...[
                    _PendingItem(
                      item: pending,
                      onRemove: () => setState(() => _pendingItem = null),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('chat-input'),
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: maxChatMessageLength,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Write a message…',
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(
                                color: AppColors.line,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(
                                color: AppColors.line,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        key: const ValueKey('chat-send'),
                        tooltip: 'Send',
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine, this.onOpenItem});

  final ChatMessage message;
  final bool mine;
  final VoidCallback? onOpenItem;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(13, 9, 13, 7),
          decoration: BoxDecoration(
            color: mine ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
            border: mine ? null : Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (message.item case final item?) ...[
                _ChatItemCard(item: item, onTap: onOpenItem),
                const SizedBox(height: 7),
              ],
              Text(
                message.text,
                style: TextStyle(
                  color: mine ? Colors.white : AppColors.ink,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _timeLabel(message.sentAt),
                style: TextStyle(
                  color: mine ? Colors.white70 : AppColors.muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _itemThumb(ChatItem item, double size) {
  const grey = ColoredBox(
    color: Color(0xFFE6E4E0),
    child: Icon(Icons.inventory_2_outlined, color: Color(0xFFB4B0AA)),
  );
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: size,
      height: size,
      child: item.imageUrl.isEmpty
          ? grey
          : Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, sync) =>
                  sync || frame != null ? child : grey,
              errorBuilder: (context, error, stack) => grey,
            ),
    ),
  );
}

/// The item shown inside a message bubble.
class _ChatItemCard extends StatelessWidget {
  const _ChatItemCard({required this.item, this.onTap});

  final ChatItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: ValueKey('chat-item-${item.productId}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _itemThumb(item, 48),
              const SizedBox(width: 9),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatPeso(item.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "Asking about this item" above the message box, until the buyer sends.
class _PendingItem extends StatelessWidget {
  const _PendingItem({required this.item, required this.onRemove});

  final ChatItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('chat-pending-item'),
      padding: const EdgeInsets.fromLTRB(8, 8, 2, 8),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _itemThumb(item, 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Asking about this item',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${item.name} · ${formatPeso(item.price)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('chat-pending-item-remove'),
            tooltip: 'Remove item',
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

/// A list of chats: the buyer's chats with shops, or a shop's chats with
/// buyers when [shopId] is given.
class ChatInboxPage extends StatelessWidget {
  const ChatInboxPage({this.shopId, this.service, this.openItem, super.key});

  /// The seller's shop; null shows the signed-in buyer's chats.
  final String? shopId;
  final ChatService? service;

  /// Opens an item when its card in a chat is tapped.
  final ChatItemOpener? openItem;

  @override
  Widget build(BuildContext context) {
    final chat = service ?? ChatService.shared;
    final asSeller = shopId != null;
    final uid = chat.currentUid;
    final Stream<List<ChatThread>> threads = asSeller
        ? chat.backend.shopThreads(shopId!)
        : uid == null
        ? Stream.value(const [])
        : chat.backend.buyerThreads(uid);
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text(asSeller ? 'Customer messages' : 'My messages'),
      ),
      body: StreamBuilder<List<ChatThread>>(
        stream: threads,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Can't load messages",
                style: TextStyle(color: AppColors.muted),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data!;
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  asSeller
                      ? 'No messages yet. Buyers can message you from your '
                            'items.'
                      : 'No messages yet. Tap "Message seller" on an item to '
                            'ask a shop.',
                  key: const ValueKey('inbox-empty'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final thread = list[index];
              final unread = thread.unreadFor(asSeller: asSeller);
              final name = asSeller ? thread.buyerName : thread.shopName;
              return Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  key: ValueKey('inbox-${thread.id}'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.line),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    foregroundColor: AppColors.primary,
                    child: Icon(
                      asSeller ? Icons.person_outline : Icons.storefront,
                    ),
                  ),
                  title: Text(
                    name.isEmpty ? 'Chat' : name,
                    style: TextStyle(
                      fontWeight: unread > 0
                          ? FontWeight.w900
                          : FontWeight.w700,
                    ),
                  ),
                  // The latest item asked about, so the seller knows what
                  // the buyer wants before opening the chat.
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (thread.productName.isNotEmpty)
                        Text(
                          'Item: ${thread.productName}',
                          key: ValueKey('inbox-item-${thread.id}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        thread.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _timeLabel(thread.updatedAt),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(height: 4),
                        _CountBadge(count: unread),
                      ],
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatPage(
                        service: chat,
                        thread: thread,
                        asSeller: asSeller,
                        openItem: openItem,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      constraints: const BoxConstraints(minWidth: 18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Messages icon with the live unread count, for app bars and buttons.
/// Pass [shopId] for a seller's count; otherwise the buyer's.
class ChatUnreadIcon extends StatelessWidget {
  const ChatUnreadIcon({this.shopId, this.service, super.key});

  final String? shopId;
  final ChatService? service;

  @override
  Widget build(BuildContext context) {
    final chat = service ?? ChatService.shared;
    final uid = chat.currentUid;
    final asSeller = shopId != null;
    final Stream<List<ChatThread>> threads = asSeller
        ? chat.backend.shopThreads(shopId!)
        : uid == null
        ? Stream.value(const [])
        : chat.backend.buyerThreads(uid);
    return StreamBuilder<List<ChatThread>>(
      stream: threads,
      builder: (context, snapshot) {
        final unread = (snapshot.data ?? const <ChatThread>[]).fold<int>(
          0,
          (sum, thread) => sum + thread.unreadFor(asSeller: asSeller),
        );
        return Badge(
          key: const ValueKey('chat-unread-badge'),
          isLabelVisible: unread > 0,
          label: Text(unread > 99 ? '99+' : '$unread'),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.chat_bubble_outline),
        );
      },
    );
  }
}

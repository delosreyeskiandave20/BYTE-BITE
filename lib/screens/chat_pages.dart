import 'dart:async';

import 'package:flutter/material.dart';

import '../data/chat.dart';
import '../theme/app_theme.dart';

/// Asks the buyer for their name the first time, then opens their chat with
/// the shop. Shows a message instead when chat cannot be started.
Future<void> openChatWithShop(
  BuildContext context, {
  required String shopId,
  required String shopName,
  String productName = '',
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
      productName: productName,
    );
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ChatPage(service: chat, thread: thread, asSeller: false),
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
    super.key,
  });

  final ChatService service;

  /// The chat, possibly not stored yet (a buyer's first message saves it).
  final ChatThread thread;

  /// True when the shop owner is replying.
  final bool asSeller;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  late final Stream<List<ChatMessage>> _messages = widget.service.backend
      .messages(widget.thread.id);
  StreamSubscription<ChatThread?>? _readSubscription;
  ChatThread? _stored;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Keep this side's unread count at zero while the chat is open.
    _readSubscription = widget.service.backend.thread(widget.thread.id).listen((
      thread,
    ) {
      _stored = thread;
      if (thread != null && thread.unreadFor(asSeller: widget.asSeller) > 0) {
        widget.service.backend
            .markRead(thread.id, asSeller: widget.asSeller)
            .catchError((_) {});
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _readSubscription?.cancel();
    _controller.dispose();
    super.dispose();
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
      );
      _controller.clear();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.isEmpty ? 'Chat' : title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            if (thread.productName.isNotEmpty)
              Text(
                'About: ${thread.productName}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: AppType.caption,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messages,
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
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        widget.asSeller
                            ? 'No messages yet.'
                            : 'Say hello to ${thread.shopName}. Ask about '
                                  'price, stock or fit.',
                        key: const ValueKey('chat-empty'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  key: const ValueKey('chat-messages'),
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    return _Bubble(
                      message: message,
                      mine: message.senderUid == me,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: Row(
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
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: AppColors.line),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
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
  const _Bubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

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

/// A list of chats: the buyer's chats with shops, or a shop's chats with
/// buyers when [shopId] is given.
class ChatInboxPage extends StatelessWidget {
  const ChatInboxPage({this.shopId, this.service, super.key});

  /// The seller's shop; null shows the signed-in buyer's chats.
  final String? shopId;
  final ChatService? service;

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
                  subtitle: Text(
                    thread.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

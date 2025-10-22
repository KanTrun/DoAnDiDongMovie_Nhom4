import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../state/chat_providers.dart';
import '../state/messages_notifier.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Conversation conversation;
  const ChatScreen({super.key, required this.conversation});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scroll    = ScrollController();
  late final HubController _hub;

  @override
  void initState() {
    super.initState();
    _hub = ref.read(hubControllerProvider.notifier);
    _hub.connect();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hub.joinConversation(widget.conversation.id);
      ref.read(currentOpenConversationIdProvider.notifier).state = widget.conversation.id;
    });
  }

  @override
  void deactivate() {
    // Không dùng ref trong deactivate để tránh "modify provider while building"
    _hub.leaveConversation(widget.conversation.id);
    // Delay việc set currentOpenConversationIdProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(currentOpenConversationIdProvider.notifier).state = null;
      }
    });
    super.deactivate();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scroll.dispose();
    // Cleanup hub connection
    try {
      _hub.leaveConversation(widget.conversation.id);
    } catch (_) {
      // Ignore errors during dispose
    }
    super.dispose();
  }

  bool get _isNearBottom {
    if (!_scroll.hasClients) return true;
    final delta = _scroll.position.maxScrollExtent - _scroll.offset;
    return delta < 120; // đang ở gần đáy
  }

  void _maybeStickToBottom() {
    if (!_scroll.hasClients) return;
    if (_isNearBottom) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    await ref.read(messagesProvider(widget.conversation.id).notifier).sendMessage(text);
    _maybeStickToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversation.id));
    
    // Sử dụng ref.listen một cách an toàn - chỉ trong build method
    ref.listen<AsyncValue<List<Message>>>(
      messagesProvider(widget.conversation.id),
      (prev, next) {
        // Chỉ scroll khi có tin mới và user đang ở gần đáy
        if (prev != next && next.hasValue) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeStickToBottom();
          });
        }
      },
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.conversation.title ?? 'Chat')),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (messagesAsc) {
                // ASC: cũ -> mới. KHÔNG reverse. Tin mới hiển thị dưới.
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  itemCount: messagesAsc.length,
                  itemBuilder: (_, i) {
                    final m = messagesAsc[i];
                    final prev = i > 0 ? messagesAsc[i - 1] : null;
                    final next = i < messagesAsc.length - 1 ? messagesAsc[i + 1] : null;
                    return _MessageBubbleWrapper(
                      message: m, previous: prev, next: next,
                      isGroup: widget.conversation.isGroup,
                    );
                  },
                );
              },
            ),
          ),
          _InputBar(
            controller: _inputCtrl,
            onChanged: (_) => _hub.startTyping(widget.conversation.id),
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.onChanged, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: const Border(top: BorderSide(width: .5, color: Colors.black26)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: (_) => onSend(),
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn…',
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(onPressed: onSend, icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}

class _MessageBubbleWrapper extends StatefulWidget {
  final Message message;
  final Message? previous;
  final Message? next;
  final bool isGroup;
  const _MessageBubbleWrapper({
    required this.message,
    this.previous,
    this.next,
    required this.isGroup,
  });

  @override
  State<_MessageBubbleWrapper> createState() => _MessageBubbleWrapperState();
}

class _MessageBubbleWrapperState extends State<_MessageBubbleWrapper> {
  String? _me;

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    _me = await const FlutterSecureStorage().read(key: 'user_id');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isMe = (widget.message.senderId == _me);
    final samePrev = widget.previous?.senderId == widget.message.senderId;
    final sameNext = widget.next?.senderId == widget.message.senderId;
    
    return Container(
      margin: EdgeInsets.only(top: samePrev ? 2 : 8, bottom: sameNext ? 2 : 8),
      child: _MessageBubble(
        message: widget.message,
        isMe: isMe,
        isGroup: widget.isGroup,
        showAvatar: !sameNext,
        showName: !samePrev,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isGroup;
  final bool showAvatar;
  final bool showName;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isGroup,
    required this.showAvatar,
    required this.showName,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;
    final bg = isMe ? Colors.blue : Colors.grey.shade300;
    final fg = isMe ? Colors.white : Colors.black87;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showName && (message.senderName ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                message.senderName!,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: fg.withOpacity(.9),
                  fontSize: 12,
                ),
              ),
            ),
          Text(message.content ?? '',
              style: TextStyle(color: fg, fontSize: 15, height: 1.25)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(color: fg.withOpacity(.75), fontSize: 11),
              ),
              if (isMe) ...[
                const SizedBox(width: 6),
                Icon(message.isRead ? Icons.done_all : Icons.done,
                    size: 16, color: message.isRead ? Colors.white : Colors.white70),
              ],
            ],
          ),
        ],
      ),
    );

    final avatar = showAvatar
        ? CircleAvatar(
            radius: 14,
            backgroundImage: _isValidUrl(message.senderAvatar)
                ? NetworkImage(message.senderAvatar!)
                : null,
            child: !_isValidUrl(message.senderAvatar)
                ? const Icon(Icons.person, size: 14)
                : null,
          )
        : const SizedBox(width: 28); // chừa chỗ cho layout đều

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMe
            ? [
                Flexible(child: bubble),
                const SizedBox(width: 8),
                // có thể ẩn avatar của mình để đỡ rối
              ]
            : [
                avatar,
                const SizedBox(width: 8),
                Flexible(child: bubble),
              ],
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final local = dt.isUtc ? dt.toLocal() : dt;
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.isNegative) return 'now';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  static bool _isValidUrl(String? url) =>
      url != null &&
      url.isNotEmpty &&
      (url.startsWith('http://') || url.startsWith('https://'));
}
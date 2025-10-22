import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../state/chat_providers.dart';
import '../state/messages_notifier.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Conversation conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  ConsumerState<ChatScreen> createState() => _ChatState();
}

class _ChatState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _typingDebounce;

  // ⚠️ Không dùng ref trong dispose: cache sẵn Notifier
  late final HubController _hub;

  @override
  void initState() {
    super.initState();
    _hub = ref.read(hubControllerProvider.notifier);       // cache
    _hub.connect();                                        // idempotent
    // join room sau frame đầu để chắc chắn context đã sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _hub.joinConversation(widget.conversation.id);
      ref.read(currentOpenConversationIdProvider.notifier).state = widget.conversation.id;
      // Initialize MessagesNotifier sau khi setup xong
      await ref.read(messagesProvider(widget.conversation.id).notifier).initialize();
    });
  }

  @override
  void deactivate() {
    // Rời phòng ở deactivate để chắc chắn được gọi trước khi element bị dispose
    // và không đụng tới ref nữa.
    _hub.leaveConversation(widget.conversation.id);
    ref.read(currentOpenConversationIdProvider.notifier).state = null;
    super.deactivate();
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(messagesProvider(widget.conversation.id).notifier).sendMessage(text);
  }

  void _typing(String _) {
    _typingDebounce?.cancel();
    _hub.startTyping(widget.conversation.id);
    _typingDebounce = Timer(const Duration(seconds: 1), () => _hub.stopTyping(widget.conversation.id));
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(messagesProvider(widget.conversation.id));
    print('DEBUG CHAT: Building chat screen - State: ${data.runtimeType}');
    
    return Scaffold(
      appBar: AppBar(title: Text(widget.conversation.title ?? 'Chat')),
      body: data.when(
        loading: () {
          print('DEBUG CHAT: Still loading...');
          return const Center(child: CircularProgressIndicator());
        },
        error: (e, _) {
          print('DEBUG CHAT: Error state: $e');
          return Center(child: Text('Lỗi tải tin: $e'));
        },
        data: (messages) {
          print('DEBUG CHAT: Loaded ${messages.length} messages');
          _scrollToBottom();
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _BubbleRow(
                    message: messages[i],
                    prev: i > 0 ? messages[i-1] : null,
                    next: i < messages.length-1 ? messages[i+1] : null,
                  ),
                ),
              ),
              _Input(controller: _controller, onChanged: _typing, onSend: _send),
            ],
          );
        },
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  const _Input({required this.controller, required this.onChanged, required this.onSend});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.grey, width: .5))),
      child: Row(children: [
        Expanded(child: TextField(onChanged: onChanged, controller: controller,
          onSubmitted: (_) => onSend(), decoration: const InputDecoration(hintText: 'Type...', border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        IconButton(icon: const Icon(Icons.send), onPressed: onSend),
      ]),
    );
  }
}

class _BubbleRow extends StatelessWidget {
  final Message message; final Message? prev; final Message? next;
  const _BubbleRow({required this.message, this.prev, this.next});
  @override
  Widget build(BuildContext context) {
    final samePrev = prev?.senderId == message.senderId;
    final sameNext = next?.senderId == message.senderId;
    return Container(
      margin: EdgeInsets.only(top: samePrev ? 2 : 8, bottom: sameNext ? 2 : 8),
      child: _Bubble(message: message, showAvatar: !sameNext, showName: !samePrev),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message message; final bool showAvatar; final bool showName;
  const _Bubble({required this.message, required this.showAvatar, required this.showName});
  @override
  Widget build(BuildContext context) {
    // ở đây có thể thêm logic avatar/name; để ngắn gọn:
    final local = message.createdAt.isUtc ? message.createdAt.toLocal() : message.createdAt;
    final diff = DateTime.now().difference(local);
    String time = diff.isNegative ? 'now'
      : diff.inMinutes < 1 ? 'now'
      : diff.inHours >= 24 ? '${diff.inDays}d ago'
      : diff.inHours >= 1 ? '${diff.inHours}h ago'
      : '${diff.inMinutes}m ago';

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal:16, vertical:10),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (showName && (message.senderName ?? '').isNotEmpty)
                Text(message.senderName!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(message.content ?? 'Media', style: const TextStyle(color: Colors.black)),
              const SizedBox(height: 4),
              Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ]),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

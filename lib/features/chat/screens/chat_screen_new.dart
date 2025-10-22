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
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    // đảm bảo connect hub (nếu chưa)
    ref.read(hubControllerProvider.notifier).connect();
    // join room
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hubControllerProvider.notifier).joinConversation(widget.conversation.id);
      ref.read(currentOpenConversationIdProvider.notifier).state = widget.conversation.id;
    });
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    ref.read(hubControllerProvider.notifier).leaveConversation(widget.conversation.id);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();
    await ref.read(messagesProvider(widget.conversation.id).notifier).sendMessage(content);
  }

  void _onTypingChanged(String _) {
    final hub = ref.read(hubControllerProvider.notifier);
    _typingDebounce?.cancel();
    // gửi Typing ngay, và nếu user ngừng gõ 1s thì StopTyping
    hub.startTyping(widget.conversation.id);
    _typingDebounce = Timer(const Duration(seconds: 1), () {
      hub.stopTyping(widget.conversation.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversation.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.title ?? 'Chat'),
      ),
      body: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải tin: $e')),
        data: (messages) {
          // scroll xuống khi có data mới
          _scrollToBottom();
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _MessageBubbleWrapper(
                    message: messages[i],
                    previous: i > 0 ? messages[i - 1] : null,
                    next: i < messages.length - 1 ? messages[i + 1] : null,
                  ),
                ),
              ),
              _InputBar(
                controller: _messageController,
                onChanged: _onTypingChanged,
                onSend: _sendMessage,
              ),
            ],
          );
        },
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.grey, width: 0.5))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(hintText: 'Type a message...', border: OutlineInputBorder()),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.send), onPressed: onSend),
        ],
      ),
    );
  }
}

class _MessageBubbleWrapper extends StatelessWidget {
  final Message message;
  final Message? previous;
  final Message? next;
  const _MessageBubbleWrapper({required this.message, this.previous, this.next});

  @override
  Widget build(BuildContext context) {
    final isSameSenderAsPrev = previous?.senderId == message.senderId;
    final isSameSenderAsNext = next?.senderId == message.senderId;

    return Container(
      margin: EdgeInsets.only(
        top: isSameSenderAsPrev ? 2 : 8,
        bottom: isSameSenderAsNext ? 2 : 8,
      ),
      child: MessageBubble(
        message: message,
        showAvatar: !isSameSenderAsNext,
        showSenderName: !isSameSenderAsPrev,
      ),
    );
  }
}

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool showAvatar;
  final bool showSenderName;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.showSenderName = true,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final storage = const FlutterSecureStorage();
    final userId = await storage.read(key: 'user_id');
    setState(() {
      _currentUserId = userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMe = _currentUserId != null && widget.message.senderId == _currentUserId;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe && widget.showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: _isValidImageUrl(widget.message.senderAvatar)
                  ? NetworkImage(widget.message.senderAvatar!)
                  : null,
              child: !_isValidImageUrl(widget.message.senderAvatar)
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 8),
          ] else if (!isMe && !widget.showAvatar) ...[
            const SizedBox(width: 24), // Space for avatar when not showing
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && widget.showSenderName && widget.message.senderName != null)
                    Text(
                      widget.message.senderName!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    widget.message.content ?? 'Media message',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(widget.message.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          widget.message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: widget.message.isRead ? Colors.blue : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe && widget.showAvatar) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: _isValidImageUrl(widget.message.senderAvatar)
                  ? NetworkImage(widget.message.senderAvatar!)
                  : null,
              child: !_isValidImageUrl(widget.message.senderAvatar)
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
          ] else if (isMe && !widget.showAvatar) ...[
            const SizedBox(width: 24), // Space for avatar when not showing
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    // Backend sends UTC time, convert to local time
    final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;
    final now = DateTime.now();
    final difference = now.difference(localDateTime);
    
    print('DEBUG: Formatting time - Original: $dateTime, Local: $localDateTime, Now: $now, Diff: $difference');

    // For very recent messages (within 1 minute), show "now"
    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url.startsWith('file:///')) return false;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return false;
    return true;
  }
}

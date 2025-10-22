import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/simple_hub_service.dart';
import '../services/local_db_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Conversation conversation;

  const ChatScreen({
    super.key,
    required this.conversation,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ChatApiService _apiService = ChatApiService();
  final LocalDbService _localDbService = LocalDbService();
  final SimpleHubService _hubService = SimpleHubService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  Set<int> _typingUsers = {};

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupHubListeners();
    _joinConversation();
  }

  void _setupHubListeners() {
    _hubService.messageStream.listen((message) {
      if (message.conversationId == widget.conversation.id) {
        _addMessage(message);
      }
    });

    _hubService.typingStream.listen((data) {
      if (data['conversationId'] == widget.conversation.id) {
        setState(() {
          _typingUsers.add(data['userId']);
        });
      }
    });

    _hubService.stopTypingStream.listen((data) {
      if (data['conversationId'] == widget.conversation.id) {
        setState(() {
          _typingUsers.remove(data['userId']);
        });
      }
    });

    _hubService.messageSeenStream.listen((data) {
      // Handle message seen
    });

    _hubService.messageReactionStream.listen((message) {
      if (message.conversationId == widget.conversation.id) {
        _updateMessage(message);
      }
    });
  }

  Future<void> _joinConversation() async {
    await _hubService.joinConversation(widget.conversation.id);
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    
    try {
      // Load from local database first
      final localMessages = await _localDbService.getMessages(widget.conversation.id);
      setState(() {
        _messages = localMessages.reversed.toList();
        _isLoading = false;
      });

      // Then fetch from API
      final apiMessages = await _apiService.getMessages(widget.conversation.id);
      
      // Update local database
      for (final message in apiMessages) {
        await _localDbService.saveMessage(message);
      }
      
      setState(() {
        _messages = apiMessages.toList();
        _isLoading = false;
      });

      // Mark conversation as read
      await _apiService.markConversationAsRead(widget.conversation.id);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  void _addMessage(Message message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _updateMessage(Message updatedMessage) {
    setState(() {
      final index = _messages.indexWhere((m) => m.id == updatedMessage.id);
      if (index != -1) {
        _messages[index] = updatedMessage;
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    
    try {
      final message = await _apiService.sendMessage(
        widget.conversation.id,
        CreateMessage(content: content),
      );
      
      _addMessage(message);
      await _localDbService.saveMessage(message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  void _onTypingChanged() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _hubService.startTyping(widget.conversation.id);
    } else if (_messageController.text.isEmpty && _isTyping) {
      _isTyping = false;
      _hubService.stopTyping(widget.conversation.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.title ?? 'Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showConversationInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _messages.length + (_typingUsers.isNotEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _typingUsers.isNotEmpty) {
                            return _buildTypingIndicator();
                          }
                          return MessageBubble(message: _messages[index]);
                        },
                      ),
          ),
          
          // Typing indicator
          if (_typingUsers.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${_typingUsers.length} user${_typingUsers.length > 1 ? 's' : ''} typing...',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _onTypingChanged(),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            '${_typingUsers.length} user${_typingUsers.length > 1 ? 's' : ''} typing...',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showConversationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.conversation.title ?? 'Conversation Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${widget.conversation.isGroup ? 'Group' : '1-to-1'}'),
            Text('Created: ${widget.conversation.createdAt}'),
            Text('Participants: ${widget.conversation.participants.length}'),
            if (widget.conversation.lastMessageAt != null)
              Text('Last message: ${widget.conversation.lastMessageAt}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _hubService.leaveConversation(widget.conversation.id);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.senderId == 1; // TODO: Get current user ID
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message.senderAvatar != null
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              child: message.senderAvatar == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 8),
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
                  if (!isMe && message.senderName != null)
                    Text(
                      message.senderName!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    message.content ?? 'Media message',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: message.isRead ? Colors.blue : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: message.senderAvatar != null
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              child: message.senderAvatar == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}

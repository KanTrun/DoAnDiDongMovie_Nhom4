import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/simple_hub_service.dart';
import '../services/local_db_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  final ChatApiService _apiService = ChatApiService();
  final LocalDbService _localDbService = LocalDbService();
  final SimpleHubService _hubService = SimpleHubService();
  
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filter = 'all'; // 'all', 'following'

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _setupHubListeners();
  }

  void _setupHubListeners() {
    _hubService.messageStream.listen((message) {
      _updateConversationWithNewMessage(message);
    });
  }

  void _updateConversationWithNewMessage(Message message) {
    setState(() {
      final index = _conversations.indexWhere((c) => c.id == message.conversationId);
      if (index != -1) {
        final conversation = _conversations[index];
        _conversations[index] = conversation.copyWith(
          lastMessage: message,
          lastMessageAt: message.createdAt,
          unreadCount: conversation.unreadCount + 1,
        );
      }
    });
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    
    try {
      // Load from local database first
      final localConversations = await _localDbService.getConversations();
      setState(() {
        _conversations = localConversations;
        _isLoading = false;
      });

      // Then fetch from API
      final apiConversations = await _apiService.getConversations();
      
      // Update local database
      for (final conversation in apiConversations) {
        await _localDbService.saveConversation(conversation);
      }
      
      setState(() {
        _conversations = apiConversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversations: $e')),
        );
      }
    }
  }

  List<Conversation> get _filteredConversations {
    var filtered = _conversations;
    
    // Filter by type (all/following)
    if (_filter == 'following') {
      // TODO: Implement following filter logic
      // For now, show all conversations
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((conv) {
        final title = conv.title?.toLowerCase() ?? '';
        return title.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _filter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'following', child: Text('Following')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          
          // Filter tabs
          Row(
            children: [
              Expanded(
                child: TabBar(
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Following'),
                  ],
                  onTap: (index) {
                    setState(() {
                      _filter = index == 0 ? 'all' : 'following';
                    });
                  },
                ),
              ),
            ],
          ),
          
          // Conversations list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredConversations.isEmpty
                    ? const Center(child: Text('No conversations found'))
                    : ListView.builder(
                        itemCount: _filteredConversations.length,
                        itemBuilder: (context, index) {
                          final conversation = _filteredConversations[index];
                          return ConversationListItem(
                            conversation: conversation,
                            onTap: () => _navigateToChat(conversation),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewConversationDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToChat(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversation: conversation),
      ),
    );
  }

  void _showNewConversationDialog() {
    showDialog(
      context: context,
      builder: (context) => NewConversationDialog(
        onConversationCreated: (conversation) {
          setState(() {
            _conversations.insert(0, conversation);
          });
        },
      ),
    );
  }
}

class ConversationListItem extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: conversation.participants.isNotEmpty
            ? NetworkImage(conversation.participants.first.userAvatar ?? '')
            : null,
        child: conversation.participants.isNotEmpty
            ? null
            : const Icon(Icons.person),
      ),
      title: Text(
        conversation.title ?? 'Unknown',
        style: TextStyle(
          fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: conversation.lastMessage != null
          ? Text(
              conversation.lastMessage!.content ?? 'Media message',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : const Text('No messages yet'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(conversation.lastMessageAt ?? conversation.createdAt),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

class NewConversationDialog extends StatefulWidget {
  final Function(Conversation) onConversationCreated;

  const NewConversationDialog({
    super.key,
    required this.onConversationCreated,
  });

  @override
  State<NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<NewConversationDialog> {
  final ChatApiService _apiService = ChatApiService();
  final TextEditingController _titleController = TextEditingController();
  bool _isGroup = false;
  List<int> _selectedParticipants = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Conversation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            title: const Text('Group conversation'),
            value: _isGroup,
            onChanged: (value) {
              setState(() => _isGroup = value ?? false);
            },
          ),
          if (_isGroup)
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Group name',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 16),
          const Text('Select participants:'),
          // TODO: Implement participant selection
          const Text('Participant selection not implemented yet'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createConversation,
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createConversation() async {
    if (_isGroup && _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name is required')),
      );
      return;
    }

    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one participant')),
      );
      return;
    }

    try {
      final conversation = await _apiService.createConversation(
        isGroup: _isGroup,
        title: _isGroup ? _titleController.text : null,
        participantIds: _selectedParticipants,
      );

      widget.onConversationCreated(conversation);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating conversation: $e')),
      );
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/simple_hub_service.dart';
import '../services/local_db_service.dart';
import '../services/fcm_service.dart';

// Services providers
final apiServiceProvider = Provider<ChatApiService>((ref) => ChatApiService());
final hubServiceProvider = Provider<SimpleHubService>((ref) => SimpleHubService());
final localDbServiceProvider = Provider<LocalDbService>((ref) => LocalDbService());

// Conversations state
final conversationsProvider = StateNotifierProvider<ConversationsNotifier, AsyncValue<List<Conversation>>>((ref) {
  return ConversationsNotifier(ref);
});

class ConversationsNotifier extends StateNotifier<AsyncValue<List<Conversation>>> {
  final Ref ref;
  
  ConversationsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadConversations();
    _setupHubListeners();
  }

  Future<void> _loadConversations() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final localDbService = ref.read(localDbServiceProvider);
      
      // Load from local database first
      final localConversations = await localDbService.getConversations();
      state = AsyncValue.data(localConversations);
      
      // Then fetch from API
      final apiConversations = await apiService.getConversations();
      
      // Update local database
      for (final conversation in apiConversations) {
        await localDbService.saveConversation(conversation);
      }
      
      state = AsyncValue.data(apiConversations);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void _setupHubListeners() {
    final hubService = ref.read(hubServiceProvider);
    
    hubService.messageStream.listen((message) {
      _updateConversationWithNewMessage(message);
    });
  }

  void _updateConversationWithNewMessage(Message message) {
    state.whenData((conversations) {
      final index = conversations.indexWhere((c) => c.id == message.conversationId);
      if (index != -1) {
        final conversation = conversations[index];
        final updatedConversation = conversation.copyWith(
          lastMessage: message,
          lastMessageAt: message.createdAt,
          unreadCount: conversation.unreadCount + 1,
        );
        
        final updatedConversations = List<Conversation>.from(conversations);
        updatedConversations[index] = updatedConversation;
        state = AsyncValue.data(updatedConversations);
      }
    });
  }

  Future<void> createConversation({
    required bool isGroup,
    String? title,
    required List<int> participantIds,
  }) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final localDbService = ref.read(localDbServiceProvider);
      
      final conversation = await apiService.createConversation(
        isGroup: isGroup,
        title: title,
        participantIds: participantIds,
      );
      
      await localDbService.saveConversation(conversation);
      
      state.whenData((conversations) {
        final updatedConversations = [conversation, ...conversations];
        state = AsyncValue.data(updatedConversations);
      });
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadConversations();
  }
}

// Messages state
final messagesProvider = StateNotifierProvider.family<MessagesNotifier, AsyncValue<List<Message>>, int>((ref, conversationId) {
  return MessagesNotifier(ref, conversationId);
});

class MessagesNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final Ref ref;
  final int conversationId;
  
  MessagesNotifier(this.ref, this.conversationId) : super(const AsyncValue.loading()) {
    _loadMessages();
    _setupHubListeners();
  }

  Future<void> _loadMessages() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final localDbService = ref.read(localDbServiceProvider);
      
      // Load from local database first
      final localMessages = await localDbService.getMessages(conversationId);
      state = AsyncValue.data(localMessages.reversed.toList());
      
      // Then fetch from API
      final apiMessages = await apiService.getMessages(conversationId);
      
      // Update local database
      for (final message in apiMessages) {
        await localDbService.saveMessage(message);
      }
      
      state = AsyncValue.data(apiMessages.toList());
      
      // Mark conversation as read
      await apiService.markConversationAsRead(conversationId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void _setupHubListeners() {
    final hubService = ref.read(hubServiceProvider);
    
    hubService.messageStream.listen((message) {
      if (message.conversationId == conversationId) {
        _addMessage(message);
      }
    });

    hubService.messageReactionStream.listen((message) {
      if (message.conversationId == conversationId) {
        _updateMessage(message);
      }
    });
  }

  void _addMessage(Message message) {
    state.whenData((messages) {
      final updatedMessages = [...messages, message];
      state = AsyncValue.data(updatedMessages);
    });
  }

  void _updateMessage(Message updatedMessage) {
    state.whenData((messages) {
      final index = messages.indexWhere((m) => m.id == updatedMessage.id);
      if (index != -1) {
        final updatedMessages = List<Message>.from(messages);
        updatedMessages[index] = updatedMessage;
        state = AsyncValue.data(updatedMessages);
      }
    });
  }

  Future<void> sendMessage(String content) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final localDbService = ref.read(localDbServiceProvider);
      
      final message = await apiService.sendMessage(
        conversationId,
        CreateMessage(content: content),
      );
      
      _addMessage(message);
      await localDbService.saveMessage(message);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> sendMessageViaHub(String content) async {
    try {
      final hubService = ref.read(hubServiceProvider);
      await hubService.sendMessage(conversationId, content);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addReaction(int messageId, String reaction) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final updatedMessage = await apiService.addReaction(conversationId, messageId, reaction);
      _updateMessage(updatedMessage);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> removeReaction(int messageId) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.removeReaction(conversationId, messageId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Typing state
final typingProvider = StateNotifierProvider.family<TypingNotifier, Set<int>, int>((ref, conversationId) {
  return TypingNotifier(ref, conversationId);
});

class TypingNotifier extends StateNotifier<Set<int>> {
  final Ref ref;
  final int conversationId;
  
  TypingNotifier(this.ref, this.conversationId) : super({}) {
    _setupHubListeners();
  }

  void _setupHubListeners() {
    final hubService = ref.read(hubServiceProvider);
    
    hubService.typingStream.listen((data) {
      if (data['conversationId'] == conversationId) {
        state = {...state, data['userId']};
      }
    });

    hubService.stopTypingStream.listen((data) {
      if (data['conversationId'] == conversationId) {
        state = Set.from(state)..remove(data['userId']);
      }
    });
  }

  void startTyping() {
    final hubService = ref.read(hubServiceProvider);
    hubService.startTyping(conversationId);
  }

  void stopTyping() {
    final hubService = ref.read(hubServiceProvider);
    hubService.stopTyping(conversationId);
  }
}

// FCM notifications
final fcmProvider = Provider<FcmService>((ref) => FcmService());

// Initialize FCM
final fcmInitializedProvider = FutureProvider<void>((ref) async {
  await FcmService.initialize();
});

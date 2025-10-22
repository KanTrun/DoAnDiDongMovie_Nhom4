import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import 'chat_providers.dart';

final messagesProvider = StateNotifierProvider.family<MessagesNotifier, AsyncValue<List<Message>>, int>(
  (ref, id) => MessagesNotifier(ref, id),
);

class MessagesNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final Ref ref; final int conversationId;
  StreamSubscription? _msg; StreamSubscription? _react;
  bool _initialized = false;

  MessagesNotifier(this.ref, this.conversationId) : super(const AsyncValue.loading()) {
    // Auto-initialize khi provider được tạo
    _autoInit();
  }

  Future<void> initialize() async {
    if (_initialized) return; // Tránh duplicate initialize
    _initialized = true;
    
    print('DEBUG MESSAGES: Initializing for conversation $conversationId');
    ref.read(hubControllerProvider.notifier).connect();
    ref.read(hubControllerProvider.notifier).joinConversation(conversationId);
    // KHÔNG set currentOpenConversationIdProvider ở đây - sẽ gây lỗi build phase

    print('DEBUG MESSAGES: Starting _load...');
    await _load();
    print('DEBUG MESSAGES: Starting _listen...');
    _listen();
    print('DEBUG MESSAGES: Starting _markReadAll...');
    await _markReadAll();
    print('DEBUG MESSAGES: Initialization complete');
  }

  // Auto-initialize khi provider được tạo
  void _autoInit() {
    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        initialize();
      });
    }
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiServiceProvider);
      final db  = ref.read(localDbServiceProvider);

      // 1) local
      final local = await db.getMessages(conversationId);
      local.sort((a,b) => a.createdAt.compareTo(b.createdAt));
      state = AsyncValue.data(local);

      // 2) remote
      final remote = await api.getMessages(conversationId);
      remote.sort((a,b) => a.createdAt.compareTo(b.createdAt));
      for (final m in remote) { await db.saveMessage(m); }
      state = AsyncValue.data(remote);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _listen() {
    final hub = ref.read(hubControllerProvider.notifier);
    _msg = hub.messageStream.listen((dynamic raw) async {
      final m = raw as Message;
      if (m.conversationId != conversationId) return;
      _upsert(m);
      if (ref.read(currentOpenConversationIdProvider) == conversationId) {
        await _markReadMessage(m.id);
      }
    });
    _react = hub.messageReactionStream.listen((dynamic raw) {
      final updated = raw as Message;
      if (updated.conversationId != conversationId) return;
      _upsert(updated);
    });
  }

  void _upsert(Message m) {
    state.whenData((list) {
      final copy = [...list];
      final i = copy.indexWhere((x) => x.id == m.id);
      if (i >= 0) copy[i] = m; else copy.add(m);
      // GIỮ ASC để UI luôn render "dưới cùng là mới nhất"
      copy.sort((a,b) => a.createdAt.compareTo(b.createdAt));
      state = AsyncValue.data(copy);
    });
  }


  Future<void> sendMessage(String content) async {
    try {
      final api = ref.read(apiServiceProvider);
      final db = ref.read(localDbServiceProvider);
      final sent = await api.sendMessage(conversationId, CreateMessage(content: content));
      _upsert(sent);
      await db.saveMessage(sent);
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  Future<void> _markReadAll() async {
    try { await ref.read(apiServiceProvider).markConversationAsRead(conversationId); } catch (_) {}
  }

  Future<void> _markReadMessage(int id) async {
    try { await ref.read(apiServiceProvider).markMessageAsRead(conversationId, id); } catch (_) {}
  }

  @override
  void dispose() {
    _msg?.cancel(); _react?.cancel();
    // Không dùng ref trong dispose để tránh "modify provider while building"
    // Hub sẽ tự cleanup khi không còn references
    super.dispose();
  }
}

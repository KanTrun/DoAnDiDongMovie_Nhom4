import 'dart:async';
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
    // Không gọi _init() trong constructor để tránh infinite loop
    // Sẽ được gọi từ ChatScreen.initState()
  }

  Future<void> initialize() async {
    if (_initialized) return; // Tránh duplicate initialize
    _initialized = true;
    
    print('DEBUG MESSAGES: Initializing for conversation $conversationId');
    ref.read(hubControllerProvider.notifier).connect();
    ref.read(hubControllerProvider.notifier).joinConversation(conversationId);
    ref.read(currentOpenConversationIdProvider.notifier).state = conversationId;

    print('DEBUG MESSAGES: Starting _load...');
    await _load();
    print('DEBUG MESSAGES: Starting _listen...');
    _listen();
    print('DEBUG MESSAGES: Starting _markReadAll...');
    await _markReadAll();
    print('DEBUG MESSAGES: Initialization complete');
  }

  Future<void> _load() async {
    try {
      print('DEBUG MESSAGES: Loading messages for conversation $conversationId');
      final api = ref.read(apiServiceProvider);
      final db = ref.read(localDbServiceProvider);

      print('DEBUG MESSAGES: Loading local messages...');
      final local = await db.getMessages(conversationId); // ASC từ DB
      print('DEBUG MESSAGES: Loaded ${local.length} local messages');
      state = AsyncValue.data(local);

      print('DEBUG MESSAGES: Loading remote messages...');
      final remote = await api.getMessages(conversationId);
      print('DEBUG MESSAGES: Loaded ${remote.length} remote messages');
      for (final m in remote) { await db.saveMessage(m); }
      state = AsyncValue.data(remote);
      print('DEBUG MESSAGES: Messages loaded successfully');
    } catch (e, st) { 
      print('DEBUG MESSAGES: Error loading messages: $e');
      state = AsyncValue.error(e, st); 
    }
  }

  void _listen() {
    final hub = ref.read(hubControllerProvider.notifier);
    _msg = hub.messageStream.listen((dynamic raw) async {
      final m = raw as Message;
      if (m.conversationId != conversationId) return;
      _addOrReplace(m);
      if (ref.read(currentOpenConversationIdProvider) == conversationId) {
        await _markReadMessage(m.id);
      }
    });
    _react = hub.messageReactionStream.listen((dynamic raw) {
      final updated = raw as Message;
      if (updated.conversationId != conversationId) return;
      _replace(updated);
    });
  }

  void _addOrReplace(Message m) {
    final current = state;
    if (current is AsyncData<List<Message>>) {
      final list = current.value;
      final exists = list.any((x) => x.id == m.id);
      final updated = exists ? list.map((x) => x.id == m.id ? m : x).toList()
                             : _insertSorted(list, m);
      state = AsyncValue.data(updated);
    } else {
      // nếu đang loading/err vì lifecycle -> khởi tạo nhẹ
      state = AsyncValue.data([m]);
    }
  }

  List<Message> _insertSorted(List<Message> list, Message m) {
    final copy = [...list];
    // insert by createdAt ASC
    final i = copy.indexWhere((x) => x.createdAt.isAfter(m.createdAt));
    if (i == -1) copy.add(m); else copy.insert(i, m);
    return copy;
  }

  void _replace(Message updated) {
    state.whenData((list) {
      final idx = list.indexWhere((x) => x.id == updated.id);
      if (idx == -1) return;
      final copy = [...list]; copy[idx] = updated;
      state = AsyncValue.data(copy);
    });
  }

  Future<void> sendMessage(String content) async {
    try {
      final api = ref.read(apiServiceProvider);
      final db = ref.read(localDbServiceProvider);
      final sent = await api.sendMessage(conversationId, CreateMessage(content: content));
      _addOrReplace(sent);
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
    ref.read(hubControllerProvider.notifier).leaveConversation(conversationId);
    super.dispose();
  }
}

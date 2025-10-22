import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import 'chat_providers.dart';

final conversationsProvider = StateNotifierProvider<ConversationsNotifier, AsyncValue<List<Conversation>>>(
  (ref) => ConversationsNotifier(ref),
);

class ConversationsNotifier extends StateNotifier<AsyncValue<List<Conversation>>> {
  final Ref ref; StreamSubscription? _sub;
  ConversationsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _load();
    _listenHub();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiServiceProvider);
      final db = ref.read(localDbServiceProvider);

      final local = await db.getConversations();
      state = AsyncValue.data(_sorted(local));

      final remote = await api.getConversations();
      for (final c in remote) { await db.saveConversation(c); }
      state = AsyncValue.data(_sorted(remote));
    } catch (e, st) { state = AsyncValue.error(e, st); }
  }

  List<Conversation> _sorted(List<Conversation> list) {
    final copy = [...list];
    copy.sort((a,b) => (b.lastMessageAt ?? b.createdAt).compareTo(a.lastMessageAt ?? a.createdAt));
    return copy;
    }

  void _listenHub() {
    final hub = ref.read(hubControllerProvider.notifier);
    _sub = hub.messageStream.listen((dynamic raw) {
      final msg = raw as Message;
      state.whenData((list) {
        final i = list.indexWhere((c) => c.id == msg.conversationId);
        if (i == -1) return;
        final openId = ref.read(currentOpenConversationIdProvider);
        final c = list[i];
        final updated = c.copyWith(
          lastMessage: msg,
          lastMessageAt: msg.createdAt,
          unreadCount: (openId == c.id) ? 0 : (c.unreadCount + 1),
        );
        final copy = [...list]..[i] = updated;
        state = AsyncValue.data(_sorted(copy));
      });
    });
  }

  Future<void> refresh() => _load();

  void insertOrReplace(Conversation c) {
    state.whenData((list) {
      final idx = list.indexWhere((x) => x.id == c.id);
      final copy = [...list];
      if (idx == -1) {
        copy.insert(0, c);
      } else {
        copy[idx] = c;
      }
      // bảo đảm re-sort theo (lastMessageAt ?? createdAt) desc
      copy.sort((a, b) => (b.lastMessageAt ?? b.createdAt)
          .compareTo(a.lastMessageAt ?? a.createdAt));
      state = AsyncValue.data(copy);
    });
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}

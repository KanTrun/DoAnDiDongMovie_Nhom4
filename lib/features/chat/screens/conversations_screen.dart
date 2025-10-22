import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../state/conversations_notifier.dart';
import 'chat_screen.dart';
import 'new_conversation_sheet.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convAsync = ref.watch(conversationsProvider);

    Future<void> _openCreator() async {
      final Conversation? created = await showModalBottomSheet<Conversation>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        builder: (_) => const NewConversationSheet(),
      );
      if (created != null) {
        // đẩy vào provider để hiển thị tức thì
        ref.read(conversationsProvider.notifier).insertOrReplace(created);
        // mở chat ngay
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversation: created)));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(conversationsProvider.notifier).refresh()),
        ],
      ),
      body: convAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (convs) => ListView.builder(
          itemCount: convs.length,
          itemBuilder: (_, i) {
            final c = convs[i];
            return ListTile(
              leading: CircleAvatar(child: Icon(c.isGroup ? Icons.group : Icons.person)),
              title: Text(_title(c),
                style: TextStyle(fontWeight: c.unreadCount > 0 ? FontWeight.bold : FontWeight.normal)),
              subtitle: Text(c.lastMessage?.content ?? 'No messages yet', maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(_shortTime(c.lastMessageAt ?? c.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversation: c))),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreator,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _title(Conversation c) {
    if (c.isGroup) return c.title ?? 'Group';
    if (c.participants.isNotEmpty) return c.participants.first.userName ?? c.participants.first.userId;
    return 'Unknown';
  }

  String _shortTime(DateTime dt) {
    final local = dt.isUtc ? dt.toLocal() : dt;
    final diff = DateTime.now().difference(local);
    if (diff.isNegative) return 'now'; // phòng lệch giờ máy
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../state/conversations_notifier.dart';
import 'chat_screen.dart';
import 'new_conversation_sheet.dart';
import '../../../core/providers/auth_provider.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  Timer? _timeRefreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh thời gian mỗi 30 giây để cập nhật "now" → "1m", "2m", etc.
    _timeRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timeRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              title: Text(_title(c, ref),
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

  String _title(Conversation c, WidgetRef ref) {
    if (c.isGroup) return c.title ?? 'Group';
    
    // For 1-1 conversations, find the other participant (not current user)
    if (c.participants.isNotEmpty) {
      // Get current user ID from auth provider
      final currentUserId = ref.read(currentUserProvider)?.userId;
      
      // Find the other participant (not current user)
      final otherParticipant = c.participants.firstWhere(
        (p) => p.userId != currentUserId,
        orElse: () => c.participants.first,
      );
      
      // Return display name or email, fallback to userId
      return otherParticipant.userName ?? 
             otherParticipant.userId.substring(0, 8) + '...';
    }
    
    return 'Unknown';
  }

  String _shortTime(DateTime dt) {
    // Đảm bảo thời gian được parse đúng từ UTC
    final utcTime = dt.isUtc ? dt : DateTime.parse(dt.toIso8601String() + 'Z').toUtc();
    final localTime = utcTime.toLocal();
    final now = DateTime.now();
    final diff = now.difference(localTime);
    
    // Nếu thời gian trong tương lai (lỗi timezone), hiển thị "now"
    if (diff.isNegative || diff.inSeconds < 5) return 'now';
    
    // Hiển thị thời gian chính xác
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/message.dart';

// ====== Phần 2.1: Phân rã messages thành các item hiển thị ======

abstract class MessageListItem {}

class DateDividerItem extends MessageListItem {
  final DateTime day; // 00:00 cục bộ
  DateDividerItem(this.day);
}

class MessageBubbleItem extends MessageListItem {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final bool showName;
  final bool showTail;        // đuôi bong bóng
  MessageBubbleItem({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.showName,
    required this.showTail,
  });
}

/// Tạo danh sách item theo đúng quy tắc:
/// - Tin của mình: align RIGHT; của người khác: LEFT
/// - Gộp cụm theo (cùng sender và trong 5 phút)
/// - Chèn Date divider khi đổi ngày
List<MessageListItem> buildMessageItems(List<Message> asc) {
  // asc (cũ -> mới). Vì ListView.reverse, ta build từ cuối về đầu:
  final items = <MessageListItem>[];
  const clusterGap = Duration(minutes: 5);

  DateTime? lastDay;               // ngày đã render (local)
  String? prevSender;              // để gộp cụm
  DateTime? prevTime;

  // DUYỆT ASC và push vào items (sẽ bị đảo do reverse khi render)
  for (final m in asc) {
    // timezone local
    final localTime = m.createdAt.isUtc ? m.createdAt.toLocal() : m.createdAt;
    final dayKey = DateTime(localTime.year, localTime.month, localTime.day);

    // divider theo ngày
    if (lastDay == null || dayKey.isAfter(lastDay)) {
      lastDay = dayKey;
      items.add(DateDividerItem(dayKey));
    }

    // cụm?
    final isSameCluster = prevSender == m.senderId &&
        prevTime != null &&
        localTime.difference(prevTime).abs() <= clusterGap;

    // cờ hiển thị
    final isMe = false; // sẽ set sau
    final showAvatar = !isSameCluster; // cuối cụm hoặc đơn lẻ -> hiện avatar
    final showName   = !isSameCluster; // nhóm: chỉ hiện ở đầu cụm
    final showTail   = !isSameCluster; // đuôi bong bóng cho tin cuối cụm

    items.add(MessageBubbleItem(
      message: m,
      isMe: isMe,          // tạm
      showAvatar: showAvatar,
      showName: showName,
      showTail: showTail,
    ));

    prevSender = m.senderId;
    prevTime   = localTime;
  }

  // Vì không thể gọi async ở trên, cập nhật cờ isMe sau khi biết userId:
  // (Ở UI tile sẽ tính lại isMe để chắc ăn)
  return items;
}

// ====== Phần 2.2: Widget hiển thị từng item ======

class MessageListTile extends StatefulWidget {
  final MessageListItem item;
  final bool isGroup;
  const MessageListTile({super.key, required this.item, required this.isGroup});

  @override
  State<MessageListTile> createState() => _MessageListTileState();
}

class _MessageListTileState extends State<MessageListTile> {
  String? _me;

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  Future<void> _loadMe() async {
    _me = await const FlutterSecureStorage().read(key: 'user_id');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item is DateDividerItem) {
      final d = (widget.item as DateDividerItem).day;
      return _DateDivider(text: _formatDay(d));
    }

    final it = widget.item as MessageBubbleItem;
    final isMe = (it.message.senderId == _me);
    return _MessageBubble(
      message: it.message,
      isMe: isMe,
      isGroup: widget.isGroup,
      showAvatar: !isMe && it.showAvatar,
      showName: !isMe && widget.isGroup && it.showName,
      showTail: it.showTail,
    );
  }
}

// ====== Phần 2.3: Bong bóng tin nhắn ======

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isGroup;
  final bool showAvatar;
  final bool showName;
  final bool showTail;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isGroup,
    required this.showAvatar,
    required this.showName,
    required this.showTail,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;
    final bg = isMe ? Colors.blue : Colors.grey.shade300;
    final fg = isMe ? Colors.white : Colors.black87;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : (showTail ? 4 : 16)),
          bottomRight: Radius.circular(isMe ? (showTail ? 4 : 16) : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showName && (message.senderName ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                message.senderName!,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: fg.withOpacity(.9),
                  fontSize: 12,
                ),
              ),
            ),
          Text(message.content ?? '',
              style: TextStyle(color: fg, fontSize: 15, height: 1.25)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(color: fg.withOpacity(.75), fontSize: 11),
              ),
              if (isMe) ...[
                const SizedBox(width: 6),
                Icon(message.isRead ? Icons.done_all : Icons.done,
                    size: 16, color: message.isRead ? Colors.white : Colors.white70),
              ],
            ],
          ),
        ],
      ),
    );

    final avatar = showAvatar
        ? CircleAvatar(
            radius: 14,
            backgroundImage: _isValidUrl(message.senderAvatar)
                ? NetworkImage(message.senderAvatar!)
                : null,
            child: !_isValidUrl(message.senderAvatar)
                ? const Icon(Icons.person, size: 14)
                : null,
          )
        : const SizedBox(width: 28); // chừa chỗ cho layout đều

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMe
            ? [
                Flexible(child: bubble),
                const SizedBox(width: 8),
                // có thể ẩn avatar của mình để đỡ rối
              ]
            : [
                avatar,
                const SizedBox(width: 8),
                Flexible(child: bubble),
              ],
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final local = dt.isUtc ? dt.toLocal() : dt;
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.isNegative) return 'now';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  static bool _isValidUrl(String? url) =>
      url != null &&
      url.isNotEmpty &&
      (url.startsWith('http://') || url.startsWith('https://'));
}

// ====== Phần 2.4: Divider ngày ======

class _DateDivider extends StatelessWidget {
  final String text;
  const _DateDivider({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(height: 32)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        const Expanded(child: Divider(height: 32)),
      ],
    );
  }
}

String _formatDay(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  if (d == today) return 'Hôm nay';
  if (d == yesterday) return 'Hôm qua';
  return '${d.day}/${d.month}/${d.year}';
}

import 'package:flutter/material.dart';
import '../../../core/models/post.dart';

class PostHeader extends StatelessWidget {
  final Post post;

  const PostHeader({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User info
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                post.displayName?.isNotEmpty == true 
                    ? post.displayName![0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.displayName ?? 'Người dùng',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _formatTimeAgo(post.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getVisibilityColor(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                post.visibilityText,
                style: TextStyle(
                  color: _getVisibilityColor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Title
        if (post.title != null && post.title!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              post.title!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        
        // Movie info
        if (post.tmdbId != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  post.mediaType == 'tv' ? Icons.tv : Icons.movie,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Về ${post.mediaType == 'tv' ? 'TV Show' : 'Movie'}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  Color _getVisibilityColor(BuildContext context) {
    switch (post.visibility) {
      case 0: // Private
        return Colors.orange;
      case 1: // Public
        return Colors.green;
      case 2: // Unlisted
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/post.dart';
import '../../core/providers/community_provider.dart';
import 'widgets/comment_section.dart';
import 'widgets/post_header.dart';
import 'widgets/post_editor.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final int postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  Post? _post;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Load post from API
      final post = await ref.read(postsProvider.notifier).getPost(widget.postId);
      
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết bài viết'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Có lỗi xảy ra',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadPost();
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết bài viết'),
        ),
        body: const Center(
          child: Text('Không tìm thấy bài viết'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bài viết'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // TODO: Handle share
            },
          ),
          if (_post!.canEdit || _post!.canDelete)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editPost();
                    break;
                  case 'delete':
                    _deletePost();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (_post!.canEdit)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Chỉnh sửa'),
                  ),
                if (_post!.canDelete)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Xóa'),
                  ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PostHeader(post: _post!),
                  const SizedBox(height: 16),
                  
                  // Content
                  Text(
                    _post!.content,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  
                  // Comments section
                  CommentSection(postId: widget.postId),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editPost() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostEditor(
          postId: widget.postId,
          isEditMode: true,
          tmdbId: _post?.tmdbId,
          mediaType: _post?.mediaType,
          initialTitle: _post?.title,
          initialContent: _post?.content,
          initialVisibility: _post?.visibility,
          onPostCreated: () {
            // Reload post after edit to reflect latest state
            _loadPost();
          },
        ),
      ),
    );
  }

  void _deletePost() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài viết'),
        content: const Text('Bạn có chắc chắn muốn xóa bài viết này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(postsProvider.notifier).deletePost(widget.postId);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bài viết đã được xóa thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi xóa bài viết: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

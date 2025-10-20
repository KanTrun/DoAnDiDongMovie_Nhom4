import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/post.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/auth_provider.dart';
import 'widgets/post_card.dart';
import 'widgets/post_editor.dart';
import 'widgets/community_filters.dart';
import 'post_detail_screen.dart';

class CommunityTab extends ConsumerStatefulWidget {
  const CommunityTab({super.key});

  @override
  ConsumerState<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends ConsumerState<CommunityTab> {
  final ScrollController _scrollController = ScrollController();
  String _currentFilter = 'all';
  int? _tmdbId;
  String? _mediaType;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeed();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      // Load more posts when reaching 80% of scroll
      _loadMorePosts();
    }
  }

  void _loadFeed() {
    final filter = PostFeedFilter(
      filter: _currentFilter,
      tmdbId: _tmdbId,
      mediaType: _mediaType,
    );
    ref.read(postsProvider.notifier).loadFeed(filter: filter);
  }

  void _loadMorePosts() {
    // TODO: Implement pagination
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _currentFilter = filter;
    });
    _loadFeed();
  }

  void _onMovieFilterChanged(int? tmdbId, String? mediaType) {
    setState(() {
      _tmdbId = tmdbId;
      _mediaType = mediaType;
    });
    _loadFeed();
  }

  void _handleLike(PostListItem post) async {
    try {
      if (post.isLikedByCurrentUser) {
        await ref.read(reactionsProvider.notifier).unlikePost(post.id);
      } else {
        await ref.read(reactionsProvider.notifier).likePost(post.id);
      }
      // Refresh feed to update like counts
      _loadFeed();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToPostDetail(int postId) {
    // Navigate to post detail screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(postId: postId),
      ),
    );
  }

  void _handleShare(PostListItem post) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng chia sẻ đang được phát triển'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _handleFollow(String userId) async {
    try {
      // For now, always follow (TODO: implement proper follow status check)
      await ref.read(followsProvider.notifier).followUser(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã theo dõi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleEditPost(PostListItem post) {
    // Open PostEditor in edit mode
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PostEditor(
        postId: post.id,
        isEditMode: true,
        tmdbId: post.tmdbId,
        mediaType: post.mediaType,
        initialTitle: post.title,
        initialContent: post.excerpt,
        initialVisibility: 1, // Default to Public
        onPostCreated: () {
          // Refresh the feed after editing
          _loadFeed();
        },
      ),
    );
  }

  void _handleDeletePost(PostListItem post) {
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
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(postsProvider.notifier).deletePost(post.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa bài viết'),
                    backgroundColor: Colors.red,
                  ),
                );
              // Refresh the feed again to ensure latest data
              _loadFeed();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi xóa bài viết: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showPostEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PostEditor(
        tmdbId: _tmdbId,
        mediaType: _mediaType,
        onPostCreated: () {
          _loadFeed();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsState = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cộng đồng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: Column(
        children: [
          CommunityFilters(
            currentFilter: _currentFilter,
            onFilterChanged: _onFilterChanged,
            onMovieFilterChanged: _onMovieFilterChanged,
          ),
          Expanded(
            child: postsState.when(
              data: (response) {
                if (response.posts.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có bài viết nào',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Hãy là người đầu tiên chia sẻ về bộ phim yêu thích!',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadFeed();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: response.posts.length,
                    itemBuilder: (context, index) {
                      final post = response.posts[index];
                      final currentUser = ref.watch(currentUserProvider);
                      final isOwner = currentUser?.userId == post.userId;
                      final followStatus = ref.watch(followStatusProvider(post.userId));
                      
                      return PostCard(
                        post: post,
                        onLike: () {
                          _handleLike(post);
                        },
                        onComment: () {
                          _navigateToPostDetail(post.id);
                        },
                        onShare: () {
                          _handleShare(post);
                        },
                        onFollow: isOwner ? null : () {
                          _handleFollow(post.userId);
                        },
                        onEdit: isOwner ? () {
                          _handleEditPost(post);
                        } : null,
                        onDelete: isOwner ? () {
                          _handleDeletePost(post);
                        } : null,
                        isFollowing: followStatus.when(
                          data: (isFollowing) => isFollowing,
                          loading: () => false,
                          error: (_, __) => false,
                        ),
                        isOwner: isOwner,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
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
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadFeed,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPostEditor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/community_provider.dart';
import 'widgets/post_card.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? displayName;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.displayName,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserPosts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  void _loadUserPosts() {
    ref.read(postsProvider.notifier).loadUserPosts(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.displayName ?? 'Hồ sơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showMoreOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // User info
          _buildUserInfo(),
          
          // Follow button
          _buildFollowButton(),
          
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Bài viết'),
              Tab(text: 'Thích'),
              Tab(text: 'Theo dõi'),
            ],
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(),
                _buildLikesTab(),
                _buildFollowingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              (widget.displayName?.isNotEmpty == true 
                  ? widget.displayName![0].toUpperCase()
                  : 'U'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.displayName ?? 'Người dùng',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem('Bài viết', '0'),
              const SizedBox(width: 24),
              _buildStatItem('Theo dõi', '0'),
              const SizedBox(width: 24),
              _buildStatItem('Người theo dõi', '0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // TODO: Handle follow/unfollow
              },
              child: const Text('Theo dõi'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // TODO: Handle message
              },
              child: const Text('Nhắn tin'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    final postsState = ref.watch(postsProvider);

    return postsState.when(
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
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadUserPosts();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: response.posts.length,
            itemBuilder: (context, index) {
              final post = response.posts[index];
              return PostCard(
                post: post,
                onLike: () {
                  // TODO: Handle like
                },
                onComment: () {
                  // TODO: Navigate to post detail
                },
                onShare: () {
                  // TODO: Handle share
                },
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
              onPressed: _loadUserPosts,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikesTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Chưa có bài viết nào được thích',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowingTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Chưa theo dõi ai',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Báo cáo'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Handle report
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('Chặn'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Handle block
              },
            ),
          ],
        ),
      ),
    );
  }
}

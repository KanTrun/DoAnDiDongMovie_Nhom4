import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/notification.dart';
import '../services/posts_service.dart';
import '../services/comments_service.dart';
import '../services/reactions_service.dart';
import '../services/follows_service.dart';
import '../services/notifications_service.dart';
import 'auth_provider.dart';

// Posts provider
final postsProvider = StateNotifierProvider<PostsNotifier, AsyncValue<PagedPostsResponse>>((ref) {
  final token = ref.watch(authTokenProvider);
  return PostsNotifier(token);
});

class PostsNotifier extends StateNotifier<AsyncValue<PagedPostsResponse>> {
  final String? token;
  PostFeedFilter? _currentFilter;

  PostsNotifier(this.token) : super(const AsyncValue.loading()) {
    if (token != null) {
      loadFeed();
    } else {
      state = AsyncValue.data(PagedPostsResponse(
        posts: [],
        totalCount: 0,
        page: 1,
        pageSize: 20,
        totalPages: 0,
      ));
    }
  }

  Future<void> loadFeed({PostFeedFilter? filter}) async {
    if (token == null) {
      state = AsyncValue.data(PagedPostsResponse(
        posts: [],
        totalCount: 0,
        page: 1,
        pageSize: 20,
        totalPages: 0,
      ));
      return;
    }

    _currentFilter = filter ?? PostFeedFilter();
    state = const AsyncValue.loading();
    
    try {
      final response = await PostsService.getFeed(token!, _currentFilter!);
      state = AsyncValue.data(response);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadPostsByMovie(int tmdbId, {String? mediaType}) async {
    if (token == null) return;

    state = const AsyncValue.loading();
    
    try {
      final response = await PostsService.getPostsByMovie(token!, tmdbId, mediaType: mediaType);
      state = AsyncValue.data(response);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadUserPosts(String userId) async {
    if (token == null) return;

    state = const AsyncValue.loading();
    
    try {
      final response = await PostsService.getUserPosts(token!, userId);
      state = AsyncValue.data(response);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createPost(CreatePostRequest request) async {
    if (token == null) return;

    try {
      final post = await PostsService.createPost(token!, request);
      
      // Convert Post to PostListItem
      final postListItem = PostListItem(
        id: post.id,
        userId: post.userId,
        displayName: post.displayName ?? 'Người dùng',
        tmdbId: post.tmdbId,
        mediaType: post.mediaType,
        title: post.title,
        excerpt: post.content.length > 200 ? post.content.substring(0, 200) + '...' : post.content,
        likeCount: post.likeCount,
        commentCount: post.commentCount,
        createdAt: post.createdAt,
        isLikedByCurrentUser: post.isLikedByCurrentUser,
        posterPath: post.posterPath,
      );
      
      state.whenData((response) {
        final updatedPosts = [postListItem, ...response.posts];
        state = AsyncValue.data(PagedPostsResponse(
          posts: updatedPosts,
          totalCount: response.totalCount + 1,
          page: response.page,
          pageSize: response.pageSize,
          totalPages: response.totalPages,
        ));
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updatePost(int postId, UpdatePostRequest request) async {
    if (token == null) return;

    try {
      final updatedPost = await PostsService.updatePost(token!, postId, request);
      
      // Convert Post to PostListItem
      final postListItem = PostListItem(
        id: updatedPost.id,
        userId: updatedPost.userId,
        displayName: updatedPost.displayName ?? 'Người dùng',
        tmdbId: updatedPost.tmdbId,
        mediaType: updatedPost.mediaType,
        title: updatedPost.title,
        excerpt: updatedPost.content.length > 200 ? updatedPost.content.substring(0, 200) + '...' : updatedPost.content,
        likeCount: updatedPost.likeCount,
        commentCount: updatedPost.commentCount,
        createdAt: updatedPost.createdAt,
        isLikedByCurrentUser: updatedPost.isLikedByCurrentUser,
        posterPath: updatedPost.posterPath,
      );
      
      state.whenData((response) {
        final updatedPosts = response.posts.map((post) {
          return post.id == postId ? postListItem : post;
        }).toList();
        
        state = AsyncValue.data(PagedPostsResponse(
          posts: updatedPosts,
          totalCount: response.totalCount,
          page: response.page,
          pageSize: response.pageSize,
          totalPages: response.totalPages,
        ));
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deletePost(int postId) async {
    if (token == null) return;

    try {
      await PostsService.deletePost(token!, postId);
      
      state.whenData((response) {
        final updatedPosts = response.posts.where((post) => post.id != postId).toList();
        state = AsyncValue.data(PagedPostsResponse(
          posts: updatedPosts,
          totalCount: response.totalCount - 1,
          page: response.page,
          pageSize: response.pageSize,
          totalPages: response.totalPages,
        ));
      });

      // Force refresh from server to avoid stale cache and ensure consistency
      if (_currentFilter != null) {
        await loadFeed(filter: _currentFilter);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<Post> getPost(int postId) async {
    if (token == null) throw Exception('Not authenticated');
    
    try {
      return await PostsService.getPost(token!, postId);
    } catch (e) {
      throw Exception('Failed to load post: $e');
    }
  }
}

// Comments provider
final commentsProvider = StateNotifierProvider.family<CommentsNotifier, AsyncValue<PagedCommentsResponse>, int>((ref, postId) {
  final token = ref.watch(authTokenProvider);
  return CommentsNotifier(token, postId);
});

class CommentsNotifier extends StateNotifier<AsyncValue<PagedCommentsResponse>> {
  final String? token;
  final int postId;

  CommentsNotifier(this.token, this.postId) : super(const AsyncValue.loading()) {
    if (token != null) {
      loadComments();
    } else {
      state = AsyncValue.data(PagedCommentsResponse(
        comments: [],
        totalCount: 0,
        page: 1,
        pageSize: 20,
        totalPages: 0,
      ));
    }
  }

  Future<void> loadComments() async {
    if (token == null) {
      state = AsyncValue.data(PagedCommentsResponse(
        comments: [],
        totalCount: 0,
        page: 1,
        pageSize: 20,
        totalPages: 0,
      ));
      return;
    }

    state = const AsyncValue.loading();
    
    try {
      final filter = CommentFilter(postId: postId);
      final response = await CommentsService.getPostComments(token!, filter);
      state = AsyncValue.data(response);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createComment(CreateCommentRequest request) async {
    if (token == null) return;

    try {
      final comment = await CommentsService.createComment(token!, postId, request);
      
      state.whenData((response) {
        final updatedComments = [comment, ...response.comments];
        state = AsyncValue.data(PagedCommentsResponse(
          comments: updatedComments,
          totalCount: response.totalCount + 1,
          page: response.page,
          pageSize: response.pageSize,
          totalPages: response.totalPages,
        ));
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateComment(int commentId, UpdateCommentRequest request) async {
    if (token == null) return;

    try {
      final updatedComment = await CommentsService.updateComment(token!, commentId, request);
      
      state.whenData((response) {
        final updatedComments = response.comments.map((comment) {
          return comment.id == commentId ? updatedComment : comment;
        }).toList();
        
        state = AsyncValue.data(PagedCommentsResponse(
          comments: updatedComments,
          totalCount: response.totalCount,
          page: response.page,
          pageSize: response.pageSize,
          totalPages: response.totalPages,
        ));
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteComment(int commentId) async {
    if (token == null) return;

    try {
      await CommentsService.deleteComment(token!, commentId);
      
      state.whenData((response) {
        final updatedComments = response.comments.where((comment) => comment.id != commentId).toList();
        state = AsyncValue.data(PagedCommentsResponse(
          comments: updatedComments,
          totalCount: response.totalCount - 1,
          page: response.page,
          pageSize: response.pageSize,
          totalPages: response.totalPages,
        ));
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleCommentLike(int commentId) async {
    if (token == null) return;

    try {
      // Use ReactionsService to like/unlike comment
      await ReactionsService.likeComment(token!, commentId);
      
      // Reload comments to get updated like status
      await loadComments();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Reactions provider
final reactionsProvider = StateNotifierProvider<ReactionsNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  final token = ref.watch(authTokenProvider);
  return ReactionsNotifier(token);
});

class ReactionsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final String? token;

  ReactionsNotifier(this.token) : super(const AsyncValue.data({}));

  Future<void> likePost(int postId) async {
    if (token == null) return;

    try {
      await ReactionsService.likePost(token!, postId);
      
      // Update local state
      state.whenData((data) {
        final updatedData = Map<String, dynamic>.from(data);
        updatedData['post_$postId'] = true;
        state = AsyncValue.data(updatedData);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> unlikePost(int postId) async {
    if (token == null) return;

    try {
      await ReactionsService.unlikePost(token!, postId);
      
      // Update local state
      state.whenData((data) {
        final updatedData = Map<String, dynamic>.from(data);
        updatedData['post_$postId'] = false;
        state = AsyncValue.data(updatedData);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> likeComment(int commentId) async {
    if (token == null) return;

    try {
      await ReactionsService.likeComment(token!, commentId);
      
      // Update local state
      state.whenData((data) {
        final updatedData = Map<String, dynamic>.from(data);
        updatedData['comment_$commentId'] = true;
        state = AsyncValue.data(updatedData);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> unlikeComment(int commentId) async {
    if (token == null) return;

    try {
      await ReactionsService.unlikeComment(token!, commentId);
      
      // Update local state
      state.whenData((data) {
        final updatedData = Map<String, dynamic>.from(data);
        updatedData['comment_$commentId'] = false;
        state = AsyncValue.data(updatedData);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  bool isPostLiked(int postId) {
    return state.whenOrNull(
      data: (data) => data['post_$postId'] == true,
    ) ?? false;
  }

  bool isCommentLiked(int commentId) {
    return state.whenOrNull(
      data: (data) => data['comment_$commentId'] == true,
    ) ?? false;
  }
}

// Follows provider
final followsProvider = StateNotifierProvider<FollowsNotifier, AsyncValue<Map<String, dynamic>>>((ref) {
  final token = ref.watch(authTokenProvider);
  return FollowsNotifier(token);
});

class FollowsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final String? token;

  FollowsNotifier(this.token) : super(const AsyncValue.data({}));

  Future<void> followUser(String userId) async {
    if (token == null) return;

    try {
      await FollowsService.followUser(token!, userId);
      
      // Update local state
      state.whenData((data) {
        final updatedData = Map<String, dynamic>.from(data);
        updatedData['follow_$userId'] = true;
        state = AsyncValue.data(updatedData);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> unfollowUser(String userId) async {
    if (token == null) return;

    try {
      await FollowsService.unfollowUser(token!, userId);
      
      // Update local state
      state.whenData((data) {
        final updatedData = Map<String, dynamic>.from(data);
        updatedData['follow_$userId'] = false;
        state = AsyncValue.data(updatedData);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  bool isFollowing(String userId) {
    return state.whenOrNull(
      data: (data) => data['follow_$userId'] == true,
    ) ?? false;
  }
}

// Notifications provider
final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<PagedNotificationsResponse>>((ref) {
  final token = ref.watch(authTokenProvider);
  return NotificationsNotifier(token);
});

// Follow status provider
  final followStatusProvider = FutureProvider.family<bool, String>((ref, userId) async {
    final token = ref.watch(authTokenProvider);
    if (token == null) return false;
    
    try {
      final result = await FollowsService.isFollowing(token, userId);
      return result;
    } catch (e) {
      return false;
    }
  });

// Follow statistics provider
final followStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) return {'following': 0, 'followers': 0};
  
  try {
    final stats = await FollowsService.getUserFollowStats(token);
    return stats;
  } catch (e) {
    return {'following': 0, 'followers': 0};
  }
});

class NotificationsNotifier extends StateNotifier<AsyncValue<PagedNotificationsResponse>> {
  final String? token;

  NotificationsNotifier(this.token) : super(const AsyncValue.loading()) {
    if (token != null) {
      loadNotifications();
    } else {
      state = AsyncValue.data(PagedNotificationsResponse(
        notifications: [],
        totalCount: 0,
        page: 1,
        pageSize: 20,
        totalPages: 0,
        unreadCount: 0,
      ));
    }
  }

  Future<void> loadNotifications({NotificationFilter? filter}) async {
    if (token == null) {
      state = AsyncValue.data(PagedNotificationsResponse(
        notifications: [],
        totalCount: 0,
        page: 1,
        pageSize: 20,
        totalPages: 0,
        unreadCount: 0,
      ));
      return;
    }

    state = const AsyncValue.loading();
    
    try {
      final response = await NotificationsService.getNotifications(token!, filter ?? NotificationFilter());
      state = AsyncValue.data(response);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsRead(int notificationId) async {
    if (token == null) return;

    try {
      await NotificationsService.markAsRead(token!, notificationId);
      
      state.whenData((response) {
        final updatedNotifications = response.notifications.map((notification) {
          return notification.id == notificationId 
              ? notification.copyWith(isRead: true)
              : notification;
        }).toList();
        
        state = AsyncValue.data(PagedNotificationsResponse(
          notifications: updatedNotifications,
          totalCount: response.totalCount,
          page: response.page,
          pageSize: response.pageSize,
          totalPages: response.totalPages,
          unreadCount: response.unreadCount - 1,
        ));
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAllAsRead({List<int>? notificationIds}) async {
    if (token == null) return;

    try {
      await NotificationsService.markAllAsRead(token!, notificationIds: notificationIds);
      
      state.whenData((response) {
        final updatedNotifications = response.notifications.map((notification) {
          return notification.copyWith(isRead: true);
        }).toList();
        
        state = AsyncValue.data(PagedNotificationsResponse(
          notifications: updatedNotifications,
          totalCount: response.totalCount,
          page: response.page,
          pageSize: response.pageSize,
          totalPages: response.totalPages,
          unreadCount: 0,
        ));
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<int> getUnreadCount() async {
    if (token == null) return 0;
    
    try {
      return await NotificationsService.getUnreadCount(token!);
    } catch (e) {
      return 0;
    }
  }
}

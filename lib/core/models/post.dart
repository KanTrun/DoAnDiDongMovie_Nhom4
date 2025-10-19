class Post {
  final int id;
  final String userId;
  final int? tmdbId;
  final String? mediaType;
  final String? title;
  final String content;
  final int visibility; // 0=Private, 1=Public, 2=Unlisted
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? displayName;
  final String? posterPath;
  final bool isLikedByCurrentUser;
  final bool canEdit;
  final bool canDelete;

  Post({
    required this.id,
    required this.userId,
    this.tmdbId,
    this.mediaType,
    this.title,
    required this.content,
    required this.visibility,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.updatedAt,
    this.displayName,
    this.posterPath,
    this.isLikedByCurrentUser = false,
    this.canEdit = false,
    this.canDelete = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['userId'],
      tmdbId: json['tmdbId'],
      mediaType: json['mediaType'],
      title: json['title'],
      content: json['content'],
      visibility: json['visibility'],
      likeCount: json['likeCount'],
      commentCount: json['commentCount'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      displayName: json['displayName'],
      posterPath: json['posterPath'],
      isLikedByCurrentUser: json['isLikedByCurrentUser'] ?? false,
      canEdit: json['canEdit'] ?? false,
      canDelete: json['canDelete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tmdbId': tmdbId,
      'mediaType': mediaType,
      'title': title,
      'content': content,
      'visibility': visibility,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'displayName': displayName,
      'posterPath': posterPath,
      'isLikedByCurrentUser': isLikedByCurrentUser,
      'canEdit': canEdit,
      'canDelete': canDelete,
    };
  }

  Post copyWith({
    int? id,
    String? userId,
    int? tmdbId,
    String? mediaType,
    String? title,
    String? content,
    int? visibility,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? displayName,
    String? posterPath,
    bool? isLikedByCurrentUser,
    bool? canEdit,
    bool? canDelete,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tmdbId: tmdbId ?? this.tmdbId,
      mediaType: mediaType ?? this.mediaType,
      title: title ?? this.title,
      content: content ?? this.content,
      visibility: visibility ?? this.visibility,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      displayName: displayName ?? this.displayName,
      posterPath: posterPath ?? this.posterPath,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
    );
  }

  String get visibilityText {
    switch (visibility) {
      case 0:
        return 'Private';
      case 1:
        return 'Public';
      case 2:
        return 'Unlisted';
      default:
        return 'Unknown';
    }
  }

  bool get isPublic => visibility == 1;
  bool get isPrivate => visibility == 0;
  bool get isUnlisted => visibility == 2;
}

class PostListItem {
  final int id;
  final String userId;
  final String displayName;
  final int? tmdbId;
  final String? mediaType;
  final String? title;
  final String excerpt;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final bool isLikedByCurrentUser;
  final String? posterPath;

  PostListItem({
    required this.id,
    required this.userId,
    required this.displayName,
    this.tmdbId,
    this.mediaType,
    this.title,
    required this.excerpt,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.isLikedByCurrentUser = false,
    this.posterPath,
  });

  factory PostListItem.fromJson(Map<String, dynamic> json) {
    return PostListItem(
      id: json['id'],
      userId: json['userId'],
      displayName: json['displayName'],
      tmdbId: json['tmdbId'],
      mediaType: json['mediaType'],
      title: json['title'],
      excerpt: json['excerpt'],
      likeCount: json['likeCount'],
      commentCount: json['commentCount'],
      createdAt: DateTime.parse(json['createdAt']),
      isLikedByCurrentUser: json['isLikedByCurrentUser'] ?? false,
      posterPath: json['posterPath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'displayName': displayName,
      'tmdbId': tmdbId,
      'mediaType': mediaType,
      'title': title,
      'excerpt': excerpt,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': createdAt.toIso8601String(),
      'isLikedByCurrentUser': isLikedByCurrentUser,
      'posterPath': posterPath,
    };
  }
}

class PagedPostsResponse {
  final List<PostListItem> posts;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  PagedPostsResponse({
    required this.posts,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PagedPostsResponse.fromJson(Map<String, dynamic> json) {
    return PagedPostsResponse(
      posts: (json['posts'] as List)
          .map((postJson) => PostListItem.fromJson(postJson))
          .toList(),
      totalCount: json['totalCount'],
      page: json['page'],
      pageSize: json['pageSize'],
      totalPages: json['totalPages'],
    );
  }
}

class CreatePostRequest {
  final int? tmdbId;
  final String? mediaType;
  final String? title;
  final String content;
  final int visibility;
  final String? posterPath;

  CreatePostRequest({
    this.tmdbId,
    this.mediaType,
    this.title,
    required this.content,
    this.visibility = 1, // Default to Public
    this.posterPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'tmdbId': tmdbId,
      'mediaType': mediaType,
      'title': title,
      'content': content,
      'visibility': visibility,
      'posterPath': posterPath,
    };
  }
}

class UpdatePostRequest {
  final String? title;
  final String? content;
  final int? visibility;

  UpdatePostRequest({
    this.title,
    this.content,
    this.visibility,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'visibility': visibility,
    };
  }
}

class PostFeedFilter {
  final String? filter; // "all", "following", "movie"
  final int? tmdbId;
  final String? mediaType;
  final int page;
  final int pageSize;

  PostFeedFilter({
    this.filter,
    this.tmdbId,
    this.mediaType,
    this.page = 1,
    this.pageSize = 20,
  });

  Map<String, dynamic> toJson() {
    return {
      'filter': filter,
      'tmdbId': tmdbId,
      'mediaType': mediaType,
      'page': page,
      'pageSize': pageSize,
    };
  }
}

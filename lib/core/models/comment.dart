import '../utils/time_utils.dart';

class Comment {
  final int id;
  final int postId;
  final String userId;
  final String displayName;
  final int? parentCommentId;
  final String content;
  final int likeCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isLikedByCurrentUser;
  final bool canEdit;
  final bool canDelete;
  final List<Comment>? replies;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.displayName,
    this.parentCommentId,
    required this.content,
    required this.likeCount,
    required this.createdAt,
    this.updatedAt,
    this.isLikedByCurrentUser = false,
    this.canEdit = false,
    this.canDelete = false,
    this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: _parseInt(json['id']),
      postId: _parseInt(json['postId']),
      userId: json['userId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      parentCommentId: json['parentCommentId'] != null ? _parseInt(json['parentCommentId']) : null,
      content: json['content']?.toString() ?? '',
      likeCount: _parseInt(json['likeCount']),
      createdAt: TimeUtils.parseUtcDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? TimeUtils.parseUtcDateTime(json['updatedAt']) : null,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] ?? false,
      canEdit: json['canEdit'] ?? false,
      canDelete: json['canDelete'] ?? false,
      replies: json['replies'] != null
          ? (json['replies'] as List)
              .map((replyJson) => Comment.fromJson(replyJson))
              .toList()
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'displayName': displayName,
      'parentCommentId': parentCommentId,
      'content': content,
      'likeCount': likeCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isLikedByCurrentUser': isLikedByCurrentUser,
      'canEdit': canEdit,
      'canDelete': canDelete,
      'replies': replies?.map((reply) => reply.toJson()).toList(),
    };
  }

  Comment copyWith({
    int? id,
    int? postId,
    String? userId,
    String? displayName,
    int? parentCommentId,
    String? content,
    int? likeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLikedByCurrentUser,
    bool? canEdit,
    bool? canDelete,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      content: content ?? this.content,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      replies: replies ?? this.replies,
    );
  }

  bool get isReply => parentCommentId != null;
  bool get hasReplies => replies != null && replies!.isNotEmpty;
}

class PagedCommentsResponse {
  final List<Comment> comments;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  PagedCommentsResponse({
    required this.comments,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PagedCommentsResponse.fromJson(Map<String, dynamic> json) {
    return PagedCommentsResponse(
      comments: (json['comments'] as List)
          .map((commentJson) => Comment.fromJson(commentJson))
          .toList(),
      totalCount: json['totalCount'],
      page: json['page'],
      pageSize: json['pageSize'],
      totalPages: json['totalPages'],
    );
  }
}

class CreateCommentRequest {
  final String content;
  final int? parentCommentId;

  CreateCommentRequest({
    required this.content,
    this.parentCommentId,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'parentCommentId': parentCommentId,
    };
  }
}

class UpdateCommentRequest {
  final String content;

  UpdateCommentRequest({
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }
}

class CommentFilter {
  final int postId;
  final int page;
  final int pageSize;
  final bool includeReplies;

  CommentFilter({
    required this.postId,
    this.page = 1,
    this.pageSize = 20,
    this.includeReplies = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'page': page,
      'pageSize': pageSize,
      'includeReplies': includeReplies,
    };
  }
}

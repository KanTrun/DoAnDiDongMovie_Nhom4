class Reaction {
  final int id;
  final int postId;
  final String userId;
  final String displayName;
  final int type;
  final DateTime createdAt;

  Reaction({
    required this.id,
    required this.postId,
    required this.userId,
    required this.displayName,
    required this.type,
    required this.createdAt,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      id: json['id'],
      postId: json['postId'],
      userId: json['userId'],
      displayName: json['displayName'],
      type: json['type'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'displayName': displayName,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class CommentReaction {
  final int id;
  final int commentId;
  final String userId;
  final String displayName;
  final int type;
  final DateTime createdAt;

  CommentReaction({
    required this.id,
    required this.commentId,
    required this.userId,
    required this.displayName,
    required this.type,
    required this.createdAt,
  });

  factory CommentReaction.fromJson(Map<String, dynamic> json) {
    return CommentReaction(
      id: json['id'],
      commentId: json['commentId'],
      userId: json['userId'],
      displayName: json['displayName'],
      type: json['type'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commentId': commentId,
      'userId': userId,
      'displayName': displayName,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ReactionSummary {
  final int totalLikes;
  final bool isLikedByCurrentUser;
  final List<Reaction>? recentLikes;

  ReactionSummary({
    required this.totalLikes,
    required this.isLikedByCurrentUser,
    this.recentLikes,
  });

  factory ReactionSummary.fromJson(Map<String, dynamic> json) {
    return ReactionSummary(
      totalLikes: json['totalLikes'],
      isLikedByCurrentUser: json['isLikedByCurrentUser'],
      recentLikes: json['recentLikes'] != null
          ? (json['recentLikes'] as List)
              .map((reactionJson) => Reaction.fromJson(reactionJson))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalLikes': totalLikes,
      'isLikedByCurrentUser': isLikedByCurrentUser,
      'recentLikes': recentLikes?.map((reaction) => reaction.toJson()).toList(),
    };
  }
}

class CommentReactionSummary {
  final int totalLikes;
  final bool isLikedByCurrentUser;
  final List<CommentReaction>? recentLikes;

  CommentReactionSummary({
    required this.totalLikes,
    required this.isLikedByCurrentUser,
    this.recentLikes,
  });

  factory CommentReactionSummary.fromJson(Map<String, dynamic> json) {
    return CommentReactionSummary(
      totalLikes: json['totalLikes'],
      isLikedByCurrentUser: json['isLikedByCurrentUser'],
      recentLikes: json['recentLikes'] != null
          ? (json['recentLikes'] as List)
              .map((reactionJson) => CommentReaction.fromJson(reactionJson))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalLikes': totalLikes,
      'isLikedByCurrentUser': isLikedByCurrentUser,
      'recentLikes': recentLikes?.map((reaction) => reaction.toJson()).toList(),
    };
  }
}

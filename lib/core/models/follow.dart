class FollowUser {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isFollowing;
  final bool isFollowedBy;

  FollowUser({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    this.isFollowing = false,
    this.isFollowedBy = false,
  });

  factory FollowUser.fromJson(Map<String, dynamic> json) {
    return FollowUser(
      userId: json['userId'],
      displayName: json['displayName'],
      avatarUrl: json['avatarUrl'],
      followersCount: json['followersCount'],
      followingCount: json['followingCount'],
      postsCount: json['postsCount'],
      isFollowing: json['isFollowing'] ?? false,
      isFollowedBy: json['isFollowedBy'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'postsCount': postsCount,
      'isFollowing': isFollowing,
      'isFollowedBy': isFollowedBy,
    };
  }

  FollowUser copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    bool? isFollowing,
    bool? isFollowedBy,
  }) {
    return FollowUser(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowedBy: isFollowedBy ?? this.isFollowedBy,
    );
  }
}

class PagedFollowsResponse {
  final List<FollowUser> users;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  PagedFollowsResponse({
    required this.users,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PagedFollowsResponse.fromJson(Map<String, dynamic> json) {
    return PagedFollowsResponse(
      users: (json['users'] as List)
          .map((userJson) => FollowUser.fromJson(userJson))
          .toList(),
      totalCount: json['totalCount'],
      page: json['page'],
      pageSize: json['pageSize'],
      totalPages: json['totalPages'],
    );
  }
}

class FollowFilter {
  final String userId;
  final String type; // "followers" or "following"
  final int page;
  final int pageSize;

  FollowFilter({
    required this.userId,
    required this.type,
    this.page = 1,
    this.pageSize = 20,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type,
      'page': page,
      'pageSize': pageSize,
    };
  }
}

class FollowStatus {
  final bool isFollowing;
  final bool isFollowedBy;

  FollowStatus({
    required this.isFollowing,
    required this.isFollowedBy,
  });

  factory FollowStatus.fromJson(Map<String, dynamic> json) {
    return FollowStatus(
      isFollowing: json['isFollowing'],
      isFollowedBy: json['isFollowedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isFollowing': isFollowing,
      'isFollowedBy': isFollowedBy,
    };
  }
}

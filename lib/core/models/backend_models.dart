class Favorite {
  final String favoriteId;
  final String userId;
  final int tmdbId; // Changed from movieId to tmdbId to match backend
  final String? mediaType; // 'movie' or 'tv', nullable for backward compatibility
  final DateTime addedAt;

  Favorite({
    required this.favoriteId,
    required this.userId,
    required this.tmdbId,
    this.mediaType,
    required this.addedAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      favoriteId: json['favoriteId'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: json['userId'] ?? '',
      tmdbId: json['tmdbId'] ?? json['movieId'] ?? 0, // Backend uses tmdbId
      mediaType: json['mediaType'] ?? 'movie', // Default to movie for backward compatibility
      addedAt: json['addedAt'] != null 
        ? DateTime.parse(json['addedAt']) 
        : (json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favoriteId': favoriteId,
      'userId': userId,
      'tmdbId': tmdbId,
      'mediaType': mediaType,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  // For backward compatibility
  int get movieId => tmdbId;
}

class Watchlist {
  final String watchlistId;
  final String userId;
  final int tmdbId; // Changed from movieId to tmdbId to match backend
  final String? mediaType; // 'movie' or 'tv', nullable for backward compatibility
  final String? note; // Optional note field
  final DateTime addedAt;

  Watchlist({
    required this.watchlistId,
    required this.userId,
    required this.tmdbId,
    this.mediaType,
    this.note,
    required this.addedAt,
  });

  factory Watchlist.fromJson(Map<String, dynamic> json) {
    return Watchlist(
      watchlistId: json['watchlistId'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: json['userId'] ?? '',
      tmdbId: json['tmdbId'] ?? json['movieId'] ?? 0, // Backend uses tmdbId
      mediaType: json['mediaType'] ?? 'movie', // Default to movie for backward compatibility
      note: json['note'],
      addedAt: json['addedAt'] != null 
        ? DateTime.parse(json['addedAt']) 
        : (json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'watchlistId': watchlistId,
      'userId': userId,
      'tmdbId': tmdbId,
      'mediaType': mediaType,
      'note': note,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  // For backward compatibility
  int get movieId => tmdbId;
}

class Note {
  final String noteId;
  final String userId;
  final int movieId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.noteId,
    required this.userId,
    required this.movieId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      noteId: json['noteId'] ?? '',
      userId: json['userId'] ?? '',
      movieId: json['movieId'] ?? 0,
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'noteId': noteId,
      'userId': userId,
      'movieId': movieId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}


class Rating {
  final String ratingId;
  final String userId;
  final int movieId;
  final double rating;
  final DateTime ratedAt;

  Rating({
    required this.ratingId,
    required this.userId,
    required this.movieId,
    required this.rating,
    required this.ratedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      ratingId: json['ratingId'] ?? '',
      userId: json['userId'] ?? '',
      movieId: json['movieId'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      ratedAt: DateTime.parse(json['ratedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ratingId': ratingId,
      'userId': userId,
      'movieId': movieId,
      'rating': rating,
      'ratedAt': ratedAt.toIso8601String(),
    };
  }
}

class AddFavoriteRequest {
  final int tmdbId;
  final String mediaType;

  AddFavoriteRequest({required this.tmdbId, required this.mediaType});

  Map<String, dynamic> toJson() {
    return {
      'tmdbId': tmdbId,
      'mediaType': mediaType,
    };
  }
}

class AddWatchlistRequest {
  final int tmdbId;
  final String mediaType;
  final String? note;

  AddWatchlistRequest({required this.tmdbId, required this.mediaType, this.note});

  Map<String, dynamic> toJson() {
    return {
      'tmdbId': tmdbId,
      'mediaType': mediaType,
      'note': note,
    };
  }
}

class AddNoteRequest {
  final int movieId;
  final String content;

  AddNoteRequest({
    required this.movieId,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'movieId': movieId,
      'content': content,
    };
  }
}

class AddHistoryRequest {
  final int movieId;

  AddHistoryRequest({required this.movieId});

  Map<String, dynamic> toJson() {
    return {'movieId': movieId};
  }
}

class AddRatingRequest {
  final int movieId;
  final double rating;

  AddRatingRequest({
    required this.movieId,
    required this.rating,
  });

  Map<String, dynamic> toJson() {
    return {
      'movieId': movieId,
      'rating': rating,
    };
  }
}

// Admin Models
class AdminUser {
  final String id;
  final String email;
  final String? displayName;
  final String role;
  final DateTime createdAt;
  final bool bioAuthEnabled;
  final int favoritesCount;
  final int watchlistsCount;
  final int notesCount;
  final int historiesCount;
  final int ratingsCount;

  AdminUser({
    required this.id,
    required this.email,
    this.displayName,
    required this.role,
    required this.createdAt,
    required this.bioAuthEnabled,
    required this.favoritesCount,
    required this.watchlistsCount,
    required this.notesCount,
    required this.historiesCount,
    required this.ratingsCount,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      role: json['role'] ?? 'User',
      createdAt: DateTime.parse(json['createdAt']),
      bioAuthEnabled: json['bioAuthEnabled'] ?? false,
      favoritesCount: json['favoritesCount'] ?? 0,
      watchlistsCount: json['watchlistsCount'] ?? 0,
      notesCount: json['notesCount'] ?? 0,
      historiesCount: json['historiesCount'] ?? 0,
      ratingsCount: json['ratingsCount'] ?? 0,
    );
  }
}

class AdminStats {
  final int totalUsers;
  final int totalAdmins;
  final int totalRegularUsers;
  final int totalFavorites;
  final int totalWatchlists;
  final int totalNotes;
  final int totalHistories;
  final int totalRatings;
  final int recentUsers;

  AdminStats({
    required this.totalUsers,
    required this.totalAdmins,
    required this.totalRegularUsers,
    required this.totalFavorites,
    required this.totalWatchlists,
    required this.totalNotes,
    required this.totalHistories,
    required this.totalRatings,
    required this.recentUsers,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalAdmins: json['totalAdmins'] ?? 0,
      totalRegularUsers: json['totalRegularUsers'] ?? 0,
      totalFavorites: json['totalFavorites'] ?? 0,
      totalWatchlists: json['totalWatchlists'] ?? 0,
      totalNotes: json['totalNotes'] ?? 0,
      totalHistories: json['totalHistories'] ?? 0,
      totalRatings: json['totalRatings'] ?? 0,
      recentUsers: json['recentUsers'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalAdmins': totalAdmins,
      'totalRegularUsers': totalRegularUsers,
      'totalFavorites': totalFavorites,
      'totalWatchlists': totalWatchlists,
      'totalNotes': totalNotes,
      'totalHistories': totalHistories,
      'totalRatings': totalRatings,
      'recentUsers': recentUsers,
    };
  }
}

class History {
  final int id;
  final String userId;
  final int tmdbId;
  final String mediaType; // "movie" | "tv"
  final DateTime watchedAt;
  final String action; // TrailerView, DetailOpen, ProviderClick, etc.
  final String? extra; // JSON metadata

  History({
    required this.id,
    required this.userId,
    required this.tmdbId,
    required this.mediaType,
    required this.watchedAt,
    required this.action,
    this.extra,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? '',
      tmdbId: json['tmdbId'] ?? 0,
      mediaType: json['mediaType'] ?? 'movie',
      watchedAt: DateTime.parse(json['watchedAt']),
      action: json['action'] ?? '',
      extra: json['extra'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'tmdbId': tmdbId,
      'mediaType': mediaType,
      'watchedAt': watchedAt.toIso8601String(),
      'action': action,
      'extra': extra,
    };
  }
}
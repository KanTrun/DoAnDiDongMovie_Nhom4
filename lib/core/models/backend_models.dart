class Favorite {
  final String favoriteId;
  final String userId;
  final int movieId;
  final DateTime addedAt;

  Favorite({
    required this.favoriteId,
    required this.userId,
    required this.movieId,
    required this.addedAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      favoriteId: json['favoriteId'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: json['userId'] ?? '',
      movieId: json['movieId'] ?? json['tmdbId'] ?? 0, // Backend uses tmdbId
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
      'movieId': movieId,
      'addedAt': addedAt.toIso8601String(),
    };
  }
}

class Watchlist {
  final String watchlistId;
  final String userId;
  final int movieId;
  final DateTime addedAt;

  Watchlist({
    required this.watchlistId,
    required this.userId,
    required this.movieId,
    required this.addedAt,
  });

  factory Watchlist.fromJson(Map<String, dynamic> json) {
    return Watchlist(
      watchlistId: json['watchlistId'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: json['userId'] ?? '',
      movieId: json['movieId'] ?? json['tmdbId'] ?? 0, // Backend uses tmdbId
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
      'movieId': movieId,
      'addedAt': addedAt.toIso8601String(),
    };
  }
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

class History {
  final String historyId;
  final String userId;
  final int movieId;
  final DateTime watchedAt;

  History({
    required this.historyId,
    required this.userId,
    required this.movieId,
    required this.watchedAt,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      historyId: json['historyId'] ?? '',
      userId: json['userId'] ?? '',
      movieId: json['movieId'] ?? 0,
      watchedAt: DateTime.parse(json['watchedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'historyId': historyId,
      'userId': userId,
      'movieId': movieId,
      'watchedAt': watchedAt.toIso8601String(),
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
  final int movieId;

  AddFavoriteRequest({required this.movieId});

  Map<String, dynamic> toJson() {
    return {
      'tmdbId': movieId,  // Backend expects 'tmdbId'
      'mediaType': 'movie',  // Backend expects 'mediaType'
    };
  }
}

class AddWatchlistRequest {
  final int movieId;

  AddWatchlistRequest({required this.movieId});

  Map<String, dynamic> toJson() {
    return {
      'tmdbId': movieId,  // Backend expects 'tmdbId'
      'mediaType': 'movie',  // Backend expects 'mediaType'
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
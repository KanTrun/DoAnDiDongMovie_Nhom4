import '../utils/time_utils.dart';

class Rating {
  final int id;
  final int tmdbId;
  final String mediaType;
  final double score;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Rating({
    required this.id,
    required this.tmdbId,
    required this.mediaType,
    required this.score,
    required this.createdAt,
    this.updatedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'],
      tmdbId: json['tmdbId'],
      mediaType: json['mediaType'],
      score: (json['score'] as num).toDouble(),
      createdAt: TimeUtils.parseUtcDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? TimeUtils.parseUtcDateTime(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tmdbId': tmdbId,
      'mediaType': mediaType,
      'score': score,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Rating copyWith({
    int? id,
    int? tmdbId,
    String? mediaType,
    double? score,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Rating(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      mediaType: mediaType ?? this.mediaType,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PagedRatingsResponse {
  final List<Rating> ratings;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  PagedRatingsResponse({
    required this.ratings,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PagedRatingsResponse.fromJson(Map<String, dynamic> json) {
    return PagedRatingsResponse(
      ratings: (json['ratings'] as List)
          .map((ratingJson) => Rating.fromJson(ratingJson))
          .toList(),
      totalCount: json['totalCount'],
      page: json['page'],
      pageSize: json['pageSize'],
      totalPages: json['totalPages'],
    );
  }
}


import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rating.dart';
import '../services/ratings_service.dart';
import 'auth_provider.dart';

final ratingsServiceProvider = Provider<RatingsService>((ref) {
  final token = ref.read(authTokenProvider);
  print('🔑 RATINGS SERVICE PROVIDER - Token: ${token != null ? "Present" : "NULL"}');
  return RatingsService(token);
});

final ratingsProvider = StateNotifierProvider<RatingsNotifier, RatingsState>((ref) {
  final ratingsService = ref.read(ratingsServiceProvider);
  return RatingsNotifier(ratingsService);
});

final movieRatingProvider = StateNotifierProvider.family<MovieRatingNotifier, MovieRatingState, String>((ref, key) {
  print('🔍 RATINGS PROVIDER - Creating provider for key: $key');
  final ratingsService = ref.read(ratingsServiceProvider);
  final parts = key.split('_');
  final tmdbId = int.parse(parts[0]);
  final mediaType = parts[1];
  print('🔍 RATINGS PROVIDER - Parsed tmdbId: $tmdbId, mediaType: $mediaType');
  return MovieRatingNotifier(ratingsService, tmdbId, mediaType);
});

class RatingsState {
  final List<Rating> ratings;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  RatingsState({
    this.ratings = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 0,
    this.hasMore = false,
  });

  RatingsState copyWith({
    List<Rating>? ratings,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
  }) {
    return RatingsState(
      ratings: ratings ?? this.ratings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class MovieRatingState {
  final Rating? rating;
  final bool isLoading;
  final String? error;

  MovieRatingState({
    this.rating,
    this.isLoading = false,
    this.error,
  });

  MovieRatingState copyWith({
    Rating? rating,
    bool? isLoading,
    String? error,
  }) {
    return MovieRatingState(
      rating: rating ?? this.rating,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RatingsNotifier extends StateNotifier<RatingsState> {
  final RatingsService _ratingsService;

  RatingsNotifier(this._ratingsService) : super(RatingsState());

  Future<void> loadRatings({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, error: null, currentPage: 1);
    } else if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _ratingsService.getRatings(
        page: refresh ? 1 : state.currentPage,
        pageSize: 20,
      );

      final newRatings = refresh ? response.ratings : [...state.ratings, ...response.ratings];

      state = state.copyWith(
        ratings: newRatings,
        isLoading: false,
        currentPage: response.page,
        totalPages: response.totalPages,
        hasMore: response.page < response.totalPages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMoreRatings() async {
    if (!state.hasMore || state.isLoading) return;
    await loadRatings();
  }

  Future<void> upsertRating({
    required int tmdbId,
    required String mediaType,
    required double score,
  }) async {
    try {
      final newRating = await _ratingsService.upsertRating(
        tmdbId: tmdbId,
        mediaType: mediaType,
        score: score,
      );

      // Update or add rating
      final existingIndex = state.ratings.indexWhere((r) => r.id == newRating.id);
      if (existingIndex >= 0) {
        final updatedRatings = List<Rating>.from(state.ratings);
        updatedRatings[existingIndex] = newRating;
        state = state.copyWith(ratings: updatedRatings);
      } else {
        state = state.copyWith(ratings: [newRating, ...state.ratings]);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteRating(int id) async {
    try {
      await _ratingsService.deleteRating(id);

      final updatedRatings = state.ratings.where((rating) => rating.id != id).toList();
      state = state.copyWith(ratings: updatedRatings);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

class MovieRatingNotifier extends StateNotifier<MovieRatingState> {
  final RatingsService _ratingsService;
  final int tmdbId;
  final String mediaType;

  MovieRatingNotifier(this._ratingsService, this.tmdbId, this.mediaType) : super(MovieRatingState()) {
    print('🔍 RATINGS NOTIFIER - Constructor called for tmdbId: $tmdbId, mediaType: $mediaType');
    loadRating();
  }

  Future<void> loadRating() async {
    print('🔍 RATINGS PROVIDER - Loading rating for tmdbId: $tmdbId, mediaType: $mediaType');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final rating = await _ratingsService.getRatingByMovie(tmdbId, mediaType);
      print('✅ RATINGS PROVIDER - Successfully loaded rating: ${rating?.score}');
      state = state.copyWith(rating: rating, isLoading: false);
    } catch (e) {
      print('❌ RATINGS PROVIDER - Error loading rating: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> upsertRating(double score) async {
    try {
      final rating = await _ratingsService.upsertRating(
        tmdbId: tmdbId,
        mediaType: mediaType,
        score: score,
      );

      state = state.copyWith(rating: rating);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteRating() async {
    if (state.rating == null) return;

    try {
      await _ratingsService.deleteRating(state.rating!.id);
      state = state.copyWith(rating: null);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

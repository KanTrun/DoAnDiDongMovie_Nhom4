import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';

// Popular movies provider
final popularMoviesProvider = FutureProvider.family<MovieResponse, int>((ref, page) async {
  return TmdbService.getPopularMovies(page: page);
});

// Top rated movies provider
final topRatedMoviesProvider = FutureProvider.family<MovieResponse, int>((ref, page) async {
  return TmdbService.getTopRatedMovies(page: page);
});

// Upcoming movies provider
final upcomingMoviesProvider = FutureProvider.family<MovieResponse, int>((ref, page) async {
  return TmdbService.getUpcomingMovies(page: page);
});

// Now playing movies provider
final nowPlayingMoviesProvider = FutureProvider.family<MovieResponse, int>((ref, page) async {
  return TmdbService.getNowPlayingMovies(page: page);
});

// Trending movies provider
final trendingMoviesProvider = FutureProvider.family<MovieResponse, TrendingRequest>((ref, request) async {
  return TmdbService.getTrendingMovies(
    timeWindow: request.timeWindow,
    page: request.page,
  );
});

class TrendingRequest {
  final String timeWindow;
  final int page;

  TrendingRequest({this.timeWindow = 'day', this.page = 1});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrendingRequest &&
          runtimeType == other.runtimeType &&
          timeWindow == other.timeWindow &&
          page == other.page;

  @override
  int get hashCode => timeWindow.hashCode ^ page.hashCode;
}

// Discover movies provider
final discoverMoviesProvider = FutureProvider.family<MovieResponse, DiscoverRequest>((ref, request) async {
  return TmdbService.discoverMovies(
    page: request.page,
    sortBy: request.sortBy,
    withGenres: request.withGenres,
    withoutGenres: request.withoutGenres,
    voteAverageGte: request.voteAverageGte,
    voteAverageLte: request.voteAverageLte,
    releaseDateGte: request.releaseDateGte,
    releaseDateLte: request.releaseDateLte,
    withOriginalLanguage: request.withOriginalLanguage,
  );
});

class DiscoverRequest {
  final int page;
  final String? sortBy;
  final String? withGenres;
  final String? withoutGenres;
  final double? voteAverageGte;
  final double? voteAverageLte;
  final String? releaseDateGte;
  final String? releaseDateLte;
  final String? withOriginalLanguage;

  DiscoverRequest({
    this.page = 1,
    this.sortBy,
    this.withGenres,
    this.withoutGenres,
    this.voteAverageGte,
    this.voteAverageLte,
    this.releaseDateGte,
    this.releaseDateLte,
    this.withOriginalLanguage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoverRequest &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          sortBy == other.sortBy &&
          withGenres == other.withGenres &&
          withoutGenres == other.withoutGenres &&
          voteAverageGte == other.voteAverageGte &&
          voteAverageLte == other.voteAverageLte &&
          releaseDateGte == other.releaseDateGte &&
          releaseDateLte == other.releaseDateLte &&
          withOriginalLanguage == other.withOriginalLanguage;

  @override
  int get hashCode =>
      page.hashCode ^
      sortBy.hashCode ^
      withGenres.hashCode ^
      withoutGenres.hashCode ^
      voteAverageGte.hashCode ^
      voteAverageLte.hashCode ^
      releaseDateGte.hashCode ^
      releaseDateLte.hashCode ^
      withOriginalLanguage.hashCode;
}

// Search movies provider
final searchMoviesProvider = FutureProvider.family<MovieResponse, SearchRequest>((ref, request) async {
  return TmdbService.searchMovies(request.query, page: request.page);
});

class SearchRequest {
  final String query;
  final int page;

  SearchRequest({required this.query, this.page = 1});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchRequest &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          page == other.page;

  @override
  int get hashCode => query.hashCode ^ page.hashCode;
}

// Movie details provider
final movieDetailsProvider = FutureProvider.family<MovieDetail, int>((ref, movieId) async {
  return TmdbService.getMovieDetails(movieId);
});

// Movie videos provider
final movieVideosProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, movieId) async {
  return TmdbService.getMovieVideos(movieId);
});

// Movie credits provider
final movieCreditsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, movieId) async {
  return TmdbService.getMovieCredits(movieId);
});

// Similar movies provider
final similarMoviesProvider = FutureProvider.family<MovieResponse, MoviePageRequest>((ref, request) async {
  return TmdbService.getSimilarMovies(request.movieId, page: request.page);
});

// Recommended movies provider
final recommendedMoviesProvider = FutureProvider.family<MovieResponse, MoviePageRequest>((ref, request) async {
  return TmdbService.getRecommendedMovies(request.movieId, page: request.page);
});

class MoviePageRequest {
  final int movieId;
  final int page;

  MoviePageRequest({required this.movieId, this.page = 1});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoviePageRequest &&
          runtimeType == other.runtimeType &&
          movieId == other.movieId &&
          page == other.page;

  @override
  int get hashCode => movieId.hashCode ^ page.hashCode;
}

// Genres provider
final genresProvider = FutureProvider<List<Genre>>((ref) async {
  return TmdbService.getGenres();
});

// Person details provider
final personDetailsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, personId) async {
  return TmdbService.getPersonDetails(personId);
});

// Search people provider
final searchPeopleProvider = FutureProvider.family<Map<String, dynamic>, SearchRequest>((ref, request) async {
  return TmdbService.searchPeople(request.query, page: request.page);
});

// Configuration provider
final tmdbConfigurationProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return TmdbService.getConfiguration();
});

// Search state provider for managing search history and state
final searchStateProvider = StateNotifierProvider<SearchStateNotifier, SearchState>((ref) {
  return SearchStateNotifier();
});

class SearchState {
  final String query;
  final List<String> recentSearches;
  final bool isSearching;

  const SearchState({
    this.query = '',
    this.recentSearches = const [],
    this.isSearching = false,
  });

  SearchState copyWith({
    String? query,
    List<String>? recentSearches,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      recentSearches: recentSearches ?? this.recentSearches,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

class SearchStateNotifier extends StateNotifier<SearchState> {
  SearchStateNotifier() : super(const SearchState());

  void updateQuery(String query) {
    state = state.copyWith(query: query);
  }

  void addToRecentSearches(String query) {
    if (query.trim().isEmpty) return;
    
    final updatedSearches = [
      query,
      ...state.recentSearches.where((s) => s != query).take(9)
    ];
    state = state.copyWith(recentSearches: updatedSearches);
  }

  void removeFromRecentSearches(String query) {
    state = state.copyWith(
      recentSearches: state.recentSearches.where((s) => s != query).toList(),
    );
  }

  void clearRecentSearches() {
    state = state.copyWith(recentSearches: []);
  }

  void setSearching(bool isSearching) {
    state = state.copyWith(isSearching: isSearching);
  }
}

// =========================
//     TV SHOW PROVIDERS
// =========================

// TV Show detail provider
final tvShowDetailProvider = FutureProvider.family<TvShowDetail, int>((ref, tvShowId) async {
  return TmdbService.getTvShowDetails(tvShowId);
});

// TV Show videos provider
final tvShowVideosProvider = FutureProvider.family<List<Video>, int>((ref, tvShowId) async {
  return TmdbService.getTvShowVideos(tvShowId);
});

// TV Show credits provider
final tvShowCreditsProvider = FutureProvider.family<Credits, int>((ref, tvShowId) async {
  return TmdbService.getTvShowCredits(tvShowId);
});

// Similar TV shows provider
final similarTvShowsProvider = FutureProvider.family<List<TvShow>, int>((ref, tvShowId) async {
  return TmdbService.getSimilarTvShows(tvShowId);
});
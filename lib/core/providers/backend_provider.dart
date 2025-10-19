import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/backend_models.dart';
import '../services/backend_service.dart';
import 'auth_provider.dart';

// Favorites provider
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<List<Favorite>>>((ref) {
  final token = ref.watch(authTokenProvider);
  return FavoritesNotifier(token);
});

class FavoritesNotifier extends StateNotifier<AsyncValue<List<Favorite>>> {
  final String? token;
  DateTime? _lastRequestTime;

  FavoritesNotifier(this.token) : super(const AsyncValue.loading()) {
    if (token != null) {
      loadFavorites();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  // Force reload when needed
  void forceReload() {
    if (token != null) {
      loadFavorites();
    }
  }

  bool _canMakeRequest() {
    final now = DateTime.now();
    if (_lastRequestTime == null || now.difference(_lastRequestTime!).inMilliseconds > 500) {
      _lastRequestTime = now;
      return true;
    }
    return false;
  }

  Future<void> loadFavorites() async {
    if (token == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final favorites = await BackendService.getFavorites(token!);
      state = AsyncValue.data(favorites);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addFavorite(int tmdbId, {String mediaType = 'movie'}) async {
    if (!_canMakeRequest()) {
      return;
    }
    
    if (token == null) {
      return;
    }

    try {
      final request = AddFavoriteRequest(tmdbId: tmdbId, mediaType: mediaType);
      final favorite = await BackendService.addFavorite(token!, request);
      
      state.whenData((favorites) {
        state = AsyncValue.data([...favorites, favorite]);
      });
    } catch (e, stack) {
      // Handle 409 (Already exists) error gracefully
      if (e.toString().contains('409') || e.toString().contains('Already in favorites')) {
        // Add delay to avoid race condition, then refresh
        await Future.delayed(const Duration(milliseconds: 100));
        await loadFavorites(); // Refresh the list to sync with backend
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> removeFavorite(int tmdbId, {String mediaType = 'movie'}) async {
    if (token == null) {
      return;
    }

    try {
      await BackendService.removeFavorite(token!, tmdbId, mediaType: mediaType);
      
      state.whenData((favorites) {
        final newFavorites = favorites.where((f) => f.tmdbId != tmdbId).toList();
        state = AsyncValue.data(newFavorites);
      });
    } catch (e, stack) {
      // Handle 404 (Not found) error gracefully
      if (e.toString().contains('404') || e.toString().contains('Not found')) {
        // Add delay to avoid race condition, then refresh
        await Future.delayed(const Duration(milliseconds: 100));
        await loadFavorites(); // Refresh the list to sync with backend
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<bool> isFavorite(int tmdbId, {String mediaType = 'movie'}) async {
    if (token == null) return false;
    
    try {
      // Check if item exists in local state first
      final isInLocalState = state.whenOrNull(
        data: (favorites) => favorites.any((f) => f.tmdbId == tmdbId && (f.mediaType ?? 'movie') == mediaType),
      ) ?? false;
      
      if (isInLocalState) return true;
      
      return await BackendService.isFavorite(token!, tmdbId);
    } catch (e) {
      return false;
    }
  }

  bool isMovieInFavorites(int tmdbId, {String mediaType = 'movie'}) {
    return state.whenOrNull(
      data: (favorites) => favorites.any((f) => f.tmdbId == tmdbId && (f.mediaType ?? 'movie') == mediaType),
    ) ?? false;
  }
}

// Watchlist provider
final watchlistProvider = StateNotifierProvider<WatchlistNotifier, AsyncValue<List<Watchlist>>>((ref) {
  final token = ref.watch(authTokenProvider);
  return WatchlistNotifier(token);
});

class WatchlistNotifier extends StateNotifier<AsyncValue<List<Watchlist>>> {
  final String? token;
  DateTime? _lastRequestTime;

  WatchlistNotifier(this.token) : super(const AsyncValue.loading()) {
    if (token != null) {
      loadWatchlist();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  // Force reload when needed
  void forceReload() {
    if (token != null) {
      loadWatchlist();
    }
  }

  bool _canMakeRequest() {
    final now = DateTime.now();
    if (_lastRequestTime == null || now.difference(_lastRequestTime!).inMilliseconds > 500) {
      _lastRequestTime = now;
      return true;
    }
    return false;
  }

  Future<void> loadWatchlist() async {
    if (token == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final watchlist = await BackendService.getWatchlist(token!);
      state = AsyncValue.data(watchlist);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addToWatchlist(int tmdbId, {String mediaType = 'movie', String? note}) async {
    if (!_canMakeRequest()) {
      return;
    }
    
    if (token == null) {
      return;
    }

    try {
      final request = AddWatchlistRequest(tmdbId: tmdbId, mediaType: mediaType, note: note);
      final watchlistItem = await BackendService.addToWatchlist(token!, request);
      
      state.whenData((watchlist) {
        state = AsyncValue.data([...watchlist, watchlistItem]);
      });
    } catch (e, stack) {
      // Handle 409 (Already exists) error gracefully
      if (e.toString().contains('409') || e.toString().contains('Already in watchlist')) {
        // Add delay to avoid race condition, then refresh
        await Future.delayed(const Duration(milliseconds: 100));
        await loadWatchlist(); // Refresh the list to sync with backend
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> removeFromWatchlist(int tmdbId, {String mediaType = 'movie'}) async {
    if (token == null) {
      return;
    }

    try {
      await BackendService.removeFromWatchlist(token!, tmdbId, mediaType: mediaType);
      
      state.whenData((watchlist) {
        final newWatchlist = watchlist.where((w) => w.tmdbId != tmdbId).toList();
        state = AsyncValue.data(newWatchlist);
      });
    } catch (e, stack) {
      // Handle 404 (Not found) error gracefully
      if (e.toString().contains('404') || e.toString().contains('Not found')) {
        // Add delay to avoid race condition, then refresh
        await Future.delayed(const Duration(milliseconds: 100));
        await loadWatchlist(); // Refresh the list to sync with backend
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<bool> isInWatchlist(int tmdbId, {String mediaType = 'movie'}) async {
    if (token == null) return false;
    
    try {
      // Check if item exists in local state first
      final isInLocalState = state.whenOrNull(
        data: (watchlist) => watchlist.any((w) => w.tmdbId == tmdbId && (w.mediaType ?? 'movie') == mediaType),
      ) ?? false;
      
      if (isInLocalState) return true;
      
      return await BackendService.isInWatchlist(token!, tmdbId);
    } catch (e) {
      return false;
    }
  }

  bool isMovieInWatchlist(int tmdbId, {String mediaType = 'movie'}) {
    return state.whenOrNull(
      data: (watchlist) => watchlist.any((w) => w.tmdbId == tmdbId && (w.mediaType ?? 'movie') == mediaType),
    ) ?? false;
  }
}

// Notes provider
final notesProvider = StateNotifierProvider<NotesNotifier, AsyncValue<List<Note>>>((ref) {
  final token = ref.watch(authTokenProvider);
  return NotesNotifier(token);
});

class NotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final String? token;

  NotesNotifier(this.token) : super(const AsyncValue.loading()) {
    if (token != null) {
      loadNotes();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadNotes() async {
    if (token == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final notes = await BackendService.getNotes(token!);
      state = AsyncValue.data(notes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadNotesForMovie(int movieId) async {
    if (token == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final notes = await BackendService.getNotesForMovie(token!, movieId);
      state = AsyncValue.data(notes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addNote(int movieId, String content) async {
    if (token == null) return;

    try {
      final request = AddNoteRequest(movieId: movieId, content: content);
      final note = await BackendService.addNote(token!, request);
      
      state.whenData((notes) {
        state = AsyncValue.data([...notes, note]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateNote(String noteId, String content) async {
    if (token == null) return;

    try {
      final updatedNote = await BackendService.updateNote(token!, noteId, content);
      
      state.whenData((notes) {
        final updatedNotes = notes.map((note) {
          return note.noteId == noteId ? updatedNote : note;
        }).toList();
        state = AsyncValue.data(updatedNotes);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteNote(String noteId) async {
    if (token == null) return;

    try {
      await BackendService.deleteNote(token!, noteId);
      
      state.whenData((notes) {
        state = AsyncValue.data(
          notes.where((note) => note.noteId != noteId).toList(),
        );
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// History provider
final historyProvider = StateNotifierProvider<HistoryNotifier, AsyncValue<List<History>>>((ref) {
  final token = ref.watch(authTokenProvider);
  return HistoryNotifier(token);
});

class HistoryNotifier extends StateNotifier<AsyncValue<List<History>>> {
  final String? token;

  HistoryNotifier(this.token) : super(const AsyncValue.loading()) {
    if (token != null) {
      loadHistory();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadHistory() async {
    if (token == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final history = await BackendService.getHistory(token!);
      state = AsyncValue.data(history);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addToHistory(int movieId) async {
    if (token == null) return;

    try {
      final request = AddHistoryRequest(movieId: movieId);
      final historyItem = await BackendService.addToHistory(token!, request);
      
      state.whenData((history) {
        // Remove existing entry if exists and add new one at the beginning
        final filteredHistory = history.where((h) => h.tmdbId != movieId).toList();
        state = AsyncValue.data([historyItem, ...filteredHistory]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> clearHistory() async {
    if (token == null) return;

    try {
      await BackendService.clearHistory(token!);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Ratings provider
final ratingsProvider = StateNotifierProvider<RatingsNotifier, AsyncValue<List<Rating>>>((ref) {
  final token = ref.watch(authTokenProvider);
  return RatingsNotifier(token);
});

class RatingsNotifier extends StateNotifier<AsyncValue<List<Rating>>> {
  final String? token;

  RatingsNotifier(this.token) : super(const AsyncValue.loading()) {
    if (token != null) {
      loadRatings();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadRatings() async {
    if (token == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final ratings = await BackendService.getRatings(token!);
      state = AsyncValue.data(ratings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addRating(int movieId, double rating) async {
    if (token == null) return;

    try {
      final request = AddRatingRequest(movieId: movieId, rating: rating);
      final ratingItem = await BackendService.addRating(token!, request);
      
      state.whenData((ratings) {
        // Remove existing rating if exists and add new one
        final filteredRatings = ratings.where((r) => r.movieId != movieId).toList();
        state = AsyncValue.data([...filteredRatings, ratingItem]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateRating(String ratingId, double rating) async {
    if (token == null) return;

    try {
      final updatedRating = await BackendService.updateRating(token!, ratingId, rating);
      
      state.whenData((ratings) {
        final updatedRatings = ratings.map((r) {
          return r.ratingId == ratingId ? updatedRating : r;
        }).toList();
        state = AsyncValue.data(updatedRatings);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteRating(String ratingId) async {
    if (token == null) return;

    try {
      await BackendService.deleteRating(token!, ratingId);
      
      state.whenData((ratings) {
        state = AsyncValue.data(
          ratings.where((r) => r.ratingId != ratingId).toList(),
        );
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<Rating?> getRatingForMovie(int movieId) async {
    if (token == null) return null;
    
    try {
      return await BackendService.getRatingForMovie(token!, movieId);
    } catch (e) {
      return null;
    }
  }

  double? getMovieRating(int movieId) {
    return state.whenOrNull(
      data: (ratings) => ratings
          .where((r) => r.movieId == movieId)
          .map((r) => r.rating)
          .firstOrNull,
    );
  }
}
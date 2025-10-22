import 'package:dio/dio.dart';
import '../models/backend_models.dart';
import '../network/api_client.dart';

class BackendService {
  // Favorites
  static Future<List<Favorite>> getFavorites(String token) async {
    try {
      final response = await ApiClient.backend(token: token).get('/api/favorites');
      
      // Handle both List and object responses
      dynamic data = response.data;
      if (data is Map && data['items'] != null) {
        data = data['items']; // Backend returns {total: x, items: [...]}
      } else if (data is Map && data['favorites'] != null) {
        data = data['favorites'];
      } else if (data is Map && data['data'] != null) {
        data = data['data'];
      }
      
      if (data is! List) {
        return []; // Return empty list if data is not a list
      }
      
      final favorites = data
          .map<Favorite>((json) => Favorite.fromJson(json))
          .toList();
          
      return favorites;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      // Handle any other errors and return empty list
      return [];
    }
  }

  static Future<Favorite> addFavorite(String token, AddFavoriteRequest request) async {
    try {
      await ApiClient.backend(token: token).post(
        '/api/favorites',
        data: request.toJson(),
      );
      
      // Backend returns { message: "Added to favorites" }
      // Create a temporary Favorite object since we don't get the full object back
      return Favorite(
        favoriteId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '', // Will be updated by provider
        tmdbId: request.tmdbId,
        mediaType: request.mediaType,
        addedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> removeFavorite(String token, int tmdbId, {String mediaType = 'movie'}) async {
    try {
      await ApiClient.backend(token: token).delete('/api/favorites/$tmdbId?mediaType=$mediaType');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<bool> isFavorite(String token, int movieId) async {
    try {
      final response = await ApiClient.backend(token: token).get('/api/favorites/$movieId');
      return response.data['isFavorite'] ?? false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return false;
      throw _handleError(e);
    }
  }

  // Watchlist
  static Future<List<Watchlist>> getWatchlist(String token) async {
    try {
      final response = await ApiClient.backend(token: token).get('/api/watchlist');
      
      // Handle both List and object responses
      dynamic data = response.data;
      if (data is Map && data['items'] != null) {
        data = data['items']; // Backend returns {total: x, items: [...]}
      } else if (data is Map && data['watchlist'] != null) {
        data = data['watchlist'];
      } else if (data is Map && data['data'] != null) {
        data = data['data'];
      }
      
      if (data is! List) {
        return []; // Return empty list if data is not a list
      }
      
      final watchlist = data
          .map<Watchlist>((json) => Watchlist.fromJson(json))
          .toList();
          
      return watchlist;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      // Handle any other errors and return empty list
      return [];
    }
  }

  static Future<Watchlist> addToWatchlist(String token, AddWatchlistRequest request) async {
    try {
      await ApiClient.backend(token: token).post(
        '/api/watchlist',
        data: request.toJson(),
      );
      
      // Backend returns { message: "Added to watchlist" }
      // Create a temporary Watchlist object since we don't get the full object back
      return Watchlist(
        watchlistId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '', // Will be updated by provider
        tmdbId: request.tmdbId,
        mediaType: request.mediaType,
        note: request.note,
        addedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> removeFromWatchlist(String token, int tmdbId, {String mediaType = 'movie'}) async {
    try {
      await ApiClient.backend(token: token).delete('/api/watchlist/$tmdbId?mediaType=$mediaType');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<bool> isInWatchlist(String token, int movieId) async {
    try {
      final response = await ApiClient.backend(token: token).get('/api/watchlist/$movieId');
      return response.data['isInWatchlist'] ?? false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return false;
      throw _handleError(e);
    }
  }

  // Notes
  static Future<List<Note>> getNotes(String token) async {
    try {
      final response = await ApiClient.backend(token: token).get('/api/notes');
      
      // Handle both List and object responses
      dynamic data = response.data;
      if (data is Map && data['notes'] != null) {
        data = data['notes'];
      } else if (data is Map && data['data'] != null) {
        data = data['data'];
      }
      
      if (data is! List) {
        return []; // Return empty list if data is not a list
      }
      
      return data
          .map<Note>((json) => Note.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      // Handle any other errors and return empty list
      return [];
    }
  }

  static Future<List<Note>> getNotesForMovie(String token, int movieId) async {
    try {
      final response = await ApiClient.backend(token: token).get('/notes/movie/$movieId');
      
      // Handle both List and object responses
      dynamic data = response.data;
      if (data is Map && data['notes'] != null) {
        data = data['notes'];
      } else if (data is Map && data['data'] != null) {
        data = data['data'];
      }
      
      if (data is! List) {
        return []; // Return empty list if data is not a list
      }
      
      return data
          .map<Note>((json) => Note.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Note> addNote(String token, AddNoteRequest request) async {
    try {
      final response = await ApiClient.backend(token: token).post(
        '/api/notes',
        data: request.toJson(),
      );
      return Note.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Note> updateNote(String token, String noteId, String content) async {
    try {
      final response = await ApiClient.backend(token: token).put(
        '/notes/$noteId',
        data: {'content': content},
      );
      return Note.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> deleteNote(String token, String noteId) async {
    try {
      await ApiClient.backend(token: token).delete('/notes/$noteId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // History
  static Future<List<History>> getHistory(String token) async {
    try {
      final response = await ApiClient.backend(token: token).get('/api/history');
      return (response.data as List)
          .map((json) => History.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<History> addToHistory(String token, AddHistoryRequest request) async {
    try {
      final response = await ApiClient.backend(token: token).post(
        '/api/history',
        data: request.toJson(),
      );
      return History.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> clearHistory(String token) async {
    try {
      await ApiClient.backend(token: token).delete('/api/history');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Ratings
  static Future<List<Rating>> getRatings(String token) async {
    try {
      final response = await ApiClient.backend(token: token).get('/api/ratings');
      return (response.data as List)
          .map((json) => Rating.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Rating> addRating(String token, AddRatingRequest request) async {
    try {
      final response = await ApiClient.backend(token: token).post(
        '/api/ratings',
        data: request.toJson(),
      );
      return Rating.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Rating> updateRating(String token, String ratingId, double rating) async {
    try {
      final response = await ApiClient.backend(token: token).put(
        '/ratings/$ratingId',
        data: {'rating': rating},
      );
      return Rating.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> deleteRating(String token, String ratingId) async {
    try {
      await ApiClient.backend(token: token).delete('/ratings/$ratingId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<Rating?> getRatingForMovie(String token, int movieId) async {
    try {
      final response = await ApiClient.backend(token: token).get('/ratings/movie/$movieId');
      return Rating.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleError(e);
    }
  }

  static String _handleError(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        return data['message'].toString();
      } else if (data is String) {
        return data;
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Kết nối bị timeout. Vui lòng thử lại.';
      case DioExceptionType.connectionError:
        return 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
      case DioExceptionType.badResponse:
        switch (e.response?.statusCode) {
          case 400:
            return 'Yêu cầu không hợp lệ.';
          case 401:
            return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
          case 403:
            return 'Bạn không có quyền truy cập.';
          case 404:
            return 'Không tìm thấy tài nguyên.';
          case 500:
            return 'Lỗi server. Vui lòng thử lại sau.';
          default:
            return 'Đã xảy ra lỗi. Vui lòng thử lại.';
        }
      default:
        return 'Đã xảy ra lỗi không xác định.';
    }
  }
}
import 'package:dio/dio.dart';
import '../network/api_client.dart';

class HistoryService {
  // Log an engagement event
  static Future<int> logEvent({
    required String token,
    required int tmdbId,
    required String mediaType,
    required String action,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final response = await ApiClient.backend(token: token).post(
        '/api/history',
        data: {
          'tmdbId': tmdbId,
          'mediaType': mediaType,
          'action': action,
          'extra': extra,
        },
      );

      if (response.statusCode == 201) {
        return response.data['id'] ?? 0;
      } else {
        throw Exception('Failed to log event: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error logging event: $e');
    }
  }

  // Get user's history
  static Future<Map<String, dynamic>> getHistory({
    required String token,
    int page = 1,
    int pageSize = 20,
    String? action,
    String? mediaType,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };

      if (action != null) queryParams['action'] = action;
      if (mediaType != null) queryParams['mediaType'] = mediaType;

      final response = await ApiClient.backend(token: token).get(
        '/api/history',
        queryParameters: queryParams,
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching history: $e');
    }
  }

  // Clear all user's history
  static Future<void> clearHistory({required String token}) async {
    try {
      await ApiClient.backend(token: token).delete('/api/history');
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error clearing history: $e');
    }
  }

  // Delete specific history item
  static Future<void> deleteHistoryItem({
    required String token,
    required int historyId,
  }) async {
    try {
      await ApiClient.backend(token: token).delete('/api/history/$historyId');
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error deleting history item: $e');
    }
  }

  // Analytics endpoints
  static Future<List<Map<String, dynamic>>> getTopTrailers({
    required String token,
    int days = 7,
    int limit = 10,
  }) async {
    try {
      final response = await ApiClient.backend(token: token).get(
        '/api/history/analytics/top-trailers',
        queryParameters: {
          'days': days,
          'limit': limit,
        },
      );

      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching top trailers: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getProviderStats({
    required String token,
    int days = 7,
  }) async {
    try {
      final response = await ApiClient.backend(token: token).get(
        '/api/history/analytics/provider-stats',
        queryParameters: {'days': days},
      );

      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching provider stats: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getPeakHours({
    required String token,
    int days = 7,
  }) async {
    try {
      final response = await ApiClient.backend(token: token).get(
        '/api/history/analytics/peak-hours',
        queryParameters: {'days': days},
      );

      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Error fetching peak hours: $e');
    }
  }
}

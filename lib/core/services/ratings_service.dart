import 'package:dio/dio.dart';
import '../models/rating.dart';
import '../network/api_client.dart';

class RatingsService {
  final String? _token;

  RatingsService(this._token);

  Future<PagedRatingsResponse> getRatings({int page = 1, int pageSize = 20}) async {
    try {
      final response = await ApiClient.backend(token: _token).get(
        '/api/ratings',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return PagedRatingsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Rating?> getRatingByMovie(int tmdbId, String mediaType) async {
    try {
      final response = await ApiClient.backend(token: _token).get(
        '/api/ratings/movie/$tmdbId',
        queryParameters: {
          'mediaType': mediaType,
        },
      );
      
      return Rating.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<Rating> upsertRating({
    required int tmdbId,
    required String mediaType,
    required double score,
  }) async {
    try {
      final response = await ApiClient.backend(token: _token).post(
        '/api/ratings',
        data: {
          'tmdbId': tmdbId,
          'mediaType': mediaType,
          'score': score,
        },
      );
      return Rating.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteRating(int id) async {
    try {
      await ApiClient.backend(token: _token).delete('/api/ratings/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    // Debug log removed
    // Debug logs removed
    
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data.containsKey('message')) {
        return data['message'];
      }
      if (data is String) {
        return data;
      }
    }
    return 'An error occurred while processing your request';
  }
}

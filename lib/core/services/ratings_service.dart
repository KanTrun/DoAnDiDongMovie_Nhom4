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
      print('🔍 RATINGS SERVICE - Getting rating for movie: $tmdbId, mediaType: $mediaType');
      print('🔑 RATINGS SERVICE - Token: ${_token != null ? "Present" : "NULL"}');
      
      final response = await ApiClient.backend(token: _token).get(
        '/api/ratings/movie/$tmdbId',
        queryParameters: {
          'mediaType': mediaType,
        },
      );
      
      print('✅ RATINGS SERVICE - Response received: ${response.statusCode}');
      print('📄 RATINGS SERVICE - Response data: ${response.data}');
      
      return Rating.fromJson(response.data);
    } on DioException catch (e) {
      print('❌ RATINGS SERVICE - DioException caught: ${e.response?.statusCode}');
      if (e.response?.statusCode == 404) {
        print('📭 RATINGS SERVICE - No rating found (404)');
        return null;
      }
      throw _handleError(e);
    } catch (e) {
      print('❌ RATINGS SERVICE - General exception: $e');
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
    print('❌ RATINGS SERVICE ERROR:');
    print('   Status: ${e.response?.statusCode}');
    print('   Message: ${e.message}');
    print('   Data: ${e.response?.data}');
    print('   Headers: ${e.response?.headers}');
    
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

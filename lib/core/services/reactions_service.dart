import 'package:dio/dio.dart';
import '../models/reaction.dart';
import '../network/api_client.dart';

class ReactionsService {
  // Like post
  static Future<void> likePost(String token, int postId) async {
    try {
      await ApiClient.backend(token: token).post('/api/reactions/posts/$postId/like');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Unlike post
  static Future<void> unlikePost(String token, int postId) async {
    try {
      await ApiClient.backend(token: token).delete('/api/reactions/posts/$postId/like');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Like comment
  static Future<void> likeComment(String token, int commentId) async {
    try {
      await ApiClient.backend(token: token).post('/api/reactions/comments/$commentId/like');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Unlike comment
  static Future<void> unlikeComment(String token, int commentId) async {
    try {
      await ApiClient.backend(token: token).delete('/api/reactions/comments/$commentId/like');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get post reactions
  static Future<ReactionSummary> getPostReactions(
    String token,
    int postId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await ApiClient.backend(token: token).get(
        '/api/reactions/posts/$postId/likes',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return ReactionSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get comment reactions
  static Future<CommentReactionSummary> getCommentReactions(
    String token,
    int commentId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await ApiClient.backend(token: token).get(
        '/api/reactions/comments/$commentId/likes',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return CommentReactionSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static String _handleError(DioException e) {
    if (e.response?.data != null && e.response?.data['message'] != null) {
      return e.response!.data['message'];
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

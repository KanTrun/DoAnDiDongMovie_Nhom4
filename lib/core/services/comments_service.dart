import 'package:dio/dio.dart';
import '../models/comment.dart';
import '../network/api_client.dart';

class CommentsService {
  // Get post comments
  static Future<PagedCommentsResponse> getPostComments(
    String token,
    CommentFilter filter,
  ) async {
    try {
      final response = await ApiClient.backend(token: token).get(
        '/api/comments/posts/${filter.postId}',
        queryParameters: {
          'page': filter.page,
          'pageSize': filter.pageSize,
          'includeReplies': filter.includeReplies,
        },
      );
      
      // Check if response is successful
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return PagedCommentsResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to get comments: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      // Handle specific error cases
      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        if (errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw _handleError(e);
    }
  }

  // Get comment detail
  static Future<Comment> getComment(String token, int commentId) async {
    try {
      final response = await ApiClient.backend(token: token).get('/api/comments/$commentId');
      return Comment.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Create comment
  static Future<Comment> createComment(
    String token,
    int postId,
    CreateCommentRequest request,
  ) async {
    try {
      final response = await ApiClient.backend(token: token).post(
        '/api/comments/posts/$postId',
        data: request.toJson(),
      );
      
      // Check if response is successful
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return Comment.fromJson(response.data);
      } else {
        throw Exception('Failed to create comment: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      // Handle specific error cases
      if (e.response?.data is Map<String, dynamic>) {
        final errorData = e.response!.data as Map<String, dynamic>;
        if (errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
      }
      throw _handleError(e);
    }
  }

  // Update comment
  static Future<Comment> updateComment(
    String token,
    int commentId,
    UpdateCommentRequest request,
  ) async {
    try {
      final response = await ApiClient.backend(token: token).put(
        '/api/comments/$commentId',
        data: request.toJson(),
      );
      return Comment.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Delete comment
  static Future<void> deleteComment(String token, int commentId) async {
    try {
      await ApiClient.backend(token: token).delete('/api/comments/$commentId');
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
            return 'Không tìm thấy bình luận.';
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

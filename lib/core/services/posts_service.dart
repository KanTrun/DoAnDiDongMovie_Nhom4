import 'package:dio/dio.dart';
import '../models/post.dart';
import '../network/api_client.dart';

class PostsService {
  // Get community feed
  static Future<PagedPostsResponse> getFeed(String token, PostFeedFilter filter) async {
    try {
      final response = await ApiClient.backend(token: token).get(
        '/api/posts/feed',
        queryParameters: filter.toJson(),
      );
      if (response.data is Map<String, dynamic> && (response.data as Map<String, dynamic>).containsKey('posts')) {
        return PagedPostsResponse.fromJson(response.data);
      }
      // If backend returned an error body with { message: ... }
      if (response.data is Map<String, dynamic> && (response.data as Map<String, dynamic>).containsKey('message')) {
        throw Exception((response.data as Map<String, dynamic>)['message']?.toString() ?? 'Đã xảy ra lỗi.');
      }
      throw Exception('Dữ liệu phản hồi không hợp lệ.');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get posts by movie
  static Future<PagedPostsResponse> getPostsByMovie(
    String token,
    int tmdbId, {
    String? mediaType,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await ApiClient.backend(token: token).get(
        '/api/posts/movie/$tmdbId',
        queryParameters: {
          if (mediaType != null) 'mediaType': mediaType,
          'page': page,
          'pageSize': pageSize,
        },
      );
      if (response.data is Map<String, dynamic> && (response.data as Map<String, dynamic>).containsKey('posts')) {
        return PagedPostsResponse.fromJson(response.data);
      }
      if (response.data is Map<String, dynamic> && (response.data as Map<String, dynamic>).containsKey('message')) {
        throw Exception((response.data as Map<String, dynamic>)['message']?.toString() ?? 'Đã xảy ra lỗi.');
      }
      throw Exception('Dữ liệu phản hồi không hợp lệ.');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get post detail
  static Future<Post> getPost(String token, int postId) async {
    try {
      final response = await ApiClient.backend(token: token).get('/api/posts/$postId');
      return Post.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get user posts
  static Future<PagedPostsResponse> getUserPosts(
    String token,
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await ApiClient.backend(token: token).get(
        '/api/posts/users/$userId',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      if (response.data is Map<String, dynamic> && (response.data as Map<String, dynamic>).containsKey('posts')) {
        return PagedPostsResponse.fromJson(response.data);
      }
      if (response.data is Map<String, dynamic> && (response.data as Map<String, dynamic>).containsKey('message')) {
        throw Exception((response.data as Map<String, dynamic>)['message']?.toString() ?? 'Đã xảy ra lỗi.');
      }
      throw Exception('Dữ liệu phản hồi không hợp lệ.');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Create post
  static Future<Post> createPost(String token, CreatePostRequest request) async {
    try {
      final response = await ApiClient.backend(token: token).post(
        '/api/posts',
        data: request.toJson(),
      );
      return Post.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update post
  static Future<Post> updatePost(String token, int postId, UpdatePostRequest request) async {
    try {
      final response = await ApiClient.backend(token: token).put(
        '/api/posts/$postId',
        data: request.toJson(),
      );
      return Post.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Delete post
  static Future<void> deletePost(String token, int postId) async {
    try {
      await ApiClient.backend(token: token).delete('/api/posts/$postId');
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
            return 'Không tìm thấy bài viết.';
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

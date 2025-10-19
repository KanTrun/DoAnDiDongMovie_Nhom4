import 'package:dio/dio.dart';
import '../models/follow.dart';
import '../network/api_client.dart';

class FollowsService {
  // Follow user
  static Future<void> followUser(String token, String userId) async {
    try {
      await ApiClient.backend(token: token).post('/api/follows/users/$userId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Unfollow user
  static Future<void> unfollowUser(String token, String userId) async {
    try {
      await ApiClient.backend(token: token).delete('/api/follows/users/$userId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get user followers
  static Future<PagedFollowsResponse> getUserFollowers(
    String token,
    FollowFilter filter,
  ) async {
    try {
      final response = await ApiClient.backend(token: token).get(
        '/api/follows/users/${filter.userId}/followers',
        queryParameters: {
          'page': filter.page,
          'pageSize': filter.pageSize,
        },
      );
      return PagedFollowsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get user following
  static Future<PagedFollowsResponse> getUserFollowing(
    String token,
    FollowFilter filter,
  ) async {
    try {
      final response = await ApiClient.backend(token: token).get(
        '/api/follows/users/${filter.userId}/following',
        queryParameters: {
          'page': filter.page,
          'pageSize': filter.pageSize,
        },
      );
      return PagedFollowsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get follow status
  static Future<FollowStatus> getFollowStatus(String token, String userId) async {
    try {
      final response = await ApiClient.backend(token: token).get('/api/follows/users/$userId/status');
      return FollowStatus.fromJson(response.data);
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
            return 'Không tìm thấy người dùng.';
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

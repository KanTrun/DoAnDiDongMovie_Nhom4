import 'package:dio/dio.dart';
import '../models/notification.dart';
import '../network/api_client.dart';

class NotificationsService {
  // Get notifications
  static Future<PagedNotificationsResponse> getNotifications(
    String token,
    NotificationFilter filter,
  ) async {
    try {
      final response = await ApiClient.backend(token: token).get(
        '/api/notifications',
        queryParameters: filter.toJson(),
      );
      return PagedNotificationsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get notification detail
  static Future<Notification> getNotification(String token, int notificationId) async {
    try {
      final response = await ApiClient.backend(token: token).get('/api/notifications/$notificationId');
      return Notification.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String token, int notificationId) async {
    try {
      await ApiClient.backend(token: token).put('/api/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead(
    String token, {
    List<int>? notificationIds,
  }) async {
    try {
      await ApiClient.backend(token: token).put(
        '/api/notifications/read-all',
        data: MarkAllNotificationsReadRequest(notificationIds: notificationIds).toJson(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get unread count
  static Future<int> getUnreadCount(String token) async {
    try {
      final response = await ApiClient.backend(token: token).get('/api/notifications/unread-count');
      return response.data['unreadCount'];
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
            return 'Không tìm thấy thông báo.';
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

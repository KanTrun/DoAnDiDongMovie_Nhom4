import 'package:dio/dio.dart';
import '../models/user.dart';
import '../network/api_client.dart';

class AuthService {
  static const String _baseUrl = '/auth';

  static Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await ApiClient.backend().post(
        '$_baseUrl/login',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<void> register(RegisterRequest request) async {
    try {
      await ApiClient.backend().post(
        '$_baseUrl/register',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<User> getProfile(String token) async {
    try {
      final response = await ApiClient.backend(token: token).get(
        '$_baseUrl/profile',
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  static Future<User> updateProfile(String token, Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.backend(token: token).put(
        '$_baseUrl/profile',
        data: data,
      );
      return User.fromJson(response.data);
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
            return 'Thông tin đăng nhập không chính xác.';
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
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/backend_models.dart';
import '../auth/jwt_storage.dart';

class AdminService {
  static Future<List<AdminUser>> getUsers() async {
    try {
      final token = await JwtStorage.getToken();
      if (token == null) throw Exception('Không có token xác thực');

      final dio = Dio();
      dio.options.baseUrl = AppConfig.backendBaseUrl;
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-Type'] = 'application/json';

      final response = await dio.get('/admin/users');
      
      if (response.statusCode == 200) {
        final List<dynamic> usersJson = response.data;
        return usersJson.map((json) => AdminUser.fromJson(json)).toList();
      } else {
        throw Exception('Không thể tải danh sách người dùng: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Lỗi tải danh sách người dùng: $e');
    }
  }

  static Future<AdminStats> getStats() async {
    try {
      final token = await JwtStorage.getToken();
      if (token == null) throw Exception('Không có token xác thực');

      final dio = Dio();
      dio.options.baseUrl = AppConfig.backendBaseUrl;
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-Type'] = 'application/json';

      final response = await dio.get('/admin/stats');
      
      if (response.statusCode == 200) {
        return AdminStats.fromJson(response.data);
      } else {
        throw Exception('Không thể tải thống kê: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Lỗi tải thống kê: $e');
    }
  }

  static Future<void> updateUserRole(String userId, String role) async {
    try {
      final token = await JwtStorage.getToken();
      if (token == null) throw Exception('Không có token xác thực');

      final dio = Dio();
      dio.options.baseUrl = AppConfig.backendBaseUrl;
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-Type'] = 'application/json';

      final response = await dio.put(
        '/admin/users/$userId/role',
        data: {'role': role},
      );
      
      if (response.statusCode != 200) {
        throw Exception('Không thể cập nhật vai trò người dùng: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Lỗi cập nhật vai trò người dùng: $e');
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      final token = await JwtStorage.getToken();
      if (token == null) throw Exception('Không có token xác thực');

      final dio = Dio();
      dio.options.baseUrl = AppConfig.backendBaseUrl;
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-Type'] = 'application/json';

      final response = await dio.delete('/admin/users/$userId');
      
      if (response.statusCode != 200) {
        throw Exception('Không thể xóa người dùng: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Lỗi xóa người dùng: $e');
    }
  }
}

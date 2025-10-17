import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/backend_models.dart';
import '../auth/jwt_storage.dart';

class AdminService {
  static Future<List<AdminUser>> getUsers() async {
    try {
      final token = await JwtStorage.getToken();
      if (token == null) throw Exception('No authentication token');

      final dio = Dio();
      dio.options.baseUrl = AppConfig.backendBaseUrl;
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-Type'] = 'application/json';

      final response = await dio.get('/admin/users');
      
      if (response.statusCode == 200) {
        final List<dynamic> usersJson = response.data;
        return usersJson.map((json) => AdminUser.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch users: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  static Future<AdminStats> getStats() async {
    try {
      final token = await JwtStorage.getToken();
      if (token == null) throw Exception('No authentication token');

      final dio = Dio();
      dio.options.baseUrl = AppConfig.backendBaseUrl;
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-Type'] = 'application/json';

      final response = await dio.get('/admin/stats');
      
      if (response.statusCode == 200) {
        return AdminStats.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch stats: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error fetching stats: $e');
    }
  }

  static Future<void> updateUserRole(String userId, String role) async {
    try {
      final token = await JwtStorage.getToken();
      if (token == null) throw Exception('No authentication token');

      final dio = Dio();
      dio.options.baseUrl = AppConfig.backendBaseUrl;
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-Type'] = 'application/json';

      final response = await dio.put(
        '/admin/users/$userId/role',
        data: {'role': role},
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to update user role: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error updating user role: $e');
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      final token = await JwtStorage.getToken();
      if (token == null) throw Exception('No authentication token');

      final dio = Dio();
      dio.options.baseUrl = AppConfig.backendBaseUrl;
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Content-Type'] = 'application/json';

      final response = await dio.delete('/admin/users/$userId');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete user: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }
}

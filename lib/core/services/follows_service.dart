import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class FollowsService {
  static const String _baseUrl = AppConfig.backendBaseUrl;

  /// Follow a user
  static Future<void> followUser(String token, String userId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/follows/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to follow user');
    }
  }

  /// Unfollow a user
  static Future<void> unfollowUser(String token, String userId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/follows/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return;
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to unfollow user');
    }
  }

  /// Check if current user is following a specific user
  static Future<bool> isFollowing(String token, String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/follows/users/$userId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final result = data['isFollowing'] ?? false;
      return result;
    } else {
      return false;
    }
  }

  /// Get user's followers
  static Future<Map<String, dynamic>> getUserFollowers(
    String token,
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/follows/users/$userId/followers?page=$page&pageSize=$pageSize'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get followers');
    }
  }

  /// Get users that a user is following
  static Future<Map<String, dynamic>> getUserFollowing(
    String token,
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/follows/users/$userId/following?page=$page&pageSize=$pageSize'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get following');
    }
  }

  /// Get current user's follow statistics
  static Future<Map<String, int>> getUserFollowStats(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/follows/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'following': data['following'] ?? 0,
        'followers': data['followers'] ?? 0,
      };
    } else {
      return {'following': 0, 'followers': 0};
    }
  }
}
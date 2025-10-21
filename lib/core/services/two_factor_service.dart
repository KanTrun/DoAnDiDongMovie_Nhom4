import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../auth/jwt_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TwoFactorService {
  static const String _baseUrl = '/api/auth';

  // Enable 2FA - Get QR code and secret key
  static Future<Enable2FAResponse> enable2FA() async {
    try {
      final token = await _getAuthToken();
      print('🔍 DEBUG: Calling enable-2fa with token: ${token?.substring(0, 20)}...');
      final response = await ApiClient.backend(token: token).post('$_baseUrl/enable-2fa');
      print('🔍 DEBUG: Raw response: ${response.data}');
      print('🔍 DEBUG: Response type: ${response.data.runtimeType}');
      
      if (response.data is Map<String, dynamic>) {
        print('🔍 DEBUG: Response is Map');
        return Enable2FAResponse.fromJson(response.data);
      } else {
        print('❌ DEBUG: Response is not Map, it is: ${response.data.runtimeType}');
        throw Exception('Invalid response format: ${response.data.runtimeType}');
      }
    } on DioException catch (e) {
      print('❌ DEBUG: DioException: ${e.response?.data}');
      throw _handleError(e);
    } catch (e) {
      print('❌ DEBUG: General error: $e');
      rethrow;
    }
  }

  // Verify 2FA setup
  static Future<Verify2FAResponse> verify2FA(String totpCode) async {
    try {
      final token = await _getAuthToken();
      final response = await ApiClient.backend(token: token).post(
        '$_baseUrl/verify-2fa',
        data: {'totpCode': totpCode},
      );
      return Verify2FAResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Disable 2FA
  static Future<Disable2FAResponse> disable2FA(String totpCode) async {
    try {
      final token = await _getAuthToken();
      final response = await ApiClient.backend(token: token).post(
        '$_baseUrl/disable-2fa',
        data: {'totpCode': totpCode},
      );
      return Disable2FAResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Login with 2FA
  static Future<LoginWith2FAResponse> loginWith2FA({
    required String email,
    required String password,
    required String totpCode,
  }) async {
    try {
      final response = await ApiClient.backend().post(
        '$_baseUrl/login-with-2fa',
        data: {
          'email': email,
          'password': password,
          'totpCode': totpCode,
        },
      );
      return LoginWith2FAResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get 2FA status
  static Future<TwoFAStatusResponse> get2FAStatus() async {
    try {
      final token = await _getAuthToken();
      final response = await ApiClient.backend(token: token).get('$_baseUrl/2fa-status');
      return TwoFAStatusResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Complete 2FA after biometric login
  static Future<LoginWith2FAResponse> complete2FABiometric(String totpCode) async {
    try {
      final token = await _getAuthToken();
      final response = await ApiClient.backend(token: token).post(
        '$_baseUrl/complete-2fa-biometric',
        data: {'totpCode': totpCode},
      );
      return LoginWith2FAResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Helper methods
  static Future<String?> _getAuthToken() async {
    try {
      // Try to get token from JwtStorage first
      final token = await JwtStorage.getToken();
      if (token != null) {
        print('🔍 DEBUG: Got token from JwtStorage: ${token.substring(0, 20)}...');
        return token;
      }
      
      // Fallback to FlutterSecureStorage
      final storage = const FlutterSecureStorage();
      final secureToken = await storage.read(key: 'auth_token');
      if (secureToken != null) {
        print('🔍 DEBUG: Got token from FlutterSecureStorage: ${secureToken.substring(0, 20)}...');
        return secureToken;
      }
      
      print('❌ DEBUG: No token found in any storage');
      return null;
    } catch (e) {
      print('❌ DEBUG: Error getting token: $e');
      return null;
    }
  }

  static String _handleError(DioException e) {
    if (e.response?.statusCode == 400) {
      return e.response?.data['message'] ?? 'Bad request';
    } else if (e.response?.statusCode == 401) {
      return e.response?.data['message'] ?? 'Unauthorized';
    } else if (e.response?.statusCode == 404) {
      return e.response?.data['message'] ?? 'Not found';
    } else {
      return e.message ?? 'Unknown error occurred';
    }
  }
}

// Response models
class Enable2FAResponse {
  final String secretKey;
  final String qrCodeBase64;
  final String manualEntryKey;

  Enable2FAResponse({
    required this.secretKey,
    required this.qrCodeBase64,
    required this.manualEntryKey,
  });

  factory Enable2FAResponse.fromJson(Map<String, dynamic> json) {
    return Enable2FAResponse(
      secretKey: json['secretKey'] ?? '',
      qrCodeBase64: json['qrCodeBase64'] ?? '',
      manualEntryKey: json['manualEntryKey'] ?? '',
    );
  }
}

class Verify2FAResponse {
  final bool success;
  final String message;
  final List<String> recoveryCodes;

  Verify2FAResponse({
    required this.success,
    required this.message,
    required this.recoveryCodes,
  });

  factory Verify2FAResponse.fromJson(Map<String, dynamic> json) {
    return Verify2FAResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      recoveryCodes: List<String>.from(json['recoveryCodes'] ?? []),
    );
  }
}

class Disable2FAResponse {
  final bool success;
  final String message;

  Disable2FAResponse({
    required this.success,
    required this.message,
  });

  factory Disable2FAResponse.fromJson(Map<String, dynamic> json) {
    return Disable2FAResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class LoginWith2FAResponse {
  final String token;
  final User user;

  LoginWith2FAResponse({
    required this.token,
    required this.user,
  });

  factory LoginWith2FAResponse.fromJson(Map<String, dynamic> json) {
    return LoginWith2FAResponse(
      token: json['token'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
    );
  }
}

class TwoFAStatusResponse {
  final bool twoFactorEnabled;
  final DateTime? twoFactorEnabledAt;

  TwoFAStatusResponse({
    required this.twoFactorEnabled,
    this.twoFactorEnabledAt,
  });

  factory TwoFAStatusResponse.fromJson(Map<String, dynamic> json) {
    print('🔍 DEBUG: TwoFAStatusResponse JSON: $json');
    
    DateTime? enabledAt;
    if (json['twoFactorEnabledAt'] != null) {
      try {
        if (json['twoFactorEnabledAt'] is String) {
          enabledAt = DateTime.parse(json['twoFactorEnabledAt']);
        } else if (json['twoFactorEnabledAt'] is DateTime) {
          enabledAt = json['twoFactorEnabledAt'];
        }
      } catch (e) {
        print('❌ DEBUG: Error parsing twoFactorEnabledAt: $e');
        enabledAt = null;
      }
    }
    
    return TwoFAStatusResponse(
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
      twoFactorEnabledAt: enabledAt,
    );
  }
}

class User {
  final String id;
  final String email;
  final String displayName;
  final String role;
  final bool twoFactorEnabled;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.twoFactorEnabled,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      role: json['role'] ?? '',
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
    );
  }
}

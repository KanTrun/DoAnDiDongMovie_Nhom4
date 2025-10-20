import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../auth/jwt_storage.dart';
import '../services/auth_service.dart';
import 'package:local_auth/local_auth.dart';

// Storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
});

// Auth state
class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => user != null && token != null;
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;

  AuthNotifier(this._storage) : super(const AuthState());

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Try to get token from AuthProvider storage first
      String? token = await _storage.read(key: _tokenKey);
      final userJson = await _storage.read(key: _userKey);
      
      // If not found, try JwtStorage
      token ??= await JwtStorage.getToken();
      
      if (token != null && userJson != null) {
        // Verify token is still valid
        try {
          final user = await AuthService.getProfile(token);
          state = AuthState(user: user, token: token);
          
          // Sync to both storages
          await _storage.write(key: _tokenKey, value: token);
          await _storage.write(key: _userKey, value: user.toJson().toString());
          await JwtStorage.saveToken(token);
          await JwtStorage.saveUserId(user.userId);
        } catch (e) {
          // Token invalid, clear both storages
          await logout();
        }
      } else if (token != null) {
        // Have token but no user data, try to get user
        try {
          final user = await AuthService.getProfile(token);
          state = AuthState(user: user, token: token);
          
          // Save to both storages
          await _storage.write(key: _tokenKey, value: token);
          await _storage.write(key: _userKey, value: user.toJson().toString());
          await JwtStorage.saveToken(token);
          await JwtStorage.saveUserId(user.userId);
        } catch (e) {
          // Token invalid, clear both storages
          await logout();
        }
      } else {
        state = const AuthState();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi khi khởi tạo: ${e.toString()}',
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await AuthService.login(request);
      
      // Save to both secure storage systems for compatibility
      await _storage.write(key: _tokenKey, value: response.token);
      await _storage.write(key: _userKey, value: response.user.toJson().toString());
      
      // Also save to JwtStorage for backend service compatibility
      await JwtStorage.saveToken(response.token);
      await JwtStorage.saveUserId(response.user.userId);
      
      state = AuthState(
        user: response.user,
        token: response.token,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> register({required String email, required String password, String? fullName}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final request = RegisterRequest(
        email: email,
        password: password,
        username: '', // Backend doesn't use username, use empty string
        fullName: fullName,
      );
      await AuthService.register(request);
      
      // Registration successful, don't auto-login
      // User should manually login after registration
      state = state.copyWith(isLoading: false, error: null);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    print('DEBUG AUTH - logout() called');
    state = state.copyWith(isLoading: true);
    
    try {
      // Clear both storage systems
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
      await JwtStorage.clearAll();
      
      print('DEBUG AUTH - Storage cleared, setting empty state');
      state = const AuthState();
      print('DEBUG AUTH - After logout - isAuthenticated: ${state.isAuthenticated}');
    } catch (e) {
      print('DEBUG AUTH - logout error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Lỗi khi đăng xuất: ${e.toString()}',
      );
    }
  }


  // Biometric login with account selection support
  Future<Map<String, dynamic>> loginWithBiometrics() async {
    try {
      final localAuth = LocalAuthentication();
      final isSupported = await localAuth.isDeviceSupported();
      final canCheck = await localAuth.canCheckBiometrics;
      if (!isSupported || !canCheck) return {'success': false, 'error': 'Biometric not supported'};

      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Xác thực sinh trắc học để đăng nhập',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!didAuthenticate) return {'success': false, 'error': 'Authentication failed'};

      // Tạo template cố định (giống như khi đăng ký)
      final template = await _generateBiometricTemplate();
      print('🔐 DEBUG: Template đăng nhập = $template');

      // Kiểm tra có nhiều tài khoản không
      final result = await AuthService.loginBiometricWithSelection(template);
      
      if (result['multipleAccounts'] == true) {
        // Có nhiều tài khoản - trả về danh sách để UI hiển thị
        return {
          'success': false,
          'needsSelection': true,
          'accounts': result['accounts'],
          'template': template,
        };
      } else {
        // Chỉ có 1 tài khoản - đăng nhập luôn
        final response = AuthResponse.fromJson(result);
        await _saveAuthData(response);
        return {'success': true};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> _showAccountSelectionDialog(List accounts, String template) async {
    print('🔍 DEBUG: Có ${accounts.length} tài khoản cùng vân tay');
    for (int i = 0; i < accounts.length; i++) {
      final account = accounts[i];
      print('👤 DEBUG: Tài khoản $i: ${account.toString()}');
    }
    
    if (accounts.isNotEmpty) {
      print('🎯 DEBUG: Cần hiển thị dialog chọn tài khoản');
      print('⚠️ DEBUG: Tạm thời chọn tài khoản đầu tiên - cần implement UI');
      
      // Tạm thời chọn tài khoản đầu tiên để test
      // TODO: Implement proper account selection dialog
      final firstAccount = accounts.first;
      print('✅ DEBUG: Chọn tài khoản đầu tiên (tạm thời)');
      print('🔍 DEBUG: Account data: ${firstAccount.toString()}');
      
      // Tìm ID của tài khoản (có thể là 'Id', 'id', hoặc 'userId')
      String? accountId = firstAccount['Id'] ?? firstAccount['id'] ?? firstAccount['userId'];
      
      if (accountId != null) {
        print('🔑 DEBUG: Account ID = $accountId');
        final response = await AuthService.loginBiometricAccount(template, accountId);
        await _saveAuthData(response);
        return true;
      } else {
        print('❌ DEBUG: Không tìm thấy Account ID');
        return false;
      }
    }
    return false;
  }

  // Hiển thị dialog chọn tài khoản
  Future<bool> _showAccountSelectionUI(List accounts, String template) async {
    // TODO: Implement proper account selection UI
    // For now, return false to indicate no selection made
    return false;
  }

  Future<void> _saveAuthData(AuthResponse response) async {
    await _storage.write(key: _tokenKey, value: response.token);
    await _storage.write(key: _userKey, value: response.user.toJson().toString());
    await JwtStorage.saveToken(response.token);
    await JwtStorage.saveUserId(response.user.userId);
    state = AuthState(user: response.user, token: response.token);
  }

  // Đăng nhập với tài khoản đã chọn
  Future<bool> loginWithSelectedAccount(String template, String accountId) async {
    try {
      final response = await AuthService.loginBiometricAccount(template, accountId);
      await _saveAuthData(response);
      return true;
    } catch (e) {
      print('❌ DEBUG: Lỗi đăng nhập tài khoản đã chọn: $e');
      return false;
    }
  }

  // Đăng ký vân tay cho user hiện tại
  Future<bool> registerBiometrics() async {
    try {
      print('🔍 DEBUG: Bắt đầu đăng ký vân tay');
      
      if (state.token == null) {
        print('❌ DEBUG: Không có token');
        throw Exception('Không có token xác thực');
      }

      print('✅ DEBUG: Có token, bắt đầu kiểm tra thiết bị');
      final localAuth = LocalAuthentication();
      
      print('🔍 DEBUG: Kiểm tra hỗ trợ sinh trắc học...');
      final isSupported = await localAuth.isDeviceSupported();
      print('📱 DEBUG: isSupported = $isSupported');
      
      if (!isSupported) {
        print('❌ DEBUG: Thiết bị không hỗ trợ sinh trắc học');
        throw Exception('Thiết bị không hỗ trợ sinh trắc học');
      }
      
      print('🔍 DEBUG: Kiểm tra có thể xác thực...');
      final canCheck = await localAuth.canCheckBiometrics;
      print('🔐 DEBUG: canCheck = $canCheck');
      
      if (!canCheck) {
        print('❌ DEBUG: Chưa đăng ký vân tay trong hệ thống');
        throw Exception('Chưa đăng ký vân tay trong cài đặt hệ thống');
      }

      print('✅ DEBUG: Thiết bị OK, bắt đầu xác thực vân tay...');
      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Xác thực vân tay để liên kết với tài khoản này',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      print('🔐 DEBUG: Kết quả xác thực = $didAuthenticate');
      if (!didAuthenticate) {
        print('❌ DEBUG: Xác thực vân tay thất bại');
        throw Exception('Xác thực vân tay thất bại');
      }

      print('✅ DEBUG: Xác thực thành công, tạo template...');
      final template = await _generateBiometricTemplate();
      print('🎯 DEBUG: Template mới = $template');

      print('🌐 DEBUG: Gửi template lên server...');
      await AuthService.registerBiometric(state.token!, template);
      print('✅ DEBUG: Đăng ký thành công!');
      
      // Cập nhật state để bioAuthEnabled = true
      if (state.user != null) {
        final updatedUser = User(
          userId: state.user!.userId,
          email: state.user!.email,
          username: state.user!.username,
          fullName: state.user!.fullName,
          profilePicture: state.user!.profilePicture,
          role: state.user!.role,
          bioAuthEnabled: true,
          lastLogin: state.user!.lastLogin,
          createdAt: state.user!.createdAt,
          updatedAt: state.user!.updatedAt,
        );
        state = state.copyWith(user: updatedUser);
        print('🔄 DEBUG: Đã cập nhật bioAuthEnabled = true');
      }
      
      return true;
    } catch (e) {
      print('❌ DEBUG: Lỗi chi tiết: $e');
      print('❌ DEBUG: Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Xóa vân tay đã đăng ký
  Future<bool> removeBiometrics() async {
    try {
      print('🗑️ DEBUG: Bắt đầu xóa vân tay');
      
      if (state.token == null) {
        print('❌ DEBUG: Không có token');
        return false;
      }
      
      print('🌐 DEBUG: Gửi request xóa vân tay lên server...');
      await AuthService.removeBiometric(state.token!);
      print('✅ DEBUG: Xóa vân tay thành công!');
      
      // Cập nhật state để bioAuthEnabled = false
      if (state.user != null) {
        final updatedUser = User(
          userId: state.user!.userId,
          email: state.user!.email,
          username: state.user!.username,
          fullName: state.user!.fullName,
          profilePicture: state.user!.profilePicture,
          role: state.user!.role,
          bioAuthEnabled: false,
          lastLogin: state.user!.lastLogin,
          createdAt: state.user!.createdAt,
          updatedAt: state.user!.updatedAt,
        );
        state = state.copyWith(user: updatedUser);
        print('🔄 DEBUG: Đã cập nhật bioAuthEnabled = false');
      }
      
      return true;
    } catch (e) {
      print('❌ DEBUG: Lỗi xóa vân tay: $e');
      return false;
    }
  }

  // Tạo template unique dựa trên thông tin vân tay thực tế
  Future<String> _generateBiometricTemplate() async {
    // Template được tạo từ thông tin CỐ ĐỊNH:
    // 1. Device ID cố định (để cùng thiết bị có cùng template)
    // 2. Thông tin thiết bị
    // KHÔNG phụ thuộc vào user vì có thể chưa đăng nhập
    final deviceId = await _getDeviceId();
    
    // Tạo hash cố định từ thông tin device
    final combined = 'device_${deviceId}';
    final hash = combined.hashCode.abs().toString();
    
    print('🔧 DEBUG: Device ID = $deviceId');
    print('🔧 DEBUG: Combined = $combined');
    print('🔧 DEBUG: Hash = $hash');
    
    // Tạo template với format: bio_device_hash
    return 'bio_$hash';
  }


  // Lấy device ID (giả lập)
  Future<String> _getDeviceId() async {
    // Trong thực tế sẽ lấy device ID thật
    // Hiện tại tạo một ID cố định cho demo
    return 'device_12345';
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (state.token == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedUser = await AuthService.updateProfile(state.token!, data);
      await _storage.write(key: _userKey, value: updatedUser.toJson().toString());
      
      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(storage);
});

// Token provider for easy access
final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).token;
});

// User provider for easy access
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

// Auth loading provider
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

// Auth error provider
final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});

// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
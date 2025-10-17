import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../auth/jwt_storage.dart';

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
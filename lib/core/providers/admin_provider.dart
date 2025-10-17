import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/backend_models.dart';
import '../services/admin_service.dart';

// Admin users provider
final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  return AdminService.getUsers();
});

// Admin stats provider
final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  return AdminService.getStats();
});

// Admin notifier for managing users
class AdminNotifier extends StateNotifier<AsyncValue<List<AdminUser>>> {
  AdminNotifier() : super(const AsyncValue.loading());

  Future<void> loadUsers() async {
    state = const AsyncValue.loading();
    try {
      final users = await AdminService.getUsers();
      state = AsyncValue.data(users);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    try {
      await AdminService.updateUserRole(userId, role);
      // Reload users after update
      await loadUsers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await AdminService.deleteUser(userId);
      // Reload users after deletion
      await loadUsers();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final adminNotifierProvider = StateNotifierProvider<AdminNotifier, AsyncValue<List<AdminUser>>>((ref) {
  return AdminNotifier();
});

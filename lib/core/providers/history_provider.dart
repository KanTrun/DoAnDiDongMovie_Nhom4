import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/backend_models.dart';
import '../services/history_service.dart';
import 'auth_provider.dart';

// History provider
final historyProvider = StateNotifierProvider<HistoryNotifier, AsyncValue<List<History>>>((ref) {
  final token = ref.watch(authTokenProvider);
  return HistoryNotifier(token);
});

class HistoryNotifier extends StateNotifier<AsyncValue<List<History>>> {
  final String? token;

  HistoryNotifier(this.token) : super(const AsyncValue.loading()) {
    if (token != null) {
      loadHistory();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadHistory({
    int page = 1,
    int pageSize = 20,
    String? action,
    String? mediaType,
  }) async {
    if (token == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final response = await HistoryService.getHistory(
        token: token!,
        page: page,
        pageSize: pageSize,
        action: action,
        mediaType: mediaType,
      );

      final historyData = (response['items'] as List)
          .map((json) => History.fromJson(json))
          .toList();

      state = AsyncValue.data(historyData);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> logEvent({
    required int tmdbId,
    required String mediaType,
    required String action,
    Map<String, dynamic>? extra,
  }) async {
    if (token == null) return;

    try {
      await HistoryService.logEvent(
        token: token!,
        tmdbId: tmdbId,
        mediaType: mediaType,
        action: action,
        extra: extra,
      );

      // Refresh history after logging
      await loadHistory();
    } catch (e) {
      // Log error but don't update state
      print('Error logging history event: $e');
    }
  }

  Future<void> clearHistory() async {
    if (token == null) return;

    try {
      await HistoryService.clearHistory(token: token!);
      state = const AsyncValue.data([]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteHistoryItem(int historyId) async {
    if (token == null) return;

    try {
      await HistoryService.deleteHistoryItem(
        token: token!,
        historyId: historyId,
      );

      // Remove from local state
      state.whenData((history) {
        final updatedHistory = history.where((h) => h.id != historyId).toList();
        state = AsyncValue.data(updatedHistory);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Analytics providers
final topTrailersProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) return [];
  
  return HistoryService.getTopTrailers(token: token, days: days);
});

final providerStatsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) return [];
  
  return HistoryService.getProviderStats(token: token, days: days);
});

final peakHoursProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final token = ref.watch(authTokenProvider);
  if (token == null) return [];
  
  return HistoryService.getPeakHours(token: token, days: days);
});

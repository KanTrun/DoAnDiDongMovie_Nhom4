import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/cinema.dart';
import '../../../core/repositories/cinema_repository.dart';

// State cho nearby cinema
class NearbyCinemaState {
  final List<Cinema> cinemas;
  final bool isLoading;
  final String? error;
  final double? userLat;
  final double? userLon;
  final int radiusMeters;
  final bool hasPermission;

  const NearbyCinemaState({
    this.cinemas = const [],
    this.isLoading = false,
    this.error,
    this.userLat,
    this.userLon,
    this.radiusMeters = 10000,
    this.hasPermission = false,
  });

  NearbyCinemaState copyWith({
    List<Cinema>? cinemas,
    bool? isLoading,
    String? error,
    double? userLat,
    double? userLon,
    int? radiusMeters,
    bool? hasPermission,
  }) {
    return NearbyCinemaState(
      cinemas: cinemas ?? this.cinemas,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      userLat: userLat ?? this.userLat,
      userLon: userLon ?? this.userLon,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }

  bool get hasData => cinemas.isNotEmpty;
  bool get hasError => error != null;
}

// Controller cho nearby cinema
class NearbyCinemaController extends StateNotifier<NearbyCinemaState> {
  final CinemaRepository? _repository;

  NearbyCinemaController(this._repository) : super(const NearbyCinemaState());
  
  // Constructor cho loading state
  NearbyCinemaController._loading() : _repository = null, super(const NearbyCinemaState());
  
  // Constructor cho error state
  NearbyCinemaController._error() : _repository = null, super(const NearbyCinemaState());

  /// Tải danh sách rạp gần vị trí hiện tại
  Future<void> loadNearbyCinemas({int? radiusMeters, bool useCache = true}) async {
    if (_repository == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Repository not ready',
      );
      return;
    }
    
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final radius = radiusMeters ?? state.radiusMeters;
      final cinemas = await _repository!.getNearbyCinemas(
        radiusMeters: radius,
        useCache: useCache,
      );
      
      // Lấy vị trí hiện tại để cập nhật state
      final location = await _repository!.getCurrentLocation();
      
      state = state.copyWith(
        cinemas: cinemas,
        isLoading: false,
        userLat: location.latitude,
        userLon: location.longitude,
        radiusMeters: radius,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Tải danh sách rạp tại vị trí cụ thể
  Future<void> loadCinemasAtLocation({
    required double lat,
    required double lon,
    int? radiusMeters,
    bool useCache = true,
  }) async {
    if (_repository == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Repository not ready',
      );
      return;
    }
    
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final radius = radiusMeters ?? state.radiusMeters;
      final cinemas = await _repository!.getNearbyCinemasAtLocation(
        lat: lat,
        lon: lon,
        radiusMeters: radius,
        useCache: useCache,
      );
      
      state = state.copyWith(
        cinemas: cinemas,
        isLoading: false,
        userLat: lat,
        userLon: lon,
        radiusMeters: radius,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Thay đổi bán kính tìm kiếm
  Future<void> changeRadius(int radiusMeters) async {
    if (state.userLat != null && state.userLon != null) {
      await loadCinemasAtLocation(
        lat: state.userLat!,
        lon: state.userLon!,
        radiusMeters: radiusMeters,
      );
    } else {
      await loadNearbyCinemas(radiusMeters: radiusMeters);
    }
  }

  /// Kiểm tra quyền truy cập vị trí
  Future<void> checkLocationPermission() async {
    if (_repository == null) return;
    final hasPermission = await _repository!.hasLocationPermission();
    state = state.copyWith(hasPermission: hasPermission);
  }

  /// Kiểm tra location service
  Future<bool> checkLocationService() async {
    if (_repository == null) return false;
    return await _repository!.isLocationServiceEnabled();
  }

  /// Làm mới dữ liệu (bỏ qua cache)
  Future<void> refresh() async {
    if (state.userLat != null && state.userLon != null) {
      await loadCinemasAtLocation(
        lat: state.userLat!,
        lon: state.userLon!,
        useCache: false,
      );
    } else {
      await loadNearbyCinemas(useCache: false);
    }
  }

  /// Xóa cache
  Future<void> clearCache() async {
    if (_repository == null) return;
    await _repository!.clearCache();
  }

  /// Xóa lỗi
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset state
  void reset() {
    state = const NearbyCinemaState();
  }
}

// Provider cho repository
final cinemaRepositoryProvider = FutureProvider<CinemaRepository>((ref) {
  return CinemaRepository.create();
});

// Provider cho controller
final nearbyCinemaControllerProvider = StateNotifierProvider<NearbyCinemaController, NearbyCinemaState>((ref) {
  // Chỉ tạo controller khi repository đã sẵn sàng
  final repositoryAsync = ref.watch(cinemaRepositoryProvider);
  return repositoryAsync.when(
    data: (repository) => NearbyCinemaController(repository),
    loading: () => NearbyCinemaController._loading(),
    error: (_, __) => NearbyCinemaController._error(),
  );
});

// Provider cho danh sách rạp
final nearbyCinemasProvider = Provider<List<Cinema>>((ref) {
  final state = ref.watch(nearbyCinemaControllerProvider);
  return state.cinemas;
});

// Provider cho trạng thái loading
final isLoadingNearbyCinemasProvider = Provider<bool>((ref) {
  final state = ref.watch(nearbyCinemaControllerProvider);
  return state.isLoading;
});

// Provider cho lỗi
final nearbyCinemasErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(nearbyCinemaControllerProvider);
  return state.error;
});

// Provider cho vị trí người dùng
final userLocationProvider = Provider<Map<String, double>?>((ref) {
  final state = ref.watch(nearbyCinemaControllerProvider);
  if (state.userLat != null && state.userLon != null) {
    return {
      'lat': state.userLat!,
      'lon': state.userLon!,
    };
  }
  return null;
});

// Provider cho bán kính hiện tại
final currentRadiusProvider = Provider<int>((ref) {
  final state = ref.watch(nearbyCinemaControllerProvider);
  return state.radiusMeters;
});

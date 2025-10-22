import '../models/cinema.dart';
import '../services/location_service.dart';
import '../services/overpass_service.dart';
import '../services/distance.dart';
import '../services/cache/nearby_cache.dart';

class CinemaRepository {
  final OverpassService _overpassService;
  final LocationService _locationService;
  final NearbyCache _cache;
  
  CinemaRepository({
    OverpassService? overpassService,
    LocationService? locationService,
    NearbyCache? cache,
  }) : _overpassService = overpassService ?? OverpassService(),
       _locationService = locationService ?? LocationService(),
       _cache = cache ?? (throw ArgumentError('NearbyCache must be provided'));
  
  // Factory constructor để tạo instance với NearbyCache
  static Future<CinemaRepository> create() async {
    final cache = await NearbyCache.create();
    return CinemaRepository(cache: cache);
  }

  /// Lấy danh sách rạp gần vị trí hiện tại
  Future<List<Cinema>> getNearbyCinemas({
    int radiusMeters = 10000,
    bool useCache = true,
  }) async {
    try {
      // Lấy vị trí hiện tại
      final location = await _locationService.getCurrentLocation();
      
      return await getNearbyCinemasAtLocation(
        lat: location.latitude,
        lon: location.longitude,
        radiusMeters: radiusMeters,
        useCache: useCache,
      );
    } catch (e) {
      throw CinemaRepositoryException('Failed to get nearby cinemas: $e');
    }
  }

  /// Lấy danh sách rạp gần vị trí cụ thể
  Future<List<Cinema>> getNearbyCinemasAtLocation({
    required double lat,
    required double lon,
    int radiusMeters = 10000,
    bool useCache = true,
  }) async {
    try {
      // Kiểm tra cache trước
      if (useCache) {
      final cachedCinemas = await _cache.getCinemas(
        lat: lat,
        lon: lon,
        radius: radiusMeters,
      );
        
        if (cachedCinemas != null && cachedCinemas.isNotEmpty) {
          return _processCinemas(cachedCinemas, lat, lon);
        }
      }

      // Gọi Overpass API
      final cinemas = await _overpassService.fetchCinemas(
        lat: lat,
        lon: lon,
        radiusMeters: radiusMeters,
      );

      // Xử lý và tính khoảng cách
      final processedCinemas = _processCinemas(cinemas, lat, lon);

      // Lưu cache
      if (useCache) {
        await _cache.saveCinemas(
          lat: lat,
          lon: lon,
          radius: radiusMeters,
          cinemas: processedCinemas,
        );
      }

      return processedCinemas;
    } catch (e) {
      throw CinemaRepositoryException('Failed to get nearby cinemas: $e');
    }
  }

  /// Xử lý danh sách rạp: tính khoảng cách, sắp xếp, gộp trùng
  List<Cinema> _processCinemas(List<Cinema> cinemas, double userLat, double userLon) {
    // Tính khoảng cách cho mỗi rạp
    final cinemasWithDistance = cinemas.map((cinema) {
      final distance = metersBetween(userLat, userLon, cinema.lat, cinema.lon);
      return cinema.copyWith(distanceMeters: distance);
    }).toList();

    // Lọc bỏ các rạp quá xa (có thể do lỗi dữ liệu)
    final validCinemas = cinemasWithDistance.where((cinema) => 
      cinema.distanceMeters != null && cinema.distanceMeters! <= 50000 // 50km
    ).toList();

    // Gộp các rạp trùng lặp (cùng tên và gần nhau)
    final deduplicatedCinemas = _deduplicateCinemas(validCinemas);

    // Sắp xếp theo khoảng cách
    deduplicatedCinemas.sort((a, b) => 
      (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0)
    );

    return deduplicatedCinemas;
  }

  /// Gộp các rạp trùng lặp
  List<Cinema> _deduplicateCinemas(List<Cinema> cinemas) {
    final Map<String, Cinema> uniqueCinemas = {};
    
    for (final cinema in cinemas) {
      final key = _generateCinemaKey(cinema);
      
      if (!uniqueCinemas.containsKey(key)) {
        uniqueCinemas[key] = cinema;
      } else {
        // Nếu rạp mới gần hơn, thay thế
        final existing = uniqueCinemas[key]!;
        if ((cinema.distanceMeters ?? 0) < (existing.distanceMeters ?? 0)) {
          uniqueCinemas[key] = cinema;
        }
      }
    }
    
    return uniqueCinemas.values.toList();
  }

  /// Tạo key để nhận diện rạp trùng lặp
  String _generateCinemaKey(Cinema cinema) {
    // Normalize tên rạp
    final normalizedName = cinema.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
    
    // Tạo key dựa trên tên và brand
    final brand = cinema.brand?.toLowerCase().trim() ?? '';
    return '$normalizedName|$brand';
  }

  /// Lấy vị trí hiện tại
  Future<LatLng> getCurrentLocation() async {
    return await _locationService.getCurrentLocation();
  }

  /// Kiểm tra quyền truy cập vị trí
  Future<bool> hasLocationPermission() async {
    return await _locationService.hasLocationPermission();
  }

  /// Kiểm tra xem location service có được bật không
  Future<bool> isLocationServiceEnabled() async {
    return await _locationService.isLocationServiceEnabled();
  }

  /// Xóa cache
  Future<void> clearCache() async {
    await _cache.clearCache();
  }

  /// Kiểm tra cache có hợp lệ không
  bool hasValidCache({
    required double lat,
    required double lon,
    int radiusMeters = 10000,
  }) {
    return _cache.hasValidCache(
      lat: lat,
      lon: lon,
      radius: radiusMeters,
    );
  }
}

class CinemaRepositoryException implements Exception {
  final String message;
  CinemaRepositoryException(this.message);
  
  @override
  String toString() => 'CinemaRepositoryException: $message';
}

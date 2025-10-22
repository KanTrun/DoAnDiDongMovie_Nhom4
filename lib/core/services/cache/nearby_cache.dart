import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/cinema.dart';

class NearbyCache {
  static const String _cacheKey = 'nearby_cinemas_cache';
  static const String _locationKey = 'last_location';
  static const Duration _cacheExpiry = Duration(minutes: 15);
  
  final SharedPreferences _prefs;
  
  NearbyCache(this._prefs);
  
  // Factory constructor để tạo instance với SharedPreferences
  static Future<NearbyCache> create() async {
    final prefs = await SharedPreferences.getInstance();
    return NearbyCache(prefs);
  }

  /// Lưu cache danh sách rạp theo vị trí
  Future<void> saveCinemas({
    required double lat,
    required double lon,
    required int radius,
    required List<Cinema> cinemas,
  }) async {
    final cacheKey = _generateCacheKey(lat, lon, radius);
    final cacheData = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'lat': lat,
      'lon': lon,
      'radius': radius,
      'cinemas': cinemas.map((c) => c.toJson()).toList(),
    };
    
    await _prefs.setString(cacheKey, json.encode(cacheData));
    await _prefs.setString(_locationKey, json.encode({'lat': lat, 'lon': lon}));
  }

  /// Lấy cache danh sách rạp
  Future<List<Cinema>?> getCinemas({
    required double lat,
    required double lon,
    required int radius,
  }) async {
    final cacheKey = _generateCacheKey(lat, lon, radius);
    final cachedData = _prefs.getString(cacheKey);
    
    if (cachedData == null) return null;
    
    try {
      final data = json.decode(cachedData) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
      
      // Kiểm tra cache có hết hạn không
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        await _prefs.remove(cacheKey);
        return null;
      }
      
      // Parse danh sách rạp
      final cinemasJson = (data['cinemas'] as List).cast<Map<String, dynamic>>();
      return cinemasJson.map((json) => Cinema.fromJson(json)).toList();
    } catch (e) {
      // Cache bị lỗi, xóa đi
      await _prefs.remove(cacheKey);
      return null;
    }
  }

  /// Kiểm tra xem có cache hợp lệ không
  bool hasValidCache({
    required double lat,
    required double lon,
    required int radius,
  }) {
    final cacheKey = _generateCacheKey(lat, lon, radius);
    final cachedData = _prefs.getString(cacheKey);
    
    if (cachedData == null) return false;
    
    try {
      final data = json.decode(cachedData) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
      return DateTime.now().difference(timestamp) <= _cacheExpiry;
    } catch (e) {
      return false;
    }
  }

  /// Lấy vị trí cuối cùng đã cache
  Future<Map<String, double>?> getLastLocation() async {
    final locationData = _prefs.getString(_locationKey);
    if (locationData == null) return null;
    
    try {
      final data = json.decode(locationData) as Map<String, dynamic>;
      return {
        'lat': (data['lat'] as num).toDouble(),
        'lon': (data['lon'] as num).toDouble(),
      };
    } catch (e) {
      return null;
    }
  }

  /// Xóa tất cả cache
  Future<void> clearCache() async {
    final keys = _prefs.getKeys().where((key) => key.startsWith('cinema_cache_'));
    for (final key in keys) {
      await _prefs.remove(key);
    }
    await _prefs.remove(_locationKey);
  }

  /// Tạo cache key dựa trên vị trí và bán kính
  String _generateCacheKey(double lat, double lon, int radius) {
    // Làm tròn tọa độ để cache theo ô lưới (khoảng 1km)
    final roundedLat = (lat * 100).round() / 100;
    final roundedLon = (lon * 100).round() / 100;
    return 'cinema_cache_${roundedLat}_${roundedLon}_$radius';
  }

  /// Kiểm tra xem vị trí mới có khác nhiều so với vị trí cache không
  bool isLocationSignificantlyDifferent({
    required double newLat,
    required double newLon,
    required double cachedLat,
    required double cachedLon,
    double thresholdKm = 2.0, // 2km
  }) {
    // Tính khoảng cách Haversine (đơn giản hóa)
    const R = 6371.0; // Bán kính Trái Đất tính bằng km
    final dLat = (newLat - cachedLat) * 3.14159 / 180.0;
    final dLon = (newLon - cachedLon) * 3.14159 / 180.0;
    final a = (dLat / 2) * (dLat / 2) + 
              (dLon / 2) * (dLon / 2) * 
              cos(newLat * 3.14159 / 180.0) * cos(cachedLat * 3.14159 / 180.0);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = R * c;
    
    return distance > thresholdKm;
  }
}

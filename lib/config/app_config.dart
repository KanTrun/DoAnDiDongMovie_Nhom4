class AppConfig {
  // Nearby Cinema Configuration
  static const int defaultRadiusMeters = 10000; // 10km
  static const List<int> radiusOptions = [5000, 10000, 20000, 50000]; // 5km, 10km, 20km, 50km
  static const int maxResults = 200;
  static const Duration cacheExpiry = Duration(minutes: 15);
  static const Duration requestTimeout = Duration(seconds: 30);
  
  // Overpass API Configuration
  static const List<String> overpassMirrors = [
    'https://overpass-api.de/api/interpreter',
    'https://z.overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];
  
  // Cache Configuration
  static const double cacheGridSize = 0.01; // ~1km grid
  static const double duplicateThresholdMeters = 50.0; // 50m
  static const int maxCacheAgeHours = 24;
  
  // UI Configuration
  static const double listItemHeight = 120.0;
  static const double mapHeight = 300.0;
  static const int maxAddressLength = 100;
  
  // Error Messages
  static const String locationPermissionDenied = 'Quyền truy cập vị trí bị từ chối';
  static const String locationServiceDisabled = 'Dịch vụ vị trí bị tắt';
  static const String networkError = 'Lỗi kết nối mạng';
  static const String noCinemasFound = 'Không tìm thấy rạp nào trong bán kính';
  
  // Attribution
  static const String osmAttribution = '© OpenStreetMap contributors';
  static const String appName = 'FlutterMovieTMDB';
  static const String contactEmail = 'developer@example.com';
}

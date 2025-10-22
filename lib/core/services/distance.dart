import 'dart:math';

/// Tính khoảng cách giữa hai điểm địa lý sử dụng công thức Haversine
/// Trả về khoảng cách tính bằng mét
double metersBetween(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000.0; // Bán kính Trái Đất tính bằng mét
  
  final dLat = (lat2 - lat1) * pi / 180.0;
  final dLon = (lon2 - lon1) * pi / 180.0;
  
  final a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
  
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return R * c;
}

/// Chuyển đổi mét sang kilomet
double metersToKilometers(double meters) {
  return meters / 1000.0;
}

/// Chuyển đổi mét sang dặm
double metersToMiles(double meters) {
  return meters * 0.000621371;
}

/// Format khoảng cách thành chuỗi dễ đọc
String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.round()}m';
  } else {
    final km = metersToKilometers(meters);
    return '${km.toStringAsFixed(1)}km';
  }
}

/// Kiểm tra xem hai điểm có gần nhau không (trong bán kính cho trước)
bool isNearby(double lat1, double lon1, double lat2, double lon2, double radiusMeters) {
  return metersBetween(lat1, lon1, lat2, lon2) <= radiusMeters;
}

/// Tính diện tích của một vùng tròn (để cache)
double calculateAreaRadius(double radiusMeters) {
  return pi * radiusMeters * radiusMeters;
}

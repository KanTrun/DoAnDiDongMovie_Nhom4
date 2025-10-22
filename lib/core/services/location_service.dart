import 'package:geolocator/geolocator.dart';
import '../models/cinema.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Kiểm tra và yêu cầu quyền truy cập vị trí
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedException('Location permissions are permanently denied');
    }

    return true;
  }

  /// Lấy vị trí hiện tại của người dùng
  Future<LatLng> getCurrentLocation() async {
    await requestLocationPermission();
    
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw LocationException('Failed to get current location: $e');
    }
  }

  /// Lấy vị trí cuối cùng đã biết (nhanh hơn)
  Future<LatLng?> getLastKnownLocation() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        return LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      // Không throw exception, chỉ return null
    }
    return null;
  }

  /// Kiểm tra xem có quyền truy cập vị trí không
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  /// Kiểm tra xem location service có được bật không
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);
  
  @override
  String toString() => 'LocationException: $message';
}

class LocationServiceDisabledException extends LocationException {
  LocationServiceDisabledException(String message) : super(message);
}

class LocationPermissionDeniedException extends LocationException {
  LocationPermissionDeniedException(String message) : super(message);
}

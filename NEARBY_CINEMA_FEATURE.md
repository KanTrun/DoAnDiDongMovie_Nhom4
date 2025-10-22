# Tính năng "Rạp gần tôi" - Nearby Cinema Feature

## Tổng quan

Tính năng "Rạp gần tôi" cho phép người dùng tìm kiếm các rạp chiếu phim gần vị trí hiện tại của họ. Tính năng này sử dụng OpenStreetMap (OSM) và Overpass API để lấy dữ liệu rạp chiếu phim toàn cầu mà không cần phụ thuộc vào Google Cloud.

## Kiến trúc

### 1. Nguồn dữ liệu
- **OpenStreetMap**: Cơ sở dữ liệu mở toàn cầu
- **Overpass API**: API để truy vấn dữ liệu OSM
- **GPS gốc**: Sử dụng GPS của thiết bị (không cần Google Play Services)

### 2. Cấu trúc thư mục
```
lib/
├── core/
│   ├── models/
│   │   └── cinema.dart                    # Model rạp chiếu phim
│   ├── services/
│   │   ├── location_service.dart           # Quản lý vị trí GPS
│   │   ├── overpass_service.dart           # Gọi Overpass API
│   │   ├── distance.dart                   # Tính toán khoảng cách
│   │   └── cache/
│   │       └── nearby_cache.dart           # Cache dữ liệu
│   └── repositories/
│       └── cinema_repository.dart           # Repository chính
├── features/nearby_cinema/
│   ├── controllers/
│   │   └── nearby_cinema_controller.dart   # State management
│   ├── screens/
│   │   └── nearby_cinema_screen.dart       # Màn hình chính
│   └── widgets/
│       ├── cinema_list_item.dart           # Widget hiển thị rạp
│       └── permission_gate.dart            # Quản lý quyền truy cập
└── config/
    └── app_config.dart                     # Cấu hình ứng dụng
```

## Tính năng chính

### 1. Tìm kiếm rạp gần vị trí
- Tự động lấy vị trí hiện tại của người dùng
- Tìm kiếm rạp trong bán kính có thể tùy chỉnh (5km, 10km, 20km, 50km)
- Sắp xếp theo khoảng cách từ gần đến xa

### 2. Thông tin rạp chiếu phim
- Tên rạp và thương hiệu (CGV, Lotte, Galaxy, BHD...)
- Địa chỉ chi tiết
- Số điện thoại
- Website
- Giờ mở cửa
- Khoảng cách từ vị trí người dùng

### 3. Tương tác với rạp
- **Chỉ đường**: Mở ứng dụng bản đồ mặc định
- **Gọi điện**: Gọi trực tiếp đến rạp
- **Truy cập website**: Mở website của rạp
- **Sao chép địa chỉ**: Copy địa chỉ vào clipboard

### 4. Cache thông minh
- Cache dữ liệu theo ô lưới địa lý
- Tự động làm mới khi di chuyển đáng kể
- Cache 15 phút để tránh spam API

## Cấu hình

### Android Permissions
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS Permissions
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Ứng dụng cần truy cập vị trí của bạn để tìm rạp chiếu phim gần nhất.</string>
```

### Dependencies
```yaml
dependencies:
  geolocator: ^10.1.0      # GPS location
  http: ^1.1.0             # HTTP requests
  url_launcher: ^6.2.2     # Open external apps
  shared_preferences: ^2.2.2 # Local cache
  flutter_riverpod: ^2.4.9  # State management
```

## Sử dụng

### 1. Thêm vào navigation
```dart
// Trong app.dart
GoRoute(
  path: '/nearby-cinema',
  name: 'nearby-cinema',
  builder: (context, state) => const NearbyCinemaScreen(),
),
```

### 2. Thêm vào bottom navigation
```dart
// Trong home_shell.dart
BottomNavigationBarItem(
  icon: Icon(Icons.location_on_outlined),
  activeIcon: Icon(Icons.location_on),
  label: 'Rạp gần tôi',
),
```

### 3. Sử dụng trong code
```dart
// Lấy danh sách rạp gần vị trí
final cinemas = await CinemaRepository().getNearbyCinemas(
  radiusMeters: 10000, // 10km
);

// Lấy rạp tại vị trí cụ thể
final cinemas = await CinemaRepository().getNearbyCinemasAtLocation(
  lat: 10.762622,
  lon: 106.660172,
  radiusMeters: 5000, // 5km
);
```

## API và Dữ liệu

### Overpass Query
```overpass
[out:json][timeout:25];
(
  node["amenity"="cinema"](around:10000,<LAT>,<LON>);
  way["amenity"="cinema"](around:10000,<LAT>,<LON>);
  relation["amenity"="cinema"](around:10000,<LAT>,<LON>);
);
out center tags;
```

### Cinema Model
```dart
class Cinema {
  final String id;          // "osm:<type>:<id>"
  final String name;        // Tên rạp
  final double lat;         // Vĩ độ
  final double lon;         // Kinh độ
  final String? brand;      // Thương hiệu
  final String? address;    // Địa chỉ
  final String? phone;      // Số điện thoại
  final String? website;    // Website
  final String? openingHours; // Giờ mở cửa
  final double? distanceMeters; // Khoảng cách (mét)
}
```

## Tối ưu hóa

### 1. Cache Strategy
- Cache theo ô lưới địa lý (1km x 1km)
- Tự động làm mới khi di chuyển > 2km
- Cache 15 phút để tránh spam API

### 2. Performance
- Sử dụng multiple Overpass mirrors
- Retry logic với exponential backoff
- Gộp các rạp trùng lặp (cùng tên, gần nhau < 50m)

### 3. User Experience
- Loading states và error handling
- Permission management
- Offline support với cache

## Mở rộng

### 1. Tích hợp lịch chiếu
- Kết nối với API lịch chiếu của rạp
- Hiển thị phim đang chiếu
- Đặt vé trực tiếp

### 2. Bộ lọc nâng cao
- Lọc theo thương hiệu
- Lọc theo giờ mở cửa
- Lọc theo tiện ích (ghế VIP, bãi xe...)

### 3. Thông báo
- Thông báo khi có rạp mới gần
- Nhắc nhở xem phim
- Khuyến mãi từ rạp

## Troubleshooting

### 1. Không tìm thấy rạp
- Kiểm tra kết nối mạng
- Tăng bán kính tìm kiếm
- Kiểm tra quyền truy cập vị trí

### 2. Lỗi vị trí
- Bật GPS trên thiết bị
- Cấp quyền truy cập vị trí
- Kiểm tra cài đặt location services

### 3. Lỗi API
- Kiểm tra kết nối internet
- Thử lại sau vài phút
- Kiểm tra log để debug

## Attribution

- **OpenStreetMap**: © OpenStreetMap contributors
- **Overpass API**: Cung cấp bởi Overpass API community
- **Icons**: Material Design Icons

## Chính sách sử dụng

### 1. Rate Limiting
- Không gọi API quá 1 lần/phút
- Sử dụng cache để giảm requests
- Tôn trọng terms of service của Overpass API

### 2. Privacy
- Vị trí chỉ được sử dụng để tìm rạp
- Không lưu trữ vị trí lâu dài
- Tuân thủ GDPR và các quy định bảo mật

### 3. Data Usage
- Sử dụng dữ liệu OSM miễn phí
- Tuân thủ ODbL license
- Ghi nhận nguồn dữ liệu

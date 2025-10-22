import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/cinema.dart';

class OverpassService {
  final String baseUrl;
  final http.Client _client;
  
  // Danh sách các mirror Overpass API để fallback
  static const List<String> _mirrors = [
    'https://overpass-api.de/api/interpreter',
    'https://z.overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  OverpassService({
    String? baseUrl,
    http.Client? client,
  }) : baseUrl = baseUrl ?? _mirrors.first,
       _client = client ?? http.Client();

  /// Lấy danh sách rạp chiếu phim gần vị trí
  Future<List<Cinema>> fetchCinemas({
    required double lat,
    required double lon,
    int radiusMeters = 10000,
  }) async {
    final query = _buildOverpassQuery(lat, lon, radiusMeters);
    
    // Thử các mirror khác nhau nếu có lỗi
    for (int attempt = 0; attempt < _mirrors.length; attempt++) {
      try {
        final url = _mirrors[attempt];
        final response = await _makeRequest(url, query);
        
        if (response.statusCode == 200) {
          return _parseResponse(response.body);
        } else if (response.statusCode == 429) {
          // Rate limit - đợi một chút rồi thử mirror khác
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        }
      } catch (e) {
        if (attempt == _mirrors.length - 1) {
          rethrow;
        }
        // Thử mirror tiếp theo
        await Future.delayed(Duration(seconds: 1));
      }
    }
    
    throw OverpassException('All Overpass mirrors failed');
  }

  /// Tạo Overpass QL query
  String _buildOverpassQuery(double lat, double lon, int radiusMeters) {
    return '''
[out:json][timeout:25];
(
  node["amenity"="cinema"](around:$radiusMeters,$lat,$lon);
  way["amenity"="cinema"](around:$radiusMeters,$lat,$lon);
  relation["amenity"="cinema"](around:$radiusMeters,$lat,$lon);
);
out center tags;
''';
  }

  /// Gửi request đến Overpass API
  Future<http.Response> _makeRequest(String url, String query) async {
    return await _client.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'FlutterMovieTMDB/1.0 (contact: developer@example.com)',
      },
      body: {'data': query},
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw OverpassException('Request timeout');
      },
    );
  }

  /// Parse response từ Overpass API
  List<Cinema> _parseResponse(String responseBody) {
    try {
      final data = json.decode(responseBody) as Map<String, dynamic>;
      final elements = (data['elements'] as List).cast<Map<String, dynamic>>();
      
      return elements.map((element) => _parseElement(element)).toList();
    } catch (e) {
      throw OverpassException('Failed to parse Overpass response: $e');
    }
  }

  /// Parse một element từ Overpass response
  Cinema _parseElement(Map<String, dynamic> element) {
    final tags = (element['tags'] as Map?)?.cast<String, dynamic>() ?? {};
    final isNode = element['type'] == 'node';
    
    // Lấy tọa độ
    final lat = isNode 
        ? (element['lat'] as num?)?.toDouble() 
        : (element['center']?['lat'] as num?)?.toDouble();
    final lon = isNode 
        ? (element['lon'] as num?)?.toDouble() 
        : (element['center']?['lon'] as num?)?.toDouble();

    // Lấy thông tin cơ bản
    final name = (tags['name'] as String?)?.trim() ?? 'Unnamed cinema';
    final brand = tags['brand'] as String?;
    
    // Ghép địa chỉ từ các trường khác nhau
    final address = _buildAddress(tags);
    
    return Cinema(
      id: '${element['type']}:${element['id']}',
      name: name,
      lat: lat ?? 0.0,
      lon: lon ?? 0.0,
      brand: brand,
      address: address,
      phone: (tags['contact:phone'] ?? tags['phone']) as String?,
      website: tags['website'] as String?,
      openingHours: tags['opening_hours'] as String?,
    );
  }

  /// Ghép địa chỉ từ các trường OSM
  String? _buildAddress(Map<String, dynamic> tags) {
    // Thử lấy địa chỉ đầy đủ trước
    final fullAddress = tags['addr:full'] as String?;
    if (fullAddress != null && fullAddress.isNotEmpty) {
      return fullAddress;
    }
    
    // Ghép từ các trường riêng lẻ
    final parts = <String>[];
    
    final houseNumber = tags['addr:housenumber'] as String?;
    final street = tags['addr:street'] as String?;
    final city = tags['addr:city'] as String?;
    final postcode = tags['addr:postcode'] as String?;
    
    if (houseNumber != null && houseNumber.isNotEmpty) {
      parts.add(houseNumber);
    }
    if (street != null && street.isNotEmpty) {
      parts.add(street);
    }
    if (city != null && city.isNotEmpty) {
      parts.add(city);
    }
    if (postcode != null && postcode.isNotEmpty) {
      parts.add(postcode);
    }
    
    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  void dispose() {
    _client.close();
  }
}

class OverpassException implements Exception {
  final String message;
  OverpassException(this.message);
  
  @override
  String toString() => 'OverpassException: $message';
}

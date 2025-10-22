class Cinema {
  final String id;          // "osm:<type>:<id>"
  final String name;
  final double lat;
  final double lon;
  final String? brand;      // CGV/Lotte/Galaxy/BHD...
  final String? address;
  final String? phone;
  final String? website;
  final String? openingHours;
  final double? distanceMeters; // tính runtime

  const Cinema({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.brand,
    this.address,
    this.phone,
    this.website,
    this.openingHours,
    this.distanceMeters,
  });

  Cinema copyWith({
    String? id,
    String? name,
    double? lat,
    double? lon,
    String? brand,
    String? address,
    String? phone,
    String? website,
    String? openingHours,
    double? distanceMeters,
  }) =>
      Cinema(
        id: id ?? this.id,
        name: name ?? this.name,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        brand: brand ?? this.brand,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        website: website ?? this.website,
        openingHours: openingHours ?? this.openingHours,
        distanceMeters: distanceMeters ?? this.distanceMeters,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lat': lat,
    'lon': lon,
    'brand': brand,
    'address': address,
    'phone': phone,
    'website': website,
    'openingHours': openingHours,
    'distanceMeters': distanceMeters,
  };

  factory Cinema.fromJson(Map<String, dynamic> json) => Cinema(
    id: json['id'] as String,
    name: json['name'] as String,
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
    brand: json['brand'] as String?,
    address: json['address'] as String?,
    phone: json['phone'] as String?,
    website: json['website'] as String?,
    openingHours: json['openingHours'] as String?,
    distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
  );

  @override
  String toString() => 'Cinema(id: $id, name: $name, distance: ${distanceMeters?.toStringAsFixed(0)}m)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cinema &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng($latitude, $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

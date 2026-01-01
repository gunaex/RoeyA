class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? placeName;
  final String? city;
  final String? country;
  final DateTime? takenAt;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeName,
    this.city,
    this.country,
    this.takenAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'place_name': placeName,
      'city': city,
      'country': country,
      'taken_at': takenAt?.toIso8601String(),
    };
  }

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'] as String?,
      placeName: map['place_name'] as String?,
      city: map['city'] as String?,
      country: map['country'] as String?,
      takenAt: map['taken_at'] != null
          ? DateTime.parse(map['taken_at'] as String)
          : null,
    );
  }

  String get fullLocationName {
    final parts = <String>[];
    if (placeName != null && placeName!.isNotEmpty) parts.add(placeName!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    
    if (parts.isEmpty) {
      return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }
    return parts.join(', ');
  }

  LocationData copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? placeName,
    String? city,
    String? country,
    DateTime? takenAt,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      placeName: placeName ?? this.placeName,
      city: city ?? this.city,
      country: country ?? this.country,
      takenAt: takenAt ?? this.takenAt,
    );
  }
}


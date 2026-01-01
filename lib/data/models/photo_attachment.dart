import 'location_data.dart';

class PhotoAttachment {
  final String id;
  final String path;
  final String? thumbnailPath;
  final LocationData? location;
  final DateTime addedAt;

  PhotoAttachment({
    required this.id,
    required this.path,
    this.thumbnailPath,
    this.location,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'thumbnail_path': thumbnailPath,
      'location': location?.toMap(),
      'added_at': addedAt.toIso8601String(),
    };
  }

  factory PhotoAttachment.fromMap(Map<String, dynamic> map) {
    return PhotoAttachment(
      id: map['id'] as String,
      path: map['path'] as String,
      thumbnailPath: map['thumbnail_path'] as String?,
      location: map['location'] != null
          ? LocationData.fromMap(map['location'] as Map<String, dynamic>)
          : null,
      addedAt: DateTime.parse(map['added_at'] as String),
    );
  }

  PhotoAttachment copyWith({
    String? id,
    String? path,
    String? thumbnailPath,
    LocationData? location,
    DateTime? addedAt,
  }) {
    return PhotoAttachment(
      id: id ?? this.id,
      path: path ?? this.path,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      location: location ?? this.location,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}


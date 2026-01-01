import 'dart:io';
import 'dart:typed_data';
import 'package:exif/exif.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:native_exif/native_exif.dart';
import '../../data/models/location_data.dart';
import 'package:flutter/services.dart';

class ExifLocationService {
  static final ExifLocationService instance = ExifLocationService._init();

  static const MethodChannel _gpsChannel = MethodChannel('com.example/gps');
  
  ExifLocationService._init();

  /// Request ACCESS_MEDIA_LOCATION permission (required on Android 10+)
  Future<bool> requestMediaLocationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.accessMediaLocation.status;
      if (status.isGranted) return true;

      final result = await Permission.accessMediaLocation.request();
      print('📍 ACCESS_MEDIA_LOCATION permission: $result');
      return result.isGranted;
    }
    return true; // iOS doesn't need this permission
  }

  /// Request media read permissions (Android 13+ uses READ_MEDIA_IMAGES)
  Future<void> requestMediaReadPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ : READ_MEDIA_IMAGES via Permission.photos
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isDenied || photosStatus.isLimited) {
        final result = await Permission.photos.request();
        print('📍 READ_MEDIA_IMAGES permission: $result');
      } else if (photosStatus.isPermanentlyDenied) {
        print('📍 READ_MEDIA_IMAGES permanently denied. Prompting to open settings.');
        await openAppSettings();
      }

      // Android 12 and below: READ_EXTERNAL_STORAGE fallback
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isDenied || storageStatus.isLimited) {
        final result = await Permission.storage.request();
        print('📍 READ_EXTERNAL_STORAGE permission: $result');
      } else if (storageStatus.isPermanentlyDenied) {
        print('📍 READ_EXTERNAL_STORAGE permanently denied. Prompting to open settings.');
        await openAppSettings();
      }
    }
  }

  /// Extract location data from image EXIF
  Future<LocationData?> extractLocation(File imageFile) async {
    try {
      // Request required permissions first
      await requestMediaReadPermission();
      await requestMediaLocationPermission();
      
      // Read EXIF data
      final bytes = await imageFile.readAsBytes();
      final fromBytes = await extractLocationFromBytes(bytes);
      if (fromBytes != null) {
        return fromBytes;
      }

      // Fallback: use native_exif from file path (handles HEIC/Android 13 picker cases)
      final fromNative = await _extractWithNativeExif(imageFile.path);
      if (fromNative != null) return fromNative;

      // Fallback: MediaStore via platform channel
      return await _extractWithMediaStore(imageFile.path);
    } catch (e) {
      // EXIF extraction failed
      return null;
    }
  }

  /// Extract location data from raw image bytes (useful when file access is limited)
  Future<LocationData?> extractLocationFromBytes(Uint8List bytes) async {
    try {
      // Request required permissions first
      await requestMediaReadPermission();
      await requestMediaLocationPermission();

      final data = await readExifFromBytes(bytes);

      if (data.isEmpty) {
        print('📍 EXIF: No EXIF data found in image');
        return null;
      }

      // Debug: Print all GPS-related tags
      print('📍 EXIF GPS tags found:');
      data.forEach((key, value) {
        if (key.toString().contains('GPS')) {
          print('   $key: ${value.printable} (values: ${value.values})');
        }
      });

      // Extract GPS coordinates
      final gpsLat = data['GPS GPSLatitude'];
      final gpsLatRef = data['GPS GPSLatitudeRef'];
      final gpsLon = data['GPS GPSLongitude'];
      final gpsLonRef = data['GPS GPSLongitudeRef'];

      if (gpsLat == null || gpsLon == null) {
        print('📍 EXIF: No GPS coordinates found');
        return null;
      }

      print('📍 EXIF Raw GPS Latitude: ${gpsLat.printable}');
      print('📍 EXIF Raw GPS Longitude: ${gpsLon.printable}');
      print('📍 EXIF Lat Ref: ${gpsLatRef?.printable}, Lon Ref: ${gpsLonRef?.printable}');

      // Convert GPS coordinates to decimal degrees
      final latitude = _convertToDecimalDegrees(gpsLat.values, gpsLatRef?.printable ?? 'N');
      final longitude = _convertToDecimalDegrees(gpsLon.values, gpsLonRef?.printable ?? 'E');
      
      print('📍 EXIF Converted: lat=$latitude, lon=$longitude');

      // If conversion failed or is 0,0 (Ghana Sea / error), treat as no GPS
      if (latitude == null || longitude == null || (latitude == 0.0 && longitude == 0.0)) {
        return null;
      }

      // Extract date/time
      DateTime? takenAt;
      final dateTime = data['EXIF DateTimeOriginal'] ?? data['Image DateTime'];
      if (dateTime != null) {
        try {
          final dateStr = dateTime.printable;
          // EXIF format: "YYYY:MM:DD HH:MM:SS"
          takenAt = _parseExifDateTime(dateStr);
        } catch (e) {
          // Ignore date parsing errors
        }
      }

      // Get location name from coordinates (reverse geocoding)
      String? address;
      String? placeName;
      String? city;
      String? country;

      try {
        final placemarks = await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          
          // Better city/region detection (crucial for TH)
          city = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea;
          placeName = p.name ?? p.subLocality;
          country = p.country;
          
          // Build comprehensive address
          final addressParts = <String>[];
          if (p.name != null && p.name!.isNotEmpty) addressParts.add(p.name!);
          if (p.street != null && p.street!.isNotEmpty && p.street != p.name) addressParts.add(p.street!);
          if (p.subLocality != null && p.subLocality!.isNotEmpty) addressParts.add(p.subLocality!);
          if (p.locality != null && p.locality!.isNotEmpty && p.locality != p.subLocality) addressParts.add(p.locality!);
          if (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty) addressParts.add(p.subAdministrativeArea!);
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) addressParts.add(p.administrativeArea!);
          if (p.postalCode != null && p.postalCode!.isNotEmpty) addressParts.add(p.postalCode!);
          if (p.country != null && p.country!.isNotEmpty) addressParts.add(p.country!);
          
          address = addressParts.where((s) => s.isNotEmpty).toSet().join(', ');
        }
      } catch (e) {
        // Geocoding failed
      }

      return LocationData(
        latitude: latitude,
        longitude: longitude,
        address: address,
        placeName: placeName,
        city: city,
        country: country,
        takenAt: takenAt,
      );
    } catch (e) {
      // EXIF extraction failed
      return null;
    }
  }

  /// Fallback using native_exif (handles some HEIC / Android picker cases)
  Future<LocationData?> _extractWithNativeExif(String filePath) async {
    Exif? exif;
    try {
      exif = await Exif.fromPath(filePath);
      final latLong = await exif.getLatLong();
      if (latLong == null ||
          latLong.latitude == 0.0 && latLong.longitude == 0.0) {
        print('📍 native_exif: no lat/long or 0,0');
        return null;
      }

      // Date
      DateTime? takenAt;
      final dt = await exif.getAttribute('DateTimeOriginal') ??
          await exif.getAttribute('DateTime');
      if (dt != null) {
        takenAt = _parseExifDateTime(dt);
      }

      // Reverse geocode
      String? address;
      String? placeName;
      String? city;
      String? country;

      try {
        final placemarks = await placemarkFromCoordinates(
          latLong.latitude,
          latLong.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          city = p.locality ?? p.subAdministrativeArea ?? p.administrativeArea;
          placeName = p.name ?? p.subLocality;
          country = p.country;

          final addressParts = <String>[];
          if (p.name != null && p.name!.isNotEmpty) addressParts.add(p.name!);
          if (p.street != null && p.street!.isNotEmpty && p.street != p.name) {
            addressParts.add(p.street!);
          }
          if (p.subLocality != null && p.subLocality!.isNotEmpty) {
            addressParts.add(p.subLocality!);
          }
          if (p.locality != null &&
              p.locality!.isNotEmpty &&
              p.locality != p.subLocality) {
            addressParts.add(p.locality!);
          }
          if (p.subAdministrativeArea != null &&
              p.subAdministrativeArea!.isNotEmpty) {
            addressParts.add(p.subAdministrativeArea!);
          }
          if (p.administrativeArea != null &&
              p.administrativeArea!.isNotEmpty) {
            addressParts.add(p.administrativeArea!);
          }
          if (p.postalCode != null && p.postalCode!.isNotEmpty) {
            addressParts.add(p.postalCode!);
          }
          if (p.country != null && p.country!.isNotEmpty) {
            addressParts.add(p.country!);
          }
          address = addressParts.where((s) => s.isNotEmpty).toSet().join(', ');
        }
      } catch (_) {}

      return LocationData(
        latitude: latLong.latitude,
        longitude: latLong.longitude,
        address: address,
        placeName: placeName,
        city: city,
        country: country,
        takenAt: takenAt,
      );
    } catch (e) {
      print('📍 native_exif error: $e');
      return null;
    } finally {
      await exif?.close();
    }
  }

  /// Fallback using MediaStore (platform channel)
  Future<LocationData?> _extractWithMediaStore(String filePath) async {
    try {
      final uri = Uri.file(filePath).toString();
      final result = await _gpsChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getMediaStoreGps',
        {'uri': uri},
      );
      if (result == null) return null;
      final lat = (result['lat'] as num?)?.toDouble();
      final lon = (result['lon'] as num?)?.toDouble();
      if (lat == null || lon == null) return null;
      if (lat == 0.0 && lon == 0.0) return null;
      return LocationData(
        latitude: lat,
        longitude: lon,
        takenAt: null,
      );
    } catch (e) {
      print('📍 MediaStore GPS error: $e');
      return null;
    }
  }

  /// Convert GPS coordinates from EXIF format to decimal degrees
  /// EXIF GPS coordinates are stored as [degrees, minutes, seconds] with each as a Ratio
  double? _convertToDecimalDegrees(dynamic values, String ref) {
    try {
      if (values == null) return null;
      
      print('📍 Converting GPS values: $values (type: ${values.runtimeType})');
      
      List<double> parts = [];
      
      // The exif package returns IfdRatios which needs special handling
      // IfdRatios.toString() returns "[deg, min, sec/denom]" format
      // We need to parse the string representation
      final valuesStr = values.toString();
      print('📍 Values as string: $valuesStr');
      
      // Parse the string representation: "[13, 44, 2723/10000]"
      if (valuesStr.startsWith('[') && valuesStr.endsWith(']')) {
        // Remove brackets and split by comma
        final innerStr = valuesStr.substring(1, valuesStr.length - 1);
        final components = innerStr.split(',').map((s) => s.trim()).toList();
        
        print('📍 Components: $components');
        
        for (final component in components) {
          final doubleValue = _parseRatioOrNumber(component);
          if (doubleValue != null) {
            parts.add(doubleValue);
          }
        }
      } else {
        // Single value - try to parse directly
        final doubleValue = _parseRatioOrNumber(valuesStr);
        if (doubleValue != null) {
          parts.add(doubleValue);
        }
      }

      print('📍 Parsed GPS parts: $parts');

      if (parts.isEmpty) {
        print('📍 Failed to parse any GPS coordinate parts');
        return null;
      }

      // Calculate decimal degrees based on available parts
      // Format: [degrees, minutes, seconds] -> decimal degrees
      double decimal = 0.0;
      if (parts.length >= 1) decimal += parts[0];           // degrees
      if (parts.length >= 2) decimal += parts[1] / 60.0;    // minutes to degrees
      if (parts.length >= 3) decimal += parts[2] / 3600.0;  // seconds to degrees

      // Apply hemisphere reference (N/S, E/W)
      final cleanRef = ref.trim().toUpperCase();
      if (cleanRef == 'S' || cleanRef == 'W') {
        decimal = -decimal;
      }

      print('📍 Final decimal degrees: $decimal (ref: $cleanRef)');
      return decimal;
    } catch (e) {
      print('❌ Error converting EXIF coordinates: $e');
      return null;
    }
  }

  /// Parse a Ratio string or number to double
  /// Handles formats like: "13", "44", "2723/10000"
  double? _parseRatioOrNumber(dynamic item) {
    if (item == null) return null;
    
    // Handle numeric types directly
    if (item is num) {
      return item.toDouble();
    }
    
    final itemStr = item.toString().trim();
    if (itemStr.isEmpty) return null;
    
    // Handle Ratio format: "numerator/denominator"
    if (itemStr.contains('/')) {
      final ratioParts = itemStr.split('/');
      if (ratioParts.length == 2) {
        final numerator = double.tryParse(ratioParts[0].trim());
        final denominator = double.tryParse(ratioParts[1].trim());
        if (numerator != null && denominator != null && denominator != 0) {
          return numerator / denominator;
        }
      }
    } else {
      // Try to parse as plain number (integer or double)
      return double.tryParse(itemStr);
    }
    
    return null;
  }

  /// Parse EXIF date/time format: "YYYY:MM:DD HH:MM:SS"
  DateTime? _parseExifDateTime(String exifDateTime) {
    try {
      final parts = exifDateTime.split(' ');
      if (parts.length != 2) return null;

      final dateParts = parts[0].split(':');
      final timeParts = parts[1].split(':');

      if (dateParts.length != 3 || timeParts.length != 3) return null;

      return DateTime(
        int.parse(dateParts[0]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[2]), // day
        int.parse(timeParts[0]), // hour
        int.parse(timeParts[1]), // minute
        int.parse(timeParts[2]), // second
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if image has GPS data
  Future<bool> hasGpsData(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final data = await readExifFromBytes(bytes);

      return data['GPS GPSLatitude'] != null && data['GPS GPSLongitude'] != null;
    } catch (e) {
      return false;
    }
  }

  /// Get location name from coordinates (reverse geocoding)
  Future<String?> getLocationName(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        
        final parts = <String>[];
        if (placemark.name != null && placemark.name!.isNotEmpty) {
          parts.add(placemark.name!);
        }
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          parts.add(placemark.locality!);
        }
        if (placemark.country != null && placemark.country!.isNotEmpty) {
          parts.add(placemark.country!);
        }
        
        return parts.isEmpty ? null : parts.join(', ');
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}


import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class PhotoService {
  static final PhotoService instance = PhotoService._init();
  
  PhotoService._init();

  static const int maxPhotos = 5;
  static const int thumbnailSize = 200;
  static const int imageQuality = 80;

  /// Get the directory for storing transaction photos
  Future<Directory> _getPhotosDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Photo storage not supported on web');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(path.join(appDir.path, 'transaction_photos'));
    
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    
    return photosDir;
  }

  /// Get the directory for storing thumbnails
  Future<Directory> _getThumbnailsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final thumbsDir = Directory(path.join(appDir.path, 'thumbnails'));
    
    if (!await thumbsDir.exists()) {
      await thumbsDir.create(recursive: true);
    }
    
    return thumbsDir;
  }

  /// Save a photo and generate thumbnail
  Future<Map<String, String>> savePhoto(File imageFile) async {
    try {
      final photosDir = await _getPhotosDirectory();
      final thumbsDir = await _getThumbnailsDirectory();
      
      // Generate unique filename
      final fileName = '${const Uuid().v4()}${path.extension(imageFile.path)}';
      final photoPath = path.join(photosDir.path, fileName);
      final thumbPath = path.join(thumbsDir.path, 'thumb_$fileName');

      // Read and decode image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Compress and save original
      final compressedImage = img.encodeJpg(image, quality: imageQuality);
      await File(photoPath).writeAsBytes(compressedImage);

      // Generate and save thumbnail
      final thumbnail = img.copyResize(
        image,
        width: thumbnailSize,
        height: thumbnailSize,
        interpolation: img.Interpolation.average,
      );
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 85);
      await File(thumbPath).writeAsBytes(thumbnailBytes);

      return {
        'path': photoPath,
        'thumbnailPath': thumbPath,
      };
    } catch (e) {
      throw Exception('Failed to save photo: $e');
    }
  }

  /// Delete a photo and its thumbnail
  Future<void> deletePhoto(String photoPath, String? thumbnailPath) async {
    try {
      final photoFile = File(photoPath);
      if (await photoFile.exists()) {
        await photoFile.delete();
      }

      if (thumbnailPath != null) {
        final thumbFile = File(thumbnailPath);
        if (await thumbFile.exists()) {
          await thumbFile.delete();
        }
      }
    } catch (e) {
      // Log error but don't throw - file might already be deleted
      debugPrint('Error deleting photo: $e');
    }
  }

  /// Delete all photos for a transaction
  Future<void> deleteTransactionPhotos(List<String> photoPaths, List<String?> thumbnailPaths) async {
    for (int i = 0; i < photoPaths.length; i++) {
      await deletePhoto(
        photoPaths[i],
        i < thumbnailPaths.length ? thumbnailPaths[i] : null,
      );
    }
  }

  /// Get file size in MB
  Future<double> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.length();
      return bytes / (1024 * 1024); // Convert to MB
    } catch (e) {
      return 0;
    }
  }

  /// Get total storage used by photos
  Future<double> getTotalStorageUsed() async {
    try {
      final photosDir = await _getPhotosDirectory();
      final thumbsDir = await _getThumbnailsDirectory();
      
      double total = 0;
      
      if (await photosDir.exists()) {
        final photoFiles = photosDir.listSync();
        for (final file in photoFiles) {
          if (file is File) {
            total += await file.length();
          }
        }
      }
      
      if (await thumbsDir.exists()) {
        final thumbFiles = thumbsDir.listSync();
        for (final file in thumbFiles) {
          if (file is File) {
            total += await file.length();
          }
        }
      }
      
      return total / (1024 * 1024); // Convert to MB
    } catch (e) {
      return 0;
    }
  }

  /// Clean up orphaned photos (photos not referenced in database)
  Future<int> cleanupOrphanedPhotos(Set<String> referencedPaths) async {
    try {
      int deletedCount = 0;
      final photosDir = await _getPhotosDirectory();
      final thumbsDir = await _getThumbnailsDirectory();
      
      // Check photos directory
      if (await photosDir.exists()) {
        final files = photosDir.listSync();
        for (final file in files) {
          if (file is File && !referencedPaths.contains(file.path)) {
            await file.delete();
            deletedCount++;
          }
        }
      }
      
      // Check thumbnails directory
      if (await thumbsDir.exists()) {
        final files = thumbsDir.listSync();
        for (final file in files) {
          if (file is File) {
            // Extract original filename from thumbnail
            final fileName = path.basename(file.path).replaceFirst('thumb_', '');
            final originalPath = path.join(photosDir.path, fileName);
            
            if (!await File(originalPath).exists()) {
              await file.delete();
              deletedCount++;
            }
          }
        }
      }
      
      return deletedCount;
    } catch (e) {
      debugPrint('Error cleaning up photos: $e');
      return 0;
    }
  }
}


import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/exif_location_service.dart';
import '../../core/services/photo_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/photo_attachment.dart';
import '../../data/models/location_data.dart';

class PhotoAttachmentWidget extends StatefulWidget {
  final List<PhotoAttachment> photos;
  final Function(List<PhotoAttachment>) onPhotosChanged;
  final int maxPhotos;
  final bool readOnly;

  const PhotoAttachmentWidget({
    super.key,
    required this.photos,
    required this.onPhotosChanged,
    this.maxPhotos = 5,
    this.readOnly = false,
  });

  @override
  State<PhotoAttachmentWidget> createState() => _PhotoAttachmentWidgetState();
}

class _PhotoAttachmentWidgetState extends State<PhotoAttachmentWidget> {
  final ImagePicker _picker = ImagePicker();
  final PhotoService _photoService = PhotoService.instance;
  final ExifLocationService _exifService = ExifLocationService.instance;
  
  bool _isProcessing = false;

  /// Pick image from camera using image_picker
  Future<void> _pickFromCamera() async {
    if (widget.photos.length >= widget.maxPhotos) {
      _showMaxPhotosDialog();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) {
        setState(() => _isProcessing = false);
        return;
      }

      await _processAndAddPhoto(File(image.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Pick image from gallery using file_picker (preserves EXIF GPS on Android 13+)
  /// Android 13+ Photo Picker strips GPS data, but file_picker bypasses it
  Future<void> _pickFromGallery() async {
    if (widget.photos.length >= widget.maxPhotos) {
      _showMaxPhotosDialog();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Use file_picker instead of image_picker for gallery
      // This bypasses Android 13+ Photo Picker which strips EXIF GPS data
      await _exifService.requestMediaReadPermission();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // so we can read EXIF without needing file permissions
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }

      final file = result.files.single;
      final filePath = file.path;
      if (filePath == null) {
        setState(() => _isProcessing = false);
        return;
      }

      await _processAndAddPhoto(File(filePath), bytes: file.bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Process the picked image file: save, extract EXIF, create attachment
  Future<void> _processAndAddPhoto(File imageFile, {Uint8List? bytes}) async {
    // Extract location from EXIF BEFORE any processing (to preserve original data)
    var location = bytes != null
        ? await _exifService.extractLocationFromBytes(bytes)
        : await _exifService.extractLocation(imageFile);
    
    // If no EXIF GPS found, automatically use current device location (no popup)
    if (location == null) {
      location = await _getCurrentLocation();
    }

    // Save photo and generate thumbnail
    final paths = await _photoService.savePhoto(imageFile);

    // Create photo attachment
    final photo = PhotoAttachment(
      id: const Uuid().v4(),
      path: paths['path']!,
      thumbnailPath: paths['thumbnailPath'],
      location: location,
      addedAt: DateTime.now(),
    );

    final updatedPhotos = List<PhotoAttachment>.from(widget.photos)..add(photo);
    widget.onPhotosChanged(updatedPhotos);

    if (mounted && location != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Location: ${location.fullLocationName}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Get current device GPS location silently (no popup)
  Future<LocationData?> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('📍 Location services are disabled');
        return null;
      }

      // Check/request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('📍 Location permission denied');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('📍 Location permission permanently denied');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      
      print('📍 Using current location: ${position.latitude}, ${position.longitude}');
      
      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      print('📍 Error getting current location: $e');
      return null;
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              subtitle: const Text('Full quality with GPS location'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMaxPhotosDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maximum Photos Reached'),
        content: Text('You can attach up to ${widget.maxPhotos} photos per transaction.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _deletePhoto(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final photo = widget.photos[index];
              final updatedPhotos = List<PhotoAttachment>.from(widget.photos)
                ..removeAt(index);
              widget.onPhotosChanged(updatedPhotos);

              // Delete files
              await _photoService.deletePhoto(photo.path, photo.thumbnailPath);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewPhoto(PhotoAttachment photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PhotoViewScreen(photo: photo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Photos (${widget.photos.length}/${widget.maxPhotos})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.photos.isNotEmpty) ...[
              const Spacer(),
              Text(
                '📍 ${widget.photos.where((p) => p.location != null).length} with location',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                    ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        
        if (_isProcessing)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: widget.photos.length + (widget.photos.length < widget.maxPhotos && !widget.readOnly ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == widget.photos.length) {
                return _buildAddPhotoButton();
              }
              return _buildPhotoTile(widget.photos[index], index);
            },
          ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _showImageSourceDialog,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate, size: 32, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoTile(PhotoAttachment photo, int index) {
    return Stack(
      children: [
        InkWell(
          onTap: () => _viewPhoto(photo),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(photo.thumbnailPath ?? photo.path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.surfaceDark,
                    child: const Icon(Icons.broken_image, color: AppColors.textHint),
                  );
                },
              ),
            ),
          ),
        ),
        
        // Location indicator
        if (photo.location != null)
          const Positioned(
            top: 4,
            left: 4,
            child: Icon(
              Icons.location_on,
              color: AppColors.success,
              size: 20,
              shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
            ),
          ),
        
        // Delete button
        if (!widget.readOnly)
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _deletePhoto(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }
}

// Photo view screen for full-size preview
class _PhotoViewScreen extends StatelessWidget {
  final PhotoAttachment photo;

  const _PhotoViewScreen({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: photo.location != null
            ? Text(photo.location!.fullLocationName)
            : const Text('Photo'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(photo.path),
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image, color: Colors.white, size: 64);
            },
          ),
        ),
      ),
      bottomNavigationBar: photo.location != null
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          photo.location!.fullLocationName,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  if (photo.location!.address != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      photo.location!.address!,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ],
              ),
            )
          : null,
    );
  }
}


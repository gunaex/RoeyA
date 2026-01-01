import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/exif_location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/location_data.dart';
import '../../../data/models/photo_attachment.dart';
import 'package:uuid/uuid.dart';

class BrowseSlipsScreen extends StatefulWidget {
  const BrowseSlipsScreen({super.key});

  @override
  State<BrowseSlipsScreen> createState() => _BrowseSlipsScreenState();
}

class _BrowseSlipsScreenState extends State<BrowseSlipsScreen> {
  List<SlipCandidate> _slipCandidates = [];
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Saved Slips'),
        actions: [
          if (_slipCandidates.isNotEmpty)
            TextButton.icon(
              onPressed: _continueWithSelected,
              icon: const Icon(Icons.check),
              label: Text('Continue (${_getSelectedCount()})'),
            ),
        ],
      ),
      body: _isScanning
          ? _buildScanningView()
          : _slipCandidates.isEmpty
              ? _buildEmptyView(l10n)
              : _buildSlipList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickMultipleImages,
        icon: const Icon(Icons.photo_library),
        label: const Text('Select Images'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _pickMultipleImages() async {
    setState(() => _isScanning = true);

    try {
      // Use file_picker instead of image_picker to preserve EXIF GPS data
      // Android 13+ Photo Picker strips GPS data, but file_picker bypasses it
      await ExifLocationService.instance.requestMediaReadPermission();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true, // read EXIF from bytes if file access is blocked
      );
      
      if (result == null || result.files.isEmpty) {
        setState(() => _isScanning = false);
        return;
      }

      List<SlipCandidate> candidates = [];

      for (final file in result.files) {
        if (file.path == null) continue;
        
        // Extract EXIF data for location and timestamp
        final imageFile = File(file.path!);
        final locationData = file.bytes != null
            ? await ExifLocationService.instance.extractLocationFromBytes(file.bytes!)
            : await ExifLocationService.instance.extractLocation(imageFile);
        
        // Create candidate
        final candidate = SlipCandidate(
          id: const Uuid().v4(),
          imagePath: file.path!,
          fileName: file.name,
          dateTime: locationData?.takenAt ?? DateTime.now(),
          location: locationData,
          isSelected: false, // User selects what they want
        );
        
        candidates.add(candidate);
      }

      setState(() {
        _slipCandidates = candidates;
        _isScanning = false;
      });

      if (mounted) {
        final withLocation = candidates.where((c) => c.location != null).length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Found ${candidates.length} image(s), $withLocation with GPS location'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  int _getSelectedCount() {
    return _slipCandidates.where((s) => s.isSelected).length;
  }

  void _continueWithSelected() {
    final selected = _slipCandidates.where((s) => s.isSelected).toList();
    
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select one slip to continue'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (selected.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select only one slip to scan'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Route to Scan Slip OCR screen with the selected image path
    Navigator.pushNamed(
      context,
      AppConstants.routeScanSlip,
      arguments: selected.first.imagePath,
    );
  }

  Widget _buildScanningView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Scanning images...'),
          SizedBox(height: 8),
          Text(
            'Extracting location data...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Browse Saved Slips',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select transfer slip images saved on your phone by Thai banking apps (SCB, Kbank, Bangkok Bank, etc.)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: AppColors.info, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'How it works:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem('1. Tap button below to select images'),
                  _buildInfoItem('2. Choose up to 5 slip photos'),
                  _buildInfoItem('3. Location data extracted automatically'),
                  _buildInfoItem('4. Continue to manual entry'),
                  _buildInfoItem('5. Edit details and save!'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlipList() {
    return Column(
      children: [
        // Info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: AppColors.info.withOpacity(0.1),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Select up to 5 slips for this transaction. Location data will be extracted automatically.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        
        // Slip list
        Expanded(
          child: ListView.builder(
            itemCount: _slipCandidates.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final slip = _slipCandidates[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  value: slip.isSelected,
                  onChanged: (value) {
                    setState(() {
                      _slipCandidates[index] = slip.copyWith(isSelected: value ?? false);
                    });
                  },
                  title: Text(
                    slip.fileName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${slip.dateTime.day}/${slip.dateTime.month}/${slip.dateTime.year}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        if (slip.location != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: AppColors.success),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  slip.location!.fullLocationName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.success,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  secondary: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: slip.isSelected ? AppColors.primary : AppColors.border,
                        width: slip.isSelected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.file(
                        File(slip.imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Helper model for slip candidates
class SlipCandidate {
  final String id;
  final String imagePath;
  final String fileName;
  final DateTime dateTime;
  final LocationData? location;
  final bool isSelected;

  SlipCandidate({
    required this.id,
    required this.imagePath,
    required this.fileName,
    required this.dateTime,
    this.location,
    required this.isSelected,
  });

  SlipCandidate copyWith({
    String? id,
    String? imagePath,
    String? fileName,
    DateTime? dateTime,
    LocationData? location,
    bool? isSelected,
  }) {
    return SlipCandidate(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      fileName: fileName ?? this.fileName,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}


import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/thai_qr_parser.dart';

/// QR Scanner Service
/// รองรับ 2 โหมด: Gallery และ Camera (real-time ใช้ใน Widget แทน)
class QrScannerService {
  static final QrScannerService instance = QrScannerService._init();
  QrScannerService._init();

  final ImagePicker _picker = ImagePicker();
  final BarcodeScanner _scanner = BarcodeScanner(
    formats: [BarcodeFormat.qrCode],
  );

  /// Scan QR from Gallery Image
  Future<SlipTransactionQr?> scanFromGallery() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return null;

      return await _scanFromImagePath(picked.path);
    } catch (e) {
      print('❌ scanFromGallery error: $e');
      return null;
    }
  }

  /// Scan QR from Camera
  Future<SlipTransactionQr?> scanFromCamera() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked == null) return null;

      return await _scanFromImagePath(picked.path);
    } catch (e) {
      print('❌ scanFromCamera error: $e');
      return null;
    }
  }

  /// Scan QR from existing image path
  Future<SlipTransactionQr?> scanFromImagePath(String imagePath) async {
    return await _scanFromImagePath(imagePath);
  }

  /// Internal: Scan QR from image path
  Future<SlipTransactionQr?> _scanFromImagePath(String path) async {
    try {
      print('📸 Scanning image: $path');
      
      final inputImage = InputImage.fromFilePath(path);
      final barcodes = await _scanner.processImage(inputImage);

      print('🔍 Found ${barcodes.length} barcodes');

      if (barcodes.isEmpty) {
        print('❌ No QR code found in image');
        return null;
      }

      // Try each barcode until we find a valid Thai QR Payment
      for (final barcode in barcodes) {
        final rawValue = barcode.rawValue;
        if (rawValue == null || rawValue.isEmpty) {
          print('⚠️ Barcode has no value');
          continue;
        }

        print('📱 QR Raw (${rawValue.length} chars): ${rawValue.substring(0, rawValue.length > 100 ? 100 : rawValue.length)}...');
        print('📱 QR Type: ${barcode.type}');
        print('📱 QR Format: ${barcode.format}');

        final transaction = ThaiQrParser.parse(rawValue);
        if (transaction != null) {
          print('✅ Valid Thai QR Payment found!');
          print('   Amount: ${transaction.amount}');
          print('   Reference: ${transaction.reference}');
          print('   Bank: ${getBankLabel(transaction.bank)}');
          return transaction;
        } else {
          print('❌ Not a valid Thai QR Payment - trying next...');
        }
      }

      print('❌ No valid Thai QR Payment found in any barcode');
      return null;
    } catch (e, stackTrace) {
      print('❌ _scanFromImagePath error: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _scanner.close();
  }
}


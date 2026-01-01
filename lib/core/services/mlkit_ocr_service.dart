import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../data/models/slip_data.dart';
import '../utils/thai_qr_parser.dart';
import 'qr_scanner_service.dart';

/// ML Kit OCR Service (ใช้ร่วมกับ QR Scanner)
/// ✅ QR Code = แหล่งข้อมูลหลัก (amount, reference)
/// ⚠️ OCR = ใช้เสริมเท่านั้น (ชื่อ, เวลา)
class MlKitOcrService {
  static final MlKitOcrService instance = MlKitOcrService._init();
  MlKitOcrService._init();

  // ใช้ TextRecognizer แบบไม่ระบุ script เพื่อให้ auto-detect ทุกภาษา รวมภาษาไทย
  final TextRecognizer _textRecognizer = TextRecognizer();
  final QrScannerService _qrScanner = QrScannerService.instance;

  /// Scan slip แบบครบถ้วน: QR + OCR
  /// ✅ QR = reference, bank (ถ้ามี amount ก็เอา)
  /// ✅ OCR = amount (ถ้า QR ไม่มี), ชื่อ, เวลา
  Future<SlipData> scanSlip(File imageFile) async {
    try {
      print('🔍 Scanning slip: ${imageFile.path}');

      // 1. สแกน QR CODE ก่อน
      final qrResult = await _qrScanner.scanFromImagePath(imageFile.path);

      // 2. Run OCR เสมอ (เพื่ออ่าน amount, ชื่อ, เวลา)
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;

      print('📝 OCR Text (${rawText.length} chars)');

      // 3. Extract ข้อมูลจาก OCR
      final String? transactionDate = _extractDate(rawText);
      final String? transactionTime = _extractTime(rawText);
      final String? fromAccount = _extractFrom(rawText);
      final String? toAccount = _extractTo(rawText);
      final double? amountFromOcr = _extractAmountFromOcr(rawText);

      print('📅 Date: $transactionDate');
      print('🕐 Time: $transactionTime');
      print('👤 From: $fromAccount');
      print('👤 To: $toAccount');
      print('💰 Amount (OCR): $amountFromOcr');

      // 4. สร้าง SlipData โดยใช้ QR + OCR
      if (qrResult != null) {
        // มี QR - ใช้ reference จาก QR, amount จาก QR หรือ OCR
        print('✅ QR found:');
        print('   Amount (QR): ${qrResult.amount}');
        print('   Reference (QR): ${qrResult.reference}');
        print('   Bank (QR): ${getBankLabel(qrResult.bank)}');

        final finalAmount = qrResult.amount ?? amountFromOcr;
        
        if (finalAmount == null) {
          print('⚠️ No amount found in QR or OCR');
        }

        return SlipData(
          // QR Data
          amount: finalAmount, // Set both for UI
          amountFromQr: finalAmount, 
          referenceFromQr: qrResult.reference,
          bankFromQr: qrResult.bank,
          rawQr: qrResult.rawQr,
          // OCR Data
          transactionDate: transactionDate,
          transactionTime: transactionTime,
          fromAccount: fromAccount,
          toAccount: toAccount,
          rawText: rawText,
          // Metadata
          confidence: finalAmount != null ? 1.0 : 0.5,
        );
      } else {
        // ไม่มี QR - ใช้ OCR อย่างเดียว
        print('⚠️ No QR found - using OCR only');
        
        return SlipData(
          // OCR Data
          amount: amountFromOcr, // Set both for UI
          amountFromQr: amountFromOcr,
          transactionDate: transactionDate,
          transactionTime: transactionTime,
          fromAccount: fromAccount,
          toAccount: toAccount,
          rawText: rawText,
          // Metadata
          confidence: amountFromOcr != null ? 0.7 : 0.3,
        );
      }
    } catch (e) {
      print('❌ scanSlip error: $e');
      return SlipData(
        confidence: 0.0,
        rawText: 'Error: $e',
      );
    }
  }

  // === OCR HELPERS ===

  /// Extract amount from OCR text
  double? _extractAmountFromOcr(String text) {
    print('🔍 Extracting amount from OCR text...');
    
    // Normalize text: 
    // 1. Convert various symbols to standard ones
    // 2. Remove space between digits and decimal point if ML Kit split them
    final normalizedText = text.replaceAll(' ,', ',').replaceAll(', ', ',');

    // Higher priority keywords (Transfer specific)
    final patterns = [
      // Pattern 1: Labels followed by Amount + Baht (Thai)
      RegExp(r'(?:จำนวนเงิน|จำนวนเงินโอน|ยอดเงิน|ยอดเงินโอน|เงินโอน)[:\s]*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*(?:บาท|บ\.|THB)', multiLine: true),
      // Pattern 2: Labels followed by Amount (English)
      RegExp(r'(?:Amount|Net Amount|Total|Transfer Amount)[:\s]*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)\s*(?:Baht|THB|B\.)', caseSensitive: false, multiLine: true),
      // Pattern 3: Amount + Baht (No label)
      RegExp(r'(\d{1,3}(?:,\d{3})+(?:\.\d{2})?)\s*(?:บาท|บ\.|Baht|THB)', multiLine: true),
      // Pattern 4: Label then amount without "Baht"
      RegExp(r'(?:จำนวนเงิน[:\s]|Amount[:\s])\s*(\d{1,3}(?:,\d{3})+(?:\.\d{2})?)', multiLine: true),
      // Pattern 5: Small amounts with decimals and "บาท"
      RegExp(r'(\d+\.\d{2})\s*(?:บาท|บ\.|Baht|THB)', multiLine: true),
      // Pattern 6: Large numbers with commas followed by common end-of-slip markers
      RegExp(r'(\d{1,3}(?:,\d{3})+\.\d{2})'),
      // Pattern 7: Any large number matching amount format if nothing else found
      RegExp(r'(\d{1,3}(?:,\d{3})+\.\d{2})'),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final pattern = patterns[i];
      final matches = pattern.allMatches(normalizedText);
      
      for (final match in matches) {
        final group = match.groupCount >= 1 ? match.group(1) : match.group(0);
        if (group == null) continue;

        final amountStr = group.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        
        if (amount != null && amount > 0 && amount < 10000000) {
          // Additional validation: Slips usually don't have amounts like 2024 (year)
          if (amount == 2566 || amount == 2567 || amount == 2023 || amount == 2024 || amount == 2025) {
            continue; 
          }
          print('✅ Amount found via OCR (pattern ${i + 1}): $amount');
          return amount;
        }
      }
    }

    // Last resort: If we find a number like "123.45" at the end of the text (common for K+)
    final lines = normalizedText.split('\n');
    for (final line in lines.reversed) {
      final match = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})+)').firstMatch(line);
      if (match != null) {
        final amount = double.tryParse(match.group(1)!.replaceAll(',', ''));
        if (amount != null && amount > 1.0 && amount < 1000000) {
           print('✅ Amount found in last lines (heuristic): $amount');
           return amount;
        }
      }
    }

    print('❌ No amount found in OCR text');
    return null;
  }

  String? _extractDate(String text) {
    // วันที่: 25/10/2566 หรือ 25-10-2566
    final patterns = [
      // Pattern 1: 25/10/2566 หรือ 25-10-2566
      RegExp(r'(\d{1,2}[/\-]\d{1,2}[/\-]\d{4})'),
      // Pattern 2: 28 ม.ค. 2567 (เดือนไทยแบบย่อ 4 หลัก)
      RegExp(r'(\d{1,2}\s(?:ม\.ค\.|ก\.พ\.|มี\.ค\.|เม\.ย\.|พ\.ค\.|มิ\.ย\.|ก\.ค\.|ส\.ค\.|ก\.ย\.|ต\.ค\.|พ\.ย\.|ธ\.ค\.)\s\d{4})'),
      // Pattern 3: 28 ม.ค. 67 (เดือนไทยแบบย่อ 2 หลัก)
      RegExp(r'(\d{1,2}\s(?:ม\.ค\.|ก\.พ\.|มี\.ค\.|เม\.ย\.|พ\.ค\.|มิ\.ย\.|ก\.ค\.|ส\.ค\.|ก\.ย\.|ต\.ค\.|พ\.ย\.|ธ\.ค\.)\s\d{2})'),
      // Pattern 4: 28 n.A. 67 (OCR อ่านอักษรไทยผิด - จับเลข + ช่องว่าง + อักษร 2-5 ตัว + ช่องว่าง + เลข 2-4 ตัว)
      RegExp(r'(\d{1,2}\s[A-Za-zก-๙\.]+\s\d{2,4})'),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final match = patterns[i].firstMatch(text);
      if (match != null) {
        var date = match.group(1);
        print('✅ Date found via OCR (pattern ${i + 1}): $date');
        
        // แปลงปี 2 หลักเป็น 4 หลัก (67 -> 2567)
        // ตัวอย่าง: "28 n.A. 67" -> "28 n.A. 2567"
        if (date != null) {
          final yearMatch = RegExp(r'\s(\d{2})$').firstMatch(date);
          if (yearMatch != null) {
            final shortYear = yearMatch.group(1)!;
            final fullYear = '25$shortYear'; // 67 -> 2567
            date = date.replaceFirst(RegExp(r'\s\d{2}$'), ' $fullYear');
            print('   📅 Converted year: $shortYear -> $fullYear');
            print('   📅 Final date: $date');
          }
        }
        
        return date;
      }
    }
    print('❌ No date found in OCR text');
    return null;
  }

  String? _extractTime(String text) {
    // เวลา: 14:30:45 หรือ 14:30
    final pattern = RegExp(r'(\d{1,2}:\d{2}(?::\d{2})?)');
    final match = pattern.firstMatch(text);
    return match?.group(1);
  }

  String? _extractFrom(String text) {
    // ชื่อผู้โอน: หลัง "จาก" หรือ "From"
    final patterns = [
      RegExp(r'จาก[:\s]+([^\n]+)', multiLine: true),
      RegExp(r'From[:\s]+([^\n]+)', caseSensitive: false, multiLine: true),
      RegExp(r'ผู้โอน[:\s]+([^\n]+)', multiLine: true),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  String? _extractTo(String text) {
    // ชื่อผู้รับ: หลัง "ถึง" หรือ "To"
    final patterns = [
      RegExp(r'ถึง[:\s]+([^\n]+)', multiLine: true),
      RegExp(r'To[:\s]+([^\n]+)', caseSensitive: false, multiLine: true),
      RegExp(r'ผู้รับ[:\s]+([^\n]+)', multiLine: true),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

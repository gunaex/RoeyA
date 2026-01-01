import '../../core/utils/thai_qr_parser.dart';
import 'location_data.dart';

/// Slip Data Model - ใช้ QR เป็นหลัก, OCR เสริม
/// ✅ QR Code = แหล่งข้อมูลหลักสำหรับ amount และ reference
/// ⚠️ OCR = ใช้เสริมเท่านั้น (ชื่อ, เวลา, ข้อความ)
class SlipData {
  // === QR DATA (เชื่อถือได้ 100%) ===
  final double? amount; // Amount (from manual input or QR) ✅
  final double? amountFromQr; // จาก QR เท่านั้น 
  final String? referenceFromQr; // จาก QR เท่านั้น ✅
  final BankCode? bankFromQr; // จาก QR เท่านั้น ✅
  final String? rawQr; // QR code raw data
  
  // === OCR DATA (ใช้แสดงผลเท่านั้น) ===
  final String? transactionDate; // จาก OCR (DD/MM/YYYY)
  final String? transactionTime; // จาก OCR (HH:MM)
  final String? fromAccount; // จาก OCR (display only)
  final String? toAccount; // จาก OCR (display only)
  final String? rawText; // Raw text from OCR
  
  // === OTHER ===
  final LocationData? location; // ตำแหน่งจาก GPS/EXIF
  final double confidence; // Confidence score
  final bool isManualComplete; // Manually marked as complete

  SlipData({
    // QR Data
    this.amount,
    this.amountFromQr,
    this.referenceFromQr,
    this.bankFromQr,
    this.rawQr,
    // OCR Data
    this.transactionDate,
    this.transactionTime,
    this.fromAccount,
    this.toAccount,
    this.rawText,
    // Other
    this.location,
    this.confidence = 0.8,
    this.isManualComplete = false,
  });

  /// ✅ Get reference (จาก QR เท่านั้น)
  String? get referenceNo => referenceFromQr;

  /// ✅ Get bank name (จาก QR เท่านั้น)
  String? get bankName => bankFromQr != null ? getBankLabel(bankFromQr!) : null;

  /// วันที่เวลาแบบรวม
  String? get fullDateTime {
    if (transactionDate == null) return null;
    if (transactionTime == null) return transactionDate;
    return '$transactionDate $transactionTime';
  }

  /// ตรวจสอบว่าข้อมูลครบถ้วนหรือไม่
  bool get isComplete {
    final effectiveAmount = amount ?? amountFromQr;
    return isManualComplete || (effectiveAmount != null &&
        effectiveAmount > 0 &&
        referenceFromQr != null);
  }

  /// ตรวจสอบว่าข้อมูลน่าเชื่อถือหรือไม่
  bool get isReliable {
    return isComplete && confidence >= 0.7;
  }

  /// ❌ Fee - ไม่ใช้แล้ว (เพราะไม่สามารถอ่านจาก QR ได้อย่างแม่นยำ)
  double? get fee => null;

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'amount_from_qr': amountFromQr,
      'reference_from_qr': referenceFromQr,
      'bank_from_qr': bankFromQr?.toString(),
      'raw_qr': rawQr,
      'transaction_date': transactionDate,
      'transaction_time': transactionTime,
      'from_account': fromAccount,
      'to_account': toAccount,
      'raw_text': rawText,
      'location': location?.toMap(),
      'confidence': confidence,
      'is_manual_complete': isManualComplete ? 1 : 0,
    };
  }

  factory SlipData.fromMap(Map<String, dynamic> map) {
    return SlipData(
      amount: map['amount'] != null ? (map['amount'] as num).toDouble() : null,
      amountFromQr: map['amount_from_qr'] != null ? (map['amount_from_qr'] as num).toDouble() : null,
      referenceFromQr: map['reference_from_qr'] as String?,
      bankFromQr: map['bank_from_qr'] != null
          ? BankCode.values.firstWhere(
              (e) => e.toString() == map['bank_from_qr'],
              orElse: () => BankCode.unknown,
            )
          : null,
      rawQr: map['raw_qr'] as String?,
      transactionDate: map['transaction_date'] as String?,
      transactionTime: map['transaction_time'] as String?,
      fromAccount: map['from_account'] as String?,
      toAccount: map['to_account'] as String?,
      rawText: map['raw_text'] as String?,
      location: map['location'] != null
          ? LocationData.fromMap(map['location'] as Map<String, dynamic>)
          : null,
      confidence: map['confidence'] != null ? (map['confidence'] as num).toDouble() : 0.8,
      isManualComplete: (map['is_manual_complete'] as int?) == 1,
    );
  }

  SlipData copyWith({
    double? amount,
    double? amountFromQr,
    String? referenceFromQr,
    BankCode? bankFromQr,
    String? rawQr,
    String? transactionDate,
    String? transactionTime,
    String? fromAccount,
    String? toAccount,
    String? rawText,
    LocationData? location,
    double? confidence,
    bool? isManualComplete,
  }) {
    return SlipData(
      amount: amount ?? this.amount,
      amountFromQr: amountFromQr ?? this.amountFromQr,
      referenceFromQr: referenceFromQr ?? this.referenceFromQr,
      bankFromQr: bankFromQr ?? this.bankFromQr,
      rawQr: rawQr ?? this.rawQr,
      transactionDate: transactionDate ?? this.transactionDate,
      transactionTime: transactionTime ?? this.transactionTime,
      fromAccount: fromAccount ?? this.fromAccount,
      toAccount: toAccount ?? this.toAccount,
      rawText: rawText ?? this.rawText,
      location: location ?? this.location,
      confidence: confidence ?? this.confidence,
      isManualComplete: isManualComplete ?? this.isManualComplete,
    );
  }

  @override
  String toString() {
    return 'SlipData(date: $transactionDate, amountFromQr: $amountFromQr, reference: $referenceFromQr, bank: $bankName)';
  }
}

/// Thai QR Payment Parser (EMVCo)
/// อ่าน QR Code จากสลิปธนาคารไทย
/// ใช้เป็นแหล่งข้อมูลหลักสำหรับ amount และ reference
class ThaiQrParser {
  /// Parse QR Code string เป็น SlipTransaction
  /// Note: บาง QR (K+) อาจไม่มี amount - จะ return null
  static SlipTransactionQr? parse(String qr) {
    try {
      print('🔍 Parsing QR (${qr.length} chars)');
      
      final emv = EmvDecoder.decode(qr);
      
      print('📊 EMV Tags found: ${emv.keys.join(", ")}');

      // Validate
      if (!SlipValidator.isValidSlip(emv)) {
        print('❌ Not a valid slip QR code - too few tags or missing identifier');
        return null;
      }

      // Try to extract amount from various tags
      double? amount;
      String? amountStr = emv['54']; // Standard tag
      
      // Fallback for amount in nested tags
      if (amountStr == null) {
        for (final tag in ['91', '51', '31', '30']) {
          if (emv.containsKey(tag)) {
            print('🔍 Analyzing Tag $tag for nested amount');
            try {
              final subTags = EmvDecoder.decode(emv[tag]!);
              if (subTags.containsKey('54')) {
                amountStr = subTags['54'];
                print('✅ Found amount in Tag $tag sub-tags: $amountStr');
                break;
              }
            } catch (e) {}
          }
        }
      }
      
      if (amountStr != null) {
        amount = double.tryParse(amountStr);
        if (amount != null) print('✅ Amount found: $amount');
      } else {
        print('⚠️ No amount in QR - will use OCR');
      }
      
      // Reference: Extract จาก QR (Critical for duplicates)
      String? reference;
      
      // Try to find reference in common tags
      // 1. Tag 00 - some banks hide it here
      final tag00 = emv['00'];
      if (tag00 != null && tag00.length > 20) {
        final refMatch = RegExp(r'(014[0-9A-Z]{12,27})').firstMatch(tag00);
        if (refMatch != null) {
          reference = refMatch.group(1)!;
          print('✅ Reference found in Tag 00: $reference');
        }
      }
      
      // 2. Scan all values for typical Thai bank reference patterns (starting with 014)
      if (reference == null) {
        for (final entry in emv.entries) {
          final value = entry.value;
          // Look for 014 pattern
          if (value.contains('014') && value.length >= 15) {
            final match = RegExp(r'(014[0-9A-Z]{12,25})').firstMatch(value);
            if (match != null) {
              reference = match.group(1);
              print('✅ Reference found in Tag ${entry.key}: $reference');
              break;
            }
          }
          
          // Try nested tags in common merchant info areas
          final tagInt = int.tryParse(entry.key);
          if (tagInt != null && tagInt >= 26 && tagInt <= 51) {
            try {
              final subTags = EmvDecoder.decode(value);
              for (final subValue in subTags.values) {
                final subMatch = RegExp(r'(014[0-9A-Z]{12,25})').firstMatch(subValue);
                if (subMatch != null) {
                  reference = subMatch.group(1);
                  print('✅ Reference found in nested Tag ${entry.key}: $reference');
                  break;
                }
              }
            } catch (e) {}
            if (reference != null) break;
          }
        }
      }
      
      // 3. Fallback to common tags if still null
      reference ??= emv['62'] ?? emv['05'] ?? emv['25'] ?? emv['01'];
      if (reference == 'UNKNOWN' || reference == null) {
        // If we still have nothing, just take the longest string that looks like a ref
        for (final v in emv.values) {
          if (v.length > 15 && RegExp(r'[0-9]{15,}').hasMatch(v)) {
            reference = v;
            break;
          }
        }
      }
      
      reference ??= 'UNKNOWN';
      
      final bank = BankMapper.fromEmv(emv);

      print('✅ Parsed QR: Bank=${getBankLabel(bank)}, Ref=$reference, Amt=${amount ?? "N/A"}');

      return SlipTransactionQr(
        amount: amount,
        reference: reference,
        rawQr: qr,
        bank: bank,
      );
    } catch (e, stackTrace) {
      print('❌ ThaiQrParser error: $e');
      print(stackTrace);
      return null;
    }
  }
}

/// EMV Decoder - แกะ QR Code ตาม EMVCo Standard
class EmvDecoder {
  static Map<String, String> decode(String payload) {
    final map = <String, String>{};
    int i = 0;

    // Remove any leading/trailing whitespace or invisible chars
    payload = payload.trim();

    while (i + 4 <= payload.length) {
      try {
        final tag = payload.substring(i, i + 2);
        final lengthStr = payload.substring(i + 2, i + 4);
        
        int length;
        try {
          length = int.parse(lengthStr);
        } catch (e) {
          i++; // Skip one char and try to find next tag
          continue;
        }
        
        if (i + 4 + length > payload.length) {
          break;
        }
        
        final value = payload.substring(i + 4, i + 4 + length);
        map[tag] = value;
        i += 4 + length;
      } catch (e) {
        break;
      }
    }
    return map;
  }
}

/// Validate ว่าเป็นสลิปโอนเงินจริงหรือไม่
class SlipValidator {
  static bool isValidSlip(Map<String, String> emv) {
    // Relaxed validation: Any EMV QR with Format Indicator (00) and at least 3 tags
    // or known banking tags (30, 31, 51, 62)
    if (!emv.containsKey('00')) return false;
    
    // Most banking slips have many tags (usually > 5)
    if (emv.length >= 3) return true;
    
    // Or if it contains specific banking tags
    final bankingTags = ['30', '31', '51', '62', '54'];
    return emv.keys.any((k) => bankingTags.contains(k));
  }
}

/// Map ธนาคารจาก EMV Data
class BankMapper {
  static BankCode fromEmv(Map<String, String> emv) {
    // ตรวจสอบ Merchant Info (Tag 29-31 และอื่นๆ)
    for (var i = 26; i <= 51; i++) {
      final tag = i.toString().padLeft(2, '0');
      final merchantInfo = emv[tag];
      
      if (merchantInfo == null) continue;

      // PromptPay
      if (merchantInfo.contains('A000000677010111')) {
        return BankCode.promptpay;
      }

      // Bank Application
      if (merchantInfo.contains('A000000677010112')) {
        if (merchantInfo.contains('KBANK') || 
            merchantInfo.toLowerCase().contains('kasikorn')) {
          return BankCode.kbank;
        }
        if (merchantInfo.contains('SCB') || 
            merchantInfo.toLowerCase().contains('siam commercial')) {
          return BankCode.scb;
        }
        if (merchantInfo.contains('BBL') || 
            merchantInfo.toLowerCase().contains('bangkok bank')) {
          return BankCode.bbl;
        }
        if (merchantInfo.contains('KTB') || 
            merchantInfo.toLowerCase().contains('krung thai')) {
          return BankCode.ktb;
        }
        if (merchantInfo.contains('TMB') || 
            merchantInfo.toLowerCase().contains('tmb')) {
          return BankCode.tmb;
        }
      }
    }

    // Fallback: check Merchant Name
    final merchantName = emv['59']; // Merchant Name
    
    if (merchantName != null) {
      final lower = merchantName.toLowerCase();
      if (lower.contains('kbank') || lower.contains('kasikorn')) {
        return BankCode.kbank;
      }
      if (lower.contains('scb')) return BankCode.scb;
      if (lower.contains('bbl') || lower.contains('bangkok')) {
        return BankCode.bbl;
      }
      if (lower.contains('ktb') || lower.contains('krung')) {
        return BankCode.ktb;
      }
    }

    return BankCode.unknown;
  }
}

/// Bank Code Enum
enum BankCode {
  kbank,
  scb,
  bbl,
  ktb,
  tmb,
  promptpay,
  unknown,
}

/// Helper function to get bank label
String getBankLabel(BankCode bank) {
  switch (bank) {
    case BankCode.kbank:
      return 'KBank (K+)';
    case BankCode.scb:
      return 'SCB';
    case BankCode.bbl:
      return 'Bangkok Bank';
    case BankCode.ktb:
      return 'Krungthai Bank';
    case BankCode.tmb:
      return 'TMB';
    case BankCode.promptpay:
      return 'PromptPay';
    case BankCode.unknown:
      return 'Unknown Bank';
  }
}

/// Slip Transaction from QR (เชื่อถือได้สูง)
class SlipTransactionQr {
  final double? amount; // อาจเป็น null (บางธนาคารไม่มีใน QR)
  final String reference; // จาก QR เท่านั้น ✅
  final DateTime? dateTime; // optional
  final String rawQr; // เก็บไว้ debug
  final BankCode bank; // ธนาคาร

  SlipTransactionQr({
    this.amount, // nullable
    required this.reference,
    required this.rawQr,
    required this.bank,
    this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'reference': reference,
      'dateTime': dateTime?.toIso8601String(),
      'rawQr': rawQr,
      'bank': bank.toString(),
    };
  }

  factory SlipTransactionQr.fromMap(Map<String, dynamic> map) {
    return SlipTransactionQr(
      amount: (map['amount'] as num?)?.toDouble(),
      reference: map['reference'] as String,
      rawQr: map['rawQr'] as String,
      bank: BankCode.values.firstWhere(
        (e) => e.toString() == map['bank'],
        orElse: () => BankCode.unknown,
      ),
      dateTime: map['dateTime'] != null 
          ? DateTime.parse(map['dateTime'] as String)
          : null,
    );
  }
}


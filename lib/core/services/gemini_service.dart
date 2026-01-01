import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/app_constants.dart';
import 'secure_storage_service.dart';

class GeminiService {
  static final GeminiService instance = GeminiService._init();
  
  final SecureStorageService _storage = SecureStorageService.instance;
  GenerativeModel? _model;

  GeminiService._init();

  Future<void> initialize() async {
    final apiKey = await _storage.getGeminiApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: AppConstants.geminiModel,
        apiKey: apiKey,
      );
    }
  }

  Future<void> setApiKey(String apiKey) async {
    await _storage.saveGeminiApiKey(apiKey);
    _model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: apiKey,
    );
  }

  /// Validate API key by making a test API call
  /// Returns true if valid, false otherwise
  /// Throws exception with error message if validation fails
  Future<bool> validateApiKey(String apiKey) async {
    if (apiKey.isEmpty) {
      print('🔑 API Key validation: Empty key');
      return false;
    }
    
    if (!apiKey.startsWith('AIza')) {
      print('🔑 API Key validation: Invalid format (should start with AIza)');
      return false;
    }

    // Try stable models first (gemini-3-pro-preview may not be available in all regions/API versions)
    final modelsToTry = [
      'gemini-2.5-flash', // Stable model - widely available
      'gemini-2.0-flash', // Alternative stable model
      AppConstants.geminiModel, // Fallback to configured model
    ];

    for (final modelName in modelsToTry) {
      try {
        print('🔑 Testing API key with model: $modelName');
        
        final testModel = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
        );
        
        // Make a simple test call
        final response = await testModel.generateContent([
          Content.text('Say "OK"')
        ]).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Request timeout after 15 seconds');
          },
        );
        
        final isValid = response.text != null && response.text!.isNotEmpty;
        
        if (isValid) {
          print('🔑 ✅ API Key is valid! Model: $modelName');
          return true;
        } else {
          print('🔑 ❌ API Key validation: Empty response from model: $modelName');
        }
      } catch (e) {
        print('🔑 ❌ API Key validation error with model $modelName: $e');
        print('🔑 Error type: ${e.runtimeType}');
        
        // If it's an API error, check the error message
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('api key') || errorStr.contains('invalid') || errorStr.contains('unauthorized')) {
          print('🔑 ❌ API Key appears to be invalid or unauthorized');
          return false;
        }
        
        // If it's a model not found error, try next model
        if (errorStr.contains('not found') || errorStr.contains('model')) {
          print('🔑 ⚠️ Model $modelName not available, trying next...');
          continue;
        }
        
        // For other errors, try next model
        if (modelName != modelsToTry.last) {
          continue;
        }
        
        // Last model failed, return false
        print('🔑 ❌ All models failed validation');
        return false;
      }
    }
    
    return false;
  }

  bool get isConfigured => _model != null;

  Future<Map<String, dynamic>?> analyzeSlip(File imageFile) async {
    if (_model == null) {
      throw Exception('Gemini API key not configured');
    }

    try {
      final imageBytes = await imageFile.readAsBytes();
      final imagePart = DataPart('image/jpeg', imageBytes);

      const prompt = '''
Analyze this payment slip/receipt and extract the following information in JSON format:
{
  "type": "income" or "expense",
  "amount": <number>,
  "currency": "<currency code like THB, USD, etc>",
  "description": "<brief description>",
  "merchant": "<merchant/sender name if available>",
  "date": "<date in YYYY-MM-DD format if available>",
  "category": "<suggested category>"
}

Rules:
- Amount should be a number without currency symbols
- If currency is not clear, use "THB" as default
- Type should be "income" if it's money received, "expense" if it's payment made
- Return ONLY valid JSON, no additional text
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          imagePart,
        ])
      ];

      final response = await _model!.generateContent(content);
      final text = response.text;

      if (text == null) {
        throw Exception('No response from Gemini');
      }

      // Try to parse JSON from response
      final jsonStart = text.indexOf('{');
      final jsonEnd = text.lastIndexOf('}') + 1;

      if (jsonStart == -1 || jsonEnd == 0) {
        throw Exception('Invalid JSON response');
      }

      final jsonStr = text.substring(jsonStart, jsonEnd);
      final Map<String, dynamic> result = {};
      
      // Parse manually to handle different formats
      final lines = jsonStr.split('\n');
      for (final line in lines) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim().replaceAll('"', '').replaceAll(',', '');
            final value = parts.sublist(1).join(':').trim()
                .replaceAll('"', '')
                .replaceAll(',', '')
                .replaceAll('}', '');
            
            if (key.isNotEmpty && value.isNotEmpty) {
              result[key] = value;
            }
          }
        }
      }

      return result;
    } catch (e) {
      throw Exception('Failed to analyze slip: $e');
    }
  }

  Future<String?> categorizeTransaction(String description, String type) async {
    if (_model == null) {
      return null;
    }

    try {
      final prompt = '''
Based on this transaction description: "$description" (type: $type)
Suggest ONE appropriate category from this list:
- Food & Dining
- Transportation
- Shopping
- Bills & Utilities
- Healthcare
- Entertainment
- Salary
- Business
- Investment
- Other

Return ONLY the category name, nothing else.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      return response.text?.trim();
    } catch (e) {
      return null;
    }
  }

  Future<void> clearApiKey() async {
    await _storage.deleteGeminiApiKey();
    _model = null;
  }
}


import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  static final SecureStorageService instance = SecureStorageService._init();
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  
  SharedPreferences? _prefs;

  SecureStorageService._init();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // PIN Management
  Future<void> savePin(String pin) async {
    await _secureStorage.write(key: AppConstants.keyPin, value: pin);
  }

  Future<String?> getPin() async {
    return await _secureStorage.read(key: AppConstants.keyPin);
  }

  Future<void> deletePin() async {
    await _secureStorage.delete(key: AppConstants.keyPin);
  }

  Future<bool> verifyPin(String pin) async {
    final storedPin = await getPin();
    return storedPin == pin;
  }

  // Recovery Email
  Future<void> saveRecoveryEmail(String email) async {
    await _secureStorage.write(key: AppConstants.keyRecoveryEmail, value: email);
  }

  Future<String?> getRecoveryEmail() async {
    return await _secureStorage.read(key: AppConstants.keyRecoveryEmail);
  }

  // Gemini API Key
  Future<void> saveGeminiApiKey(String apiKey) async {
    await _secureStorage.write(key: AppConstants.keyGeminiApiKey, value: apiKey);
  }

  Future<String?> getGeminiApiKey() async {
    return await _secureStorage.read(key: AppConstants.keyGeminiApiKey);
  }

  Future<void> deleteGeminiApiKey() async {
    await _secureStorage.delete(key: AppConstants.keyGeminiApiKey);
  }

  // Consent Management
  Future<void> saveConsentData({
    required String version,
    required String language,
    required DateTime timestamp,
  }) async {
    _prefs?.setString(AppConstants.keyConsentVersion, version);
    _prefs?.setString(AppConstants.keyConsentLanguage, language);
    _prefs?.setString(AppConstants.keyConsentTimestamp, timestamp.toIso8601String());
    _prefs?.setBool(AppConstants.keyConsentAccepted, true);
  }

  Future<bool> hasConsented() async {
    return _prefs?.getBool(AppConstants.keyConsentAccepted) ?? false;
  }

  Future<Map<String, String?>> getConsentData() async {
    return {
      'version': _prefs?.getString(AppConstants.keyConsentVersion),
      'language': _prefs?.getString(AppConstants.keyConsentLanguage),
      'timestamp': _prefs?.getString(AppConstants.keyConsentTimestamp),
    };
  }

  // First Launch
  Future<bool> isFirstLaunch() async {
    final firstLaunch = _prefs?.getBool(AppConstants.keyFirstLaunch) ?? true;
    if (firstLaunch) {
      await _prefs?.setBool(AppConstants.keyFirstLaunch, false);
    }
    return firstLaunch;
  }

  // App Settings
  Future<void> setBaseCurrency(String currency) async {
    await _prefs?.setString(AppConstants.keyBaseCurrency, currency);
  }

  Future<String> getBaseCurrency() async {
    return _prefs?.getString(AppConstants.keyBaseCurrency) ?? 'THB';
  }

  Future<void> setLanguage(String language) async {
    await _prefs?.setString(AppConstants.keyLanguage, language);
  }

  Future<String> getLanguage() async {
    return _prefs?.getString(AppConstants.keyLanguage) ?? 'en';
  }

  // PIN Attempt Tracking
  Future<int> getPinAttemptCount() async {
    return _prefs?.getInt(AppConstants.keyPinAttemptCount) ?? 0;
  }

  Future<void> incrementPinAttemptCount() async {
    final count = await getPinAttemptCount();
    await _prefs?.setInt(AppConstants.keyPinAttemptCount, count + 1);
  }

  Future<void> resetPinAttemptCount() async {
    await _prefs?.setInt(AppConstants.keyPinAttemptCount, 0);
    await _prefs?.remove(AppConstants.keyLastPinAttemptTime);
  }

  Future<void> setLastPinAttemptTime(DateTime time) async {
    await _prefs?.setString(
      AppConstants.keyLastPinAttemptTime,
      time.toIso8601String(),
    );
  }

  Future<DateTime?> getLastPinAttemptTime() async {
    final timeStr = _prefs?.getString(AppConstants.keyLastPinAttemptTime);
    if (timeStr == null) return null;
    return DateTime.parse(timeStr);
  }

  Future<bool> isPinLocked() async {
    final attempts = await getPinAttemptCount();
    if (attempts < AppConstants.maxPinAttempts) return false;

    final lastAttempt = await getLastPinAttemptTime();
    if (lastAttempt == null) return false;

    final lockoutEnd = lastAttempt.add(
      const Duration(minutes: AppConstants.lockoutDurationMinutes),
    );

    if (DateTime.now().isAfter(lockoutEnd)) {
      await resetPinAttemptCount();
      return false;
    }

    return true;
  }

  Future<DateTime?> getPinLockoutEndTime() async {
    final lastAttempt = await getLastPinAttemptTime();
    if (lastAttempt == null) return null;

    return lastAttempt.add(
      const Duration(minutes: AppConstants.lockoutDurationMinutes),
    );
  }

  // Clear all data (for logout or reset)
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs?.clear();
  }
}


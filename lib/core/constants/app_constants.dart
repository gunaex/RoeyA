class AppConstants {
  // App Info
  static const String appName = 'RoeyA';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String dbName = 'roeya.db';
  static const int dbVersion = 2; // Updated for budgets and templates tables
  
  // Security
  static const int pinLength = 4;
  static const int maxPinAttempts = 3;
  static const int lockoutDurationMinutes = 60;
  
  // Consent
  static const String consentVersion = '1.0';
  
  // Currencies
  static const List<String> supportedCurrencies = [
    'THB', // Thai Baht
    'USD', // US Dollar
    'JPY', // Japanese Yen
    'CNY', // Chinese Yuan
    'KRW', // Korean Won
    'EUR', // Euro
    'GBP', // British Pound
    'SGD', // Singapore Dollar
  ];
  
  // Account Categories
  static const String categoryAssets = 'assets';
  static const String categoryLiabilities = 'liabilities';
  static const String categoryEquity = 'equity';
  static const String categoryRevenue = 'revenue';
  static const String categoryIncome = 'income'; // Added back to fix build errors
  static const String categoryExpense = 'expense';
  
  static const List<String> accountCategories = [
    categoryAssets,
    categoryLiabilities,
    categoryEquity,
    categoryRevenue,
    categoryExpense,
  ];
  
  // Transaction Categories (for Income/Expense tagging)
  static const List<String> incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Refund',
    'Other Income',
  ];
  
  static const List<String> expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Bills & Utilities',
    'Entertainment',
    'Healthcare',
    'Education',
    'Travel',
    'Transfer',
    'Other Expense',
  ];
  
  // Storage Keys
  static const String keyPin = 'user_pin';
  static const String keyRecoveryEmail = 'recovery_email';
  static const String keyConsentAccepted = 'consent_accepted';
  static const String keyConsentVersion = 'consent_version';
  static const String keyConsentLanguage = 'consent_language';
  static const String keyConsentTimestamp = 'consent_timestamp';
  static const String keyFirstLaunch = 'first_launch';
  static const String keyBaseCurrency = 'base_currency';
  static const String keyLanguage = 'language';
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyLastPinAttemptTime = 'last_pin_attempt_time';
  static const String keyPinAttemptCount = 'pin_attempt_count';
  
  // API
  // Using gemini-2.5-flash as default (stable and widely available)
  // gemini-3-pro-preview may not be available in all regions/API versions
  static const String geminiModel = 'gemini-2.5-flash'; // Stable model with good performance
  
  // Routes (will be defined in routes.dart)
  static const String routeWelcome = '/';
  static const String routeConsent = '/consent';
  static const String routeCreatePin = '/create-pin';
  static const String routeConfirmPin = '/confirm-pin';
  static const String routeRecoveryEmail = '/recovery-email';
  static const String routePinLock = '/pin-lock';
  static const String routeForgotPin = '/forgot-pin';
  static const String routeHome = '/home';
  static const String routeTransactionMode = '/transaction-mode';
  static const String routeScanSlip = '/scan-slip';
  static const String routeAiReview = '/ai-review';
  static const String routeManualEntry = '/manual-entry';
  static const String routeAccounts = '/accounts';
  static const String routeAccountDetail = '/account-detail';
  static const String routeTransactionDetail = '/transaction-detail';
  static const String routeSettings = '/settings';
  static const String routeChangePin = '/change-pin';
  static const String routeChangeEmail = '/change-email';
  static const String routeTransactionMap = '/transaction-map';
  static const String routeBrowseSlips = '/browse-slips';
  static const String routeBulkImportOcr = '/bulk-import-ocr';
  static const String routeQrScanner = '/qr-scanner';
  static const String routeReports = '/reports';
  static const String routeBudgets = '/budgets';
  static const String routeSearchTransactions = '/search-transactions';
}


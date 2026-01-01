# RoeyA - Function List & Properties Documentation

**Version:** 1.0.0  
**Last Updated:** January 2025  
**Platform:** Flutter (Android/iOS)

---

## Table of Contents

1. [Application Overview](#application-overview)
2. [Screens & Features](#screens--features)
3. [Core Services](#core-services)
4. [Data Repositories](#data-repositories)
5. [Data Models](#data-models)
6. [Shared Widgets](#shared-widgets)
7. [Constants & Configuration](#constants--configuration)
8. [Routes](#routes)
9. [Database Schema](#database-schema)

---

## Application Overview

**RoeyA** is an AI-First Personal Finance App with offline-first architecture, focusing on privacy and local data storage.

### Key Features
- ✅ PIN-based security with lockout protection
- ✅ Multi-language support (English/Thai)
- ✅ Multi-currency support (8 currencies)
- ✅ OCR-based slip scanning (Google ML Kit)
- ✅ AI financial advisor (Gemini API)
- ✅ Transaction management with categories
- ✅ Account management
- ✅ Photo attachments with GPS location
- ✅ Interactive transaction map
- ✅ Monthly reports with BI charts
- ✅ Offline-first architecture

---

## Screens & Features

### 1. Authentication & Security Screens

#### 1.1 Welcome Screen (`WelcomeScreen`)
- **Route:** `/`
- **Purpose:** First screen shown on app launch
- **Features:**
  - App introduction
  - "Get Started" button
  - Beautiful UI with app branding

#### 1.2 Consent Screen (`ConsentScreen`)
- **Route:** `/consent`
- **Purpose:** PDPA compliance - user consent for data collection
- **Features:**
  - Privacy Policy display
  - Terms of Use display
  - Consent checkbox
  - Language switcher (EN/TH)
  - Accept/Decline buttons
- **Properties:**
  - `_hasConsented` (bool) - User consent status
  - `_selectedLanguage` (String) - Current language selection

#### 1.3 Create PIN Screen (`CreatePinScreen`)
- **Route:** `/create-pin`
- **Purpose:** Create 4-digit PIN for app security
- **Features:**
  - 4-digit PIN input
  - Visual PIN dots
  - PIN validation
- **Properties:**
  - `_pin` (String) - Current PIN being entered
  - `_pinLength` (int) - Maximum PIN length (4)

#### 1.4 Confirm PIN Screen (`ConfirmPinScreen`)
- **Route:** `/confirm-pin`
- **Purpose:** Verify PIN matches original
- **Features:**
  - PIN re-entry
  - PIN mismatch detection
  - Navigation to recovery email on success
- **Properties:**
  - `originalPin` (String) - Original PIN to match
  - `_confirmPin` (String) - Confirmation PIN

#### 1.5 Recovery Email Screen (`RecoveryEmailScreen`)
- **Route:** `/recovery-email`
- **Purpose:** Set recovery email for PIN reset
- **Features:**
  - Email input with validation
  - Email format validation
  - Secure storage
- **Properties:**
  - `_emailController` (TextEditingController)
  - `_isLoading` (bool)

#### 1.6 PIN Lock Screen (`PinLockScreen`)
- **Route:** `/pin-lock`
- **Purpose:** PIN entry on app launch
- **Features:**
  - PIN entry with numpad
  - Lockout after 3 failed attempts (60 minutes)
  - Forgot PIN option
  - Auto-lock on app start
- **Properties:**
  - `_enteredPin` (String)
  - `_attemptCount` (int)
  - `_isLocked` (bool)
  - `_lockoutEndTime` (DateTime?)

#### 1.7 Forgot PIN Screen (`ForgotPinScreen`)
- **Route:** `/forgot-pin`
- **Purpose:** PIN recovery via email
- **Features:**
  - Recovery email input
  - PIN reset functionality
  - Email verification

---

### 2. Dashboard & Reports

#### 2.1 Dashboard Screen (`DashboardScreen`)
- **Route:** `/home`
- **Purpose:** Main app dashboard showing financial overview
- **Features:**
  - Net Worth display (Assets - Liabilities)
  - Category summary cards (Assets, Liabilities, Equity, Revenue, Expense)
  - Recent transactions list (last 5)
  - Online/Offline indicator
  - Pull-to-refresh
  - Floating Action Button: "+ Add Transaction"
  - Reports button in AppBar
- **Properties:**
  - `_netWorth` (double) - Calculated net worth
  - `_categorySummary` (Map<String, double>) - Category totals
  - `_recentTransactions` (List<Transaction>) - Recent 5 transactions
  - `_isLoading` (bool)
- **Functions:**
  - `_loadData()` - Loads all dashboard data
  - `_buildNetWorthCard()` - Net worth display card
  - `_buildCategorySummaryGrid()` - Category cards grid
  - `_buildRecentTransactionsList()` - Recent transactions list
  - `_showExitConfirmationDialog()` - Exit app confirmation

#### 2.2 Reports Screen (`ReportsScreen`)
- **Route:** `/reports`
- **Purpose:** Monthly financial reports with BI charts
- **Features:**
  - Month navigation (previous/next)
  - Monthly summary card (Income, Expense, Net Balance)
  - Income vs Expense bar chart
  - Expense category pie chart
  - Income category pie chart
  - Category breakdown lists with progress bars
  - AI Financial Advisor suggestions
  - Pull-to-refresh
- **Properties:**
  - `_year` (int) - Selected year
  - `_month` (int) - Selected month
  - `_monthly` (Map<String, double>) - Monthly totals
  - `_incomeCats` (List<Map>) - Income category breakdown
  - `_expenseCats` (List<Map>) - Expense category breakdown
  - `_aiSuggestions` (String?) - AI-generated recommendations
  - `_isLoading` (bool)
  - `_isLoadingAi` (bool)
- **Functions:**
  - `_load()` - Load monthly data
  - `_loadAiSuggestions()` - Generate AI recommendations
  - `_buildSummaryCard()` - Summary statistics card
  - `_buildBarChartCard()` - Income vs Expense bar chart
  - `_buildPieChartCard()` - Category pie chart
  - `_buildCategorySection()` - Category breakdown list
  - `_buildAiSuggestionsCard()` - AI advisor card
  - `_buildMonthNavigation()` - Month selector

---

### 3. Transaction Management

#### 3.1 Transaction Mode Screen (`TransactionModeScreen`)
- **Route:** `/transaction-mode`
- **Purpose:** Select transaction entry method
- **Features:**
  - "Scan Slip (OCR)" option
  - "Manual Entry" option
  - Card-based selection UI
- **Properties:** None (StatelessWidget)

#### 3.2 Scan Transfer Slip Screen (`SlipOcrScreen`)
- **Route:** `/scan-slip`
- **Purpose:** OCR-based slip scanning and transaction creation
- **Features:**
  - Camera capture
  - Gallery selection (with EXIF GPS preservation)
  - OCR text recognition (Google ML Kit)
  - QR code scanning
  - Auto-fill transaction fields
  - Transaction type selector (Income/Expense)
  - Category selection
  - Account selection
  - Editable fields (amount, date, recipient, reference, note)
  - Save transaction
- **Properties:**
  - `_imageFile` (File?) - Selected image
  - `_slipData` (SlipData?) - Extracted slip data
  - `_isScanning` (bool) - OCR processing state
  - `_selectedAccountId` (String?) - Selected account
  - `_transactionType` (String) - 'income' or 'expense'
  - `_selectedCategory` (String?) - Selected category
  - `_amountController` (TextEditingController)
  - `_toController` (TextEditingController)
  - `_refController` (TextEditingController)
  - `_dateController` (TextEditingController)
  - `_noteController` (TextEditingController)
- **Functions:**
  - `_pickFromCamera()` - Capture photo
  - `_pickFromGallery()` - Select from gallery
  - `_processImage()` - Process image with OCR
  - `_populateControllers()` - Fill form fields from OCR data
  - `_saveTransaction()` - Save transaction to database

#### 3.3 Manual Entry Screen (`ManualEntryScreen`)
- **Route:** `/manual-entry`
- **Purpose:** Manual transaction entry
- **Features:**
  - Transaction type selector (Income/Expense)
  - Category dropdown
  - Account dropdown
  - Amount input with decimal validation
  - Description input
  - Date picker
  - Note input
  - Photo attachments (up to 5)
  - Form validation
  - Edit existing transaction support
- **Properties:**
  - `transactionId` (String?) - For editing existing transaction
  - `_type` (String) - 'income' or 'expense'
  - `_selectedCategory` (String?)
  - `_selectedAccountId` (String?)
  - `_selectedDate` (DateTime)
  - `_currency` (String) - Default 'THB'
  - `_amountController` (TextEditingController)
  - `_descriptionController` (TextEditingController)
  - `_noteController` (TextEditingController)
  - `_photos` (List<PhotoAttachment>)
  - `_isLoading` (bool)
- **Functions:**
  - `_loadTransaction()` - Load transaction for editing
  - `_loadAccounts()` - Load available accounts
  - `_selectDate()` - Show date picker
  - `_handleSave()` - Save/update transaction

#### 3.4 Transaction Detail Screen (`TransactionDetailScreen`)
- **Route:** `/transaction-detail`
- **Purpose:** View and edit transaction details
- **Features:**
  - Transaction details display
  - Edit transaction
  - Delete transaction
  - Photo gallery view
  - Location display
- **Properties:**
  - `transactionId` (String) - Transaction ID
  - `_transaction` (Transaction?) - Loaded transaction
  - `_isLoading` (bool)

#### 3.5 Browse Saved Slips Screen (`BrowseSlipsScreen`)
- **Route:** `/browse-slips`
- **Purpose:** Browse and select multiple slips from gallery
- **Features:**
  - Multi-image selection from gallery
  - EXIF GPS preservation
  - Navigate to OCR screen for processing
- **Properties:**
  - `_selectedFiles` (List<File>)
  - `_isLoading` (bool)

#### 3.6 Bulk Import OCR Screen (`BulkImportOcrScreen`)
- **Route:** `/bulk-import-ocr`
- **Purpose:** Bulk import multiple slips using OCR
- **Features:**
  - Multi-image selection
  - Batch OCR processing
  - Progress indicator
  - Results summary
- **Properties:**
  - `_selectedFiles` (List<File>)
  - `_isProcessing` (bool)
  - `_results` (List<SlipData>)

#### 3.7 QR Scanner Screen (`QrScannerScreen`)
- **Route:** `/qr-scanner`
- **Purpose:** Scan QR codes from transfer slips
- **Features:**
  - Real-time QR code scanning
  - Thai QR payment parsing
  - Auto-fill transaction data
- **Properties:**
  - `_isScanning` (bool)
  - `_scannedData` (String?)

---

### 4. Account Management

#### 4.1 Accounts Screen (`AccountsScreen`)
- **Route:** `/accounts`
- **Purpose:** Manage user accounts
- **Features:**
  - List all accounts by category
  - Account cards with balance display
  - Add new account
  - Edit account
  - Delete account
  - Category filtering
- **Properties:**
  - `_accounts` (List<Account>)
  - `_isLoading` (bool)
  - `_selectedCategory` (String?) - Filter by category
- **Functions:**
  - `_loadAccounts()` - Load all accounts
  - `_showAddAccountDialog()` - Add account dialog
  - `_showEditAccountDialog()` - Edit account dialog
  - `_showAccountForm()` - Reusable account form
  - `_buildAccountCard()` - Account display card
  - `_getCategoryLabel()` - Localized category name
  - `_getCategoryColor()` - Category color
  - `_getCategoryIconData()` - Category icon

---

### 5. Map & Location

#### 5.1 Transaction Map Screen (`TransactionMapScreen`)
- **Route:** `/transaction-map`
- **Purpose:** View transactions on interactive map
- **Features:**
  - OpenStreetMap integration (free, no API key)
  - Transaction markers with photo thumbnails
  - Marker colors (green=income, red=expense)
  - Tap marker to view transaction details
  - Location clustering
  - Map controls (zoom, pan)
- **Properties:**
  - `_transactions` (List<Transaction>)
  - `_isLoading` (bool)
  - `_mapController` (MapController)
- **Functions:**
  - `_loadTransactions()` - Load transactions with locations
  - `_createMarkers()` - Create map markers from transactions
  - `_buildMarkerPopup()` - Marker info popup

---

### 6. Settings

#### 6.1 Settings Screen (`SettingsScreen`)
- **Route:** `/settings`
- **Purpose:** App configuration and settings
- **Features:**
  - Language selection (EN/TH) with auto-refresh
  - Base currency selection
  - PIN change
  - Recovery email change
  - Gemini API Key configuration with validation
  - Transaction Map access
  - Bulk Import (OCR) access
  - Version information
  - Privacy Policy
  - Terms of Use
  - Clear All Data (danger zone)
- **Properties:**
  - `_currentLanguage` (String) - 'en' or 'th'
  - `_currentCurrency` (String) - Base currency code
  - `_recoveryEmail` (String?) - Recovery email
  - `_languageChanged` (bool) - Flag for app refresh
- **Functions:**
  - `_loadSettings()` - Load current settings
  - `_showLanguageDialog()` - Language selection dialog
  - `_showCurrencyDialog()` - Currency selection dialog
  - `_showApiKeyDialog()` - API key configuration dialog
  - `_showPrivacyPolicy()` - Privacy policy dialog
  - `_showTermsOfUse()` - Terms of use dialog
  - `_showClearDataDialog()` - Clear data confirmation

---

## Core Services

### 1. Secure Storage Service (`SecureStorageService`)
**Location:** `lib/core/services/secure_storage_service.dart`

**Purpose:** Secure storage for sensitive data (PIN, API keys, settings)

**Properties:**
- `instance` (SecureStorageService) - Singleton instance
- `_secureStorage` (FlutterSecureStorage) - Encrypted storage
- `_prefs` (SharedPreferences?) - Preferences storage

**Functions:**
- `init()` - Initialize storage
- `savePin(String pin)` - Save PIN securely
- `getPin()` - Get stored PIN
- `deletePin()` - Delete PIN
- `verifyPin(String pin)` - Verify PIN
- `saveRecoveryEmail(String email)` - Save recovery email
- `getRecoveryEmail()` - Get recovery email
- `saveGeminiApiKey(String apiKey)` - Save Gemini API key
- `getGeminiApiKey()` - Get Gemini API key
- `deleteGeminiApiKey()` - Delete API key
- `hasConsented()` - Check consent status
- `setConsentAccepted(bool accepted)` - Set consent
- `isFirstLaunch()` - Check first launch
- `setFirstLaunch(bool isFirst)` - Set first launch flag
- `setBaseCurrency(String currency)` - Set base currency
- `getBaseCurrency()` - Get base currency
- `setLanguage(String language)` - Set language preference
- `getLanguage()` - Get language preference
- `getPinAttemptCount()` - Get failed PIN attempts
- `incrementPinAttemptCount()` - Increment attempt count
- `resetPinAttemptCount()` - Reset attempts
- `setLastPinAttemptTime(DateTime time)` - Set last attempt time
- `getLastPinAttemptTime()` - Get last attempt time
- `isPinLocked()` - Check if PIN is locked
- `getPinLockoutEndTime()` - Get lockout end time

---

### 2. Gemini Service (`GeminiService`)
**Location:** `lib/core/services/gemini_service.dart`

**Purpose:** Google Gemini AI integration for slip analysis

**Properties:**
- `instance` (GeminiService) - Singleton instance
- `_model` (GenerativeModel?) - Gemini model instance
- `_storage` (SecureStorageService) - Storage service

**Functions:**
- `initialize()` - Initialize with stored API key
- `setApiKey(String apiKey)` - Set API key
- `validateApiKey(String apiKey)` - Validate API key with test call
- `isConfigured` (bool) - Check if API key is configured
- `analyzeSlip(File imageFile)` - Analyze payment slip image
- `categorizeTransaction(String description, String type)` - Categorize transaction
- `clearApiKey()` - Clear API key

---

### 3. AI Financial Advisor Service (`AiFinancialAdvisorService`)
**Location:** `lib/core/services/ai_financial_advisor_service.dart`

**Purpose:** Generate personalized financial recommendations using Gemini AI

**Properties:**
- `instance` (AiFinancialAdvisorService) - Singleton instance
- `_model` (GenerativeModel?) - Gemini model instance
- `_storage` (SecureStorageService) - Storage service

**Functions:**
- `initialize()` - Initialize with stored API key
- `setApiKey(String apiKey)` - Set API key
- `isConfigured` (bool) - Check if configured
- `generateFinancialSuggestions()` - Generate AI recommendations
  - Parameters:
    - `income` (double) - Monthly income
    - `expense` (double) - Monthly expense
    - `netBalance` (double) - Net balance
    - `incomeCategories` (Map<String, double>) - Income breakdown
    - `expenseCategories` (Map<String, double>) - Expense breakdown
    - `language` (String) - 'en' or 'th'
  - Returns: `String?` - AI-generated suggestions
- `_buildEnglishPrompt()` - Build English prompt
- `_buildThaiPrompt()` - Build Thai prompt

---

### 4. ML Kit OCR Service (`MlKitOcrService`)
**Location:** `lib/core/services/mlkit_ocr_service.dart`

**Purpose:** OCR text recognition and QR code scanning

**Properties:**
- `instance` (MlKitOcrService) - Singleton instance
- `_textRecognizer` (TextRecognizer?) - ML Kit text recognizer
- `_barcodeScanner` (BarcodeScanner?) - ML Kit barcode scanner

**Functions:**
- `initialize()` - Initialize ML Kit
- `scanSlip(File imageFile)` - Scan transfer slip
  - Returns: `SlipData` - Extracted slip information
- `scanQrCode(File imageFile)` - Scan QR code
  - Returns: `String?` - QR code content
- `dispose()` - Cleanup resources

---

### 5. EXIF Location Service (`ExifLocationService`)
**Location:** `lib/core/services/exif_location_service.dart`

**Purpose:** Extract GPS location from photo EXIF data

**Properties:**
- `instance` (ExifLocationService) - Singleton instance

**Functions:**
- `requestMediaLocationPermission()` - Request ACCESS_MEDIA_LOCATION permission
- `requestMediaReadPermission()` - Request READ_MEDIA_IMAGES permission
- `extractLocation(File imageFile, {Uint8List? bytes})` - Extract GPS from image
  - Returns: `LocationData?` - GPS coordinates and address
- `extractLocationFromBytes(Uint8List bytes)` - Extract from image bytes
- `extractLocationFromFile(File imageFile)` - Extract from file
- `_extractWithNativeExif(File imageFile)` - Fallback using native_exif
- `_extractWithMediaStore(File imageFile)` - Android MediaStore fallback
- `_convertToDecimalDegrees()` - Convert GPS coordinates
- `_parseRatioOrNumber()` - Parse numeric values

---

### 6. Photo Service (`PhotoService`)
**Location:** `lib/core/services/photo_service.dart`

**Purpose:** Manage photo storage and thumbnails

**Properties:**
- `instance` (PhotoService) - Singleton instance

**Functions:**
- `savePhoto(File imageFile)` - Save photo and generate thumbnail
  - Returns: `Map<String, String>` - {'path': ..., 'thumbnailPath': ...}
- `deletePhoto(String path, String? thumbnailPath)` - Delete photo files
- `generateThumbnail(File imageFile)` - Generate thumbnail
  - Returns: `String?` - Thumbnail path

---

### 7. QR Scanner Service (`QrScannerService`)
**Location:** `lib/core/services/qr_scanner_service.dart`

**Purpose:** QR code scanning using mobile_scanner

**Properties:**
- `instance` (QrScannerService) - Singleton instance

**Functions:**
- `scanQrCode()` - Scan QR code from camera
  - Returns: `Future<String?>` - QR code content

---

### 8. Connectivity Service (`ConnectivityService`)
**Location:** `lib/core/services/connectivity_service.dart`

**Purpose:** Monitor internet connectivity status

**Properties:**
- `instance` (ConnectivityService) - Singleton instance
- `isOnline` (bool) - Current connectivity status

**Functions:**
- `init()` - Initialize connectivity monitoring
- `_checkConnectivity()` - Check connectivity status
- `dispose()` - Cleanup

---

## Data Repositories

### 1. Transaction Repository (`TransactionRepository`)
**Location:** `lib/data/repositories/transaction_repository.dart`

**Purpose:** Database operations for transactions

**Properties:**
- `_dbHelper` (DatabaseHelper) - Database helper instance
- `_accountRepo` (AccountRepository) - Account repository

**Functions:**
- `getAllTransactions({bool includeDeleted})` - Get all transactions
  - Returns: `List<Transaction>`
- `getTransactionById(String id)` - Get single transaction
  - Returns: `Transaction?`
- `insertTransaction(Transaction transaction)` - Insert new transaction
  - Automatically updates account balance
  - Returns: `String` - Transaction ID
- `updateTransaction(Transaction newTx)` - Update transaction
  - Automatically adjusts account balances
  - Returns: `int` - Rows affected
- `softDeleteTransaction(String id)` - Soft delete transaction
  - Reverses account balance changes
  - Returns: `int` - Rows affected
- `getMonthlySummary(int year, int month)` - Get monthly totals
  - Returns: `Map<String, double>` - {'income': ..., 'expense': ...}
- `getCategoryBreakdown(String type, int year, int month)` - Get category totals
  - Returns: `List<Map<String, dynamic>>` - Category breakdown
- `getRecentTransactions({int limit})` - Get recent transactions
  - Returns: `List<Transaction>`

---

### 2. Account Repository (`AccountRepository`)
**Location:** `lib/data/repositories/account_repository.dart`

**Purpose:** Database operations for accounts

**Properties:**
- `_dbHelper` (DatabaseHelper) - Database helper instance

**Functions:**
- `createDefaultAccountsIfNeeded()` - Create default accounts on first launch
- `getAllAccounts({bool includeDeleted})` - Get all accounts
  - Returns: `List<Account>`
- `getAccountsByCategory(String category)` - Get accounts by category
  - Returns: `List<Account>`
- `getAccountById(String id)` - Get single account
  - Returns: `Account?`
- `insertAccount(Account account)` - Insert new account
  - Returns: `String` - Account ID
- `updateAccount(Account account)` - Update account
  - Returns: `int` - Rows affected
- `softDeleteAccount(String id)` - Soft delete account
  - Returns: `int` - Rows affected
- `updateBalanceInternal(Transaction txn, String accountId, double delta)` - Internal balance update
- `getNetWorth()` - Calculate net worth (Assets - Liabilities)
  - Returns: `double`
- `getCategorySummary()` - Get summary by category
  - Returns: `Map<String, double>`

---

## Data Models

### 1. Transaction Model (`Transaction`)
**Location:** `lib/data/models/transaction.dart`

**Properties:**
- `id` (String) - Unique transaction ID (UUID)
- `accountId` (String) - Associated account ID
- `type` (String) - 'income', 'expense', or 'transfer'
- `amount` (double) - Transaction amount
- `currencyCode` (String) - Currency code (THB, USD, etc.)
- `convertedAmount` (double?) - Amount in base currency
- `convertedCurrencyCode` (String?) - Base currency code
- `exchangeRate` (double?) - Exchange rate used
- `category` (String?) - Transaction category
- `description` (String?) - Transaction description
- `note` (String?) - Additional notes
- `imageUri` (String?) - Legacy image URI
- `photos` (List<PhotoAttachment>?) - Photo attachments (up to 5)
- `transactionDate` (DateTime) - Transaction date
- `isDeleted` (bool) - Soft delete flag
- `createdAt` (DateTime) - Creation timestamp
- `deletedAt` (DateTime?) - Deletion timestamp

**Functions:**
- `toMap()` - Convert to Map for database
- `fromMap(Map)` - Create from database Map
- `copyWith()` - Create copy with modified fields

---

### 2. Account Model (`Account`)
**Location:** `lib/data/models/account.dart`

**Properties:**
- `id` (String) - Unique account ID
- `name` (String) - Account name
- `category` (String) - Account category (assets, liabilities, equity, income, expense)
- `description` (String?) - Account description
- `icon` (String?) - Icon identifier
- `currencyCode` (String) - Currency code
- `balance` (double) - Current balance
- `isDeleted` (bool) - Soft delete flag
- `createdAt` (DateTime) - Creation timestamp
- `deletedAt` (DateTime?) - Deletion timestamp

**Functions:**
- `toMap()` - Convert to Map for database
- `fromMap(Map)` - Create from database Map
- `copyWith()` - Create copy with modified fields

---

### 3. Photo Attachment Model (`PhotoAttachment`)
**Location:** `lib/data/models/photo_attachment.dart`

**Properties:**
- `id` (String) - Unique photo ID (UUID)
- `path` (String) - Full-size image path
- `thumbnailPath` (String?) - Thumbnail image path
- `location` (LocationData?) - GPS location data
- `addedAt` (DateTime) - Attachment timestamp

**Functions:**
- `toMap()` - Convert to Map for JSON storage
- `fromMap(Map)` - Create from Map
- `copyWith()` - Create copy with modified fields

---

### 4. Location Data Model (`LocationData`)
**Location:** `lib/data/models/location_data.dart`

**Properties:**
- `latitude` (double) - GPS latitude
- `longitude` (double) - GPS longitude
- `address` (String?) - Reverse geocoded address
- `fullLocationName` (String) - Formatted location string

**Functions:**
- `toMap()` - Convert to Map
- `fromMap(Map)` - Create from Map

---

### 5. Slip Data Model (`SlipData`)
**Location:** `lib/data/models/slip_data.dart`

**Properties:**
- `bankName` (String?) - Bank name
- `amount` (double?) - Transaction amount
- `amountFromQr` (double?) - Amount from QR code
- `fee` (double?) - Transaction fee
- `fromAccount` (String?) - Sender account
- `toAccount` (String?) - Recipient account
- `referenceNo` (String?) - Reference number
- `transactionTime` (String?) - Transaction time
- `qrData` (String?) - Raw QR code data

---

## Shared Widgets

### 1. App Button (`AppButton`)
**Location:** `lib/shared/widgets/app_button.dart`

**Properties:**
- `text` (String) - Button text
- `onPressed` (VoidCallback?) - Press handler
- `isLoading` (bool) - Loading state
- `isOutlined` (bool) - Outlined style
- `color` (Color?) - Custom color
- `icon` (IconData?) - Optional icon

---

### 2. App Text Field (`AppTextField`)
**Location:** `lib/shared/widgets/app_text_field.dart`

**Properties:**
- `controller` (TextEditingController) - Text controller
- `label` (String) - Field label
- `hint` (String?) - Placeholder text
- `prefixIcon` (IconData?) - Prefix icon
- `suffixIcon` (IconData?) - Suffix icon
- `keyboardType` (TextInputType?) - Keyboard type
- `validator` (String? Function(String?)?) - Validation function
- `inputFormatters` (List<TextInputFormatter>?) - Input formatters
- `maxLines` (int) - Max lines (default: 1)
- `obscureText` (bool) - Password field

---

### 3. Photo Attachment Widget (`PhotoAttachmentWidget`)
**Location:** `lib/shared/widgets/photo_attachment_widget.dart`

**Properties:**
- `photos` (List<PhotoAttachment>) - Current photos
- `onPhotosChanged` (Function(List<PhotoAttachment>)) - Change callback
- `maxPhotos` (int) - Maximum photos (default: 5)
- `readOnly` (bool) - Read-only mode

**Features:**
- Add photos (camera/gallery)
- Delete photos
- View full-size photos
- Location indicators
- Automatic GPS extraction
- Fallback to current location if no EXIF GPS

**Functions:**
- `_pickFromCamera()` - Capture photo
- `_pickFromGallery()` - Select from gallery
- `_processAndAddPhoto()` - Process and add photo
- `_getCurrentLocation()` - Get device GPS location
- `_deletePhoto()` - Delete photo
- `_viewPhoto()` - View full-size photo

---

### 4. PIN Numpad (`PinNumpad`)
**Location:** `lib/shared/widgets/pin_numpad.dart`

**Properties:**
- `onNumberTap` (Function(String)) - Number tap handler
- `onDeleteTap` (VoidCallback?) - Delete handler
- `onBiometricTap` (VoidCallback?) - Biometric handler

---

### 5. Loading Overlay (`LoadingOverlay`)
**Location:** `lib/shared/widgets/loading_overlay.dart`

**Properties:**
- `isLoading` (bool) - Show/hide overlay
- `message` (String?) - Loading message

---

### 6. Empty State (`EmptyState`)
**Location:** `lib/shared/widgets/empty_state.dart`

**Properties:**
- `icon` (IconData) - Icon to display
- `title` (String) - Title text
- `message` (String?) - Message text
- `actionLabel` (String?) - Action button label
- `onAction` (VoidCallback?) - Action handler

---

## Constants & Configuration

### App Constants (`AppConstants`)
**Location:** `lib/core/constants/app_constants.dart`

**Properties:**

#### App Info
- `appName` (String) - "RoeyA"
- `appVersion` (String) - "1.0.0"

#### Database
- `dbName` (String) - "roeya.db"
- `dbVersion` (int) - 1

#### Security
- `pinLength` (int) - 4
- `maxPinAttempts` (int) - 3
- `lockoutDurationMinutes` (int) - 60

#### Currencies (8 supported)
- `supportedCurrencies` (List<String>) - ['THB', 'USD', 'JPY', 'CNY', 'KRW', 'EUR', 'GBP', 'SGD']

#### Account Categories
- `categoryAssets` (String) - "assets"
- `categoryLiabilities` (String) - "liabilities"
- `categoryEquity` (String) - "equity"
- `categoryRevenue` (String) - "revenue"
- `categoryIncome` (String) - "income"
- `categoryExpense` (String) - "expense"
- `accountCategories` (List<String>) - All account categories

#### Transaction Categories

**Income Categories:**
- Salary
- Freelance
- Investment
- Gift
- Refund
- Other Income

**Expense Categories:**
- Food & Dining
- Transportation
- Shopping
- Bills & Utilities
- Entertainment
- Healthcare
- Education
- Travel
- Transfer
- Other Expense

#### API
- `geminiModel` (String) - "gemini-2.5-flash" (Stable model)

#### Storage Keys
- `keyPin` - PIN storage key
- `keyRecoveryEmail` - Recovery email key
- `keyConsentAccepted` - Consent status key
- `keyBaseCurrency` - Base currency key
- `keyLanguage` - Language preference key
- `keyGeminiApiKey` - Gemini API key key
- `keyFirstLaunch` - First launch flag key

---

## Routes

**Location:** `lib/app/routes.dart`

**Route Constants:**
- `/` - Welcome Screen
- `/consent` - Consent Screen
- `/create-pin` - Create PIN Screen
- `/confirm-pin` - Confirm PIN Screen
- `/recovery-email` - Recovery Email Screen
- `/pin-lock` - PIN Lock Screen
- `/forgot-pin` - Forgot PIN Screen
- `/home` - Dashboard Screen
- `/transaction-mode` - Transaction Mode Screen
- `/scan-slip` - Scan Transfer Slip Screen
- `/manual-entry` - Manual Entry Screen
- `/accounts` - Accounts Screen
- `/account-detail` - Account Detail Screen
- `/transaction-detail` - Transaction Detail Screen
- `/settings` - Settings Screen
- `/change-pin` - Change PIN Screen
- `/change-email` - Change Email Screen
- `/transaction-map` - Transaction Map Screen
- `/browse-slips` - Browse Saved Slips Screen
- `/bulk-import-ocr` - Bulk Import OCR Screen
- `/qr-scanner` - QR Scanner Screen
- `/reports` - Reports Screen

---

## Database Schema

### Accounts Table
```sql
CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  currency_code TEXT NOT NULL,
  balance REAL NOT NULL DEFAULT 0.0,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  deleted_at TEXT
)
```

**Indexes:**
- `idx_accounts_category` - Category index

---

### Transactions Table
```sql
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  account_id TEXT NOT NULL,
  type TEXT NOT NULL,
  amount REAL NOT NULL,
  currency_code TEXT NOT NULL,
  converted_amount REAL,
  converted_currency_code TEXT,
  exchange_rate REAL,
  category TEXT,
  description TEXT,
  note TEXT,
  image_uri TEXT,
  photos_json TEXT,
  transaction_date TEXT NOT NULL,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  deleted_at TEXT,
  FOREIGN KEY (account_id) REFERENCES accounts (id)
)
```

**Indexes:**
- `idx_transactions_account_id` - Account ID index
- `idx_transactions_date` - Transaction date index

---

### Currency Rates Table
```sql
CREATE TABLE currency_rates (
  id TEXT PRIMARY KEY,
  from_currency TEXT NOT NULL,
  to_currency TEXT NOT NULL,
  rate REAL NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE(from_currency, to_currency)
)
```

---

## Key Features Summary

### ✅ Implemented Features

1. **Security & Authentication**
   - PIN-based security (4-digit)
   - PIN lockout protection (3 attempts, 60 min lockout)
   - Recovery email for PIN reset
   - Secure storage (encrypted)
   - PDPA consent management

2. **Transaction Management**
   - Manual transaction entry
   - OCR slip scanning (Google ML Kit)
   - QR code scanning (Thai QR payment)
   - Bulk import (multiple slips)
   - Transaction editing
   - Transaction deletion (soft delete)
   - Category assignment
   - Account assignment
   - Photo attachments (up to 5 per transaction)
   - GPS location extraction

3. **Account Management**
   - Multiple accounts support
   - Account categories (Assets, Liabilities, Equity, Revenue, Expense)
   - Account balance tracking
   - Account CRUD operations
   - Default accounts creation

4. **Financial Analysis**
   - Net worth calculation
   - Monthly summaries
   - Category breakdowns
   - Recent transactions
   - Income vs Expense charts
   - Pie charts for categories
   - Progress bars for spending

5. **AI Features**
   - Gemini API integration
   - Financial advisor suggestions
   - Personalized recommendations
   - Multi-language AI responses (EN/TH)
   - Real-time data analysis

6. **Maps & Location**
   - Transaction location mapping
   - Photo GPS extraction
   - Interactive map with thumbnails
   - Location clustering
   - Reverse geocoding

7. **Localization**
   - English/Thai support
   - Dynamic language switching
   - Localized categories
   - Localized UI elements

8. **Settings**
   - Language selection
   - Currency selection
   - API key management
   - PIN change
   - Email change
   - Privacy policy
   - Terms of use

---

## Technical Stack

- **Framework:** Flutter 3.0+
- **Database:** SQLite (sqflite)
- **State Management:** Provider
- **Localization:** flutter_localizations + intl
- **Security:** flutter_secure_storage
- **OCR:** google_mlkit_text_recognition
- **QR Scanner:** google_mlkit_barcode_scanning + mobile_scanner
- **AI:** google_generative_ai (Gemini)
- **Maps:** flutter_map + latlong2 (OpenStreetMap)
- **Location:** geolocator + geocoding
- **EXIF:** exif + native_exif
- **Charts:** fl_chart
- **Image Picker:** image_picker + file_picker
- **Permissions:** permission_handler

---

## File Structure

```
lib/
├── app/
│   ├── app.dart
│   └── routes.dart
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── localization/
│   │   ├── app_localizations.dart
│   │   └── locale_provider.dart
│   ├── services/
│   │   ├── ai_financial_advisor_service.dart
│   │   ├── connectivity_service.dart
│   │   ├── exif_location_service.dart
│   │   ├── gemini_service.dart
│   │   ├── mlkit_ocr_service.dart
│   │   ├── photo_service.dart
│   │   ├── qr_scanner_service.dart
│   │   └── secure_storage_service.dart
│   ├── theme/
│   │   └── app_colors.dart
│   └── utils/
│       ├── currency_formatter.dart
│       ├── decimal_text_input_formatter.dart
│       ├── thai_qr_parser.dart
│       └── validators.dart
├── data/
│   ├── database/
│   │   └── database_helper.dart
│   ├── models/
│   │   ├── account.dart
│   │   ├── location_data.dart
│   │   ├── photo_attachment.dart
│   │   ├── slip_data.dart
│   │   └── transaction.dart
│   └── repositories/
│       ├── account_repository.dart
│       └── transaction_repository.dart
├── features/
│   ├── accounts/
│   │   └── screens/
│   │       └── accounts_screen.dart
│   ├── auth/
│   │   └── screens/
│   │       ├── confirm_pin_screen.dart
│   │       ├── create_pin_screen.dart
│   │       ├── forgot_pin_screen.dart
│   │       ├── pin_lock_screen.dart
│   │       ├── recovery_email_screen.dart
│   │       └── welcome_screen.dart
│   ├── consent/
│   │   └── screens/
│   │       └── consent_screen.dart
│   ├── dashboard/
│   │   └── screens/
│   │       ├── dashboard_screen.dart
│   │       └── reports_screen.dart
│   ├── map/
│   │   └── screens/
│   │       └── transaction_map_screen.dart
│   ├── settings/
│   │   └── screens/
│   │       └── settings_screen.dart
│   └── transactions/
│       └── screens/
│           ├── browse_slips_screen.dart
│           ├── bulk_import_ocr_screen.dart
│           ├── manual_entry_screen.dart
│           ├── qr_scanner_screen.dart
│           ├── slip_ocr_screen.dart
│           ├── transaction_detail_screen.dart
│           └── transaction_mode_screen.dart
└── shared/
    └── widgets/
        ├── app_button.dart
        ├── app_text_field.dart
        ├── empty_state.dart
        ├── loading_overlay.dart
        ├── photo_attachment_widget.dart
        └── pin_numpad.dart
```

---

## API Endpoints & External Services

### Google Gemini API
- **Model:** gemini-2.5-flash (Stable)
- **Usage:** Financial advisor suggestions, slip analysis
- **Authentication:** API Key (stored securely)
- **Endpoint:** https://generativelanguage.googleapis.com

### Google ML Kit
- **Text Recognition:** On-device OCR
- **Barcode Scanning:** QR code detection
- **Platform:** Android/iOS native

### OpenStreetMap
- **Service:** Free map tiles (no API key required)
- **Usage:** Transaction location mapping
- **Library:** flutter_map

---

## Permissions Required

### Android
- `ACCESS_MEDIA_LOCATION` - Read GPS from photos (Android 10+)
- `READ_MEDIA_IMAGES` - Read images (Android 13+)
- `CAMERA` - Camera access
- `ACCESS_FINE_LOCATION` - Current location access
- `INTERNET` - Network access

### iOS
- `NSPhotoLibraryUsageDescription` - Photo library access
- `NSCameraUsageDescription` - Camera access
- `NSLocationWhenInUseUsageDescription` - Location access

---

## Data Flow

### Transaction Creation Flow
```
User Input → Form Validation → Transaction Model → Repository → Database
                                                      ↓
                                              Account Balance Update
```

### OCR Flow
```
Photo Selection → EXIF GPS Extraction → OCR Processing → QR Parsing → Data Extraction → Form Population
```

### AI Suggestions Flow
```
Reports Screen → Load Monthly Data → Build Prompt → Gemini API → Parse Response → Display Suggestions
```

---

## Security Features

1. **PIN Protection**
   - 4-digit PIN required
   - Encrypted storage
   - Lockout after 3 failed attempts
   - 60-minute lockout duration

2. **Data Encryption**
   - Secure storage for sensitive data
   - Encrypted SharedPreferences (Android)
   - Keychain (iOS)

3. **Privacy**
   - Offline-first architecture
   - Local data storage
   - No cloud sync (by default)
   - PDPA compliance

---

## Performance Optimizations

1. **Database Indexing**
   - Account ID index
   - Transaction date index
   - Category index

2. **Image Optimization**
   - Thumbnail generation
   - Image compression
   - Lazy loading

3. **Caching**
   - Account list caching
   - Recent transactions caching
   - Map marker caching

---

## Error Handling

- Try-catch blocks in all async operations
- User-friendly error messages
- Logging for debugging
- Graceful degradation
- Offline mode support

---

## Testing Considerations

- Unit tests for repositories
- Widget tests for UI components
- Integration tests for flows
- Manual testing checklist available

---

**End of Documentation**

*This document is automatically generated and should be updated when new features are added.*


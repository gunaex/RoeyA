import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': _enUS,
    'th': _thTH,
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Common
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get confirm => translate('confirm');
  String get next => translate('next');
  String get back => translate('back');
  String get done => translate('done');
  String get ok => translate('ok');
  String get yes => translate('yes');
  String get no => translate('no');
  String get exitConfirmation => translate('exit_confirmation');
  String get retry => translate('retry');
  String get account => translate('account');
  String get transactionType => translate('transaction_type');
  
  // App
  String get appName => translate('app_name');
  String get welcome => translate('welcome');
  String get getStarted => translate('get_started');
  
  // PDPA & Consent
  String get privacyPolicy => translate('privacy_policy');
  String get termsOfUse => translate('terms_of_use');
  String get consentTitle => translate('consent_title');
  String get consentMessage => translate('consent_message');
  String get consentCheckbox => translate('consent_checkbox');
  String get dataCollectionTitle => translate('data_collection_title');
  String get dataCollectionAccount => translate('data_collection_account');
  String get dataCollectionFinancial => translate('data_collection_financial');
  String get dataCollectionLocation => translate('data_collection_location');
  String get dataCollectionMedia => translate('data_collection_media');
  String get dataCollectionAI => translate('data_collection_ai');
  String get accept => translate('accept');
  String get decline => translate('decline');
  String get cannotContinue => translate('cannot_continue');
  String get declineMessage => translate('decline_message');
  
  // PIN
  String get createPin => translate('create_pin');
  String get confirmPin => translate('confirm_pin');
  String get enterPin => translate('enter_pin');
  String get pinMismatch => translate('pin_mismatch');
  String get forgotPin => translate('forgot_pin');
  String get changePin => translate('change_pin');
  
  // Recovery Email
  String get recoveryEmail => translate('recovery_email');
  String get enterRecoveryEmail => translate('enter_recovery_email');
  String get recoveryEmailHint => translate('recovery_email_hint');
  
  // Dashboard
  String get dashboard => translate('dashboard');
  String get netWorth => translate('net_worth');
  String get assets => translate('assets');
  String get liabilities => translate('liabilities');
  String get equity => translate('equity');
  String get revenue => translate('revenue');
  String get income => translate('income');
  String get expense => translate('expense');
  String get recentTransactions => translate('recent_transactions');
  String get viewAll => translate('view_all');
  
  // Transactions
  String get addTransaction => translate('add_transaction');
  String get scanSlip => translate('scan_slip');
  String get scanTransferSlip => translate('scan_transfer_slip');
  String get manualEntry => translate('manual_entry');
  String get amount => translate('amount');
  String get category => translate('category');
  String get description => translate('description');
  String get date => translate('date');
  String get note => translate('note');
  String get takePhoto => translate('take_photo');
  String get gallery => translate('gallery');
  String get scanning => translate('scanning');
  String get cannotReadSlip => translate('cannot_read_slip');
  String get recipient => translate('recipient');
  String get reference => translate('reference');
  String get saveToAccount => translate('save_to_account');
  String get pleaseEnterValidAmount => translate('please_enter_valid_amount');
  String get savedSuccessfully => translate('saved_successfully');
  String get editedSuccessfully => translate('edited_successfully');
  
  // Accounts
  String get accounts => translate('accounts');
  String get accountName => translate('account_name');
  String get addAccount => translate('add_account');
  String get editAccount => translate('edit_account');
  String get selectCategory => translate('select_category');
  String get selectAccount => translate('select_account');
  String get balance => translate('balance');
  String get initialBalance => translate('initial_balance');
  
  // Account Categories
  String get categoryAssets => translate('cat_assets');
  String get categoryLiabilities => translate('cat_liabilities');
  String get categoryEquity => translate('cat_equity');
  String get categoryIncome => translate('cat_income');
  String get categoryExpense => translate('cat_expense');

  // Transaction Categories - Income
  String get catSalary => translate('cat_salary');
  String get catFreelance => translate('cat_freelance');
  String get catInvestment => translate('cat_investment');
  String get catGift => translate('cat_gift');
  String get catRefund => translate('cat_refund');
  String get catOtherIncome => translate('cat_other_income');
  
  // Transaction Categories - Expense
  String get catFoodDining => translate('cat_food_dining');
  String get catTransportation => translate('cat_transportation');
  String get catShopping => translate('cat_shopping');
  String get catBillsUtilities => translate('cat_bills_utilities');
  String get catEntertainment => translate('cat_entertainment');
  String get catHealthcare => translate('cat_healthcare');
  String get catEducation => translate('cat_education');
  String get catTravel => translate('cat_travel');
  String get catTransfer => translate('cat_transfer');
  String get catOtherExpense => translate('cat_other_expense');

  // Reports
  String get reports => translate('reports');
  String get monthlySummary => translate('monthly_summary');
  String get incomeVsExpense => translate('income_vs_expense');
  String get breakdown => translate('breakdown');
  String get netBalance => translate('net_balance');
  String get noTransactionsThisMonth => translate('no_transactions_this_month');
  String get addTransactionsToSeeReports => translate('add_transactions_to_see_reports');
  String get transactions => translate('transactions');
  String get aiSuggestions => translate('ai_suggestions');
  String get aiSuggestionsDesc => translate('ai_suggestions_desc');
  String get configureAiToEnable => translate('configure_ai_to_enable');
  String get generatingSuggestions => translate('generating_suggestions');
  String get failedToGenerateSuggestions => translate('failed_to_generate_suggestions');
  String get refreshSuggestions => translate('refresh_suggestions');

  // Settings
  String get settings => translate('settings');
  String get language => translate('language');
  String get currency => translate('currency');
  String get security => translate('security');
  String get about => translate('about');
  String get geminiApiKey => translate('gemini_api_key');
  String get bulkImportOcr => translate('bulk_import_ocr');
  String get dataAndReports => translate('data_and_reports');
  
  // Messages
  String get offlineMode => translate('offline_mode');
  String get onlineMode => translate('online_mode');
  String get noInternetConnection => translate('no_internet_connection');
  String get dataLoading => translate('data_loading');
  String get noDataAvailable => translate('no_data_available');
  String get location => translate('location');
  String get transactionLocation => translate('transaction_location');
  String get mapView => translate('map_view');
  
  // Settings Screen Additional
  String get app => translate('app');
  String get aiFeatures => translate('ai_features');
  String get configureAi => translate('configure_ai');
  String get transactionMap => translate('transaction_map');
  String get viewLocationsOnMap => translate('view_locations_on_map');
  String get bulkImportDesc => translate('bulk_import_desc');
  String get version => translate('version');
  String get selectLanguage => translate('select_language');
  String get selectCurrency => translate('select_currency');
  String get clearAllData => translate('clear_all_data');
  String get clearDataWarning => translate('clear_data_warning');
  String get deleteAll => translate('delete_all');
  String get notSet => translate('not_set');
  String get apiKeySaved => translate('api_key_saved');
  String get enterApiKey => translate('enter_api_key');
  String get apiKeyHint => translate('api_key_hint');
  String get validatingApiKey => translate('validating_api_key');
  String get apiKeyValid => translate('api_key_valid');
  String get apiKeyInvalid => translate('api_key_invalid');
  String get apiKeySavedSuccess => translate('api_key_saved_success');
  
  // Transaction Mode Screen
  String get howToAddTransaction => translate('how_to_add_transaction');
  String get scanSlipOcr => translate('scan_slip_ocr');
  String get scanSlipOcrDesc => translate('scan_slip_ocr_desc');
  String get manualEntryDesc => translate('manual_entry_desc');
  
  // Budgets
  String get budgets => translate('budgets');
  String get budget => translate('budget');
  String get setBudget => translate('set_budget');
  String get editBudget => translate('edit_budget');
  String get deleteBudget => translate('delete_budget');
  String get monthlyBudget => translate('monthly_budget');
  String get categoryBudget => translate('category_budget');
  String get budgetAmount => translate('budget_amount');
  String get selectMonth => translate('select_month');
  String get budgetVsActual => translate('budget_vs_actual');
  String get budgetExceeded => translate('budget_exceeded');
  String get budgetWarning => translate('budget_warning');
  String get budgetUsage => translate('budget_usage');
  String get noBudgetSet => translate('no_budget_set');
  String get overBudget => translate('over_budget');
  String get withinBudget => translate('within_budget');
  
  // Search
  String get search => translate('search');
  String get searchTransactions => translate('search_transactions');
  String get searchHint => translate('search_hint');
  String get filters => translate('filters');
  String get applyFilters => translate('apply_filters');
  String get clearFilters => translate('clear_filters');
  String get searchResults => translate('search_results');
  String get noResults => translate('no_results');
  String get dateRange => translate('date_range');
  String get amountRange => translate('amount_range');
  String get minAmount => translate('min_amount');
  String get maxAmount => translate('max_amount');
  String get fromDate => translate('from_date');
  String get toDate => translate('to_date');
  
  // Templates
  String get templates => translate('templates');
  String get template => translate('template');
  String get saveAsTemplate => translate('save_as_template');
  String get useTemplate => translate('use_template');
  String get templateName => translate('template_name');
  String get createTemplate => translate('create_template');
  String get editTemplate => translate('edit_template');
  String get deleteTemplate => translate('delete_template');
  String get selectTemplate => translate('select_template');
  String get noTemplates => translate('no_templates');
  String get templateSaved => translate('template_saved');
  
  // Helper method to get localized category name
  String getCategoryName(String categoryKey) {
    final key = 'cat_${categoryKey.toLowerCase().replaceAll(' ', '_').replaceAll('&', '').replaceAll('/', '_')}';
    final translated = translate(key);
    // If no translation found, return original
    return translated == key ? categoryKey : translated;
  }
}

// English
const Map<String, String> _enUS = {
  'app_name': 'RoeyA',
  'welcome': 'Welcome to RoeyA',
  'get_started': 'Get Started',
  
  // PDPA & Consent
  'privacy_policy': 'Privacy Policy',
  'terms_of_use': 'Terms of Use',
  'consent_title': 'Privacy & Terms',
  'consent_message': 'Before using the service, please read and consent to our Privacy Policy and Terms of Service.',
  'consent_checkbox': 'I have read and agree to the Privacy Policy and Terms of Service',
  'data_collection_title': 'We may collect the following personal data:',
  'data_collection_account': 'Account information (name, email, password)',
  'data_collection_financial': 'Financial and expense tracking data',
  'data_collection_location': 'Device location (from photo metadata)',
  'data_collection_media': 'Uploaded photos and receipts',
  'data_collection_ai': 'AI/Chat interaction data',
  'accept': 'Accept',
  'decline': 'Decline',
  'cannot_continue': 'Cannot Continue',
  'decline_message': 'You must accept the Privacy Policy and Terms of Use to use this app.',
  
  // PIN
  'create_pin': 'Create PIN',
  'confirm_pin': 'Confirm PIN',
  'enter_pin': 'Enter PIN',
  'pin_mismatch': 'PINs do not match',
  'forgot_pin': 'Forgot PIN?',
  'change_pin': 'Change PIN',
  
  // Recovery Email
  'recovery_email': 'Recovery Email',
  'enter_recovery_email': 'Enter your email for PIN recovery',
  'recovery_email_hint': 'Used only for PIN recovery',
  
  // Common
  'save': 'Save',
  'cancel': 'Cancel',
  'delete': 'Delete',
  'edit': 'Edit',
  'confirm': 'Confirm',
  'next': 'Next',
  'back': 'Back',
  'done': 'Done',
  'ok': 'OK',
  'yes': 'Yes',
  'no': 'No',
  'exit_confirmation': 'Do you want to exit the app?',
  'retry': 'Retry',
  'account': 'Account',
  'transaction_type': 'Transaction Type',

  // Dashboard
  'dashboard': 'Dashboard',
  'net_worth': 'Net Worth',
  'assets': 'Assets',
  'liabilities': 'Liabilities',
  'equity': 'Equity',
  'revenue': 'Revenue',
  'income': 'Income',
  'expense': 'Expense',
  'recent_transactions': 'Recent Transactions',
  'view_all': 'View All',
  
  // Transactions
  'add_transaction': 'Add Transaction',
  'scan_slip': 'Scan Slip',
  'scan_transfer_slip': 'Scan Transfer Slip',
  'manual_entry': 'Manual Entry',
  'amount': 'Amount',
  'category': 'Category',
  'description': 'Description',
  'date': 'Date',
  'note': 'Note',
  'take_photo': 'Take Photo',
  'gallery': 'Gallery',
  'scanning': 'Scanning...',
  'cannot_read_slip': 'Cannot read slip',
  'recipient': 'Recipient',
  'reference': 'Reference',
  'save_to_account': 'Save to Account',
  'please_enter_valid_amount': 'Please enter a valid amount',
  'saved_successfully': 'Saved successfully',
  'edited_successfully': 'Edited successfully',

  // Accounts
  'accounts': 'Accounts',
  'account_name': 'Account Name',
  'add_account': 'Add Account',
  'edit_account': 'Edit Account',
  'select_category': 'Select Category',
  'select_account': 'Select Account',
  'balance': 'Balance',
  'initial_balance': 'Initial Balance',
  
  // Account Categories
  'cat_assets': 'Assets',
  'cat_liabilities': 'Liabilities',
  'cat_equity': 'Equity',
  'cat_income': 'Income/Revenue',
  'cat_expense': 'Expenses',
  
  // Transaction Categories - Income
  'cat_salary': 'Salary',
  'cat_freelance': 'Freelance',
  'cat_investment': 'Investment',
  'cat_gift': 'Gift',
  'cat_refund': 'Refund',
  'cat_other_income': 'Other Income',
  
  // Transaction Categories - Expense
  'cat_food_dining': 'Food & Dining',
  'cat_food__dining': 'Food & Dining',
  'cat_transportation': 'Transportation',
  'cat_shopping': 'Shopping',
  'cat_bills_utilities': 'Bills & Utilities',
  'cat_bills__utilities': 'Bills & Utilities',
  'cat_entertainment': 'Entertainment',
  'cat_healthcare': 'Healthcare',
  'cat_education': 'Education',
  'cat_travel': 'Travel',
  'cat_transfer': 'Transfer',
  'cat_other_expense': 'Other Expense',

  // Reports
  'reports': 'Reports',
  'monthly_summary': 'Monthly Summary',
  'income_vs_expense': 'Income vs Expense',
  'breakdown': 'Breakdown',
  'net_balance': 'Net Balance',
  'no_transactions_this_month': 'No transactions this month',
  'add_transactions_to_see_reports': 'Add some transactions to see your reports',
  'transactions': 'transactions',
  'ai_suggestions': 'AI Financial Advisor',
  'ai_suggestions_desc': 'Personalized financial recommendations based on your spending patterns',
  'configure_ai_to_enable': 'Configure Gemini API Key in Settings to enable AI suggestions',
  'generating_suggestions': 'Generating AI suggestions...',
  'failed_to_generate_suggestions': 'Failed to generate suggestions. Please check your API key.',
  'refresh_suggestions': 'Refresh Suggestions',

  // Settings
  'settings': 'Settings',
  'language': 'Language',
  'currency': 'Currency',
  'security': 'Security',
  'about': 'About',
  'gemini_api_key': 'Gemini API Key',
  'bulk_import_ocr': 'Bulk Import (OCR)',
  'data_and_reports': 'Data & Reports',
  
  // Messages
  'offline_mode': 'Offline Mode',
  'online_mode': 'Online',
  'no_internet_connection': 'No internet connection. Offline mode enabled.',
  'data_loading': 'Loading...',
  'no_data_available': 'No data available',
  'location': 'Location',
  'transaction_location': 'Transaction Location',
  'map_view': 'Map View',
  
  // Settings Screen Additional
  'app': 'App',
  'ai_features': 'AI Features',
  'configure_ai': 'Configure AI features',
  'transaction_map': 'Transaction Map',
  'view_locations_on_map': 'View locations on map',
  'bulk_import_desc': 'Import multiple slips at once',
  'version': 'Version',
  'select_language': 'Select Language',
  'select_currency': 'Select Base Currency',
  'clear_all_data': 'Clear All Data',
  'clear_data_warning': 'This will permanently delete all your data including accounts, transactions, and settings. This action cannot be undone.',
  'delete_all': 'Delete All',
  'not_set': 'Not set',
  'api_key_saved': 'API Key saved',
  'enter_api_key': 'Enter your Google Gemini API key to enable AI features like slip scanning.',
  'api_key_hint': 'API Key',
  'validating_api_key': 'Validating API key...',
  'api_key_valid': '✅ API Key is valid',
  'api_key_invalid': '❌ API Key is invalid. Please check your key and try again.',
  'api_key_saved_success': 'API Key saved successfully',
  
  // Transaction Mode Screen
  'how_to_add_transaction': 'How would you like to add this transaction?',
  'scan_slip_ocr': 'Scan Slip (OCR)',
  'scan_slip_ocr_desc': 'Auto-read slip with AI (free, no internet required)',
  'manual_entry_desc': 'Enter transaction details manually',
};

// Thai
const Map<String, String> _thTH = {
  'app_name': 'RoeyA',
  'welcome': 'ยินดีต้อนรับสู่ RoeyA',
  'get_started': 'เริ่มต้นใช้งาน',
  
  // PDPA & Consent
  'privacy_policy': 'นโยบายความเป็นส่วนตัว',
  'terms_of_use': 'ข้อกำหนดการใช้งาน',
  'consent_title': 'ความเป็นส่วนตัวและข้อกำหนด',
  'consent_message': 'ก่อนเริ่มใช้งาน กรุณาอ่านและยืนยันความยินยอมต่อ นโยบายความเป็นส่วนตัว และ ข้อกำหนดการใช้งาน',
  'consent_checkbox': 'ข้าพเจ้าได้อ่านและยินยอมตาม นโยบายความเป็นส่วนตัว และ ข้อกำหนดการใช้งาน',
  'data_collection_title': 'เราอาจเก็บข้อมูลส่วนบุคคลดังนี้:',
  'data_collection_account': 'ข้อมูลบัญชี (ชื่อ, อีเมล, รหัสผ่าน)',
  'data_collection_financial': 'ข้อมูลการเงินและการบันทึกบัญชี',
  'data_collection_location': 'ตำแหน่งของอุปกรณ์ (จากข้อมูลรูปถ่าย)',
  'data_collection_media': 'รูปถ่ายและสื่อที่ท่านอัปโหลด',
  'data_collection_ai': 'ข้อมูลที่สร้างจาก AI / Chat',
  'accept': 'ยอมรับ',
  'decline': 'ไม่ยอมรับ',
  'cannot_continue': 'ไม่สามารถดำเนินการต่อได้',
  'decline_message': 'คุณต้องยอมรับนโยบายความเป็นส่วนตัวและข้อกำหนดการใช้งานเพื่อใช้งานแอปนี้',
  
  // PIN
  'create_pin': 'สร้างรหัส PIN',
  'confirm_pin': 'ยืนยันรหัส PIN',
  'enter_pin': 'ใส่รหัส PIN',
  'pin_mismatch': 'รหัส PIN ไม่ตรงกัน',
  'forgot_pin': 'ลืมรหัส PIN?',
  'change_pin': 'เปลี่ยนรหัส PIN',
  
  // Recovery Email
  'recovery_email': 'อีเมลสำหรับกู้คืน',
  'enter_recovery_email': 'ใส่อีเมลของคุณสำหรับกู้คืนรหัส PIN',
  'recovery_email_hint': 'ใช้สำหรับกู้คืนรหัส PIN เท่านั้น',
  
  // Common
  'save': 'บันทึก',
  'cancel': 'ยกเลิก',
  'delete': 'ลบ',
  'edit': 'แก้ไข',
  'confirm': 'ยืนยัน',
  'next': 'ถัดไป',
  'back': 'กลับ',
  'done': 'เสร็จสิ้น',
  'ok': 'ตกลง',
  'yes': 'ใช่',
  'no': 'ไม่',
  'exit_confirmation': 'คุณต้องการออกจากแอปหรือไม่?',
  'retry': 'ลองอีกครั้ง',
  'account': 'บัญชี',
  'transaction_type': 'ประเภทรายการ',

  // Dashboard
  'dashboard': 'หน้าหลัก',
  'net_worth': 'มูลค่าสุทธิ',
  'assets': 'สินทรัพย์',
  'liabilities': 'หนี้สิน',
  'equity': 'ส่วนของเจ้าของ',
  'revenue': 'รายได้',
  'income': 'รายได้',
  'expense': 'ค่าใช้จ่าย',
  'recent_transactions': 'รายการล่าสุด',
  'view_all': 'ดูทั้งหมด',
  
  // Transactions
  'add_transaction': 'เพิ่มรายการ',
  'scan_slip': 'สแกนสลิป',
  'scan_transfer_slip': 'สแกนสลิปโอนเงิน',
  'manual_entry': 'กรอกข้อมูลเอง',
  'amount': 'จำนวนเงิน',
  'category': 'หมวดหมู่',
  'description': 'รายละเอียด',
  'date': 'วันที่',
  'note': 'หมายเหตุ',
  'take_photo': 'ถ่ายรูป',
  'gallery': 'แกลเลอรี',
  'scanning': 'กำลังอ่านสลิป...',
  'cannot_read_slip': 'ไม่สามารถอ่านสลิปได้',
  'recipient': 'ผู้รับ',
  'reference': 'เลขอ้างอิง',
  'save_to_account': 'บันทึกลงบัญชี',
  'please_enter_valid_amount': 'กรุณาใส่จำนวนเงินที่ถูกต้อง',
  'saved_successfully': 'บันทึกสำเร็จ',
  'edited_successfully': 'แก้ไขสำเร็จ',

  // Accounts
  'accounts': 'บัญชี',
  'account_name': 'ชื่อบัญชี',
  'add_account': 'เพิ่มบัญชี',
  'edit_account': 'แก้ไขบัญชี',
  'select_category': 'เลือกหมวดหมู่',
  'select_account': 'เลือกบัญชี',
  'balance': 'ยอดคงเหลือ',
  'initial_balance': 'ยอดเริ่มต้น',
  
  // Account Categories
  'cat_assets': 'สินทรัพย์',
  'cat_liabilities': 'หนี้สิน',
  'cat_equity': 'ส่วนของเจ้าของ',
  'cat_income': 'รายได้',
  'cat_expense': 'ค่าใช้จ่าย',
  
  // Transaction Categories - Income
  'cat_salary': 'เงินเดือน',
  'cat_freelance': 'รายได้ฟรีแลนซ์',
  'cat_investment': 'เงินลงทุน',
  'cat_gift': 'ของขวัญ/เงินให้',
  'cat_refund': 'เงินคืน',
  'cat_other_income': 'รายได้อื่นๆ',
  
  // Transaction Categories - Expense
  'cat_food_dining': 'อาหารและเครื่องดื่ม',
  'cat_food__dining': 'อาหารและเครื่องดื่ม',
  'cat_transportation': 'การเดินทาง',
  'cat_shopping': 'ช้อปปิ้ง',
  'cat_bills_utilities': 'ค่าสาธารณูปโภค',
  'cat_bills__utilities': 'ค่าสาธารณูปโภค',
  'cat_entertainment': 'ความบันเทิง',
  'cat_healthcare': 'สุขภาพ/การแพทย์',
  'cat_education': 'การศึกษา',
  'cat_travel': 'ท่องเที่ยว',
  'cat_transfer': 'โอนเงิน',
  'cat_other_expense': 'ค่าใช้จ่ายอื่นๆ',

  // Reports
  'reports': 'รายงาน',
  'monthly_summary': 'สรุปรายเดือน',
  'income_vs_expense': 'รายรับ vs รายจ่าย',
  'breakdown': 'แยกตามหมวดหมู่',
  'net_balance': 'ยอดคงเหลือสุทธิ',
  'no_transactions_this_month': 'ไม่มีรายการในเดือนนี้',
  'add_transactions_to_see_reports': 'เพิ่มรายการเพื่อดูรายงาน',
  'transactions': 'รายการ',
  'ai_suggestions': 'ที่ปรึกษาทางการเงิน AI',
  'ai_suggestions_desc': 'คำแนะนำทางการเงินส่วนบุคคลตามรูปแบบการใช้จ่ายของคุณ',
  'configure_ai_to_enable': 'ตั้งค่า Gemini API Key ในตั้งค่าเพื่อเปิดใช้งานคำแนะนำ AI',
  'generating_suggestions': 'กำลังสร้างคำแนะนำ AI...',
  'failed_to_generate_suggestions': 'ไม่สามารถสร้างคำแนะนำได้ กรุณาตรวจสอบ API Key ของคุณ',
  'refresh_suggestions': 'รีเฟรชคำแนะนำ',

  // Settings
  'settings': 'ตั้งค่า',
  'language': 'ภาษา',
  'currency': 'สกุลเงิน',
  'security': 'ความปลอดภัย',
  'about': 'เกี่ยวกับ',
  'gemini_api_key': 'Gemini API Key',
  'bulk_import_ocr': 'นำเข้าหลายรายการ (OCR)',
  'data_and_reports': 'ข้อมูลและรายงาน',
  
  // Messages
  'offline_mode': 'โหมดออฟไลน์',
  'online_mode': 'ออนไลน์',
  'no_internet_connection': 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต เปิดใช้งานโหมดออฟไลน์',
  'data_loading': 'กำลังโหลด...',
  'no_data_available': 'ไม่มีข้อมูล',
  'location': 'ตำแหน่งที่ตั้ง',
  'transaction_location': 'ตำแหน่งที่ทำรายการ',
  'map_view': 'ดูแผนที่',
  
  // Settings Screen Additional
  'app': 'แอปพลิเคชัน',
  'ai_features': 'ฟีเจอร์ AI',
  'configure_ai': 'ตั้งค่าฟีเจอร์ AI',
  'transaction_map': 'แผนที่รายการ',
  'view_locations_on_map': 'ดูตำแหน่งบนแผนที่',
  'bulk_import_desc': 'นำเข้าสลิปพร้อมกันหลายรูป',
  'version': 'เวอร์ชัน',
  'select_language': 'เลือกภาษา',
  'select_currency': 'เลือกสกุลเงินหลัก',
  'clear_all_data': 'ล้างข้อมูลทั้งหมด',
  'clear_data_warning': 'การดำเนินการนี้จะลบข้อมูลทั้งหมดของคุณรวมถึงบัญชี รายการ และการตั้งค่า ไม่สามารถกู้คืนได้',
  'delete_all': 'ลบทั้งหมด',
  'not_set': 'ยังไม่ได้ตั้งค่า',
  'api_key_saved': 'บันทึก API Key แล้ว',
  'enter_api_key': 'ใส่ Google Gemini API Key เพื่อเปิดใช้งานฟีเจอร์ AI เช่น การสแกนสลิป',
  'api_key_hint': 'API Key',
  'validating_api_key': 'กำลังตรวจสอบ API Key...',
  'api_key_valid': '✅ API Key ถูกต้อง',
  'api_key_invalid': '❌ API Key ไม่ถูกต้อง กรุณาตรวจสอบและลองอีกครั้ง',
  'api_key_saved_success': 'บันทึก API Key สำเร็จ',
  
  // Transaction Mode Screen
  'how_to_add_transaction': 'คุณต้องการเพิ่มรายการอย่างไร?',
  'scan_slip_ocr': 'สแกนสลิป (OCR)',
  'scan_slip_ocr_desc': 'อ่านสลิปอัตโนมัติด้วย AI (ฟรี, ไม่ต้องใช้อินเทอร์เน็ต)',
  'manual_entry_desc': 'กรอกรายละเอียดธุรกรรมด้วยตนเอง',
  
  // Budgets
  'budgets': 'งบประมาณ',
  'budget': 'งบประมาณ',
  'set_budget': 'ตั้งงบประมาณ',
  'edit_budget': 'แก้ไขงบประมาณ',
  'delete_budget': 'ลบงบประมาณ',
  'monthly_budget': 'งบประมาณรายเดือน',
  'category_budget': 'งบประมาณตามหมวดหมู่',
  'budget_amount': 'จำนวนงบประมาณ',
  'select_month': 'เลือกเดือน',
  'budget_vs_actual': 'งบประมาณ vs จริง',
  'budget_exceeded': 'เกินงบประมาณ',
  'budget_warning': 'เตือนงบประมาณ',
  'budget_usage': 'การใช้งบประมาณ',
  'no_budget_set': 'ยังไม่ได้ตั้งงบประมาณ',
  'over_budget': 'เกินงบประมาณ',
  'within_budget': 'อยู่ในงบประมาณ',
  
  // Search
  'search': 'ค้นหา',
  'search_transactions': 'ค้นหารายการ',
  'search_hint': 'ค้นหาตามคำอธิบาย, หมายเหตุ, หรือหมวดหมู่...',
  'filters': 'ตัวกรอง',
  'apply_filters': 'ใช้ตัวกรอง',
  'clear_filters': 'ล้างตัวกรอง',
  'search_results': 'ผลการค้นหา',
  'no_results': 'ไม่พบผลลัพธ์',
  'date_range': 'ช่วงวันที่',
  'amount_range': 'ช่วงจำนวนเงิน',
  'min_amount': 'จำนวนเงินขั้นต่ำ',
  'max_amount': 'จำนวนเงินสูงสุด',
  'from_date': 'จากวันที่',
  'to_date': 'ถึงวันที่',
  
  // Templates
  'templates': 'เทมเพลต',
  'template': 'เทมเพลต',
  'save_as_template': 'บันทึกเป็นเทมเพลต',
  'use_template': 'ใช้เทมเพลต',
  'template_name': 'ชื่อเทมเพลต',
  'create_template': 'สร้างเทมเพลต',
  'edit_template': 'แก้ไขเทมเพลต',
  'delete_template': 'ลบเทมเพลต',
  'select_template': 'เลือกเทมเพลต',
  'no_templates': 'ไม่มีเทมเพลต',
  'template_saved': 'บันทึกเทมเพลตสำเร็จ',
};

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'th'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

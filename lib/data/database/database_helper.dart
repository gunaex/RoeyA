import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _initialized = false;

  DatabaseHelper._init();

  Future<void> _initializeDatabaseFactory() async {
    if (_initialized) return;
    
    // Skip database initialization on web (not supported)
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    
    // Initialize FFI for desktop platforms (Windows, Linux, macOS)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    _initialized = true;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    await _initializeDatabaseFactory();
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // Web platform doesn't support SQLite
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite is not supported on web. Please use a mobile or desktop app.',
      );
    }
    
    String dbPath;
    
    // Get appropriate path based on platform
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final appDir = await getApplicationDocumentsDirectory();
      dbPath = appDir.path;
    } else {
      // Mobile (Android/iOS)
      dbPath = await getDatabasesPath();
    }
    
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Accounts table
    await db.execute('''
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
    ''');

    // Transactions table
    await db.execute('''
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
        is_subscription INTEGER NOT NULL DEFAULT 0,
        frequency TEXT,
        subscription_id TEXT,
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    // Currency rates table
    await db.execute('''
      CREATE TABLE currency_rates (
        id TEXT PRIMARY KEY,
        from_currency TEXT NOT NULL,
        to_currency TEXT NOT NULL,
        rate REAL NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(from_currency, to_currency)
      )
    ''');

    // Budgets table
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        category TEXT,
        amount REAL NOT NULL,
        currency_code TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Transaction templates table
    await db.execute('''
      CREATE TABLE transaction_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT,
        account_id TEXT,
        amount REAL NOT NULL,
        currency_code TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    // Subscriptions table
    await db.execute('''
      CREATE TABLE subscriptions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        currency_code TEXT NOT NULL,
        frequency TEXT NOT NULL,
        category TEXT,
        icon TEXT,
        color_value INTEGER NOT NULL,
        next_billing_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX idx_transactions_account_id 
      ON transactions(account_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_date 
      ON transactions(transaction_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_accounts_category 
      ON accounts(category)
    ''');

    await db.execute('''
      CREATE INDEX idx_budgets_year_month_category 
      ON budgets(year, month, category)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_category 
      ON transactions(category)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_description 
      ON transactions(description)
    ''');

    await db.execute('''
      CREATE INDEX idx_subscriptions_name 
      ON subscriptions(name)
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migration from version 1 to 2: Add budgets and templates tables
    if (oldVersion < 2) {
      // Budgets table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets (
          id TEXT PRIMARY KEY,
          year INTEGER NOT NULL,
          month INTEGER NOT NULL,
          category TEXT,
          amount REAL NOT NULL,
          currency_code TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Transaction templates table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transaction_templates (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          category TEXT,
          account_id TEXT,
          amount REAL NOT NULL,
          currency_code TEXT NOT NULL,
          note TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (account_id) REFERENCES accounts (id)
        )
      ''');

      // Add indexes
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_budgets_year_month_category 
        ON budgets(year, month, category)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_transactions_category 
        ON transactions(category)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_transactions_description 
        ON transactions(description)
      ''');
    }

    // Migration from version 2 to 3: Add subscriptions table and transaction subscription fields
    if (oldVersion < 3) {
      // Add subscription columns to transactions table
      await db.execute('ALTER TABLE transactions ADD COLUMN is_subscription INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE transactions ADD COLUMN frequency TEXT');
      await db.execute('ALTER TABLE transactions ADD COLUMN subscription_id TEXT');
      
      // Create subscriptions table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS subscriptions (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          amount REAL NOT NULL,
          currency_code TEXT NOT NULL,
          frequency TEXT NOT NULL,
          category TEXT,
          icon TEXT,
          color_value INTEGER NOT NULL,
          next_billing_date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_subscriptions_name 
        ON subscriptions(name)
      ''');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}


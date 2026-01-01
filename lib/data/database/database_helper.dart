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
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    // This will be used in future versions
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


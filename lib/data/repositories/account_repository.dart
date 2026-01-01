import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/account.dart';

class AccountRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// สร้าง default accounts ถ้ายังไม่มี (first-time setup)
  Future<void> createDefaultAccountsIfNeeded() async {
    final accounts = await getAllAccounts();
    
    // ถ้ามี account แล้ว ไม่ต้องสร้างใหม่
    if (accounts.isNotEmpty) {
      return;
    }
    
    final now = DateTime.now();
    final uuid = const Uuid();
    
    // สร้าง default accounts สำหรับแต่ละหมวด (Ported from RoeyP but cleaner)
    final defaultAccounts = [
      Account(
        id: 'default', // ID พิเศษสำหรับ account หลัก
        name: 'เงินสด',
        category: AppConstants.categoryAssets,
        description: 'เงินสดในกระเป๋า',
        icon: 'wallet',
        currencyCode: 'THB',
        balance: 0.0,
        createdAt: now,
      ),
      Account(
        id: uuid.v4(),
        name: 'บัญชีธนาคาร',
        category: AppConstants.categoryAssets,
        description: 'บัญชีออมทรัพย์หลัก',
        icon: 'account_balance',
        currencyCode: 'THB',
        balance: 0.0,
        createdAt: now,
      ),
      Account(
        id: uuid.v4(),
        name: 'บัตรเครดิต',
        category: AppConstants.categoryLiabilities,
        description: 'ยอดค้างชำระบัตรเครดิต',
        icon: 'credit_card',
        currencyCode: 'THB',
        balance: 0.0,
        createdAt: now,
      ),
      Account(
        id: uuid.v4(),
        name: 'ทุนส่วนตัว',
        category: AppConstants.categoryEquity,
        description: 'ส่วนของเจ้าของเริ่มต้น',
        icon: 'pie_chart',
        currencyCode: 'THB',
        balance: 0.0,
        createdAt: now,
      ),
    ];
    
    for (final account in defaultAccounts) {
      await insertAccount(account);
    }
  }

  Future<List<Account>> getAllAccounts({bool includeDeleted = false}) async {
    final db = await _dbHelper.database;
    final whereClause = includeDeleted ? null : 'is_deleted = 0';
    
    final maps = await db.query(
      'accounts',
      where: whereClause,
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => Account.fromMap(map)).toList();
  }

  Future<List<Account>> getAccountsByCategory(String category, {bool includeDeleted = false}) async {
    final db = await _dbHelper.database;
    final whereClause = includeDeleted
        ? 'category = ?'
        : 'category = ? AND is_deleted = 0';
    
    final maps = await db.query(
      'accounts',
      where: whereClause,
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => Account.fromMap(map)).toList();
  }

  Future<Account?> getAccountById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  Future<String> insertAccount(Account account) async {
    final db = await _dbHelper.database;
    await db.insert('accounts', account.toMap());
    return account.id;
  }

  Future<int> updateAccount(Account account) async {
    final db = await _dbHelper.database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  /// helper สำหรับการ update balance (จะใช้ใน TransactionRepository)
  Future<void> updateBalanceInternal(dynamic db, String accountId, double amountDelta) async {
    // ใช้ dynamic db เพื่อให้รับได้ทั้ง Database และ Transaction object ของ sqflite
    await db.rawUpdate('''
      UPDATE accounts 
      SET balance = balance + ? 
      WHERE id = ?
    ''', [amountDelta, accountId]);
  }

  Future<int> softDeleteAccount(String id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'accounts',
      {
        'is_deleted': 1,
        'deleted_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getNetWorth() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN category = 'assets' THEN balance ELSE 0 END) -
        SUM(CASE WHEN category = 'liabilities' THEN balance ELSE 0 END) as net_worth
      FROM accounts
      WHERE is_deleted = 0
    ''');
    
    if (result.isEmpty || result.first['net_worth'] == null) {
      return 0.0;
    }
    
    return (result.first['net_worth'] as num).toDouble();
  }

  Future<Map<String, double>> getCategorySummary() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT category, SUM(balance) as total
      FROM accounts
      WHERE is_deleted = 0
      GROUP BY category
    ''');
    
    final summary = <String, double>{};
    for (final row in result) {
      summary[row['category'] as String] = (row['total'] as num).toDouble();
    }
    
    return summary;
  }
}

import '../database/database_helper.dart';
import '../models/transaction.dart' as model;
import 'account_repository.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AccountRepository _accountRepo = AccountRepository();

  Future<List<model.Transaction>> getAllTransactions({bool includeDeleted = false}) async {
    final db = await _dbHelper.database;
    final whereClause = includeDeleted ? null : 'is_deleted = 0';
    
    final maps = await db.query(
      'transactions',
      where: whereClause,
      orderBy: 'transaction_date DESC, created_at DESC',
    );
    
    return maps.map((map) => model.Transaction.fromMap(map)).toList();
  }

  Future<model.Transaction?> getTransactionById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return model.Transaction.fromMap(maps.first);
  }

  /// บันทึกรายการและอัปเดตยอดเงินในบัญชี (Transactional)
  Future<String> insertTransaction(model.Transaction transaction) async {
    final db = await _dbHelper.database;
    
    return await db.transaction((txn) async {
      // 1. บันทึก transaction
      await txn.insert('transactions', transaction.toMap());
      
      // 2. คำนวณ delta สำหรับ balance
      // Income -> balance + amount
      // Expense -> balance - amount
      double delta = transaction.type == 'income' ? transaction.amount : -transaction.amount;
      
      // 3. อัปเดต balance ในบัญชี
      await _accountRepo.updateBalanceInternal(txn, transaction.accountId, delta);
      
      return transaction.id;
    });
  }

  /// ลบรายการ (Soft Delete) และคืนยอดเงินในบัญชี (Transactional)
  Future<int> softDeleteTransaction(String id) async {
    final db = await _dbHelper.database;
    final transaction = await getTransactionById(id);
    
    if (transaction == null || transaction.isDeleted) return 0;
    
    return await db.transaction((txn) async {
      // 1. Mark as deleted
      final result = await txn.update(
        'transactions',
        {
          'is_deleted': 1,
          'deleted_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      
      // 2. คืนยอดเงิน (Reverse delta)
      // ถ้าเดิมเป็น Expense (ลบ) -> ต้องบวกคืน
      // ถ้าเดิมเป็น Income (บวก) -> ต้องลบออก
      double reverseDelta = transaction.type == 'income' ? -transaction.amount : transaction.amount;
      
      await _accountRepo.updateBalanceInternal(txn, transaction.accountId, reverseDelta);
      
      return result;
    });
  }

  /// อัปเดตรายการและปรับปรุงยอดเงินในบัญชี (Transactional)
  Future<int> updateTransaction(model.Transaction newTx) async {
    final db = await _dbHelper.database;
    final oldTx = await getTransactionById(newTx.id);
    
    if (oldTx == null) return 0;
    
    return await db.transaction((txn) async {
      // 1. คืนยอดเงินเดิม (Reverse old delta)
      double reverseOldDelta = oldTx.type == 'income' ? -oldTx.amount : oldTx.amount;
      await _accountRepo.updateBalanceInternal(txn, oldTx.accountId, reverseOldDelta);
      
      // 2. หัก/บวกยอดเงินใหม่ (Apply new delta)
      double newDelta = newTx.type == 'income' ? newTx.amount : -newTx.amount;
      await _accountRepo.updateBalanceInternal(txn, newTx.accountId, newDelta);
      
      // 3. อัปเดตข้อมูล
      return await txn.update(
        'transactions',
        newTx.toMap(),
        where: 'id = ?',
        whereArgs: [newTx.id],
      );
    });
  }

  // --- Summary Methods (Ported & Refined from RoeyP) ---

  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final db = await _dbHelper.database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    
    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as income,
        SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as expense
      FROM transactions
      WHERE is_deleted = 0
        AND transaction_date BETWEEN ? AND ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
    
    if (result.isEmpty) return {'income': 0.0, 'expense': 0.0};
    
    return {
      'income': (result.first['income'] as num?)?.toDouble() ?? 0.0,
      'expense': (result.first['expense'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getCategoryBreakdown(String type, int year, int month) async {
    final db = await _dbHelper.database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    
    return await db.rawQuery('''
      SELECT category, SUM(amount) as total, COUNT(*) as count
      FROM transactions
      WHERE type = ?
        AND is_deleted = 0
        AND transaction_date BETWEEN ? AND ?
        AND category IS NOT NULL
      GROUP BY category
      ORDER BY total DESC
    ''', [type, startDate.toIso8601String(), endDate.toIso8601String()]);
  }

  /// ดึงรายการล่าสุดสำหรับ Dashboard
  Future<List<model.Transaction>> getRecentTransactions({int limit = 10}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'transactions',
      where: 'is_deleted = 0',
      orderBy: 'transaction_date DESC, created_at DESC',
      limit: limit,
    );
    
    return maps.map((map) => model.Transaction.fromMap(map)).toList();
  }
}

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

  /// Search transactions with multiple filters
  Future<List<model.Transaction>> searchTransactions({
    String? query,
    String? category,
    String? accountId,
    DateTime? from,
    DateTime? to,
    double? minAmount,
    double? maxAmount,
    String? type, // 'income' or 'expense'
  }) async {
    final db = await _dbHelper.database;
    
    final List<String> whereConditions = ['is_deleted = 0'];
    final List<dynamic> whereArgs = [];
    
    // Keyword search in description, note, or category
    if (query != null && query.isNotEmpty) {
      whereConditions.add('(description LIKE ? OR note LIKE ? OR category LIKE ?)');
      final searchPattern = '%$query%';
      whereArgs.addAll([searchPattern, searchPattern, searchPattern]);
    }
    
    // Category filter
    if (category != null && category.isNotEmpty) {
      whereConditions.add('category = ?');
      whereArgs.add(category);
    }
    
    // Account filter
    if (accountId != null && accountId.isNotEmpty) {
      whereConditions.add('account_id = ?');
      whereArgs.add(accountId);
    }
    
    // Date range filter
    if (from != null) {
      whereConditions.add('transaction_date >= ?');
      whereArgs.add(from.toIso8601String());
    }
    if (to != null) {
      whereConditions.add('transaction_date <= ?');
      whereArgs.add(to.toIso8601String());
    }
    
    // Amount range filter
    if (minAmount != null) {
      whereConditions.add('amount >= ?');
      whereArgs.add(minAmount);
    }
    if (maxAmount != null) {
      whereConditions.add('amount <= ?');
      whereArgs.add(maxAmount);
    }
    
    // Type filter
    if (type != null && type.isNotEmpty) {
      whereConditions.add('type = ?');
      whereArgs.add(type);
    }
    
    final whereClause = whereConditions.join(' AND ');
    
    final maps = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'transaction_date DESC, created_at DESC',
    );
    
    return maps.map((map) => model.Transaction.fromMap(map)).toList();
  }

  /// Get category history for the last N months (for AI insights)
  Future<Map<DateTime, double>> getCategoryHistory(String category, int months) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months + 1, 1);
    
    final maps = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', transaction_date) as month,
        SUM(amount) as total
      FROM transactions
      WHERE category = ?
        AND is_deleted = 0
        AND transaction_date >= ?
      GROUP BY strftime('%Y-%m', transaction_date)
      ORDER BY month ASC
    ''', [category, startDate.toIso8601String()]);
    
    final history = <DateTime, double>{};
    for (var map in maps) {
      final monthStr = map['month'] as String;
      final parts = monthStr.split('-');
      if (parts.length == 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final total = (map['total'] as num?)?.toDouble() ?? 0.0;
        history[DateTime(year, month, 1)] = total;
      }
    }
    
    return history;
  }

  /// Get outlier transactions (anomaly detection)
  /// Flags transactions that are > threshold (default 3x) the average for their category
  Future<List<model.Transaction>> getOutlierTransactions(int year, int month, {double threshold = 3.0}) async {
    final db = await _dbHelper.database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    
    // First, get average amounts per category
    final avgMaps = await db.rawQuery('''
      SELECT 
        category,
        AVG(amount) as avg_amount,
        COUNT(*) as count
      FROM transactions
      WHERE is_deleted = 0
        AND category IS NOT NULL
        AND transaction_date BETWEEN ? AND ?
      GROUP BY category
      HAVING count >= 3
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
    
    final categoryAverages = <String, double>{};
    for (var map in avgMaps) {
      final category = map['category'] as String;
      final avg = (map['avg_amount'] as num?)?.toDouble() ?? 0.0;
      if (category != null && avg > 0) {
        categoryAverages[category] = avg;
      }
    }
    
    if (categoryAverages.isEmpty) return [];
    
    // Get all transactions for the month
    final allTransactions = await db.query(
      'transactions',
      where: 'is_deleted = 0 AND category IS NOT NULL AND transaction_date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    
    final outliers = <model.Transaction>[];
    for (var map in allTransactions) {
      final tx = model.Transaction.fromMap(map);
      if (tx.category != null && categoryAverages.containsKey(tx.category)) {
        final avg = categoryAverages[tx.category]!;
        if (tx.amount > avg * threshold) {
          outliers.add(tx);
        }
      }
    }
    
    return outliers;
  }
}

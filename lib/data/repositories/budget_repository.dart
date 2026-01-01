import '../database/database_helper.dart';
import '../models/budget.dart';

class BudgetRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert or update a budget (upsert)
  Future<String> upsertBudget(Budget budget) async {
    final db = await _dbHelper.database;
    
    // Check if budget exists for this year/month/category
    final existing = await getBudget(budget.year, budget.month, budget.category);
    
    if (existing != null) {
      // Update existing budget
      await db.update(
        'budgets',
        budget.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      return existing.id;
    } else {
      // Insert new budget
      await db.insert('budgets', budget.toMap());
      return budget.id;
    }
  }

  /// Get budget for specific year/month/category
  Future<Budget?> getBudget(int year, int month, String? category) async {
    final db = await _dbHelper.database;
    
    final whereClause = category == null
        ? 'year = ? AND month = ? AND category IS NULL'
        : 'year = ? AND month = ? AND category = ?';
    final whereArgs = category == null
        ? [year, month]
        : [year, month, category];
    
    final maps = await db.query(
      'budgets',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  /// Get all budgets for a specific month
  Future<List<Budget>> getBudgetsForMonth(int year, int month) async {
    final db = await _dbHelper.database;
    
    final maps = await db.query(
      'budgets',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
      orderBy: 'category ASC',
    );
    
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  /// Get all category budgets for a specific month
  Future<List<Budget>> getCategoryBudgets(int year, int month) async {
    final db = await _dbHelper.database;
    
    final maps = await db.query(
      'budgets',
      where: 'year = ? AND month = ? AND category IS NOT NULL',
      whereArgs: [year, month],
      orderBy: 'category ASC',
    );
    
    return maps.map((map) => Budget.fromMap(map)).toList();
  }

  /// Delete a budget
  Future<int> deleteBudget(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all budgets for a specific month
  Future<int> deleteBudgetsForMonth(int year, int month) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'budgets',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
    );
  }

  /// Get all budgets
  Future<List<Budget>> getAllBudgets() async {
    final db = await _dbHelper.database;
    
    final maps = await db.query(
      'budgets',
      orderBy: 'year DESC, month DESC, category ASC',
    );
    
    return maps.map((map) => Budget.fromMap(map)).toList();
  }
}


import '../database/database_helper.dart';
import '../models/transaction_template.dart';

class TemplateRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert a new template
  Future<String> insertTemplate(TransactionTemplate template) async {
    final db = await _dbHelper.database;
    await db.insert('transaction_templates', template.toMap());
    return template.id;
  }

  /// Get all templates
  Future<List<TransactionTemplate>> getAllTemplates() async {
    final db = await _dbHelper.database;
    
    final maps = await db.query(
      'transaction_templates',
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => TransactionTemplate.fromMap(map)).toList();
  }

  /// Get templates by type
  Future<List<TransactionTemplate>> getTemplatesByType(String type) async {
    final db = await _dbHelper.database;
    
    final maps = await db.query(
      'transaction_templates',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => TransactionTemplate.fromMap(map)).toList();
  }

  /// Get template by ID
  Future<TransactionTemplate?> getTemplateById(String id) async {
    final db = await _dbHelper.database;
    
    final maps = await db.query(
      'transaction_templates',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return TransactionTemplate.fromMap(maps.first);
  }

  /// Update template
  Future<int> updateTemplate(TransactionTemplate template) async {
    final db = await _dbHelper.database;
    return await db.update(
      'transaction_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  /// Delete template
  Future<int> deleteTemplate(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'transaction_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}


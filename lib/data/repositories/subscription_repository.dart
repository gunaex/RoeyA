import '../database/database_helper.dart';
import '../models/subscription.dart';

class SubscriptionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Subscription>> getAllSubscriptions() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'subscriptions',
      orderBy: 'amount DESC',
    );
    return maps.map((map) => Subscription.fromMap(map)).toList();
  }

  Future<Subscription?> getSubscriptionById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Subscription.fromMap(maps.first);
  }

  Future<String> insertSubscription(Subscription subscription) async {
    final db = await _dbHelper.database;
    await db.insert('subscriptions', subscription.toMap());
    return subscription.id;
  }

  Future<int> updateSubscription(Subscription subscription) async {
    final db = await _dbHelper.database;
    return await db.update(
      'subscriptions',
      subscription.toMap(),
      where: 'id = ?',
      whereArgs: [subscription.id],
    );
  }

  Future<int> deleteSubscription(String id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, double>> getSubscriptionStats() async {
    final subscriptions = await getAllSubscriptions();
    double monthlyTotal = 0;
    for (var sub in subscriptions) {
      if (sub.frequency == 'monthly') {
        monthlyTotal += sub.amount;
      } else {
        monthlyTotal += sub.amount / 12;
      }
    }
    return {
      'monthly_total': monthlyTotal,
      'yearly_projection': monthlyTotal * 12,
    };
  }
}

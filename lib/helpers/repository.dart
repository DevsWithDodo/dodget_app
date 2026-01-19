import 'package:csocsort_szamla/helpers/models.dart' as models;
import 'package:csocsort_szamla/helpers/providers/database_provider.dart';
import 'package:logger/web.dart';
import 'package:sqflite/sqflite.dart';

class TransactionRepository {
  final DatabaseProvider dbProvider;
  var logger = Logger();

  TransactionRepository(this.dbProvider);

  Future<void> insert(models.Transaction transaction) async {
    logger.d("DB: inserting transaction: $transaction");
    
    final db = await dbProvider.db;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    logger.d("DB: inserted transaction: $transaction");
  }

  Future<void> update(models.Transaction transaction) async {
    logger.d("DB: updating transaction: $transaction");
    
    final db = await dbProvider.db;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    logger.d("DB: updated transaction: $transaction");
  }

  Future<void> delete(int id) async {
    logger.d("DB: deleting transaction with id: $id");
    
    final db = await dbProvider.db;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    logger.d("DB: deleted transaction with id: $id");
  }

  Future<List<models.Transaction>> list() async {
    final db = await dbProvider.db;
    logger.d("DB: listing transactions");
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    logger.d("DB: listed ${maps.length} transactions");
    
    return [
      for (final map in maps) models.Transaction.fromMap(map)
    ];
  }

  Future<List<models.Transaction>> getByDateRange(DateTime start, DateTime end) async {
    final db = await dbProvider.db;
    logger.d("DB: getting transactions from $start to $end");
    
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String().split('T')[0], end.toIso8601String().split('T')[0]],
      orderBy: 'date DESC',
    );
    logger.d("DB: found ${maps.length} transactions in date range");
    
    return [
      for (final map in maps) models.Transaction.fromMap(map)
    ];
  }

  Future<List<models.Transaction>> getRecurringTransactions() async {
    final db = await dbProvider.db;
    logger.d("DB: getting recurring transactions");
    
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'recurring_months IS NOT NULL',
      orderBy: 'date DESC',
    );
    logger.d("DB: found ${maps.length} recurring transactions");
    
    return [
      for (final map in maps) models.Transaction.fromMap(map)
    ];
  }

  Future<List<Map<String, dynamic>>> getStatDetailed() async {
    final db = await dbProvider.db;
    logger.d("DB: getting detailed statistics");
    
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', date) as month,
        c.name as category_name,
        (-1) * SUM(CASE WHEN price < 0 THEN price ELSE 0 END) as total_income,
        SUM(CASE WHEN price > 0 THEN price ELSE 0 END) as total_expense
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      GROUP BY month, c.name
      ORDER BY month DESC, c.name
    ''');
    
    logger.d("DB: got ${result.length} stat rows");
    return result;
  }

  Future<Map<String, double>> getMonthlyTotals(String yearMonth) async {
    final db = await dbProvider.db;
    logger.d("DB: getting monthly totals for $yearMonth");
    
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        (-1) * SUM(CASE WHEN price < 0 THEN price ELSE 0 END) as total_income,
        SUM(CASE WHEN price > 0 THEN price ELSE 0 END) as total_expense
      FROM transactions
      WHERE strftime('%Y-%m', date) = ?
    ''', [yearMonth]);
    
    if (result.isNotEmpty) {
      return {
        'income': result[0]['total_income'] ?? 0.0,
        'expense': result[0]['total_expense'] ?? 0.0,
      };
    }
    
    return {'income': 0.0, 'expense': 0.0};
  }
}

class CategoryRepository {
  final DatabaseProvider dbProvider;
  var logger = Logger();

  CategoryRepository(this.dbProvider);

  Future<List<models.CategoryModel>> list() async {
    final db = await dbProvider.db;
    logger.d("DB: listing categories");
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      orderBy: 'name',
    );
    logger.d("DB: listed ${maps.length} categories");
    
    return [
      for (final map in maps) models.CategoryModel.fromMap(map)
    ];
  }

  Future<models.CategoryModel?> getById(int id) async {
    final db = await dbProvider.db;
    logger.d("DB: getting category with id: $id");
    
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return models.CategoryModel.fromMap(maps.first);
  }
}

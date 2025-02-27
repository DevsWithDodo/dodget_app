import 'package:csocsort_szamla/helpers/models.dart';
import 'package:csocsort_szamla/helpers/providers/database_provider.dart';
import 'package:logger/web.dart';
import 'package:sqflite/sqflite.dart';

class PurchaseRepository {
  final DatabaseProvider dbProvider;
  var logger = Logger();

  PurchaseRepository(this.dbProvider);

  Future<void> insert(Purchase purchase) async {
    logger.d("DB: inserting purchase: $purchase");
    
    final db = await dbProvider.db;
    await db.insert(
      'purchases',
      purchase.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    logger.d("DB: inserted purchase: $purchase");
  }

  Future<List<Purchase>> list() async {
    final db = await dbProvider.db;
    final List<Map<String, dynamic>> maps = await db.query('purchases');
    
    return [
      for (final map in maps) Purchase.fromMap(map)
    ];
  }
}
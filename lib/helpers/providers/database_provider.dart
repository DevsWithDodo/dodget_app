import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/widgets.dart';

class DatabaseProvider {
  static Database? _database;

  Future<Database> get db async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    return openDatabase(
      join(await getDatabasesPath(), 'your_database.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE purchases(id INTEGER PRIMARY KEY, name TEXT, amount FLOAT, date TEXT, currency TEXT, category TEXT)
        ''');
      },
      version: 1,
    );
  }
}
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
      join(await getDatabasesPath(), 'dodget.db'),
      onCreate: (db, version) async {
        // Create categories table
        await db.execute('''
          CREATE TABLE categories(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        
        // Create transactions table
        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            price NUMERIC NOT NULL,
            date TEXT NOT NULL,
            recurring_months INTEGER,
            recurring_until TEXT,
            currency TEXT NOT NULL,
            category_id INTEGER NOT NULL,
            name TEXT,
            FOREIGN KEY (category_id) REFERENCES categories(id)
          )
        ''');
        
        // Create indexes for better query performance
        await db.execute('''
          CREATE INDEX idx_transactions_date ON transactions(date)
        ''');
        
        await db.execute('''
          CREATE INDEX idx_transactions_category ON transactions(category_id)
        ''');
        
        // Insert default categories
        await _insertDefaultCategories(db);
      },
      version: 1,
    );
  }
  
  Future<void> _insertDefaultCategories(Database db) async {
    final categories = [
      'Transport',
      'Groceries',
      'Gifts',
      'Donation',
      'Restaurants',
      'Home',
      'Decoration',
      'Entertainment',
      'Party',
      'Tax',
      'Clothes',
      'Travel',
      'Invoices',
      'Tools',
      'Health',
      'Sport',
      'Other',
    ];
    
    for (var category in categories) {
      await db.insert('categories', {'name': category});
    }
  }
}
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
      onConfigure: (db) async {
        // Enable foreign key constraints
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _insertDefaultCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Handle migrations between versions
        if (oldVersion < 2) {
          // Migration from version 1 to 2: ensure all tables and views exist
          await _createSchema(db);
        }
        // Add future migrations here
      },
      version: 2,
    );
  }

  Future<void> _createSchema(Database db) async {
    // Create categories table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50)
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        price NUMERIC NOT NULL,
        date TEXT NOT NULL,
        recurring_months INTEGER,
        recurring_until TEXT,
        currency TEXT NOT NULL,
        category_id INTEGER NOT NULL
          CONSTRAINT transactions_categories_FK
            REFERENCES categories,
        name TEXT
      )
    ''');

    // Create mnb_currencies table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mnb_currencies (
        Date TEXT,
        EUR TEXT,
        DKK TEXT
      )
    ''');

    // Recreate views (always safe to drop and recreate)
    await _createOrReplaceViews(db);
  }

  Future<void> _createOrReplaceViews(Database db) async {
    // Drop existing views in reverse dependency order
    final viewsToDrop = [
      'stat',
      'stat_detailed',
      'detailed_transactions',
      'detailed_recurring_transactions',
      'transactions_months_helper',
      'currencies_months',
      'months'
    ];

    for (var view in viewsToDrop) {
      await db.execute('DROP VIEW IF EXISTS $view');
    }

    // Create months view
    await db.execute('''
      CREATE VIEW months AS
      SELECT 
        (CASE WHEN month < 10 THEN year || '.0' || month || '.' 
              WHEN month >= 10 THEN year || '.' || month || '.' END) AS date,
        year,
        month,
        (year-2022)*12+month AS relative_months
      FROM 
        (WITH RECURSIVE months(value) AS (
          SELECT 1
          UNION ALL
          SELECT value + 1 FROM months WHERE value < 12
        )
        SELECT value AS month FROM months)
      JOIN
        (WITH RECURSIVE years(value) AS (
          SELECT 2022
          UNION ALL
          SELECT value + 1 FROM years WHERE value < CAST(strftime('%Y', date('now')) AS INT)
        )
        SELECT value AS year FROM years) ON true
      ORDER BY relative_months
    ''');

    // Create currencies_months view
    await db.execute('''
      CREATE VIEW currencies_months AS
      SELECT 
        substr(Date, 0, 9) AS month,
        AVG(EUR) AS EUR,
        AVG(DKK) AS DKK
      FROM mnb_currencies
      GROUP BY substr(Date, 0, 9)
    ''');

    // Create transactions_months_helper view
    await db.execute('''
      CREATE VIEW transactions_months_helper AS
      SELECT * FROM transactions
      JOIN months ON substr(transactions.date, 0, 9) = months.date
    ''');

    // Create detailed_recurring_transactions view
    await db.execute('''
      CREATE VIEW detailed_recurring_transactions AS
      SELECT
        t.id,
        t.name,
        t.category_id,
        (CASE WHEN currency = 'HUF' THEN CAST(price/DKK AS INT) ELSE price END) / t.recurring_months AS price,
        months.date AS month,
        t.date AS recurring_from,
        t.recurring_until
      FROM transactions_months_helper t
      JOIN months
      JOIN currencies_months ON currencies_months.month = months.date
      WHERE t.recurring_months IS NOT NULL
        AND t."date:1" <= months.date
        AND (t.recurring_until IS NULL OR substr(t.recurring_until, 0, 9) >= months.date)
      ORDER BY months.date
    ''');

    // Create detailed_transactions view
    await db.execute('''
      CREATE VIEW detailed_transactions AS
      SELECT 
        t.id,
        t.name,
        t.category_id,
        (CASE WHEN currency = 'HUF' THEN CAST(price/DKK AS INT) ELSE price END) AS price,
        months.date AS month
      FROM transactions t
      JOIN months ON substr(t.date, 0, 9) = months.date
      JOIN currencies_months ON currencies_months.month = months.date
      WHERE recurring_months IS NULL
    ''');

    // Create stat_detailed view
    await db.execute('''
      CREATE VIEW stat_detailed AS
      SELECT
        month,
        categories.name,
        (-1)*SUM(CASE WHEN price < 0 THEN price ELSE 0 END) AS total_income,
        SUM(CASE WHEN price > 0 THEN price ELSE 0 END) AS total_expense
      FROM
        (SELECT id, category_id, month, price FROM detailed_transactions
         UNION
         SELECT id, category_id, month, price FROM detailed_recurring_transactions)
      JOIN categories ON category_id = categories.id
      GROUP BY month, categories.name
    ''');

    // Create stat view
    await db.execute('''
      CREATE VIEW stat AS
      SELECT 
        month,
        SUM(total_expense) AS total_expenses,
        SUM(total_income) AS total_income,
        SUM(total_income - total_expense) AS profit
      FROM stat_detailed
      GROUP BY month
    ''');
  }
  
  Future<void> _insertDefaultCategories(Database db) async {
    // Check if categories already exist
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categories')
    );
    
    if (count != null && count > 0) {
      // Categories already exist, skip insertion
      return;
    }

    final categories = [
      'Közlekedés',
      'Bevásárlás',
      'Ajándék',
      'Adomány',
      'Kávézó/étterem',
      'Lakás',
      'Lakásfejlesztés',
      'Szórakozás/pihenés',
      'Parti/alkohol',
      'Adó',
      'Ruha',
      'Utazás',
      'Repülő/vonat',
      'Albérlet',
      'Egészség',
      'Eszköz',
      'Sport',
      'Egyéb',
      'Fizetés',
      'SU',
      'Szabadság',
      'Befektetés',
      'Hosszútávú vásárlás',
      'Devs with the Dodo'
    ];

    for (var category in categories) {
      await db.insert('categories', {'name': category});
    }
  }
}
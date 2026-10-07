import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expense_tracker.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE periods (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            started_at INTEGER NOT NULL,
            closed_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            period_id INTEGER NOT NULL REFERENCES periods (id),
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await _createExpenseTypesTable(db);
        await db.insert('periods', {
          'started_at': DateTime.now().millisecondsSinceEpoch,
          'closed_at': null,
        });
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createExpenseTypesTable(db);
          // Seed suggestions from types already used in expenses.
          await db.execute('''
            INSERT OR IGNORE INTO expense_types (name)
            SELECT DISTINCT lower(type) FROM expenses
            WHERE lower(type) NOT GLOB '*[^a-z]*'
          ''');
        }
      },
    );
  }

  Future<void> _createExpenseTypesTable(Database db) async {
    await db.execute('''
      CREATE TABLE expense_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
  }
}

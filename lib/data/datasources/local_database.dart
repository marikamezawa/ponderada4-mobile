import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._();
  LocalDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = join(await getDatabasesPath(), 'reggieapp.db');
    return openDatabase(
      dbPath,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE plants (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        scientific_name TEXT,
        common_name TEXT,
        photo_url TEXT,
        location TEXT,
        water_frequency_days INTEGER NOT NULL DEFAULT 3,
        fertilize_frequency_days INTEGER NOT NULL DEFAULT 30,
        last_watered TEXT,
        last_fertilized TEXT,
        created_at TEXT NOT NULL,
        description TEXT,
        care_tips TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE care_logs (
        id TEXT PRIMARY KEY,
        plant_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        care_type TEXT NOT NULL,
        note TEXT,
        logged_at TEXT NOT NULL,
        FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE growth_logs (
        id TEXT PRIMARY KEY,
        plant_id TEXT NOT NULL,
        photo_path TEXT NOT NULL,
        note TEXT,
        logged_at TEXT NOT NULL,
        FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE plants ADD COLUMN care_tips TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS growth_logs (
          id TEXT PRIMARY KEY,
          plant_id TEXT NOT NULL,
          photo_path TEXT NOT NULL,
          note TEXT,
          logged_at TEXT NOT NULL,
          FOREIGN KEY (plant_id) REFERENCES plants(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute(
          'ALTER TABLE plants ADD COLUMN description TEXT');
    }
  }
}

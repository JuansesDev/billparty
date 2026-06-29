import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Runs every CREATE TABLE statement. Shared by the real database (in
/// [AppDatabase]) and by tests (which run it against an in-memory database).
Future<void> createBillPartySchema(Database db) async {
  await db.execute('''
    CREATE TABLE plan (
      id          TEXT PRIMARY KEY,
      name        TEXT NOT NULL,
      created_at  INTEGER NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE person (
      id          TEXT PRIMARY KEY,
      plan_id     TEXT NOT NULL REFERENCES plan(id) ON DELETE CASCADE,
      name        TEXT NOT NULL,
      color_index INTEGER NOT NULL DEFAULT 0
    )
  ''');

  await db.execute('''
    CREATE TABLE expense (
      id          TEXT PRIMARY KEY,
      plan_id     TEXT NOT NULL REFERENCES plan(id) ON DELETE CASCADE,
      description TEXT NOT NULL,
      amount      INTEGER NOT NULL,
      payer_id    TEXT NOT NULL REFERENCES person(id),
      split_type  TEXT NOT NULL,
      created_at  INTEGER NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE expense_share (
      expense_id  TEXT NOT NULL REFERENCES expense(id) ON DELETE CASCADE,
      person_id   TEXT NOT NULL REFERENCES person(id),
      value       INTEGER,
      PRIMARY KEY (expense_id, person_id)
    )
  ''');

  await db.execute('''
    CREATE TABLE payment (
      id          TEXT PRIMARY KEY,
      plan_id     TEXT NOT NULL REFERENCES plan(id) ON DELETE CASCADE,
      from_id     TEXT NOT NULL REFERENCES person(id),
      to_id       TEXT NOT NULL REFERENCES person(id),
      amount      INTEGER NOT NULL,
      created_at  INTEGER NOT NULL
    )
  ''');
}

/// Opens — and creates on first run — the single local SQLite file.
///
/// The whole app shares one connection (cached in [_db]). The file lives in the
/// app's private storage, so the data never leaves the device.
class AppDatabase {
  AppDatabase._(); // private constructor: no instances, only static access

  static Database? _db;

  static Future<Database> get instance async {
    return _db ??= await _open();
  }

  static Future<Database> _open() async {
    final dbPath = join(await getDatabasesPath(), 'billparty.db');
    return openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) => createBillPartySchema(db),
    );
  }
}

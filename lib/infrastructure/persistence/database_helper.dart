// DatabaseHelper — manages SQLite connection and FFI initialization for native desktop & mobile.
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';
import 'package:universal_platform/universal_platform.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static const String _dbName = 'ghost_dice.db';
  static const int _dbVersion = 1;

  Database? _db;

  Future<Database?> get database async {
    if (kIsWeb) return null;
    _db ??= await _initDatabase();
    return _db;
  }

  Future<Database> _initDatabase() async {
    if (UniversalPlatform.isWindows || UniversalPlatform.isLinux || UniversalPlatform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE active_game (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        game_data TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE match_history (
        id TEXT PRIMARY KEY,
        winner_name TEXT NOT NULL,
        winner_color TEXT NOT NULL,
        player_count INTEGER NOT NULL,
        total_turns INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        ended_at INTEGER NOT NULL,
        players_json TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}

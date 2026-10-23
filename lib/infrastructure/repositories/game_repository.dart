// GameRepository — handles persisting active games and match history in SQLite (Native) or SharedPreferences (Web).
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghost_dice/application/state/game_state.dart';
import 'package:ghost_dice/infrastructure/persistence/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository(DatabaseHelper.instance);
});

class GameRepository {
  final DatabaseHelper _dbHelper;

  GameRepository(this._dbHelper);

  /// Saves or updates the currently active game session.
  Future<void> saveActiveGame(GameState state) async {
    final jsonStr = jsonEncode(state.toJson());

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_game', jsonStr);
      return;
    }

    final db = await _dbHelper.database;
    if (db == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'active_game',
      {
        'id': 1,
        'game_data': jsonStr,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Loads the active game session if one exists.
  Future<GameState?> loadActiveGame() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final rawData = prefs.getString('active_game');
        if (rawData == null || rawData.isEmpty) return null;
        final map = jsonDecode(rawData) as Map<String, dynamic>;
        final state = GameState.fromJson(map);
        if (state.isGameOver) return null;
        return state;
      }

      final db = await _dbHelper.database;
      if (db == null) return null;

      final rows = await db.query(
        'active_game',
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (rows.isEmpty) return null;
      final rawData = rows.first['game_data'] as String;
      final map = jsonDecode(rawData) as Map<String, dynamic>;
      final state = GameState.fromJson(map);
      if (state.isGameOver) return null;
      return state;
    } catch (_) {
      return null;
    }
  }

  /// Checks if an active uncompleted game exists in storage.
  Future<bool> hasActiveGame() async {
    try {
      final active = await loadActiveGame();
      return active != null && !active.isGameOver;
    } catch (_) {
      return false;
    }
  }

  /// Deletes the active game record.
  Future<void> clearActiveGame() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_game');
      return;
    }

    final db = await _dbHelper.database;
    if (db == null) return;

    await db.delete(
      'active_game',
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  /// Saves a completed match to match history.
  Future<void> saveCompletedMatch(GameState finalState) async {
    final winner = finalState.winner;
    if (winner == null) return;

    final now = DateTime.now();
    final durationSeconds = now.difference(finalState.startedAt).inSeconds;

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final historyList = prefs.getStringList('match_history') ?? [];
      final record = jsonEncode({
        'id': finalState.gameId,
        'winner_name': winner.name,
        'winner_color': winner.color.name,
        'player_count': finalState.players.length,
        'total_turns': finalState.recentMoves.length,
        'duration_seconds': durationSeconds > 0 ? durationSeconds : 0,
        'ended_at': now.millisecondsSinceEpoch,
      });
      historyList.insert(0, record);
      await prefs.setStringList('match_history', historyList);
      await clearActiveGame();
      return;
    }

    final db = await _dbHelper.database;
    if (db == null) return;

    await db.insert(
      'match_history',
      {
        'id': finalState.gameId,
        'winner_name': winner.name,
        'winner_color': winner.color.name,
        'player_count': finalState.players.length,
        'total_turns': finalState.recentMoves.length,
        'duration_seconds': durationSeconds > 0 ? durationSeconds : 0,
        'ended_at': now.millisecondsSinceEpoch,
        'players_json': jsonEncode(finalState.players.map((p) => p.toJson()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await clearActiveGame();
  }

  /// Retrieves match history records.
  Future<List<Map<String, dynamic>>> getMatchHistory() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final rawList = prefs.getStringList('match_history') ?? [];
        return rawList.map((str) => jsonDecode(str) as Map<String, dynamic>).toList();
      }

      final db = await _dbHelper.database;
      if (db == null) return [];

      return await db.query(
        'match_history',
        orderBy: 'ended_at DESC',
        limit: 50,
      );
    } catch (_) {
      return [];
    }
  }
}

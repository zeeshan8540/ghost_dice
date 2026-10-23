// GameSnapshot — full immutable state snapshot stored before each dice entry.
// Used by the undo system to restore prior state atomically.

import 'package:ghost_dice/domain/entities/dice_entry.dart';
import 'package:ghost_dice/domain/entities/game_rules.dart';
import 'package:ghost_dice/domain/entities/move_event.dart';
import 'package:ghost_dice/domain/entities/player.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';

class GameSnapshot {
  final String gameId;
  final List<Player> players;
  final int activePlayerIndex;
  final TurnPhase phase;

  /// Number of consecutive 6s in the current player's turn chain.
  final int consecutiveSixCount;

  /// Whether the active player has already earned a bonus entry this move.
  final bool bonusEntryPending;

  final List<DiceEntry> recentEntries; // up to undoHistoryLimit
  final List<MoveEvent> recentMoves;
  final GameRules rules;
  final DateTime snapshotAt;

  const GameSnapshot({
    required this.gameId,
    required this.players,
    required this.activePlayerIndex,
    required this.phase,
    required this.consecutiveSixCount,
    required this.bonusEntryPending,
    required this.recentEntries,
    required this.recentMoves,
    required this.rules,
    required this.snapshotAt,
  });

  Player get activePlayer => players[activePlayerIndex];

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'players': players.map((p) => p.toJson()).toList(),
        'activePlayerIndex': activePlayerIndex,
        'phase': phase.name,
        'consecutiveSixCount': consecutiveSixCount,
        'bonusEntryPending': bonusEntryPending,
        'recentEntries': recentEntries.map((e) => e.toJson()).toList(),
        'recentMoves': recentMoves.map((m) => m.toJson()).toList(),
        'rules': rules.toJson(),
        'snapshotAt': snapshotAt.toIso8601String(),
      };

  factory GameSnapshot.fromJson(Map<String, dynamic> json) => GameSnapshot(
        gameId: json['gameId'] as String,
        players: (json['players'] as List)
            .map((p) => Player.fromJson(p as Map<String, dynamic>))
            .toList(),
        activePlayerIndex: json['activePlayerIndex'] as int,
        phase: TurnPhase.values.firstWhere((e) => e.name == json['phase']),
        consecutiveSixCount: json['consecutiveSixCount'] as int,
        bonusEntryPending: json['bonusEntryPending'] as bool,
        recentEntries: (json['recentEntries'] as List)
            .map((e) => DiceEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentMoves: (json['recentMoves'] as List)
            .map((m) => MoveEvent.fromJson(m as Map<String, dynamic>))
            .toList(),
        rules: GameRules.fromJson(json['rules'] as Map<String, dynamic>),
        snapshotAt: DateTime.parse(json['snapshotAt'] as String),
      );
}

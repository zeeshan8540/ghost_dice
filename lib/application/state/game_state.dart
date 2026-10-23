// GameState — the complete reactive state exposed to the UI via Riverpod.
// Immutable value class.

import 'package:ghost_dice/domain/entities/board_position.dart';
import 'package:ghost_dice/domain/entities/dice_entry.dart';
import 'package:ghost_dice/domain/entities/game_rules.dart';
import 'package:ghost_dice/domain/entities/move_event.dart';
import 'package:ghost_dice/domain/entities/player.dart';
import 'package:ghost_dice/domain/entities/undo_request.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';
import 'package:ghost_dice/domain/services/ludo_rules_engine.dart';

class CapturedPieceAnimation {
  final String id;
  final String pieceId;
  final String playerId;
  final PlayerColor color;
  final int pieceIndex;
  final BoardPosition fromPosition;
  final DateTime timestamp;

  const CapturedPieceAnimation({
    required this.id,
    required this.pieceId,
    required this.playerId,
    required this.color,
    required this.pieceIndex,
    required this.fromPosition,
    required this.timestamp,
  });
}

class GameState {
  final String gameId;
  final List<Player> players;
  final int activePlayerIndex;
  final TurnPhase phase;

  /// The dice value the active player just declared (pending confirmation).
  final int? pendingDiceValue;

  /// Legal move options computed for the pending dice value.
  final List<LegalMove> legalMoves;

  /// Consecutive 6s count during current player's turn chain.
  final int consecutiveSixCount;
  final bool bonusEntryPending;

  /// Recent committed dice entries (up to undoHistoryLimit).
  final List<DiceEntry> recentEntries;

  /// Recent committed move events (up to undoHistoryLimit).
  final List<MoveEvent> recentMoves;

  /// Active undo vote, if any.
  final UndoRequest? pendingUndoRequest;

  final GameRules rules;

  /// Winning player once phase == gameOver.
  final Player? winner;

  /// Human-readable status message to show in the announcement area.
  final String? announcement;

  /// Transient animation triggers for captured/killed pieces flying back to home.
  final List<CapturedPieceAnimation> activeCaptures;

  /// Game start time.
  final DateTime startedAt;

  const GameState({
    required this.gameId,
    required this.players,
    required this.activePlayerIndex,
    required this.phase,
    this.pendingDiceValue,
    this.legalMoves = const [],
    this.consecutiveSixCount = 0,
    this.bonusEntryPending = false,
    this.recentEntries = const [],
    this.recentMoves = const [],
    this.pendingUndoRequest,
    required this.rules,
    this.winner,
    this.announcement,
    this.activeCaptures = const [],
    required this.startedAt,
  });

  Player get activePlayer => players[activePlayerIndex];

  bool get isGameOver => phase == TurnPhase.gameOver;
  bool get isVoting => phase == TurnPhase.undoVoting;
  bool get isAwaitingDice => phase == TurnPhase.awaitingDiceEntry;
  bool get isAwaitingPiece => phase == TurnPhase.awaitingPieceSelection;

  bool get isTeamUp => rules.isTeamUp;

  /// Returns the active player's partner in Team Up mode.
  Player? get activePartner {
    if (!isTeamUp) return null;
    return players.firstWhere(
      (p) =>
          p.id != activePlayer.id &&
          (p.teamId != null && p.teamId == activePlayer.teamId ||
              _isSameTeam(p.color, activePlayer.color)),
      orElse: () => activePlayer,
    );
  }

  static bool _isSameTeam(PlayerColor a, PlayerColor b) {
    final aIsTeam1 = a == PlayerColor.red || a == PlayerColor.yellow;
    final bIsTeam1 = b == PlayerColor.red || b == PlayerColor.yellow;
    return aIsTeam1 == bIsTeam1;
  }

  /// Whether active player has finished all 4 pieces and is rolling to move partner's pieces.
  bool get isActivePlayerRollingForPartner =>
      isTeamUp && activePlayer.finishedCount == 4;

  /// The player whose pieces are eligible to move this turn.
  Player get effectiveMovingPlayer =>
      isActivePlayerRollingForPartner ? (activePartner ?? activePlayer) : activePlayer;

  GameState copyWith({
    List<Player>? players,
    int? activePlayerIndex,
    TurnPhase? phase,
    Object? pendingDiceValue = _sentinel,
    List<LegalMove>? legalMoves,
    int? consecutiveSixCount,
    bool? bonusEntryPending,
    List<DiceEntry>? recentEntries,
    List<MoveEvent>? recentMoves,
    Object? pendingUndoRequest = _sentinel,
    GameRules? rules,
    Object? winner = _sentinel,
    Object? announcement = _sentinel,
    List<CapturedPieceAnimation>? activeCaptures,
  }) =>
      GameState(
        gameId: gameId,
        players: players ?? this.players,
        activePlayerIndex: activePlayerIndex ?? this.activePlayerIndex,
        phase: phase ?? this.phase,
        pendingDiceValue: pendingDiceValue == _sentinel
            ? this.pendingDiceValue
            : pendingDiceValue as int?,
        legalMoves: legalMoves ?? this.legalMoves,
        consecutiveSixCount: consecutiveSixCount ?? this.consecutiveSixCount,
        bonusEntryPending: bonusEntryPending ?? this.bonusEntryPending,
        recentEntries: recentEntries ?? this.recentEntries,
        recentMoves: recentMoves ?? this.recentMoves,
        pendingUndoRequest: pendingUndoRequest == _sentinel
            ? this.pendingUndoRequest
            : pendingUndoRequest as UndoRequest?,
        rules: rules ?? this.rules,
        winner: winner == _sentinel ? this.winner : winner as Player?,
        announcement: announcement == _sentinel
            ? this.announcement
            : announcement as String?,
        activeCaptures: activeCaptures ?? this.activeCaptures,
        startedAt: startedAt,
      );

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'players': players.map((p) => p.toJson()).toList(),
        'activePlayerIndex': activePlayerIndex,
        'phase': phase.name,
        'pendingDiceValue': pendingDiceValue,
        'consecutiveSixCount': consecutiveSixCount,
        'bonusEntryPending': bonusEntryPending,
        'recentEntries': recentEntries.map((e) => e.toJson()).toList(),
        'recentMoves': recentMoves.map((m) => m.toJson()).toList(),
        'rules': rules.toJson(),
        'winner': winner?.toJson(),
        'announcement': announcement,
        'startedAt': startedAt.toIso8601String(),
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        gameId: json['gameId'] as String,
        players: (json['players'] as List)
            .map((p) => Player.fromJson(p as Map<String, dynamic>))
            .toList(),
        activePlayerIndex: json['activePlayerIndex'] as int,
        phase: TurnPhase.values.firstWhere(
          (e) => e.name == json['phase'],
          orElse: () => TurnPhase.awaitingDiceEntry,
        ),
        pendingDiceValue: json['pendingDiceValue'] as int?,
        consecutiveSixCount: json['consecutiveSixCount'] as int? ?? 0,
        bonusEntryPending: json['bonusEntryPending'] as bool? ?? false,
        recentEntries: (json['recentEntries'] as List? ?? [])
            .map((e) => DiceEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentMoves: (json['recentMoves'] as List? ?? [])
            .map((m) => MoveEvent.fromJson(m as Map<String, dynamic>))
            .toList(),
        rules: GameRules.fromJson(json['rules'] as Map<String, dynamic>),
        winner: json['winner'] != null
            ? Player.fromJson(json['winner'] as Map<String, dynamic>)
            : null,
        announcement: json['announcement'] as String?,
        startedAt: DateTime.parse(json['startedAt'] as String),
      );
}

/// Sentinel object for nullable copyWith fields.
const _sentinel = Object();

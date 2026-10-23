// GameController — the single authoritative Riverpod controller.
// All game mutations pass through here.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:ghost_dice/application/state/game_state.dart';
import 'package:ghost_dice/domain/entities/board_config.dart';
import 'package:ghost_dice/domain/entities/board_position.dart';
import 'package:ghost_dice/domain/entities/dice_entry.dart';
import 'package:ghost_dice/domain/entities/game_rules.dart';
import 'package:ghost_dice/domain/entities/game_snapshot.dart';
import 'package:ghost_dice/domain/entities/move_event.dart';
import 'package:ghost_dice/domain/entities/piece.dart';
import 'package:ghost_dice/domain/entities/player.dart';
import 'package:ghost_dice/domain/entities/undo_request.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';
import 'package:ghost_dice/domain/services/ludo_rules_engine.dart';
import 'package:ghost_dice/domain/services/undo_manager.dart';
import 'package:ghost_dice/infrastructure/repositories/game_repository.dart';

final _uuid = Uuid();

final gameControllerProvider =
    StateNotifierProvider<GameController, GameState?>((ref) {
  final repo = ref.watch(gameRepositoryProvider);
  return GameController(repository: repo);
});

/// Watches whether an active uncompleted game session is available (either in memory or storage).
final hasSavedGameProvider = FutureProvider.autoDispose<bool>((ref) async {
  final inMemory = ref.watch(gameControllerProvider);
  if (inMemory != null && !inMemory.isGameOver) {
    return true;
  }
  final repo = ref.watch(gameRepositoryProvider);
  return await repo.hasActiveGame();
});

/// Provides the active or saved game state for the Home screen resume banner.
final activeGameInfoProvider = FutureProvider.autoDispose<GameState?>((ref) async {
  final inMemory = ref.watch(gameControllerProvider);
  if (inMemory != null && !inMemory.isGameOver) {
    return inMemory;
  }
  final repo = ref.watch(gameRepositoryProvider);
  return await repo.loadActiveGame();
});

class GameController extends StateNotifier<GameState?> {
  final GameRepository? _repository;

  GameController({GameRepository? repository})
      : _repository = repository,
        super(null);

  late LudoRulesEngine _engine;
  late UndoManager _undoManager;
  Timer? _undoTimer;

  @override
  set state(GameState? value) {
    super.state = value;
    if (value == null) {
      _repository?.clearActiveGame();
    } else if (value.isGameOver) {
      _repository?.saveCompletedMatch(value);
    } else {
      _repository?.saveActiveGame(value);
    }
  }

  /// Loads or resumes the active game session if one exists.
  Future<bool> loadSavedGame() async {
    // 1. If active state is already in memory and not game over, resume immediately!
    if (state != null && !state!.isGameOver) {
      return true;
    }

    // 2. Otherwise load from persistent storage (SQLite or SharedPreferences)
    final saved = await _repository?.loadActiveGame();
    if (saved != null && !saved.isGameOver) {
      _engine = LudoRulesEngine(saved.rules);
      _undoManager = UndoManager(rules: saved.rules);

      var restored = saved;
      if (saved.phase == TurnPhase.awaitingPieceSelection &&
          saved.pendingDiceValue != null) {
        final movingPlayer = saved.effectiveMovingPlayer;
        final legalMoves = _engine.computeLegalMoves(
          activePlayer: movingPlayer,
          allPlayers: saved.players,
          diceValue: saved.pendingDiceValue!,
          consecutiveSixCount: saved.consecutiveSixCount,
        );
        restored = saved.copyWith(legalMoves: legalMoves);
      }

      super.state = restored;
      return true;
    }
    return false;
  }

  /// Explicitly clears the active game session (when user discards).
  Future<void> clearActiveGameSession() async {
    super.state = null;
    await _repository?.clearActiveGame();
  }

  // ---------------------------------------------------------------------------
  // GAME SETUP
  // ---------------------------------------------------------------------------

  void createGame({
    required List<({String name, PlayerColor color})> playerSetups,
    GameRules rules = GameRules.defaults,
  }) {
    assert(playerSetups.length >= 2 && playerSetups.length <= 4);

    _engine = LudoRulesEngine(rules);
    _undoManager = UndoManager(rules: rules);

    final players = playerSetups.asMap().entries.map((entry) {
      final idx = entry.key;
      final setup = entry.value;
      final playerId = _uuid.v4();
      final pieces = List.generate(
        BoardConfig.piecesPerPlayer,
        (i) => Piece(
          id: _uuid.v4(),
          playerId: playerId,
          color: setup.color,
          pieceIndex: i,
          position: const BoardPosition.yard(),
        ),
      );

      String? teamId;
      String? teamName;
      if (rules.isTeamUp) {
        final isTeam1 = setup.color == PlayerColor.red || setup.color == PlayerColor.yellow;
        teamId = isTeam1 ? 'team_1' : 'team_2';
        teamName = isTeam1 ? 'Team 1' : 'Team 2';
      }

      return Player(
        id: playerId,
        name: setup.name,
        color: setup.color,
        seatIndex: idx,
        pieces: pieces,
        teamId: teamId,
        teamName: teamName,
      );
    }).toList();

    state = GameState(
      gameId: _uuid.v4(),
      players: players,
      activePlayerIndex: 0,
      phase: TurnPhase.awaitingDiceEntry,
      rules: rules,
      startedAt: DateTime.now(),
      announcement: rules.isTeamUp
          ? 'Team Up 2v2 started! Team 1 (Red & Yellow) vs Team 2 (Green & Blue). ${players[0].name} goes first.'
          : 'Game started! ${players[0].name} goes first.',
    );
  }

  // ---------------------------------------------------------------------------
  // DICE ENTRY
  // ---------------------------------------------------------------------------

  /// Stage and confirm a dice value for the active player, computing legal moves immediately.
  void enterDiceValue(int value) {
    final s = state;
    if (s == null || !s.isAwaitingDice) return;
    assert(value >= 1 && value <= 6);

    state = s.copyWith(pendingDiceValue: value);
    confirmDiceEntry();
  }

  void cancelDiceEntry() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(
      pendingDiceValue: null,
      announcement: null,
    );
  }

  /// Confirm the staged dice value and compute legal moves.
  void confirmDiceEntry() {
    final s = state;
    if (s == null || s.pendingDiceValue == null) return;

    final value = s.pendingDiceValue!;
    final isForfeit = _engine.isForfeitedByThreeSixes(
        value, s.consecutiveSixCount);

    final entryId = _uuid.v4();
    final entry = DiceEntry(
      id: entryId,
      playerId: s.activePlayer.id,
      value: value,
      enteredAt: DateTime.now(),
    );

    // Save snapshot BEFORE this entry.
    final snapshot = _buildSnapshot(s, entry);
    _undoManager.push(UndoHistoryItem(entry: entry, snapshotBefore: snapshot));

    if (isForfeit) {
      // Three sixes — forfeit and pass turn.
      final newEntries = [...s.recentEntries, entry];
      final move = MoveEvent(
        id: _uuid.v4(),
        playerId: s.activePlayer.id,
        diceEntryId: entryId,
        diceValue: value,
        committedAt: DateTime.now(),
        forfeitedByThreeSixes: true,
        turnEnded: true,
      );
      final nextIdx =
          _engine.nextPlayerIndex(s.activePlayerIndex, s.players.length);
      state = s.copyWith(
        phase: TurnPhase.awaitingDiceEntry,
        pendingDiceValue: null,
        activePlayerIndex: nextIdx,
        consecutiveSixCount: 0,
        bonusEntryPending: false,
        recentEntries: _trimList(newEntries, s.rules.undoHistoryLimit),
        recentMoves: _trimList([...s.recentMoves, move], s.rules.undoHistoryLimit),
        announcement:
            '${s.activePlayer.name} rolled three 6s! Turn forfeited. ${s.players[nextIdx].name}\'s turn.',
      );
      return;
    }

    final movingPlayer = s.effectiveMovingPlayer;
    final isRollingForPartner = s.isActivePlayerRollingForPartner;

    final legalMoves = _engine.computeLegalMoves(
      activePlayer: movingPlayer,
      allPlayers: s.players,
      diceValue: value,
      consecutiveSixCount: s.consecutiveSixCount,
    );

    final newConsecutiveSix =
        value == 6 ? s.consecutiveSixCount + 1 : 0;
    final newEntries = _trimList(
        [...s.recentEntries, entry], s.rules.undoHistoryLimit);

    if (legalMoves.isEmpty) {
      // No legal move — forfeit this entry.
      final move = MoveEvent(
        id: _uuid.v4(),
        playerId: s.activePlayer.id,
        diceEntryId: entryId,
        diceValue: value,
        committedAt: DateTime.now(),
        turnEnded: true,
      );
      final nextIdx = value == 6
          ? s.activePlayerIndex // 6 with no move grants a bonus normally — but no piece can use it
          : _engine.nextPlayerIndex(s.activePlayerIndex, s.players.length);
      final forWhom = isRollingForPartner ? ' for partner ${movingPlayer.name}' : '';
      state = s.copyWith(
        phase: TurnPhase.awaitingDiceEntry,
        pendingDiceValue: null,
        activePlayerIndex: nextIdx,
        consecutiveSixCount: value == 6 ? newConsecutiveSix : 0,
        bonusEntryPending: false,
        recentEntries: newEntries,
        recentMoves: _trimList([...s.recentMoves, move], s.rules.undoHistoryLimit),
        legalMoves: const [],
        announcement:
            '${s.activePlayer.name} declared $value$forWhom — no legal move. Turn passes.',
      );
      return;
    }

    final helpText = isRollingForPartner ? ' to help partner ${movingPlayer.name}!' : '.';
    final prompt = legalMoves.length == 1
        ? 'Tap the highlighted piece to move.'
        : 'Choose a piece to move.';

    state = s.copyWith(
      phase: TurnPhase.awaitingPieceSelection,
      pendingDiceValue: value,
      legalMoves: legalMoves,
      consecutiveSixCount: newConsecutiveSix,
      recentEntries: newEntries,
      announcement:
          '${s.activePlayer.name} declared $value$helpText $prompt',
    );
  }

  // ---------------------------------------------------------------------------
  // PIECE SELECTION
  // ---------------------------------------------------------------------------

  void selectPiece(String pieceId) {
    final s = state;
    if (s == null || !s.isAwaitingPiece) return;

    final move =
        s.legalMoves.firstWhere((m) => m.piece.id == pieceId, orElse: () {
      throw StateError('Piece $pieceId has no legal move');
    });

    _commitMove(s, move);
  }

  void _commitMove(GameState s, LegalMove move) {
    final value = s.pendingDiceValue!;
    final entryId = s.recentEntries.last.id;

    final resolution = _engine.resolveMove(
      piece: move.piece,
      destination: move.destination,
      activePlayer: s.activePlayer,
      allPlayers: s.players,
      diceValue: value,
    );

    final updatedPlayers = _engine.applyResolution(
      players: s.players,
      activePlayer: s.activePlayer,
      resolution: resolution,
    );

    final moveEvent = MoveEvent(
      id: _uuid.v4(),
      playerId: s.activePlayer.id,
      diceEntryId: entryId,
      pieceId: move.piece.id,
      diceValue: value,
      committedAt: DateTime.now(),
      capturedPieceIds: resolution.capturedPieces.map((p) => p.id).toList(),
      finishedPiece: resolution.finishedPiece,
      earnedBonus: resolution.earnedBonus,
      bonusReason: resolution.bonusReason,
      turnEnded: !resolution.earnedBonus,
    );

    final winner = _engine.checkWinner(updatedPlayers);

    String announcement = '${s.activePlayer.name} moved piece.';
    if (s.isTeamUp && move.piece.playerId != s.activePlayer.id) {
      final partner = s.activePartner;
      announcement = '${s.activePlayer.name} moved partner ${partner?.name}\'s piece.';
    }
    if (resolution.destinationCaptures.isNotEmpty) {
      announcement += ' Captured ${resolution.destinationCaptures.length} piece(s)!';
    } else if (resolution.capturedPieces.isNotEmpty && !s.isTeamUp) {
      announcement += ' Captured ${resolution.capturedPieces.length} piece(s)!';
    }
    if (resolution.abandonedCaptures.isNotEmpty) {
      announcement += ' ⚠️ Abandoned partner piece was caught!';
    }
    if (resolution.finishedPiece) announcement += ' Piece finished!';
    if (resolution.earnedBonus) announcement += ' Bonus entry earned!';
    if (winner != null) {
      if (s.isTeamUp) {
        final winningTeam = winner.teamName ?? (winner.teamId == 'team_1' ? 'Team 1' : 'Team 2');
        final partner = updatedPlayers.firstWhere(
          (p) => p.id != winner.id && (p.teamId == winner.teamId || p.color == BoardConfig.getOppositeColor(winner.color)),
          orElse: () => winner,
        );
        announcement = '🏆 $winningTeam (${winner.name} & ${partner.name}) WINS!';
      } else {
        announcement = '🎉 ${winner.name} wins!';
      }
    }

    final newMoves = _trimList(
        [...s.recentMoves, moveEvent], s.rules.undoHistoryLimit);

    final captureAnims = resolution.capturedPieces.map((p) => CapturedPieceAnimation(
      id: _uuid.v4(),
      pieceId: p.id,
      playerId: p.playerId,
      color: p.color,
      pieceIndex: p.pieceIndex,
      fromPosition: p.position,
      timestamp: DateTime.now(),
    )).toList();

    if (winner != null) {
      state = s.copyWith(
        players: updatedPlayers,
        phase: TurnPhase.gameOver,
        pendingDiceValue: null,
        legalMoves: const [],
        winner: winner,
        recentMoves: newMoves,
        announcement: announcement,
        activeCaptures: captureAnims,
      );
      return;
    }

    if (resolution.earnedBonus) {
      state = s.copyWith(
        players: updatedPlayers,
        phase: TurnPhase.awaitingDiceEntry,
        pendingDiceValue: null,
        legalMoves: const [],
        bonusEntryPending: false,
        recentMoves: newMoves,
        announcement: announcement,
        activeCaptures: captureAnims,
      );
    } else {
      final nextIdx =
          _engine.nextPlayerIndex(s.activePlayerIndex, updatedPlayers.length);
      state = s.copyWith(
        players: updatedPlayers,
        phase: TurnPhase.awaitingDiceEntry,
        activePlayerIndex: nextIdx,
        pendingDiceValue: null,
        legalMoves: const [],
        consecutiveSixCount: 0,
        bonusEntryPending: false,
        recentMoves: newMoves,
        announcement: '$announcement ${updatedPlayers[nextIdx].name}\'s turn.',
        activeCaptures: captureAnims,
      );
    }
  }

  void clearActiveCaptures() {
    final s = state;
    if (s == null || s.activeCaptures.isEmpty) return;
    state = s.copyWith(activeCaptures: const []);
  }

  // ---------------------------------------------------------------------------
  // UNDO VOTING
  // ---------------------------------------------------------------------------

  void requestUndo(String entryId) {
    final s = state;
    if (s == null || s.isVoting || s.isGameOver) return;
    if (!_undoManager.canUndo(entryId)) return;

    final prepared = _undoManager.prepareUndo(entryId);
    if (prepared == null) return;

    // Find the player who made this entry.
    final targetEntry =
        s.recentEntries.firstWhere((e) => e.id == entryId);
    final moverPlayerId = targetEntry.playerId;

    // Eligible voters = OTHER players only (the mover whose entry is being undone cannot vote)
    final otherPlayers = s.players.where((p) => p.id != moverPlayerId).toList();
    final eligibleVoterIds = otherPlayers.isNotEmpty
        ? otherPlayers.map((p) => p.id).toList()
        : [s.players.first.id];
    final initialVotes = <String, bool>{};

    final requesterId = s.activePlayer.id;

    final undoRequest = UndoRequest(
      id: _uuid.v4(),
      requesterPlayerId: requesterId,
      targetEntryId: entryId,
      dependentEntryIds: prepared.entriesToRemove,
      votesByPlayerId: initialVotes,
      eligibleVoterIds: eligibleVoterIds,
      result: UndoVoteResult.pending,
      requestedAt: DateTime.now(),
    );

    state = s.copyWith(
      phase: TurnPhase.undoVoting,
      pendingUndoRequest: undoRequest,
      announcement: 'Undo requested for ${_playerName(s, moverPlayerId)}\'s entry of ${targetEntry.value}. Other players: Vote YES or NO at your dock!',
    );

    // Start timeout timer.
    _undoTimer?.cancel();
    _undoTimer = Timer(
      Duration(seconds: s.rules.undoVoteTimeoutSeconds),
      () => _resolveUndoVote(timedOut: true),
    );
  }

  void castUndoVote(String voterId, bool vote) {
    final s = state;
    if (s == null || !s.isVoting || s.pendingUndoRequest == null) return;

    final req = s.pendingUndoRequest!;
    if (!req.eligibleVoterIds.contains(voterId)) return;

    final updatedVotes = Map<String, bool>.from(req.votesByPlayerId)
      ..[voterId] = vote;
    final updatedReq = req.copyWith(votesByPlayerId: updatedVotes);

    state = s.copyWith(pendingUndoRequest: updatedReq);

    // Check if all votes are in.
    if (updatedReq.remainingVoters == 0) {
      _resolveUndoVote();
    }
  }

  void _resolveUndoVote({bool timedOut = false}) {
    _undoTimer?.cancel();
    final s = state;
    if (s == null || s.pendingUndoRequest == null) return;

    final req = s.pendingUndoRequest!;
    final approved = !timedOut && req.meetsStrictMajority();

    if (approved) {
      final prepared = _undoManager.prepareUndo(req.targetEntryId);
      if (prepared == null) return;

      _undoManager.applyUndo(req.dependentEntryIds);

      // Restore the before-snapshot.
      final snap = prepared.snapshot;
      state = GameState(
        gameId: snap.gameId,
        players: snap.players,
        activePlayerIndex: snap.activePlayerIndex,
        phase: snap.phase == TurnPhase.undoVoting
            ? TurnPhase.awaitingDiceEntry
            : snap.phase,
        consecutiveSixCount: snap.consecutiveSixCount,
        bonusEntryPending: snap.bonusEntryPending,
        recentEntries: snap.recentEntries,
        recentMoves: snap.recentMoves,
        rules: snap.rules,
        startedAt: s.startedAt,
        announcement: 'Undo approved! Game restored to before that entry.',
      );
    } else {
      final reason = timedOut ? 'Timed out' : 'Rejected by vote';
      final prevPhase = s.recentMoves.isNotEmpty ? TurnPhase.awaitingDiceEntry : TurnPhase.awaitingDiceEntry;
      state = s.copyWith(
        phase: prevPhase,
        pendingUndoRequest: null,
        announcement: '$reason — undo denied. Game continues.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  GameSnapshot _buildSnapshot(GameState s, DiceEntry entry) => GameSnapshot(
        gameId: s.gameId,
        players: s.players,
        activePlayerIndex: s.activePlayerIndex,
        phase: s.phase,
        consecutiveSixCount: s.consecutiveSixCount,
        bonusEntryPending: s.bonusEntryPending,
        recentEntries: s.recentEntries,
        recentMoves: s.recentMoves,
        rules: s.rules,
        snapshotAt: DateTime.now(),
      );

  String _playerName(GameState s, String playerId) =>
      s.players.firstWhere((p) => p.id == playerId).name;

  List<T> _trimList<T>(List<T> list, int limit) =>
      list.length > limit ? list.sublist(list.length - limit) : list;

  @override
  void dispose() {
    _undoTimer?.cancel();
    super.dispose();
  }
}

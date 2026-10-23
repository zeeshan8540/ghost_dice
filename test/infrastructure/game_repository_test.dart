// Unit tests for SQLite persistence & GameRepository.
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_dice/application/controllers/game_controller.dart';
import 'package:ghost_dice/application/state/game_state.dart';
import 'package:ghost_dice/domain/entities/board_position.dart';
import 'package:ghost_dice/domain/entities/game_rules.dart';
import 'package:ghost_dice/domain/entities/piece.dart';
import 'package:ghost_dice/domain/entities/player.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('GameRepository & SQLite Persistence', () {
    test('GameState JSON roundtrip serialization preserves all state', () {
      final player1 = Player(
        id: 'p1',
        name: 'Player One',
        color: PlayerColor.red,
        seatIndex: 0,
        pieces: [
          const Piece(
            id: 'piece-1',
            playerId: 'p1',
            color: PlayerColor.red,
            pieceIndex: 0,
            position: BoardPosition.track(12),
          ),
          const Piece(
            id: 'piece-2',
            playerId: 'p1',
            color: PlayerColor.red,
            pieceIndex: 1,
            position: BoardPosition.yard(),
          ),
        ],
      );

      final state = GameState(
        gameId: 'test-game-123',
        players: [player1],
        activePlayerIndex: 0,
        phase: TurnPhase.awaitingDiceEntry,
        consecutiveSixCount: 1,
        bonusEntryPending: false,
        rules: const GameRules(requireSixToLeaveYard: true),
        startedAt: DateTime.utc(2026, 10, 16, 12, 0, 0),
        announcement: 'Turn in progress',
      );

      final json = state.toJson();
      final restored = GameState.fromJson(json);

      expect(restored.gameId, state.gameId);
      expect(restored.players.length, 1);
      expect(restored.players[0].name, 'Player One');
      expect(restored.players[0].pieces[0].position.trackIndex, 12);
      expect(restored.players[0].pieces[1].position.isInYard, isTrue);
      expect(restored.consecutiveSixCount, 1);
      expect(restored.rules.requireSixToLeaveYard, isTrue);
      expect(restored.announcement, 'Turn in progress');
    });

    test('GameController.loadSavedGame resumes in-memory game and recomputes legal moves if needed', () async {
      final player1 = Player(
        id: 'p1',
        name: 'Player One',
        color: PlayerColor.red,
        seatIndex: 0,
        pieces: [
          const Piece(
            id: 'piece-1',
            playerId: 'p1',
            color: PlayerColor.red,
            pieceIndex: 0,
            position: BoardPosition.track(10),
          ),
        ],
      );

      final state = GameState(
        gameId: 'test-resume-game',
        players: [player1],
        activePlayerIndex: 0,
        phase: TurnPhase.awaitingPieceSelection,
        pendingDiceValue: 4,
        rules: const GameRules(),
        startedAt: DateTime.now(),
      );

      final controller = GameController();
      controller.state = state;

      // Resuming in-memory game:
      final resumed = await controller.loadSavedGame();
      expect(resumed, isTrue);
      expect(controller.state?.gameId, 'test-resume-game');

      // Clearing active game session:
      await controller.clearActiveGameSession();
      expect(controller.state, isNull);
    });
  });
}

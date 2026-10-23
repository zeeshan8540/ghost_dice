// Domain unit tests for the Ludo rules engine.
// Run with: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_dice/domain/entities/board_config.dart';
import 'package:ghost_dice/domain/entities/board_position.dart';
import 'package:ghost_dice/domain/entities/game_rules.dart';
import 'package:ghost_dice/domain/entities/piece.dart';
import 'package:ghost_dice/domain/entities/player.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';
import 'package:ghost_dice/domain/services/ludo_rules_engine.dart';

Player _makePlayer(PlayerColor color,
    {List<BoardPosition>? positions}) {
  final id = color.name;
  final pos = positions ?? [
    const BoardPosition.yard(),
    const BoardPosition.yard(),
    const BoardPosition.yard(),
    const BoardPosition.yard(),
  ];
  return Player(
    id: id,
    name: color.name,
    color: color,
    seatIndex: PlayerColor.values.indexOf(color),
    pieces: List.generate(
      4,
      (i) => Piece(
        id: '${color.name}-$i',
        playerId: id,
        color: color,
        pieceIndex: i,
        position: pos[i],
      ),
    ),
  );
}

void main() {
  const defaultRules = GameRules.defaults;
  const engine = LudoRulesEngine(defaultRules);

  group('Dice value validation', () {
    test('values 1–6 are valid', () {
      final player = _makePlayer(PlayerColor.red,
          positions: [
            BoardPosition.track(0),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      for (var v = 1; v <= 6; v++) {
        expect(
            () => engine.computeLegalMoves(
                activePlayer: player,
                allPlayers: [player],
                diceValue: v,
                consecutiveSixCount: 0),
            returnsNormally);
      }
    });
  });

  group('Yard entry', () {
    test('6 allows a yard piece to enter when requireSixToLeaveYard=true', () {
      final player = _makePlayer(PlayerColor.red);
      final moves = engine.computeLegalMoves(
        activePlayer: player,
        allPlayers: [player],
        diceValue: 6,
        consecutiveSixCount: 0,
      );
      expect(moves, isNotEmpty);
      expect(moves.first.destination.isOnTrack, isTrue);
    });

    test('1–5 cannot move yard pieces when requireSixToLeaveYard=true', () {
      final player = _makePlayer(PlayerColor.red);
      for (var v = 1; v <= 5; v++) {
        final moves = engine.computeLegalMoves(
          activePlayer: player,
          allPlayers: [player],
          diceValue: v,
          consecutiveSixCount: 0,
        );
        expect(moves, isEmpty, reason: 'dice=$v should have no moves');
      }
    });

    test('any value allows yard entry when requireSixToLeaveYard=false', () {
      const lenientRules = GameRules(requireSixToLeaveYard: false);
      const lenientEngine = LudoRulesEngine(lenientRules);
      final player = _makePlayer(PlayerColor.red);
      for (var v = 1; v <= 6; v++) {
        final moves = lenientEngine.computeLegalMoves(
          activePlayer: player,
          allPlayers: [player],
          diceValue: v,
          consecutiveSixCount: 0,
        );
        expect(moves, isNotEmpty, reason: 'dice=$v should allow yard entry');
      }
    });
  });

  group('Track movement', () {
    test('piece advances correct number of squares', () {
      final player = _makePlayer(PlayerColor.red,
          positions: [
            BoardPosition.track(0),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      final moves = engine.computeLegalMoves(
        activePlayer: player,
        allPlayers: [player],
        diceValue: 5,
        consecutiveSixCount: 0,
      );
      expect(moves.length, 1);
      expect(moves.first.destination.trackIndex, 5);
    });

    test('track wraps around at index 52', () {
      final player = _makePlayer(PlayerColor.blue,
          positions: [
            BoardPosition.track(51),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      // Blue wraps from track[51] to track[0] towards its home lane at 37.
      final moves = engine.computeLegalMoves(
        activePlayer: player,
        allPlayers: [player],
        diceValue: 1,
        consecutiveSixCount: 0,
      );
      expect(moves.length, 1);
      expect(moves.first.destination.trackIndex, 0);
    });
  });

  group('Home lane entry', () {
    test('red piece enters home lane from track[50]', () {
      final player = _makePlayer(PlayerColor.red,
          positions: [
            BoardPosition.track(50),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      final moves = engine.computeLegalMoves(
        activePlayer: player,
        allPlayers: [player],
        diceValue: 1,
        consecutiveSixCount: 0,
      );
      expect(moves.length, 1);
      expect(moves.first.destination.isInHomeLane, isTrue);
      expect(moves.first.destination.homeLaneIndex, 0);
    });

    test('red piece at corner track[51] advances into home lane[1] on next roll of 1', () {
      final player = _makePlayer(PlayerColor.red,
          positions: [
            const BoardPosition.track(51),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      final moves = engine.computeLegalMoves(
        activePlayer: player,
        allPlayers: [player],
        diceValue: 1,
        consecutiveSixCount: 0,
      );
      expect(moves.length, 1);
      expect(moves.first.destination.isInHomeLane, isTrue);
      expect(moves.first.destination.homeLaneIndex, 1);
    });
  });

  group('Finishing', () {
    test('exact roll finishes the piece', () {
      // Piece at homeLaneIndex 4 (5th square) needs 1 more to reach home center.
      final player = _makePlayer(PlayerColor.red,
          positions: [
            BoardPosition.homeLane(4),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      final moves = engine.computeLegalMoves(
        activePlayer: player,
        allPlayers: [player],
        diceValue: 1,
        consecutiveSixCount: 0,
      );
      expect(moves.length, 1);
      expect(moves.first.destination.isFinished, isTrue);
    });

    test('piece on homeLane(1) finishes with roll of 4', () {
      final player = _makePlayer(PlayerColor.red,
          positions: [
            BoardPosition.homeLane(1),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      final moves = engine.computeLegalMoves(
        activePlayer: player,
        allPlayers: [player],
        diceValue: 4,
        consecutiveSixCount: 0,
      );
      expect(moves.length, 1);
      expect(moves.first.destination.isFinished, isTrue);
    });

    test('piece on homeLane(1) advances to homeLane(3) with roll of 2', () {
      final player = _makePlayer(PlayerColor.red,
          positions: [
            BoardPosition.homeLane(1),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      final moves = engine.computeLegalMoves(
        activePlayer: player,
        allPlayers: [player],
        diceValue: 2,
        consecutiveSixCount: 0,
      );
      expect(moves.length, 1);
      expect(moves.first.destination.isInHomeLane, isTrue);
      expect(moves.first.destination.homeLaneIndex, 3);
    });

    test('overshoot is illegal with requireExactRollToFinish=true', () {
      final player = _makePlayer(PlayerColor.red,
          positions: [
            BoardPosition.homeLane(4),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      final moves = engine.computeLegalMoves(
        activePlayer: player,
        allPlayers: [player],
        diceValue: 2,
        consecutiveSixCount: 0,
      );
      expect(moves, isEmpty);
    });
  });

  group('Captures', () {
    test('moving onto opponent piece captures it', () {
      final red = _makePlayer(PlayerColor.red,
          positions: [
            BoardPosition.track(4),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      final blue = _makePlayer(PlayerColor.blue,
          positions: [
            BoardPosition.track(7),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      final moves = engine.computeLegalMoves(
        activePlayer: red,
        allPlayers: [red, blue],
        diceValue: 3,
        consecutiveSixCount: 0,
      );
      expect(moves.length, 1);
      final resolution = engine.resolveMove(
        piece: moves.first.piece,
        destination: moves.first.destination,
        activePlayer: red,
        allPlayers: [red, blue],
        diceValue: 3,
      );
      expect(resolution.capturedPieces.length, 1);
      expect(resolution.capturedPieces.first.color, PlayerColor.blue);
      expect(resolution.earnedBonus, isTrue);
    });

    test('safe square prevents capture', () {
      // Track index 8 is a global safe square.
      final red = _makePlayer(PlayerColor.red,
          positions: [
            BoardPosition.track(5),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      final blue = _makePlayer(PlayerColor.blue,
          positions: [
            BoardPosition.track(8), // safe square
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      expect(BoardConfig.isGlobalSafe(8), isTrue);
      final moves = engine.computeLegalMoves(
        activePlayer: red,
        allPlayers: [red, blue],
        diceValue: 3,
        consecutiveSixCount: 0,
      );
      expect(moves.length, 1);
      final resolution = engine.resolveMove(
        piece: moves.first.piece,
        destination: moves.first.destination,
        activePlayer: red,
        allPlayers: [red, blue],
        diceValue: 3,
      );
      expect(resolution.capturedPieces, isEmpty);
    });
  });

  group('Bonus logic', () {
    test('rolling 6 earns bonus', () {
      final player = _makePlayer(PlayerColor.red,
          positions: [
            BoardPosition.track(0),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      final moves = engine.computeLegalMoves(
        activePlayer: player,
        allPlayers: [player],
        diceValue: 6,
        consecutiveSixCount: 0,
      );
      final resolution = engine.resolveMove(
        piece: moves.first.piece,
        destination: moves.first.destination,
        activePlayer: player,
        allPlayers: [player],
        diceValue: 6,
      );
      expect(resolution.earnedBonus, isTrue);
      expect(resolution.bonusReason, BonusReason.rolledSix);
    });

    test('capture earns bonus even without 6', () {
      final red = _makePlayer(PlayerColor.red,
          positions: [
            BoardPosition.track(5),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      final blue = _makePlayer(PlayerColor.blue,
          positions: [
            BoardPosition.track(7),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      final moves = engine.computeLegalMoves(
        activePlayer: red,
        allPlayers: [red, blue],
        diceValue: 2,
        consecutiveSixCount: 0,
      );
      final resolution = engine.resolveMove(
        piece: moves.first.piece,
        destination: moves.first.destination,
        activePlayer: red,
        allPlayers: [red, blue],
        diceValue: 2,
      );
      expect(resolution.earnedBonus, isTrue);
      expect(resolution.bonusReason, BonusReason.capture);
    });
  });

  group('Three consecutive sixes', () {
    test('third 6 in a row forfeits when threeSixesForfeitTurn=true', () {
      final player = _makePlayer(PlayerColor.red,
          positions: [
            BoardPosition.track(0),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
            const BoardPosition.yard(),
          ]);
      final moves = engine.computeLegalMoves(
        activePlayer: player,
        allPlayers: [player],
        diceValue: 6,
        consecutiveSixCount: 2,
      );
      expect(moves, isEmpty);
    });

    test('forfeit check helper is correct', () {
      expect(engine.isForfeitedByThreeSixes(6, 2), isTrue);
      expect(engine.isForfeitedByThreeSixes(6, 1), isFalse);
      expect(engine.isForfeitedByThreeSixes(5, 2), isFalse);
    });
  });

  group('Win detection', () {
    test('player with all 4 pieces finished is detected as winner', () {
      final winner = _makePlayer(PlayerColor.red,
          positions: [
            const BoardPosition.finished(),
            const BoardPosition.finished(),
            const BoardPosition.finished(),
            const BoardPosition.finished(),
          ]);
      final others = [_makePlayer(PlayerColor.blue)];
      expect(engine.checkWinner([winner, ...others]), winner);
    });

    test('no winner when no player is done', () {
      final players =
          [PlayerColor.red, PlayerColor.blue].map(_makePlayer).toList();
      expect(engine.checkWinner(players), isNull);
    });
  });
}

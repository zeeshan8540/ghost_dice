import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_dice/domain/entities/board_config.dart';
import 'package:ghost_dice/domain/entities/board_position.dart';
import 'package:ghost_dice/domain/entities/game_rules.dart';
import 'package:ghost_dice/domain/entities/piece.dart';
import 'package:ghost_dice/domain/entities/player.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';
import 'package:ghost_dice/domain/services/ludo_rules_engine.dart';

Player _makeTeamPlayer(
  PlayerColor color, {
  required String teamId,
  required String teamName,
  List<BoardPosition>? positions,
}) {
  final id = color.name;
  final pos = positions ??
      const [
        BoardPosition.yard(),
        BoardPosition.yard(),
        BoardPosition.yard(),
        BoardPosition.yard(),
      ];
  return Player(
    id: id,
    name: color.name.toUpperCase(),
    color: color,
    seatIndex: PlayerColor.values.indexOf(color),
    teamId: teamId,
    teamName: teamName,
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
  const teamRules = GameRules(isTeamUp: true);
  const engine = LudoRulesEngine(teamRules);

  group('Team Up 2v2 Mode Rules', () {
    test('Teammates do NOT capture each other when landing on the same square', () {
      // Red and Yellow are Team 1. Blue is Team 2.
      final red = _makeTeamPlayer(
        PlayerColor.red,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(5),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );

      final yellow = _makeTeamPlayer(
        PlayerColor.yellow,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(7), // Teammate at track 7
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );

      final blue = _makeTeamPlayer(
        PlayerColor.blue,
        teamId: 'team_2',
        teamName: 'Team 2',
        positions: [
          const BoardPosition.track(9), // Opponent at track 9
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );

      final allPlayers = [red, yellow, blue];

      // Red moves 2 steps from 5 -> lands on 7 (Yellow's square)
      final resLandingOnTeammate = engine.resolveMove(
        piece: red.pieces[0],
        destination: const BoardPosition.track(7),
        activePlayer: red,
        allPlayers: allPlayers,
        diceValue: 2,
      );

      expect(resLandingOnTeammate.capturedPieces, isEmpty,
          reason: 'Teammates must safely coexist on the same tile and not capture each other');

      // Red moves 4 steps from 5 -> lands on 9 (Blue's square)
      final resLandingOnOpponent = engine.resolveMove(
        piece: red.pieces[0],
        destination: const BoardPosition.track(9),
        activePlayer: red,
        allPlayers: allPlayers,
        diceValue: 4,
      );

      expect(resLandingOnOpponent.capturedPieces, hasLength(1),
          reason: 'Opponents must still be captured normally on non-safe tiles');
      expect(resLandingOnOpponent.capturedPieces.first.id, blue.pieces[0].id);
    });

    test('Teammates do NOT blockade each other even when allowBlockades is true', () {
      const blockadeRules = GameRules(isTeamUp: true, allowBlockades: true);
      const blockadeEngine = LudoRulesEngine(blockadeRules);

      // Yellow (Team 1) has 2 pieces on track 7
      final red = _makeTeamPlayer(
        PlayerColor.red,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(5),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );

      final yellow = _makeTeamPlayer(
        PlayerColor.yellow,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(7),
          const BoardPosition.track(7),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );

      final allPlayers = [red, yellow];

      final legal = blockadeEngine.computeLegalMoves(
        activePlayer: red,
        allPlayers: allPlayers,
        diceValue: 2,
        consecutiveSixCount: 0,
      );

      expect(legal.any((m) => m.destination == const BoardPosition.track(7)), isTrue,
          reason: 'Teammates can share squares with their own partner even with multiple tokens');
    });

    test('Single player finishing 4 pieces does NOT trigger win in Team Up mode', () {
      // Red has 4 finished pieces, but partner Yellow has not finished yet
      final red = _makeTeamPlayer(
        PlayerColor.red,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.finished(),
          const BoardPosition.finished(),
          const BoardPosition.finished(),
          const BoardPosition.finished(),
        ],
      );

      final yellow = _makeTeamPlayer(
        PlayerColor.yellow,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );

      final blue = _makeTeamPlayer(
        PlayerColor.blue,
        teamId: 'team_2',
        teamName: 'Team 2',
      );

      final green = _makeTeamPlayer(
        PlayerColor.green,
        teamId: 'team_2',
        teamName: 'Team 2',
      );

      final allPlayers = [red, green, yellow, blue];

      expect(engine.checkWinner(allPlayers), isNull,
          reason: 'Team 1 does not win until BOTH teammates finish all 8 pieces');
    });

    test('Team wins when BOTH teammates finish all 8 tokens', () {
      final red = _makeTeamPlayer(
        PlayerColor.red,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.finished(),
          const BoardPosition.finished(),
          const BoardPosition.finished(),
          const BoardPosition.finished(),
        ],
      );

      final yellow = _makeTeamPlayer(
        PlayerColor.yellow,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.finished(),
          const BoardPosition.finished(),
          const BoardPosition.finished(),
          const BoardPosition.finished(),
        ],
      );

      final blue = _makeTeamPlayer(
        PlayerColor.blue,
        teamId: 'team_2',
        teamName: 'Team 2',
      );

      final green = _makeTeamPlayer(
        PlayerColor.green,
        teamId: 'team_2',
        teamName: 'Team 2',
      );

      final allPlayers = [red, green, yellow, blue];

      final winner = engine.checkWinner(allPlayers);
      expect(winner, isNotNull, reason: 'Team 1 should be declared winner once all 8 pieces reach home');
      expect(winner?.teamId, 'team_1');
    });

    test('Pair Shield: single opponent entering square with 2 team pieces (Red + Yellow) does NOT capture', () {
      // Red and Yellow on track 10 (not a safe square). Blue moves from 6 to 10.
      final red = _makeTeamPlayer(
        PlayerColor.red,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final yellow = _makeTeamPlayer(
        PlayerColor.yellow,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final blue = _makeTeamPlayer(
        PlayerColor.blue,
        teamId: 'team_2',
        teamName: 'Team 2',
        positions: [
          const BoardPosition.track(6),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final allPlayers = [red, yellow, blue];

      final res = engine.resolveMove(
        piece: blue.pieces[0],
        destination: const BoardPosition.track(10),
        activePlayer: blue,
        allPlayers: allPlayers,
        diceValue: 4,
      );

      expect(res.capturedPieces, isEmpty,
          reason: 'A single opponent piece entering a 2-piece shield does not capture either piece and stays safely');
      expect(res.earnedBonus, isFalse);
    });

    test('Pair Shield (same color): single opponent entering square with 2 same-color pieces (2 Red) does NOT capture', () {
      final red = _makeTeamPlayer(
        PlayerColor.red,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.track(10),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final blue = _makeTeamPlayer(
        PlayerColor.blue,
        teamId: 'team_2',
        teamName: 'Team 2',
        positions: [
          const BoardPosition.track(6),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final allPlayers = [red, blue];

      final res = engine.resolveMove(
        piece: blue.pieces[0],
        destination: const BoardPosition.track(10),
        activePlayer: blue,
        allPlayers: allPlayers,
        diceValue: 4,
      );

      expect(res.capturedPieces, isEmpty,
          reason: 'Two same-colored pieces form a pair shield protecting both from a single incoming opponent');
    });

    test('Pair vs Pair Capture: second opponent entering square with 2 team pieces captures BOTH pieces', () {
      // Red and Yellow on track 10. Blue is already on track 10. Green moves to track 10.
      final red = _makeTeamPlayer(
        PlayerColor.red,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final yellow = _makeTeamPlayer(
        PlayerColor.yellow,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final blue = _makeTeamPlayer(
        PlayerColor.blue,
        teamId: 'team_2',
        teamName: 'Team 2',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final green = _makeTeamPlayer(
        PlayerColor.green,
        teamId: 'team_2',
        teamName: 'Team 2',
        positions: [
          const BoardPosition.track(7),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final allPlayers = [red, yellow, blue, green];

      final res = engine.resolveMove(
        piece: green.pieces[0],
        destination: const BoardPosition.track(10),
        activePlayer: green,
        allPlayers: allPlayers,
        diceValue: 3,
      );

      expect(res.capturedPieces, hasLength(2),
          reason: 'When 2nd piece of the opponent team lands, both original team pieces are captured');
      expect(res.destinationCaptures.map((p) => p.id), containsAll([red.pieces[0].id, yellow.pieces[0].id]));
      expect(res.earnedBonus, isTrue);
      expect(res.bonusReason, BonusReason.capture);

      final updated = engine.applyResolution(players: allPlayers, activePlayer: green, resolution: res);
      final updatedRed = updated.firstWhere((p) => p.color == PlayerColor.red);
      final updatedYellow = updated.firstWhere((p) => p.color == PlayerColor.yellow);
      expect(updatedRed.pieces[0].isInYard, isTrue);
      expect(updatedYellow.pieces[0].isInYard, isTrue);
    });

    test('Pair vs Pair Capture (same color): 2nd Blue lands with 1st Blue on 2 Red pieces and captures both', () {
      final red = _makeTeamPlayer(
        PlayerColor.red,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.track(10),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final blue = _makeTeamPlayer(
        PlayerColor.blue,
        teamId: 'team_2',
        teamName: 'Team 2',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.track(7),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final allPlayers = [red, blue];

      final res = engine.resolveMove(
        piece: blue.pieces[1],
        destination: const BoardPosition.track(10),
        activePlayer: blue,
        allPlayers: allPlayers,
        diceValue: 3,
      );

      expect(res.capturedPieces, hasLength(2));
      expect(res.destinationCaptures.map((p) => p.id), containsAll([red.pieces[0].id, red.pieces[1].id]));
      expect(res.earnedBonus, isTrue);
    });

    test('Departure Abandonment: moving one piece from pair leaves partner alone with waiting opponent and partner is caught', () {
      // Track 10 has Red, Yellow, and Blue.
      // Red moves from track 10 to track 14.
      final red = _makeTeamPlayer(
        PlayerColor.red,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final yellow = _makeTeamPlayer(
        PlayerColor.yellow,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final blue = _makeTeamPlayer(
        PlayerColor.blue,
        teamId: 'team_2',
        teamName: 'Team 2',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final allPlayers = [red, yellow, blue];

      final res = engine.resolveMove(
        piece: red.pieces[0],
        destination: const BoardPosition.track(14),
        activePlayer: red,
        allPlayers: allPlayers,
        diceValue: 4,
      );

      // Yellow was abandoned on track 10 with Blue!
      expect(res.capturedPieces, hasLength(1));
      expect(res.abandonedCaptures, hasLength(1));
      expect(res.abandonedCaptures.first.id, yellow.pieces[0].id);
      expect(res.destinationCaptures, isEmpty);
      // Red does not get a capture bonus for having their own partner caught!
      expect(res.earnedBonus, isFalse);

      final updated = engine.applyResolution(players: allPlayers, activePlayer: red, resolution: res);
      final updatedYellow = updated.firstWhere((p) => p.color == PlayerColor.yellow);
      final updatedRed = updated.firstWhere((p) => p.color == PlayerColor.red);
      expect(updatedYellow.pieces[0].isInYard, isTrue);
      expect(updatedRed.pieces[0].position, const BoardPosition.track(14));
    });

    test('Departure Abandonment (same color): moving 1 of 2 Red pieces leaves other Red piece alone with Blue and it is caught', () {
      final red = _makeTeamPlayer(
        PlayerColor.red,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.track(10),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final blue = _makeTeamPlayer(
        PlayerColor.blue,
        teamId: 'team_2',
        teamName: 'Team 2',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final allPlayers = [red, blue];

      final res = engine.resolveMove(
        piece: red.pieces[0],
        destination: const BoardPosition.track(14),
        activePlayer: red,
        allPlayers: allPlayers,
        diceValue: 4,
      );

      expect(res.capturedPieces, hasLength(1));
      expect(res.abandonedCaptures.first.id, red.pieces[1].id);

      final updated = engine.applyResolution(players: allPlayers, activePlayer: red, resolution: res);
      final updatedRed = updated.firstWhere((p) => p.color == PlayerColor.red);
      expect(updatedRed.pieces[0].position, const BoardPosition.track(14));
      expect(updatedRed.pieces[1].isInYard, isTrue);
    });

    test('Opponent Departure: when single waiting opponent moves away from pair, nobody is captured', () {
      // Track 10 has Red, Yellow, Blue. Blue moves away to track 13.
      final red = _makeTeamPlayer(
        PlayerColor.red,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final yellow = _makeTeamPlayer(
        PlayerColor.yellow,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final blue = _makeTeamPlayer(
        PlayerColor.blue,
        teamId: 'team_2',
        teamName: 'Team 2',
        positions: [
          const BoardPosition.track(10),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final allPlayers = [red, yellow, blue];

      final res = engine.resolveMove(
        piece: blue.pieces[0],
        destination: const BoardPosition.track(13),
        activePlayer: blue,
        allPlayers: allPlayers,
        diceValue: 3,
      );

      expect(res.capturedPieces, isEmpty);
      expect(res.abandonedCaptures, isEmpty);
      expect(res.destinationCaptures, isEmpty);
    });

    test('Star square immunity: departure from a safe star square does not trigger abandonment capture', () {
      // Track 8 is a Star safe square.
      expect(BoardConfig.isGlobalSafe(8), isTrue);

      final red = _makeTeamPlayer(
        PlayerColor.red,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(8),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final yellow = _makeTeamPlayer(
        PlayerColor.yellow,
        teamId: 'team_1',
        teamName: 'Team 1',
        positions: [
          const BoardPosition.track(8),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final blue = _makeTeamPlayer(
        PlayerColor.blue,
        teamId: 'team_2',
        teamName: 'Team 2',
        positions: [
          const BoardPosition.track(8),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
          const BoardPosition.yard(),
        ],
      );
      final allPlayers = [red, yellow, blue];

      final res = engine.resolveMove(
        piece: red.pieces[0],
        destination: const BoardPosition.track(11),
        activePlayer: red,
        allPlayers: allPlayers,
        diceValue: 3,
      );

      expect(res.capturedPieces, isEmpty,
          reason: 'Safe squares never allow captures on departure or arrival');
    });
  });
}

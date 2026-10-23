// LudoRulesEngine — pure Dart domain service.
// No Flutter, Riverpod, or persistence imports.
// Computes legal moves and resolves movement including captures, home-lane,
// finishing, and bonus eligibility.

import 'package:ghost_dice/domain/entities/board_config.dart';
import 'package:ghost_dice/domain/entities/board_position.dart';
import 'package:ghost_dice/domain/entities/game_rules.dart';
import 'package:ghost_dice/domain/entities/piece.dart';
import 'package:ghost_dice/domain/entities/player.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';

/// The result of resolving a single piece move.
class MoveResolution {
  final Piece movedPiece;
  final BoardPosition newPosition;
  final List<Piece> capturedPieces;
  final List<Piece> destinationCaptures;
  final List<Piece> abandonedCaptures;
  final bool finishedPiece;
  final bool earnedBonus;
  final BonusReason? bonusReason;

  const MoveResolution({
    required this.movedPiece,
    required this.newPosition,
    required this.capturedPieces,
    this.destinationCaptures = const [],
    this.abandonedCaptures = const [],
    required this.finishedPiece,
    required this.earnedBonus,
    this.bonusReason,
  });
}

/// Describes a single legal move option presented to the player.
class LegalMove {
  final Piece piece;
  final BoardPosition destination;

  const LegalMove({required this.piece, required this.destination});
}

class LudoRulesEngine {
  final GameRules rules;

  const LudoRulesEngine(this.rules);

  // ---------------------------------------------------------------------------
  // LEGAL MOVE COMPUTATION
  // ---------------------------------------------------------------------------

  /// Returns all legal moves for [activePlayer] given [diceValue].
  /// All other players' pieces are needed to check captures and blockades.
  List<LegalMove> computeLegalMoves({
    required Player activePlayer,
    required List<Player> allPlayers,
    required int diceValue,
    required int consecutiveSixCount,
  }) {
    assert(diceValue >= 1 && diceValue <= 6, 'dice value must be 1–6');

    // Three-sixes forfeit: third six has no legal moves.
    if (rules.threeSixesForfeitTurn &&
        consecutiveSixCount >= 2 &&
        diceValue == 6) {
      return [];
    }

    final legal = <LegalMove>[];

    for (final piece in activePlayer.pieces) {
      if (piece.isFinished) continue;

      if (piece.isInYard) {
        // Can only enter if rolled a 6 (when requireSixToLeaveYard) or any roll.
        if (rules.requireSixToLeaveYard && diceValue != 6) continue;
        if (!rules.requireSixToLeaveYard) {
          // move piece onto track at startIndex + diceValue-1 (variant rules)
          // Default rule handled below
        }
        if (diceValue == 6 || !rules.requireSixToLeaveYard) {
          final dest = BoardPosition.track(
              BoardConfig.startTrackIndex[piece.color]!);
          if (!_isBlockaded(dest, piece.color, allPlayers)) {
            legal.add(LegalMove(piece: piece, destination: dest));
          }
        }
      } else if (piece.isOnTrack) {
        final dest = _computeTrackDestination(
            piece, piece.color, diceValue, allPlayers);
        if (dest != null) {
          legal.add(LegalMove(piece: piece, destination: dest));
        }
      } else if (piece.isInHomeLane) {
        final dest = _computeHomeLaneDestination(piece, diceValue);
        if (dest != null) {
          legal.add(LegalMove(piece: piece, destination: dest));
        }
      }
    }

    return legal;
  }

  BoardPosition? _computeTrackDestination(
      Piece piece, PlayerColor color, int diceValue, List<Player> allPlayers) {
    final currentStep = BoardConfig.getLocalStep(piece.position, color);
    if (currentStep < 0) return null;

    final targetStep = currentStep + diceValue;
    if (targetStep < BoardConfig.totalStepsToFinish) {
      final dest = BoardConfig.positionFromLocalStep(targetStep, color);
      if (_isBlockaded(dest, color, allPlayers)) return null;
      return dest;
    } else if (targetStep == BoardConfig.totalStepsToFinish) {
      return const BoardPosition.finished();
    } else {
      if (rules.requireExactRollToFinish) return null;
      return const BoardPosition.finished();
    }
  }

  BoardPosition? _computeHomeLaneDestination(Piece piece, int diceValue) {
    final currentStep = BoardConfig.getLocalStep(piece.position, piece.color);
    final targetStep = currentStep + diceValue;

    if (targetStep < BoardConfig.totalStepsToFinish) {
      return BoardConfig.positionFromLocalStep(targetStep, piece.color);
    } else if (targetStep == BoardConfig.totalStepsToFinish) {
      return const BoardPosition.finished();
    } else {
      if (rules.requireExactRollToFinish) return null;
      return const BoardPosition.finished();
    }
  }

  bool _isBlockaded(
      BoardPosition dest, PlayerColor movingColor, List<Player> allPlayers) {
    if (!rules.allowBlockades) return false;
    // In Team Up mode, pieces can enter tiles occupied by multiple pieces without blockade
    if (rules.isTeamUp) return false;
    if (!dest.isOnTrack) return false;

    for (final player in allPlayers) {
      if (player.color == movingColor) continue;
      final count = player.pieces
          .where((p) => p.isOnTrack && p.position.trackIndex == dest.trackIndex)
          .length;
      if (count >= 2) return true;
    }
    return false;
  }

  bool _isTeammateOf(Player player, Player mover) {
    if (player.id == mover.id || player.color == mover.color) return true;
    return _areTeammates(player, mover);
  }

  bool _areTeammates(Player a, Player b) {
    if (!rules.isTeamUp) return false;
    if (a.teamId != null && b.teamId != null) {
      return a.teamId == b.teamId;
    }
    return _areColorsTeammates(a.color, b.color);
  }

  bool _areColorsTeammates(PlayerColor a, PlayerColor b) {
    final aIsTeam1 = a == PlayerColor.red || a == PlayerColor.yellow;
    final bIsTeam1 = b == PlayerColor.red || b == PlayerColor.yellow;
    return aIsTeam1 == bIsTeam1;
  }

  // ---------------------------------------------------------------------------
  // MOVE RESOLUTION
  // ---------------------------------------------------------------------------

  /// Resolves the consequences of moving [piece] to [destination].
  MoveResolution resolveMove({
    required Piece piece,
    required BoardPosition destination,
    required Player activePlayer,
    required List<Player> allPlayers,
    required int diceValue,
  }) {
    final destinationCaptures = <Piece>[];
    final abandonedCaptures = <Piece>[];

    final movingPlayer = allPlayers.firstWhere(
      (p) => p.id == piece.playerId || p.color == piece.color,
      orElse: () => activePlayer,
    );

    // 1. DEPARTURE (ABANDONMENT) CAPTURE CHECK (Team Up mode only)
    // If the moving piece leaves a non-safe track square, check if its departure
    // leaves behind exactly 1 teammate with waiting opponent(s).
    if (rules.isTeamUp && piece.position.isOnTrack) {
      final fromTrackIdx = piece.position.trackIndex!;
      final isFromSafe =
          rules.useSafeSquares && BoardConfig.isGlobalSafe(fromTrackIdx);

      if (!isFromSafe) {
        final remainingTeammates = <Piece>[];
        final remainingOpponents = <Piece>[];

        for (final player in allPlayers) {
          final isTeammate = _isTeammateOf(player, movingPlayer);
          for (final p in player.pieces) {
            if (p.id == piece.id) continue;
            if (p.isOnTrack && p.position.trackIndex == fromTrackIdx) {
              if (isTeammate) {
                remainingTeammates.add(p);
              } else {
                remainingOpponents.add(p);
              }
            }
          }
        }

        // If exactly 1 teammate is left behind and at least 1 opponent is waiting,
        // the pair shield is broken, and the remaining teammate is captured.
        if (remainingTeammates.length == 1 && remainingOpponents.isNotEmpty) {
          abandonedCaptures.addAll(remainingTeammates);
        }
      }
    }

    // 2. DESTINATION CAPTURE CHECK
    if (destination.isOnTrack) {
      final trackIdx = destination.trackIndex!;
      final isSafe =
          rules.useSafeSquares && BoardConfig.isGlobalSafe(trackIdx);

      if (!isSafe) {
        if (!rules.isTeamUp) {
          for (final player in allPlayers) {
            if (player.id == movingPlayer.id ||
                player.color == movingPlayer.color) {
              continue;
            }
            for (final p in player.pieces) {
              if (p.isOnTrack && p.position.trackIndex == trackIdx) {
                destinationCaptures.add(p);
              }
            }
          }
        } else {
          // Team Up Mode:
          final opponentPiecesOnDest = <Piece>[];
          final teammatePiecesOnDest = <Piece>[];

          for (final player in allPlayers) {
            final isTeammate = _isTeammateOf(player, movingPlayer);
            for (final p in player.pieces) {
              if (p.id == piece.id) continue;
              if (p.isOnTrack && p.position.trackIndex == trackIdx) {
                if (isTeammate) {
                  teammatePiecesOnDest.add(p);
                } else {
                  opponentPiecesOnDest.add(p);
                }
              }
            }
          }

          final teamCount = teammatePiecesOnDest.length + 1;
          final oppCount = opponentPiecesOnDest.length;

          if (oppCount == 1) {
            // Single opponent piece is captured by incoming piece(s).
            destinationCaptures.addAll(opponentPiecesOnDest);
          } else if (oppCount >= 2) {
            // Opponents have a pair shield (2+ pieces).
            // A pair (2+ pieces) is required to break their shield and capture them.
            // If only 1 piece of the incoming team arrives, it coexists safely without capture.
            if (teamCount >= 2) {
              destinationCaptures.addAll(opponentPiecesOnDest);
            }
          }
        }
      }
    }

    final allCaptures = [...destinationCaptures, ...abandonedCaptures];
    final isFinished = destination.isFinished;

    // Bonus logic: at most one bonus reason per move.
    // Bonus for capture is earned ONLY when destination opponent(s) were captured.
    BonusReason? bonusReason;
    if (diceValue == 6) {
      bonusReason = BonusReason.rolledSix;
    } else if (destinationCaptures.isNotEmpty) {
      bonusReason = BonusReason.capture;
    } else if (isFinished) {
      bonusReason = BonusReason.finishedPiece;
    }

    return MoveResolution(
      movedPiece: piece,
      newPosition: destination,
      capturedPieces: allCaptures,
      destinationCaptures: destinationCaptures,
      abandonedCaptures: abandonedCaptures,
      finishedPiece: isFinished,
      earnedBonus: bonusReason != null,
      bonusReason: bonusReason,
    );
  }

  // ---------------------------------------------------------------------------
  // FORFEIT CHECK
  // ---------------------------------------------------------------------------

  /// Returns true if this dice entry is forfeited by the three-consecutive-sixes rule.
  bool isForfeitedByThreeSixes(int diceValue, int consecutiveSixCount) {
    return rules.threeSixesForfeitTurn &&
        diceValue == 6 &&
        consecutiveSixCount >= 2;
  }

  // ---------------------------------------------------------------------------
  // WIN CHECK
  // ---------------------------------------------------------------------------

  /// Returns the winning player if one exists, otherwise null.
  Player? checkWinner(List<Player> players) {
    if (rules.isTeamUp) {
      // Team 1: Red & Yellow
      final team1 = players.where((p) => p.teamId == 'team_1' || _areColorsTeammates(p.color, PlayerColor.red)).toList();
      final team2 = players.where((p) => p.teamId == 'team_2' || !_areColorsTeammates(p.color, PlayerColor.red)).toList();

      if (team1.isNotEmpty && team1.every((p) => p.hasWon)) {
        return team1.first;
      }
      if (team2.isNotEmpty && team2.every((p) => p.hasWon)) {
        return team2.first;
      }
      return null;
    }

    for (final player in players) {
      if (player.hasWon) return player;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // NEXT PLAYER
  // ---------------------------------------------------------------------------

  int nextPlayerIndex(int current, int total) => (current + 1) % total;

  // ---------------------------------------------------------------------------
  // APPLY MOVE TO PLAYERS
  // ---------------------------------------------------------------------------

  /// Returns updated player list after applying [resolution].
  /// Captured pieces are returned to yard. Moved piece gets new position.
  List<Player> applyResolution({
    required List<Player> players,
    required Player activePlayer,
    required MoveResolution resolution,
  }) {
    final capturedIds = resolution.capturedPieces.map((c) => c.id).toSet();

    return players.map((player) {
      final updatedPieces = player.pieces.map((p) {
        if (p.id == resolution.movedPiece.id) {
          return p.copyWith(position: resolution.newPosition);
        } else if (capturedIds.contains(p.id)) {
          return p.copyWith(position: const BoardPosition.yard());
        }
        return p;
      }).toList();
      return player.copyWith(pieces: updatedPieces);
    }).toList();
  }
}

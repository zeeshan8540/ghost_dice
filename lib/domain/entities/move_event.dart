// MoveEvent — records a fully committed move with all its consequences.
import 'package:ghost_dice/domain/enums/game_enums.dart';

class MoveEvent {
  final String id;
  final String playerId;
  final String diceEntryId;

  /// Null if the dice value had no legal move.
  final String? pieceId;
  final int diceValue;
  final DateTime committedAt;
  final List<String> capturedPieceIds;
  final bool finishedPiece;
  final bool earnedBonus;
  final BonusReason? bonusReason;

  /// True when the player's turn chain ends (pass to next player).
  final bool turnEnded;

  /// True when three-sixes rule forfeited this entry.
  final bool forfeitedByThreeSixes;

  const MoveEvent({
    required this.id,
    required this.playerId,
    required this.diceEntryId,
    this.pieceId,
    required this.diceValue,
    required this.committedAt,
    this.capturedPieceIds = const [],
    this.finishedPiece = false,
    this.earnedBonus = false,
    this.bonusReason,
    this.turnEnded = false,
    this.forfeitedByThreeSixes = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerId': playerId,
        'diceEntryId': diceEntryId,
        'pieceId': pieceId,
        'diceValue': diceValue,
        'committedAt': committedAt.toIso8601String(),
        'capturedPieceIds': capturedPieceIds,
        'finishedPiece': finishedPiece,
        'earnedBonus': earnedBonus,
        'bonusReason': bonusReason?.name,
        'turnEnded': turnEnded,
        'forfeitedByThreeSixes': forfeitedByThreeSixes,
      };

  factory MoveEvent.fromJson(Map<String, dynamic> json) => MoveEvent(
        id: json['id'] as String,
        playerId: json['playerId'] as String,
        diceEntryId: json['diceEntryId'] as String,
        pieceId: json['pieceId'] as String?,
        diceValue: json['diceValue'] as int,
        committedAt: DateTime.parse(json['committedAt'] as String),
        capturedPieceIds: List<String>.from(json['capturedPieceIds'] as List),
        finishedPiece: json['finishedPiece'] as bool? ?? false,
        earnedBonus: json['earnedBonus'] as bool? ?? false,
        bonusReason: json['bonusReason'] != null
            ? BonusReason.values
                .firstWhere((e) => e.name == json['bonusReason'])
            : null,
        turnEnded: json['turnEnded'] as bool? ?? false,
        forfeitedByThreeSixes:
            json['forfeitedByThreeSixes'] as bool? ?? false,
      );
}

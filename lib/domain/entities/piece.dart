// Piece entity — immutable.
import 'package:ghost_dice/domain/entities/board_position.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';

class Piece {
  final String id;
  final String playerId;
  final PlayerColor color;

  /// 0-based index within the player's four pieces.
  final int pieceIndex;
  final BoardPosition position;

  const Piece({
    required this.id,
    required this.playerId,
    required this.color,
    required this.pieceIndex,
    required this.position,
  });

  bool get isInYard => position.isInYard;
  bool get isOnTrack => position.isOnTrack;
  bool get isInHomeLane => position.isInHomeLane;
  bool get isFinished => position.isFinished;
  bool get canMove => position.canMove;

  Piece copyWith({BoardPosition? position}) => Piece(
        id: id,
        playerId: playerId,
        color: color,
        pieceIndex: pieceIndex,
        position: position ?? this.position,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerId': playerId,
        'color': color.name,
        'pieceIndex': pieceIndex,
        'position': position.toJson(),
      };

  factory Piece.fromJson(Map<String, dynamic> json) => Piece(
        id: json['id'] as String,
        playerId: json['playerId'] as String,
        color: PlayerColor.values.firstWhere((e) => e.name == json['color']),
        pieceIndex: json['pieceIndex'] as int,
        position: BoardPosition.fromJson(
            json['position'] as Map<String, dynamic>),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Piece && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Piece($color-$pieceIndex @ $position)';
}

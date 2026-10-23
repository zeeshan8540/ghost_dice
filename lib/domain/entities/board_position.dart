// Board position entity — coordinate-free, logical position only.
import 'package:ghost_dice/domain/enums/game_enums.dart';

/// Immutable board position for a piece.
class BoardPosition {
  final PieceStatus status;

  /// 0-based index on the shared 52-square perimeter loop.
  /// Null when status is yard, homeLane, or finished.
  final int? trackIndex;

  /// 0-based index inside the player's 5-square home lane (0 = entry, 4 = home).
  /// Null unless status is homeLane.
  final int? homeLaneIndex;

  const BoardPosition.yard()
      : status = PieceStatus.yard,
        trackIndex = null,
        homeLaneIndex = null;

  const BoardPosition.track(int index)
      : status = PieceStatus.track,
        trackIndex = index,
        homeLaneIndex = null;

  const BoardPosition.homeLane(int index)
      : status = PieceStatus.homeLane,
        trackIndex = null,
        homeLaneIndex = index;

  const BoardPosition.finished()
      : status = PieceStatus.finished,
        trackIndex = null,
        homeLaneIndex = null;

  bool get isOnTrack => status == PieceStatus.track;
  bool get isInYard => status == PieceStatus.yard;
  bool get isInHomeLane => status == PieceStatus.homeLane;
  bool get isFinished => status == PieceStatus.finished;
  bool get canMove => status != PieceStatus.finished;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardPosition &&
          status == other.status &&
          trackIndex == other.trackIndex &&
          homeLaneIndex == other.homeLaneIndex;

  @override
  int get hashCode => Object.hash(status, trackIndex, homeLaneIndex);

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'trackIndex': trackIndex,
        'homeLaneIndex': homeLaneIndex,
      };

  factory BoardPosition.fromJson(Map<String, dynamic> json) {
    final status =
        PieceStatus.values.firstWhere((e) => e.name == json['status']);
    return switch (status) {
      PieceStatus.yard => const BoardPosition.yard(),
      PieceStatus.track => BoardPosition.track(json['trackIndex'] as int),
      PieceStatus.homeLane =>
        BoardPosition.homeLane(json['homeLaneIndex'] as int),
      PieceStatus.finished => const BoardPosition.finished(),
    };
  }

  @override
  String toString() => switch (status) {
        PieceStatus.yard => 'Yard',
        PieceStatus.track => 'Track[$trackIndex]',
        PieceStatus.homeLane => 'HomeLane[$homeLaneIndex]',
        PieceStatus.finished => 'Finished',
      };
}

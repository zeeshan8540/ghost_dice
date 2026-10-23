// Player entity — immutable.
import 'package:ghost_dice/domain/entities/piece.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';

class Player {
  final String id;
  final String name;
  final PlayerColor color;

  /// Seat order (0-indexed).
  final int seatIndex;
  final List<Piece> pieces;

  /// Optional team ID (e.g. 'team_1', 'team_2' for Team Up mode).
  final String? teamId;

  /// Optional display name of the team (e.g. 'Team 1', 'Team 2').
  final String? teamName;

  const Player({
    required this.id,
    required this.name,
    required this.color,
    required this.seatIndex,
    required this.pieces,
    this.teamId,
    this.teamName,
  });

  int get finishedCount => pieces.where((p) => p.isFinished).length;
  bool get hasWon => finishedCount == 4;
  int get pieceCountOnTrack => pieces.where((p) => p.isOnTrack).length;
  int get pieceCountInYard => pieces.where((p) => p.isInYard).length;

  Player copyWith({
    String? name,
    List<Piece>? pieces,
    String? teamId,
    String? teamName,
  }) =>
      Player(
        id: id,
        name: name ?? this.name,
        color: color,
        seatIndex: seatIndex,
        pieces: pieces ?? this.pieces,
        teamId: teamId ?? this.teamId,
        teamName: teamName ?? this.teamName,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.name,
        'seatIndex': seatIndex,
        'pieces': pieces.map((p) => p.toJson()).toList(),
        if (teamId != null) 'teamId': teamId,
        if (teamName != null) 'teamName': teamName,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        color: PlayerColor.values.firstWhere((e) => e.name == json['color']),
        seatIndex: json['seatIndex'] as int,
        pieces: (json['pieces'] as List)
            .map((p) => Piece.fromJson(p as Map<String, dynamic>))
            .toList(),
        teamId: json['teamId'] as String?,
        teamName: json['teamName'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Player && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Player($name, $color, seat=$seatIndex)';
}

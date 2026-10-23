// UndoRequest — tracks a vote to roll back a committed dice entry.
import 'package:ghost_dice/domain/enums/game_enums.dart';

class UndoRequest {
  final String id;
  final String requesterPlayerId;

  /// The dice-entry transaction to be undone.
  final String targetEntryId;

  /// All committed entry IDs that will be removed if approved (target + any later).
  final List<String> dependentEntryIds;

  /// playerId → true (yes) / false (no).
  final Map<String, bool> votesByPlayerId;

  /// Player IDs eligible to vote (everyone except the mover).
  final List<String> eligibleVoterIds;

  final UndoVoteResult result;
  final DateTime requestedAt;
  final DateTime? resolvedAt;

  const UndoRequest({
    required this.id,
    required this.requesterPlayerId,
    required this.targetEntryId,
    required this.dependentEntryIds,
    required this.votesByPlayerId,
    required this.eligibleVoterIds,
    required this.result,
    required this.requestedAt,
    this.resolvedAt,
  });

  bool get isPending => result == UndoVoteResult.pending;

  int get yesCount => votesByPlayerId.values.where((v) => v).length;
  int get noCount => votesByPlayerId.values.where((v) => !v).length;
  int get remainingVoters =>
      eligibleVoterIds.where((id) => !votesByPlayerId.containsKey(id)).length;

  bool meetsStrictMajority() {
    final total = eligibleVoterIds.length;
    return yesCount > total / 2;
  }

  UndoRequest copyWith({
    Map<String, bool>? votesByPlayerId,
    UndoVoteResult? result,
    DateTime? resolvedAt,
  }) =>
      UndoRequest(
        id: id,
        requesterPlayerId: requesterPlayerId,
        targetEntryId: targetEntryId,
        dependentEntryIds: dependentEntryIds,
        votesByPlayerId: votesByPlayerId ?? this.votesByPlayerId,
        eligibleVoterIds: eligibleVoterIds,
        result: result ?? this.result,
        requestedAt: requestedAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'requesterPlayerId': requesterPlayerId,
        'targetEntryId': targetEntryId,
        'dependentEntryIds': dependentEntryIds,
        'votesByPlayerId':
            votesByPlayerId.map((k, v) => MapEntry(k, v)),
        'eligibleVoterIds': eligibleVoterIds,
        'result': result.name,
        'requestedAt': requestedAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  factory UndoRequest.fromJson(Map<String, dynamic> json) => UndoRequest(
        id: json['id'] as String,
        requesterPlayerId: json['requesterPlayerId'] as String,
        targetEntryId: json['targetEntryId'] as String,
        dependentEntryIds: List<String>.from(json['dependentEntryIds'] as List),
        votesByPlayerId: (json['votesByPlayerId'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as bool)),
        eligibleVoterIds: List<String>.from(json['eligibleVoterIds'] as List),
        result: UndoVoteResult.values
            .firstWhere((e) => e.name == json['result']),
        requestedAt: DateTime.parse(json['requestedAt'] as String),
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'] as String)
            : null,
      );
}

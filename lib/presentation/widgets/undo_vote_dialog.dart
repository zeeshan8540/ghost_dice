// UndoVoteDialog — modal vote dialog shown to all eligible voters.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghost_dice/application/controllers/game_controller.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';
import 'package:ghost_dice/domain/entities/undo_request.dart';
import 'package:ghost_dice/domain/entities/player.dart';

class UndoVoteDialog extends ConsumerWidget {
  final UndoRequest request;
  final List<Player> players;

  const UndoVoteDialog({
    super.key,
    required this.request,
    required this.players,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = players.firstWhere(
        (p) => p.id == _moverPlayerId,
        orElse: () => players.first);

    return Dialog(
      backgroundColor: GhostDiceTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history,
                color: GhostDiceTheme.accentGlow, size: 36),
            const SizedBox(height: 12),
            const Text('Undo Requested',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: GhostDiceTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(
              '${target.name}\'s declared value will be undone.\n'
              '${request.dependentEntryIds.length} entry(s) will be reversed.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: GhostDiceTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            // Show voting status for each eligible voter.
            ...request.eligibleVoterIds.map((voterId) {
              final voter =
                  players.firstWhere((p) => p.id == voterId);
              final vote = request.votesByPlayerId[voterId];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(voter.name,
                        style: const TextStyle(
                            color: GhostDiceTheme.textPrimary)),
                    const Spacer(),
                    if (vote == null) ...[
                      _voteButton(
                          label: '✓ Yes',
                          color: GhostDiceTheme.pieceGreen,
                          onTap: () => ref
                              .read(gameControllerProvider.notifier)
                              .castUndoVote(voterId, true)),
                      const SizedBox(width: 8),
                      _voteButton(
                          label: '✗ No',
                          color: GhostDiceTheme.pieceRed,
                          onTap: () => ref
                              .read(gameControllerProvider.notifier)
                              .castUndoVote(voterId, false)),
                    ] else
                      Text(
                        vote ? '✓ Yes' : '✗ No',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: vote
                                ? GhostDiceTheme.pieceGreen
                                : GhostDiceTheme.pieceRed),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Text(
              '${request.yesCount} yes · ${request.noCount} no · '
              '${request.remainingVoters} pending',
              style: const TextStyle(
                  fontSize: 12, color: GhostDiceTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  String get _moverPlayerId {
    // The mover is the one NOT eligible to vote.
    return players
        .firstWhere((p) => !request.eligibleVoterIds.contains(p.id),
            orElse: () => players.first)
        .id;
  }

  Widget _voteButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ),
      );
}

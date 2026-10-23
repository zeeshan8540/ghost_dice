// PlayerPanel — shows a player's name, color, piece counts, and active indicator.
import 'package:flutter/material.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';
import 'package:ghost_dice/domain/entities/player.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';

class PlayerPanel extends StatelessWidget {
  final Player player;
  final bool isActive;

  const PlayerPanel({
    super.key,
    required this.player,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(player.color);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? color.withOpacity(0.12)
            : GhostDiceTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? color : GhostDiceTheme.border,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                )
              ]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.6), blurRadius: 6)
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  player.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? GhostDiceTheme.textPrimary
                        : GhostDiceTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'YOUR TURN',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statChip(
                  label: 'Home',
                  value: '${player.finishedCount}/4',
                  color: color),
              _statChip(
                  label: 'Track',
                  value: '${player.pieceCountOnTrack}',
                  color: GhostDiceTheme.textSecondary),
              _statChip(
                  label: 'Yard',
                  value: '${player.pieceCountInYard}',
                  color: GhostDiceTheme.textMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(
          {required String label,
          required String value,
          required Color color}) =>
      Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: GhostDiceTheme.textMuted)),
        ],
      );

  Color _colorFor(PlayerColor color) => switch (color) {
        PlayerColor.red => GhostDiceTheme.pieceRed,
        PlayerColor.blue => GhostDiceTheme.pieceBlue,
        PlayerColor.green => GhostDiceTheme.pieceGreen,
        PlayerColor.yellow => GhostDiceTheme.pieceYellow,
      };
}

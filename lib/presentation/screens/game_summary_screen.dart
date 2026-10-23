// GameSummaryScreen — shown after a player wins.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_dice/application/controllers/game_controller.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';
import 'package:ghost_dice/domain/entities/board_config.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';

class GameSummaryScreen extends ConsumerWidget {
  const GameSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);

    if (gameState == null || gameState.winner == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const Scaffold(body: SizedBox());
    }

    final winner = gameState.winner!;
    final color = _colorFor(winner.color);
    final partner = gameState.isTeamUp
        ? gameState.players.firstWhere(
            (p) =>
                p.id != winner.id &&
                (p.teamId == winner.teamId ||
                    p.color == BoardConfig.getOppositeColor(winner.color)),
            orElse: () => winner,
          )
        : null;
    final titleText = gameState.isTeamUp
        ? '${winner.teamName?.toUpperCase() ?? "TEAM"} WINS!'
        : 'WINNER!';
    final winnerNames = gameState.isTeamUp
        ? '${winner.name} & ${partner?.name}'
        : winner.name;

    return Scaffold(
      backgroundColor: GhostDiceTheme.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _WinnerGlowPainter(color: color),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏆',
                      style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                            colors: [color, color.withOpacity(0.6)])
                        .createShader(b),
                    child: Text(
                      titleText,
                      style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    winnerNames,
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Duration: ${_duration(gameState.startedAt)}',
                    style: const TextStyle(
                        color: GhostDiceTheme.textMuted),
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Play Again'),
                    onPressed: () => context.go('/setup'),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Home'),
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(PlayerColor color) => switch (color) {
        PlayerColor.red => GhostDiceTheme.pieceRed,
        PlayerColor.blue => GhostDiceTheme.pieceBlue,
        PlayerColor.green => GhostDiceTheme.pieceGreen,
        PlayerColor.yellow => GhostDiceTheme.pieceYellow,
      };

  String _duration(DateTime start) {
    final diff = DateTime.now().difference(start);
    final m = diff.inMinutes;
    final s = diff.inSeconds % 60;
    return '${m}m ${s}s';
  }
}

class _WinnerGlowPainter extends CustomPainter {
  final Color color;
  const _WinnerGlowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(colors: [
        color.withOpacity(0.2),
        Colors.transparent,
      ]).createShader(
          Rect.fromCircle(center: size.center(Offset.zero), radius: size.width * 0.7));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_WinnerGlowPainter old) => old.color != color;
}

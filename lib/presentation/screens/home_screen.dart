import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_dice/application/controllers/game_controller.dart';
import 'package:ghost_dice/application/controllers/setup_controller.dart';
import 'package:ghost_dice/application/state/game_state.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';
import 'package:ghost_dice/infrastructure/repositories/game_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    _slideUp = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GhostDiceTheme.background,
      body: Stack(
        children: [
          // Background radial glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    GhostDiceTheme.accent.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo / title
                            _GhostLogo(),
                            const SizedBox(height: 12),
                            ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [
                                  GhostDiceTheme.accentGlow,
                                  GhostDiceTheme.textPrimary
                                ],
                              ).createShader(b),
                              child: const Text(
                                'GHOST DICE',
                                style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 4,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Physical dice. Digital board.',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: GhostDiceTheme.textSecondary,
                                  letterSpacing: 1),
                            ),
                            const SizedBox(height: 40),
                            Consumer(
                              builder: (context, ref, _) {
                                final asyncGame = ref.watch(activeGameInfoProvider);
                                final game = asyncGame.valueOrNull;
                                if (game == null || game.isGameOver) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: _ResumeGameCard(
                                    gameState: game,
                                    onResume: () async {
                                      final ok = await ref
                                          .read(gameControllerProvider.notifier)
                                          .loadSavedGame();
                                      if (ok && context.mounted) {
                                        context.go('/game');
                                      }
                                    },
                                    onDiscard: () async {
                                      final discard = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: GhostDiceTheme.surface,
                                          title: const Text('Discard Saved Game?',
                                              style: TextStyle(color: Colors.white)),
                                          content: const Text(
                                            'Are you sure you want to discard this match in progress? Progress will be lost.',
                                            style: TextStyle(
                                                color: GhostDiceTheme.textSecondary),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      GhostDiceTheme.pieceRed),
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Discard'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (discard == true) {
                                        await ref
                                            .read(gameControllerProvider.notifier)
                                            .clearActiveGameSession();
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                            _MenuButton(
                              label: 'Play with Dice',
                              icon: Icons.casino_rounded,
                              isPrimary: true,
                              onTap: () {
                                final notifier = ref.read(setupControllerProvider.notifier);
                                notifier.setUseInGameDice(true);
                                notifier.setGameMode(false);
                                context.go('/setup');
                              },
                            ),
                            const SizedBox(height: 14),
                            _MenuButton(
                              label: 'New Game (Physical Dice)',
                              icon: Icons.play_arrow_rounded,
                              isPrimary: false,
                              onTap: () {
                                final notifier = ref.read(setupControllerProvider.notifier);
                                notifier.setUseInGameDice(false);
                                notifier.setGameMode(false);
                                context.go('/setup');
                              },
                            ),
                            const SizedBox(height: 14),
                            _MenuButton(
                              label: 'Team Up (2 vs 2)',
                              icon: Icons.groups_rounded,
                              isPrimary: false,
                              onTap: () {
                                ref.read(setupControllerProvider.notifier).setGameMode(true);
                                context.go('/setup');
                              },
                            ),
                            const SizedBox(height: 14),
                            _MenuButton(
                              label: 'How to Play',
                              icon: Icons.menu_book_rounded,
                              onTap: () => context.go('/rules'),
                            ),
                            const SizedBox(height: 14),
                            _MenuButton(
                              label: 'Settings',
                              icon: Icons.tune_rounded,
                              onTap: () => context.go('/settings'),
                            ),
                            const SizedBox(height: 40),
                            const Text(
                              'Roll your real die. Enter the number.\nThe app handles the rest.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: GhostDiceTheme.textMuted,
                                  height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: GhostDiceTheme.accentGlow.withValues(alpha: 0.8),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: GhostDiceTheme.accentGlow.withValues(alpha: 0.40),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/ghost_dice_app_icon.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/images/ghost_dice_app_icon.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF0A2244),
              child: const Icon(
                Icons.casino_rounded,
                size: 42,
                color: GhostDiceTheme.accentGlow,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _ResumeGameCard extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  const _ResumeGameCard({
    required this.gameState,
    required this.onResume,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final activePlayer = gameState.activePlayer;
    final playerColor = _resolveColor(activePlayer.color);
    final modeLabel =
        gameState.rules.isTeamUp ? 'Team Up (2 vs 2)' : 'Classic Mode';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F2E4A).withValues(alpha: 0.95),
            const Color(0xFF071C30).withValues(alpha: 0.98),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: GhostDiceTheme.dockGold.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: GhostDiceTheme.dockGold.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: In progress status + game mode badge + discard button
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF00E676),
                  boxShadow: [
                    BoxShadow(
                        color: Color(0xFF00E676),
                        blurRadius: 6,
                        spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'MATCH IN PROGRESS',
                style: TextStyle(
                  color: Color(0xFF00E676),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: GhostDiceTheme.dockGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: GhostDiceTheme.dockGold.withValues(alpha: 0.5),
                      width: 1),
                ),
                child: Text(
                  modeLabel,
                  style: const TextStyle(
                    color: GhostDiceTheme.dockGold,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: GhostDiceTheme.textMuted),
                tooltip: 'Discard Game',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDiscard,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Active turn details
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: playerColor,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: playerColor.withValues(alpha: 0.5),
                        blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${activePlayer.name}\'s Turn (${activePlayer.color.name.toUpperCase()})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${gameState.players.length} Players • ${gameState.recentMoves.length} turns played',
            style: const TextStyle(
              color: GhostDiceTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GhostDiceTheme.dockGold,
                foregroundColor: Colors.black87,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: const Text(
                'CONTINUE GAME',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveColor(PlayerColor c) => switch (c) {
        PlayerColor.red => GhostDiceTheme.pieceRed,
        PlayerColor.blue => GhostDiceTheme.pieceBlue,
        PlayerColor.green => GhostDiceTheme.pieceGreen,
        PlayerColor.yellow => GhostDiceTheme.pieceYellow,
      };
}




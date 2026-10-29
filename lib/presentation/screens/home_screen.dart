// HomeScreen — Tactile neon dark tabletop companion home lobby.
// Faithfully implements stitch_ghost_dice_tabletop_companion design while preserving all game controller functionality.

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
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

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
      backgroundColor: const Color(0xFF03132B),
      body: Stack(
        children: [
          // Ambient background glow blobs from DESIGN.md
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7AD0FF).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 280,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3C90FF).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Scrollable Area with Header & Nav
          Column(
            children: [
              _HomeHeader(
                onSettingsTap: () => _showSettingsSheet(context),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Hero Brand Emblem Card
                              const _HeroBrandCard(),
                              const SizedBox(height: 16),

                              // 2. Active Match Resume Banner (if match in progress)
                              Consumer(
                                builder: (context, ref, _) {
                                  final asyncGame =
                                      ref.watch(activeGameInfoProvider);
                                  final game = asyncGame.valueOrNull;
                                  if (game == null || game.isGameOver) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _ActiveMatchResumeBanner(
                                      gameState: game,
                                      onResume: () async {
                                        final ok = await ref
                                            .read(
                                                gameControllerProvider.notifier)
                                            .loadSavedGame();
                                        if (ok && context.mounted) {
                                          context.go('/game');
                                        }
                                      },
                                      onDiscard: () =>
                                          _confirmDiscardGame(context, ref),
                                    ),
                                  );
                                },
                              ),

                              // 3. Game Modes Section Header
                              const _SectionHeader(
                                title: 'GAME MODES & TABLE',
                                actionLabel: 'Quick Launch',
                              ),
                              const SizedBox(height: 10),

                              // 4. Tactile Mode Cards List
                              // Mode 1: Play with Dice (Featured)
                              _FeaturedModeCard(
                                title: 'Play with Dice',
                                badge: 'FEATURED',
                                subtitle:
                                    'Fast pass-and-play local board with virtual physics roll',
                                icon: Icons.casino_rounded,
                                onTap: () {
                                  final notifier = ref
                                      .read(setupControllerProvider.notifier);
                                  notifier.setUseInGameDice(true);
                                  notifier.setGameMode(false);
                                  context.go('/setup');
                                },
                              ),
                              const SizedBox(height: 10),

                              // Mode 2: New Game (Physical Dice Entry)
                              _StandardModeCard(
                                title: 'New Game (Physical Dice)',
                                subtitle:
                                    'Custom house rules, 2-4 players, manual pip entry',
                                icon: Icons.touch_app_rounded,
                                iconColor: const Color(0xFFA9C7FF),
                                onTap: () {
                                  final notifier = ref
                                      .read(setupControllerProvider.notifier);
                                  notifier.setUseInGameDice(false);
                                  notifier.setGameMode(false);
                                  context.go('/setup');
                                },
                              ),
                              const SizedBox(height: 10),

                              // Mode 3: Team Up (2 vs 2 Co-op)
                              _StandardModeCard(
                                title: 'Team Up (2 vs 2 Co-op)',
                                subtitle:
                                    'Partner rules, shared safe zones, coordinated assault',
                                icon: Icons.groups_rounded,
                                iconColor: const Color(0xFF7AD0FF),
                                onTap: () {
                                  final notifier = ref
                                      .read(setupControllerProvider.notifier);
                                  notifier.setGameMode(true);
                                  context.go('/setup');
                                },
                              ),
                              const SizedBox(height: 12),

                              // 5. Auxiliary Grid (Rules & Settings)
                              Row(
                                children: [
                                  Expanded(
                                    child: _AuxiliaryCard(
                                      title: 'Rules & Guide',
                                      subtitle: 'Star squares & captures',
                                      icon: Icons.menu_book_rounded,
                                      onTap: () => context.go('/rules'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _AuxiliaryCard(
                                      title: 'Tabletop Setup',
                                      subtitle: 'Haptics & house rules',
                                      icon: Icons.tune_rounded,
                                      onTap: () => _showSettingsSheet(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // 6. Quick Table Session Status Footer Badge
                              const _TableSessionStatusBadge(),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 7. Bottom Navigation Bar (Matching code.html)
              _BottomNavBar(
                activePath: 'lobby',
                onTabSelect: (path) {
                  if (path == 'setup') {
                    context.go('/setup');
                  } else if (path == 'table') {
                    context.go('/game');
                  } else if (path == 'guide') {
                    context.go('/rules');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDiscardGame(BuildContext context, WidgetRef ref) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF102038),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2C4C7C)),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: Color(0xFFFFB4AB), size: 24),
            SizedBox(width: 8),
            Text(
              'Discard Active Match?',
              style: TextStyle(
                color: Color(0xFFD6E3FF),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to discard this match in progress? Current turn progress will be cleared.',
          style: TextStyle(
            color: Color(0xFFC0C6D6),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Color(0xFF7AD0FF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF93000A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'DISCARD',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (discard == true) {
      await ref
          .read(gameControllerProvider.notifier)
          .clearActiveGameSession();
    }
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF102038),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF2C4C7C), width: 1.5)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF414754),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.tune_rounded, color: Color(0xFF7AD0FF), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Tabletop Companion Settings',
                    style: TextStyle(
                      color: Color(0xFFD6E3FF),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Customize haptics, dice sound effects, and house rules.',
                style: TextStyle(color: Color(0xFFC0C6D6), fontSize: 13),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.volume_up_rounded, color: Color(0xFF7AD0FF)),
                title: const Text('Sound Effects & Audio Clacks',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Comical captures, dice rattles, and touchdown hops',
                    style: TextStyle(color: Color(0xFFC0C6D6), fontSize: 12)),
                trailing: Switch(
                  value: true,
                  activeColor: const Color(0xFF7AD0FF),
                  onChanged: (val) {},
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.auto_mode_rounded, color: Color(0xFF7AD0FF)),
                title: const Text('Auto-Move Single Legal Piece',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Speeds up play when only one move is possible',
                    style: TextStyle(color: Color(0xFFC0C6D6), fontSize: 12)),
                trailing: Switch(
                  value: true,
                  activeColor: const Color(0xFF7AD0FF),
                  onChanged: (val) {},
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A9E3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Top Header Bar matching code.html
// ---------------------------------------------------------------------------
class _HomeHeader extends StatelessWidget {
  final VoidCallback onSettingsTap;

  const _HomeHeader({required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C1B34).withValues(alpha: 0.94),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1C2A43), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo + Title block
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/ghost_dice_app_icon.png',
                      height: 32,
                      width: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.casino_rounded,
                        color: Color(0xFF7AD0FF),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'GHOST DICE',
                            style: TextStyle(
                              color: Color(0xFF7AD0FF),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27354E).withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'HOME LOBBY',
                              style: TextStyle(
                                color: Color(0xFFC0C6D6),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Table #04 • Local Pass & Play',
                        style: TextStyle(
                          color: const Color(0xFF7AD0FF).withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Right actions: Settings button & Live pulse chip
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onSettingsTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF102038),
                          border: Border.all(
                            color: const Color(0xFF2C4C7C),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          size: 19,
                          color: Color(0xFFC0C6D6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF102038),
                      border: Border.all(
                        color: const Color(0xFF7AD0FF).withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7AD0FF).withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.sensors_rounded,
                        color: Color(0xFF7AD0FF),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Hero Brand Emblem Card
// ---------------------------------------------------------------------------
class _HeroBrandCard extends StatelessWidget {
  const _HeroBrandCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF102038),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1C2A43), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Emblem Container with pulse dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF000E26),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF7AD0FF).withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A9E3).withValues(alpha: 0.35),
                      blurRadius: 18,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/ghost_dice_app_icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.casino_rounded,
                      size: 40,
                      color: Color(0xFF7AD0FF),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7AD0FF),
                    border: Border.all(color: const Color(0xFF000E26), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF7AD0FF),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // Titles and descriptions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'GHOST DICE',
                      style: TextStyle(
                        color: Color(0xFFD6E3FF),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7AD0FF).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF7AD0FF).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'v1.1 LIVE',
                        style: TextStyle(
                          color: Color(0xFF7AD0FF),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'Physical dice. Digital board.',
                  style: TextStyle(
                    color: Color(0xFFC3E8FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(
                      Icons.wifi_tethering_rounded,
                      size: 13,
                      color: Color(0xFF7AD0FF),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Pass & Play Tabletop Companion',
                      style: TextStyle(
                        color: Color(0xFFC0C6D6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Active Match Resume Banner
// ---------------------------------------------------------------------------
class _ActiveMatchResumeBanner extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  const _ActiveMatchResumeBanner({
    required this.gameState,
    required this.onResume,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final activePlayer = gameState.activePlayer;
    final playerColor = _resolveColor(activePlayer.color);
    final modeLabel =
        gameState.rules.isTeamUp ? 'Team Up Mode' : 'Classic Mode';
    final matchTitle =
        gameState.rules.isTeamUp ? 'Continue Match - 2 vs 2' : 'Continue Match - Classic';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C2A43),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2C4C7C), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status + Title + Turns pill
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF000E26),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF414754), width: 1),
                ),
                child: const Icon(
                  Icons.diversity_3_rounded,
                  color: Color(0xFFF7BE00),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      matchTitle,
                      style: const TextStyle(
                        color: Color(0xFFD6E3FF),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      modeLabel.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF7AD0FF),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF000E26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF7BE00),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFF7BE00),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${gameState.recentMoves.length} turns',
                      style: const TextStyle(
                        color: Color(0xFFC0C6D6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Player Turn Visual Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF000E26).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: playerColor,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: playerColor.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${activePlayer.name}\'s Turn',
                          style: TextStyle(
                            color: playerColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          '${activePlayer.color.name.toUpperCase()} • ${gameState.rules.requireSixToLeaveYard ? "Needs 6 to enter" : "Ready"}',
                          style: const TextStyle(
                            color: Color(0xFFC0C6D6),
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Turn Dots Indicator
                Row(
                  children: List.generate(gameState.players.length, (i) {
                    final isCurrent = i == gameState.activePlayerIndex;
                    return Container(
                      margin: const EdgeInsets.only(left: 4),
                      width: isCurrent ? 8 : 6,
                      height: isCurrent ? 8 : 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent
                            ? playerColor
                            : const Color(0xFF27354E),
                        border: isCurrent
                            ? Border.all(color: Colors.white, width: 1)
                            : null,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons: Discard + Resume Match
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF102038),
                      foregroundColor: const Color(0xFFC0C6D6),
                      side: const BorderSide(color: Color(0xFF2C4C7C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: onDiscard,
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: const Text(
                      'DISCARD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: const Color(0xFF00A9E3),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFF00A9E3).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: const Text(
                      'RESUME MATCH',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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

// ---------------------------------------------------------------------------
// 4. Section Header with Accent Label
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.sports_esports_rounded,
              color: Color(0xFF7AD0FF),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFC3E8FF),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        Text(
          actionLabel,
          style: const TextStyle(
            color: Color(0xFFC0C6D6),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Featured Mode Card ("Play with Dice")
// ---------------------------------------------------------------------------
class _FeaturedModeCard extends StatelessWidget {
  final String title;
  final String badge;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _FeaturedModeCard({
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF102038),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2C4C7C), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Neon highlight edge accent bar
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 5,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF7AD0FF),
                        Color(0xFF3C90FF),
                        Color(0xFF00A9E3),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                child: Row(
                  children: [
                    // Sunken 3D Dice Square
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF000E26),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF7AD0FF).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7AD0FF)
                                .withValues(alpha: 0.35),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: const Color(0xFF7AD0FF),
                          size: 30,
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Texts & Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    color: Color(0xFFD6E3FF),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7AD0FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  badge,
                                  style: const TextStyle(
                                    color: Color(0xFF003A50),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Color(0xFFC0C6D6),
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Forward Chevron
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1C2A43),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF7AD0FF),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Standard Mode Card ("Physical Dice", "Team Up")
// ---------------------------------------------------------------------------
class _StandardModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _StandardModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF102038),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1C2A43), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Sunken Icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF000E26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2C4C7C), width: 1),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFD6E3FF),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFC0C6D6),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0C1B34),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFFC0C6D6),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7. Auxiliary Card (Rules & Settings)
// ---------------------------------------------------------------------------
class _AuxiliaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AuxiliaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 104,
          decoration: BoxDecoration(
            color: const Color(0xFF102038),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1C2A43), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF000E26),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2C4C7C), width: 1),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: const Color(0xFF7AD0FF),
                    size: 20,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFD6E3FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFC0C6D6),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 8. Quick Table Session Status Footer Badge
// ---------------------------------------------------------------------------
class _TableSessionStatusBadge extends StatelessWidget {
  const _TableSessionStatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF000E26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1C2A43), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Overlapping Player Circles
              SizedBox(
                width: 60,
                height: 24,
                child: Stack(
                  children: [
                    _buildDot(0, GhostDiceTheme.pieceRed, 'P1'),
                    _buildDot(12, GhostDiceTheme.pieceGreen, 'P2'),
                    _buildDot(24, GhostDiceTheme.pieceYellow, 'P3'),
                    _buildDot(36, GhostDiceTheme.pieceBlue, 'P4'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '4 Players Ready',
                    style: TextStyle(
                      color: Color(0xFFD6E3FF),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Seated around table • Auto-advance ON',
                    style: TextStyle(
                      color: Color(0xFFC0C6D6),
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Sync Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF102038),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF7AD0FF).withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sensors_rounded,
                  size: 13,
                  color: Color(0xFF7AD0FF),
                ),
                SizedBox(width: 4),
                Text(
                  'SYNC OK',
                  style: TextStyle(
                    color: Color(0xFF7AD0FF),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(double left, Color color, String label) {
    return Positioned(
      left: left,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: const Color(0xFF000E26), width: 1.5),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 9. Bottom Navigation Bar matching code.html
// ---------------------------------------------------------------------------
class _BottomNavBar extends StatelessWidget {
  final String activePath;
  final ValueChanged<String> onTabSelect;

  const _BottomNavBar({
    required this.activePath,
    required this.onTabSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C1B34).withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: Color(0xFF1C2A43), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.casino_rounded,
                label: 'Lobby',
                path: 'lobby',
                isActive: activePath == 'lobby',
              ),
              _buildNavItem(
                icon: Icons.group_add_rounded,
                label: 'Setup',
                path: 'setup',
                isActive: activePath == 'setup',
              ),
              _buildNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Table',
                path: 'table',
                isActive: activePath == 'table',
              ),
              _buildNavItem(
                icon: Icons.menu_book_rounded,
                label: 'Guide',
                path: 'guide',
                isActive: activePath == 'guide',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required String path,
    required bool isActive,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTabSelect(path),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF1C2A43).withValues(alpha: 0.8)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF7AD0FF).withValues(alpha: 0.25),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive
                    ? const Color(0xFF7AD0FF)
                    : const Color(0xFFC0C6D6),
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF7AD0FF)
                      : const Color(0xFFC0C6D6),
                  fontSize: 10,
                  fontWeight:
                      isActive ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_dice/application/controllers/game_controller.dart';
import 'package:ghost_dice/application/state/game_state.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';
import 'package:ghost_dice/domain/entities/board_config.dart';
import 'package:ghost_dice/domain/entities/board_position.dart';
import 'package:ghost_dice/domain/entities/piece.dart';
import 'package:ghost_dice/domain/entities/player.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';
import 'package:ghost_dice/domain/services/ludo_rules_engine.dart';
import 'package:ghost_dice/infrastructure/services/audio_service.dart';
import 'package:ghost_dice/presentation/board/board_coordinates.dart';
import 'package:ghost_dice/presentation/board/board_painter.dart';
import 'package:ghost_dice/presentation/board/piece_widget.dart';
import 'package:ghost_dice/presentation/widgets/captured_piece_fly_back_overlay.dart';
import 'package:ghost_dice/presentation/widgets/dice_number_picker.dart';
import 'package:ghost_dice/presentation/widgets/in_game_dice_roller.dart';
import 'package:ghost_dice/presentation/widgets/ludo_corner_dock.dart';
import 'package:ghost_dice/infrastructure/repositories/game_repository.dart';
import 'package:ghost_dice/presentation/widgets/move_announcement.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameControllerProvider);

    if (gameState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (gameState.isGameOver && gameState.winner != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/summary'));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF0D3B75),
              Color(0xFF081C3D),
              Color(0xFF040E20),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Top Bar: Title, Active Turn Indicator & Undo Action
              _GameTopBar(gameState: gameState),

              // 2. Announcements & Status Bar
              if (gameState.announcement != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: MoveAnnouncement(
                    message: gameState.announcement!,
                  ),
                ),

              // 3. Central Tabletop: 4 Corner Player Docks & 15x15 Ludo Board
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  child: _TabletopArena(gameState: gameState),
                ),
              ),

              // 4. Bottom Dock: Physical Dice Face Bar (Buttons 1 to 6 - Physical Mode Only)
              if (!gameState.rules.useInGameDice)
                _BottomDiceInputDock(gameState: gameState),
            ],
          ),
        ),
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
// Header Bar with Game Title, Turn Badge, and Quick Undo Action
// ---------------------------------------------------------------------------
class _GameTopBar extends ConsumerWidget {
  final GameState gameState;
  const _GameTopBar({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePlayer = gameState.activePlayer;
    final activeColor = _resolveColor(activePlayer.color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF061833).withValues(alpha: 0.8),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1E3A5F), width: 1.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => _showExitDialog(context, ref),
                tooltip: 'Leave Game',
              ),
              const SizedBox(width: 4),
              const Text(
                'GHOST DICE',
                style: TextStyle(
                  color: GhostDiceTheme.dockGold,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          // Active Turn Indicator
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: activeColor.withValues(alpha: 0.8), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                activePlayer.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (!gameState.rules.useInGameDice && gameState.recentEntries.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.undo_rounded, color: Colors.white, size: 24),
                  onPressed: !gameState.isVoting
                      ? () {
                          ref
                              .read(gameControllerProvider.notifier)
                              .requestUndo(gameState.recentEntries.last.id);
                        }
                      : null,
                  tooltip: 'Request Undo Vote',
                ),
              IconButton(
                icon: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                onPressed: () => context.push('/rules'),
                tooltip: 'Rules',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GhostDiceTheme.surface,
        title: const Text('Leave Game?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your game progress is saved and you can resume anytime from the Home screen.',
          style: TextStyle(color: GhostDiceTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Playing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GhostDiceTheme.pieceRed),
            onPressed: () async {
              Navigator.pop(context);
              final s = ref.read(gameControllerProvider);
              if (s != null && !s.isGameOver) {
                await ref.read(gameRepositoryProvider).saveActiveGame(s);
              }
              ref.invalidate(hasSavedGameProvider);
              ref.invalidate(activeGameInfoProvider);
              if (context.mounted) {
                context.go('/');
              }
            },
            child: const Text('Exit to Home'),
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
// 4 Corner Docks + Center Ludo Board Layout
// ---------------------------------------------------------------------------
class _TabletopArena extends ConsumerWidget {
  final GameState gameState;
  const _TabletopArena({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Map players by color
    Player? redP = gameState.players.where((p) => p.color == PlayerColor.red).firstOrNull;
    Player? greenP = gameState.players.where((p) => p.color == PlayerColor.green).firstOrNull;
    Player? yellowP = gameState.players.where((p) => p.color == PlayerColor.yellow).firstOrNull;
    Player? blueP = gameState.players.where((p) => p.color == PlayerColor.blue).firstOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final placeholderW = gameState.rules.useInGameDice ? 160.0 : 125.0;
        final placeholderH = gameState.rules.useInGameDice ? 50.0 : 42.0;

        if (isLandscape) {
          // Landscape Mode:
          // Left Rail: Red (Top-Left) & Blue (Bottom-Left)
          // Right Rail: Green (Top-Right) & Yellow (Bottom-Right)
          return Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  redP != null ? _buildDock(ref, redP, isRightSide: false) : SizedBox(width: placeholderW, height: placeholderH),
                  blueP != null ? _buildDock(ref, blueP, isRightSide: false) : SizedBox(width: placeholderW, height: placeholderH),
                ],
              ),
              const SizedBox(width: 6),

              // Center: Board
              Expanded(
                child: Center(
                  child: _BoardArea(gameState: gameState),
                ),
              ),
              const SizedBox(width: 6),

              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  greenP != null ? _buildDock(ref, greenP, isRightSide: true) : SizedBox(width: placeholderW, height: placeholderH),
                  yellowP != null ? _buildDock(ref, yellowP, isRightSide: true) : SizedBox(width: placeholderW, height: placeholderH),
                ],
              ),
            ],
          );
        } else {
          // Portrait Mode (Matching Image 4):
          // Top Row: Red (Left) and Green (Right)
          // Huge Board Center
          // Bottom Row: Blue (Left) and Yellow (Right)
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  redP != null ? _buildDock(ref, redP, isRightSide: false) : SizedBox(width: placeholderW, height: placeholderH),
                  greenP != null ? _buildDock(ref, greenP, isRightSide: true) : SizedBox(width: placeholderW, height: placeholderH),
                ],
              ),
              const SizedBox(height: 4),

              // Center: Board
              Expanded(
                child: Center(
                  child: _BoardArea(gameState: gameState),
                ),
              ),
              const SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  blueP != null ? _buildDock(ref, blueP, isRightSide: false) : SizedBox(width: placeholderW, height: placeholderH),
                  yellowP != null ? _buildDock(ref, yellowP, isRightSide: true) : SizedBox(width: placeholderW, height: placeholderH),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildDock(WidgetRef ref, Player player, {required bool isRightSide}) {
    final isActive = player.id == gameState.activePlayer.id;
    final diceVal = isActive ? gameState.pendingDiceValue : null;
    final teamLabel = gameState.isTeamUp
        ? (player.teamName ?? (player.teamId == 'team_1' ? 'TEAM 1' : 'TEAM 2'))
        : null;
    final isHelpingPartner = gameState.isTeamUp &&
        isActive &&
        gameState.isActivePlayerRollingForPartner;

    final dock = LudoCornerDock(
      player: player,
      isActive: isActive,
      useInGameDice: gameState.rules.useInGameDice,
      isAwaitingDice: gameState.isAwaitingDice,
      isAwaitingPiece: gameState.isAwaitingPiece,
      currentDiceValue: diceVal,
      teamLabel: teamLabel,
      isHelpingPartner: isHelpingPartner,
      isRightSide: isRightSide,
      onRoll: (value) {
        ref.read(gameControllerProvider.notifier).enterDiceValue(value);
      },
      onDiceTap: () {
        if (isActive && gameState.isAwaitingPiece && gameState.legalMoves.length == 1) {
          ref
              .read(gameControllerProvider.notifier)
              .selectPiece(gameState.legalMoves.first.piece.id);
        }
      },
    );

    if (!gameState.isVoting) {
      return dock;
    }

    final req = gameState.pendingUndoRequest;
    final isEligible = req != null && req.eligibleVoterIds.contains(player.id);
    if (!isEligible) {
      // The player whose entry is being undone cannot vote!
      return dock;
    }

    final voteButtons = _PlayerVoteButtons(
      player: player,
      gameState: gameState,
      ref: ref,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: isRightSide
          ? [voteButtons, const SizedBox(width: 6), dock]
          : [dock, const SizedBox(width: 6), voteButtons],
    );
  }
}

// ---------------------------------------------------------------------------
// Interactive YES / NO Voting Buttons beside each player's dock
// ---------------------------------------------------------------------------
class _PlayerVoteButtons extends StatelessWidget {
  final Player player;
  final GameState gameState;
  final WidgetRef ref;

  const _PlayerVoteButtons({
    required this.player,
    required this.gameState,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final req = gameState.pendingUndoRequest;
    if (req == null) return const SizedBox.shrink();

    final hasVoted = req.votesByPlayerId.containsKey(player.id);
    final voteVal = req.votesByPlayerId[player.id];

    if (hasVoted) {
      final isYes = voteVal == true;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: (isYes ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C)).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isYes ? const Color(0xFF4CAF50) : const Color(0xFFE57373),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isYes ? Colors.green : Colors.red).withValues(alpha: 0.4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isYes ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              isYes ? 'YES' : 'NO',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF092040).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GhostDiceTheme.dockGold, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'UNDO?',
            style: TextStyle(
              color: GhostDiceTheme.dockGold,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // YES Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ref.read(gameControllerProvider.notifier).castUndoVote(player.id, true);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, color: Colors.white, size: 13),
                        SizedBox(width: 2),
                        Text(
                          'YES',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // NO Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ref.read(gameControllerProvider.notifier).castUndoVote(player.id, false);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close_rounded, color: Colors.white, size: 13),
                        SizedBox(width: 2),
                        Text(
                          'NO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ],
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
}

// ---------------------------------------------------------------------------
// 15×15 Board Area with Pieces and Backward Flight Animation
// ---------------------------------------------------------------------------
class _BoardArea extends ConsumerStatefulWidget {
  final GameState gameState;
  const _BoardArea({required this.gameState});

  @override
  ConsumerState<_BoardArea> createState() => _BoardAreaState();
}

class _BoardAreaState extends ConsumerState<_BoardArea>
    with SingleTickerProviderStateMixin {
  late AnimationController _hopController;
  Piece? _activeHoppingPiece;
  List<BoardPosition>? _activeHoppingPath;
  Timer? _autoMoveTimer;
  int _lastHopStep = 0;
  ({Player player, int diceValue})? _activeMoveAnnouncement;
  Timer? _announcementTimer;
  String? _lastAnnouncedMoveId;

  @override
  void initState() {
    super.initState();
    _hopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _hopController.addListener(_onHopTick);
    if (widget.gameState.recentMoves.isNotEmpty) {
      _lastAnnouncedMoveId = widget.gameState.recentMoves.last.id;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAutoMove());
  }

  @override
  void didUpdateWidget(covariant _BoardArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameState.phase != widget.gameState.phase ||
        oldWidget.gameState.pendingDiceValue != widget.gameState.pendingDiceValue) {
      _checkAutoMove();
    }

    // When someone moves or plays their number: show the number in the center box for 3 seconds!
    if (widget.gameState.recentMoves.isNotEmpty) {
      final latestMove = widget.gameState.recentMoves.last;
      if (latestMove.id != _lastAnnouncedMoveId) {
        _lastAnnouncedMoveId = latestMove.id;
        final moverPlayer = widget.gameState.players.firstWhere(
          (p) => p.id == latestMove.playerId,
          orElse: () => widget.gameState.activePlayer,
        );
        _announcementTimer?.cancel();
        setState(() {
          _activeMoveAnnouncement = (
            player: moverPlayer,
            diceValue: latestMove.diceValue,
          );
        });
        _announcementTimer = Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() {
            _activeMoveAnnouncement = null;
          });
        });
      }
    }
  }

  void _checkAutoMove() {
    _autoMoveTimer?.cancel();
    if (!mounted) return;
    final s = widget.gameState;
    // Auto-move single legal piece after 350ms (authentic Ludo King behavior)
    if (s.isAwaitingPiece &&
        _activeHoppingPiece == null &&
        s.legalMoves.length == 1) {
      final move = s.legalMoves.first;
      _autoMoveTimer = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        if (widget.gameState.isAwaitingPiece && _activeHoppingPiece == null) {
          _startHoppingMove(move.piece, move);
        }
      });
    }
  }

  void _onHopTick() {
    final path = _activeHoppingPath;
    if (path == null || path.length <= 1) return;
    final numSegments = path.length - 1;
    final progress = _hopController.value * numSegments;
    final currentStep = progress.floor();
    if (currentStep > _lastHopStep && currentStep < numSegments) {
      _lastHopStep = currentStep;
      SoundEffectService.playHopSound();
    }
  }

  @override
  void dispose() {
    _autoMoveTimer?.cancel();
    _announcementTimer?.cancel();
    _hopController.removeListener(_onHopTick);
    _hopController.dispose();
    super.dispose();
  }

  void _startHoppingMove(Piece piece, LegalMove move) {
    _autoMoveTimer?.cancel();
    if (_activeHoppingPiece != null) return; // Prevent double taps during jump

    final diceValue = widget.gameState.pendingDiceValue ?? 1;
    final forwardPath = BoardConfig.computeForwardPath(
      from: piece.position,
      to: move.destination,
      color: piece.color,
      diceValue: diceValue,
    );

    final numHops = forwardPath.length - 1;
    if (numHops <= 0) {
      ref.read(gameControllerProvider.notifier).selectPiece(piece.id);
      return;
    }

    _lastHopStep = 0;
    setState(() {
      _activeHoppingPiece = piece;
      _activeHoppingPath = forwardPath;
    });

    // ~240ms per box hop for smooth, deliberate jumping
    final durationMs = (numHops * 240).clamp(280, 1800);
    _hopController.duration = Duration(milliseconds: durationMs);

    _hopController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      // Tactile touchdown sound on final target box
      SoundEffectService.playHopSound();

      final pieceId = piece.id;
      setState(() {
        _activeHoppingPiece = null;
        _activeHoppingPath = null;
      });

      // Commit the move in the game controller
      ref.read(gameControllerProvider.notifier).selectPiece(pieceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          final coords = BoardCoordinates(size: size);
          final legalPieceIds =
              widget.gameState.legalMoves.map((m) => m.piece.id).toSet();
          final capturingPieceIds =
              widget.gameState.activeCaptures.map((c) => c.pieceId).toSet();

          // Group pieces on active track by trackIndex for stacking
          final allPieces =
              widget.gameState.players.expand((p) => p.pieces).toList();
          final trackPieces = <int, List<Piece>>{};
          for (final piece in allPieces) {
            if (piece.position.isOnTrack && piece.position.trackIndex != null) {
              trackPieces.putIfAbsent(piece.position.trackIndex!, () => []).add(piece);
            }
          }

          final c = coords.cellSize;
          final isAwaiting =
              widget.gameState.isAwaitingPiece && _activeHoppingPiece == null;

          // Sort pieces so legal/active pieces are rendered last (on top of stack)
          // ensuring they are visually in front and receive tap gestures first when stacked!
          final sortedPieces = List<Piece>.from(allPieces)
            ..sort((a, b) {
              final aLegal = legalPieceIds.contains(a.id) ? 1 : 0;
              final bLegal = legalPieceIds.contains(b.id) ? 1 : 0;
              return aLegal.compareTo(bLegal);
            });

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Authentic Ludo Board CustomPainter
              CustomPaint(
                size: Size(size, size),
                painter: LudoBoardPainter(players: widget.gameState.players),
              ),

              // 2. Animated 3D Pawn Tokens (Medium Sized Molded Plastic)
              ...sortedPieces.map((piece) {
                int stackIndex = 0;
                int totalStacked = 1;
                if (piece.position.isOnTrack && piece.position.trackIndex != null) {
                  final group = trackPieces[piece.position.trackIndex!] ?? [];
                  totalStacked = group.length;
                  stackIndex = group.indexOf(piece);
                }

                final center = coords.positionToCenter(
                  piece.position,
                  piece.color,
                  pieceIndex: piece.pieceIndex,
                  stackIndex: stackIndex,
                  totalStacked: totalStacked,
                );

                // Medium size: slightly smaller than current size, fits neatly inside cell
                final pieceWidth =
                    (c * (totalStacked > 1 ? 0.54 : 0.68)).clamp(18.0, 36.0) + 1.8;
                final pieceHeight = pieceWidth * 1.36;
                final hitSize = (c * 1.30).clamp(42.0, 60.0);
                final isLegal = legalPieceIds.contains(piece.id);
                final isHopping = _activeHoppingPiece?.id == piece.id;
                final isFlyingHome = capturingPieceIds.contains(piece.id);
                final isHidden = isFlyingHome || isHopping;
                final canTap = isLegal && isAwaiting;

                void handleTap() {
                  if (!canTap) return;
                  final move = widget.gameState.legalMoves.firstWhere(
                    (m) => m.piece.id == piece.id,
                  );
                  _startHoppingMove(piece, move);
                }

                Widget pieceItem = Center(
                  child: PieceWidget(
                    piece: piece,
                    width: pieceWidth,
                    height: pieceHeight,
                    isHighlighted: canTap,
                  ),
                );

                if (canTap) {
                  pieceItem = MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: handleTap,
                      child: pieceItem,
                    ),
                  );
                } else {
                  pieceItem = IgnorePointer(
                    child: pieceItem,
                  );
                }

                return Positioned(
                  key: ValueKey('piece_${piece.id}'),
                  left: center.dx - hitSize * 0.5,
                  top: center.dy - hitSize * 0.5,
                  width: hitSize,
                  height: hitSize,
                  child: Opacity(
                    opacity: isHidden ? 0.0 : 1.0,
                    child: pieceItem,
                  ),
                );
              }),

              // 3. Smooth Step-by-Step Realistic Hopping Animation
              if (_activeHoppingPiece != null &&
                  _activeHoppingPath != null &&
                  _activeHoppingPath!.length > 1)
                _HoppingPieceOverlay(
                  piece: _activeHoppingPiece!,
                  path: _activeHoppingPath!,
                  controller: _hopController,
                  coords: coords,
                ),

              // 4. Comical backward track retreat animation for captured pieces
              if (widget.gameState.activeCaptures.isNotEmpty)
                CapturedPieceFlyBackOverlay(
                  activeCaptures: widget.gameState.activeCaptures,
                  coords: coords,
                  onComplete: () {
                    ref.read(gameControllerProvider.notifier).clearActiveCaptures();
                  },
                ),

              // 5. Center Table Area (3x3 Center Box / Home Triangles):
              // 3-second popup of chosen number, or Tabletop UNDO Button!
              Positioned(
                left: 6.0 * c,
                top: 6.0 * c,
                width: 3.0 * c,
                height: 3.0 * c,
                child: _CenterTableArea(
                  gameState: widget.gameState,
                  activeAnnouncement: _activeMoveAnnouncement,
                  size: 3.0 * c,
                  onRequestUndo: () {
                    if (widget.gameState.recentEntries.isNotEmpty &&
                        !widget.gameState.isVoting) {
                      ref
                          .read(gameControllerProvider.notifier)
                          .requestUndo(widget.gameState.recentEntries.last.id);
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Overlay that animates a piece jumping step-by-step from box to box across the board.
class _HoppingPieceOverlay extends StatelessWidget {
  final Piece piece;
  final List<BoardPosition> path;
  final AnimationController controller;
  final BoardCoordinates coords;

  const _HoppingPieceOverlay({
    required this.piece,
    required this.path,
    required this.controller,
    required this.coords,
  });

  @override
  Widget build(BuildContext context) {
    final c = coords.cellSize;
    final pieceWidth = (c * 0.68).clamp(18.0, 36.0) + 1.8;
    final pieceHeight = pieceWidth * 1.36;
    final anchorX = pieceWidth * 0.5;
    final anchorY = pieceHeight * 0.88;

    final points = path
        .map((pos) => coords.positionToCenter(
              pos,
              piece.color,
              pieceIndex: piece.pieceIndex,
            ))
        .toList();

    final numSegments = points.length - 1;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final progress = (t * numSegments).clamp(0.0, numSegments.toDouble());
        final segIndex = progress.floor().clamp(0, numSegments - 1);
        final segT = (progress - segIndex).clamp(0.0, 1.0);

        final p0 = points[segIndex];
        final p1 = points[segIndex + 1];

        // Smooth planar translation between consecutive boxes
        final curX = ui.lerpDouble(p0.dx, p1.dx, segT)!;
        final curY = ui.lerpDouble(p0.dy, p1.dy, segT)!;

        // Realistic vertical parabolic hop arc (lifts in the air and lands down)
        final hopDy = -math.sin(segT * math.pi) * (c * 0.48);

        // Tactile stretch & squash: stretches vertically at apex, squashes on landing
        double scaleX = 1.0;
        double scaleY = 1.0;
        if (segT > 0.82) {
          final landT = (segT - 0.82) / 0.18;
          scaleX = 1.0 + math.sin(landT * math.pi) * 0.12;
          scaleY = 1.0 - math.sin(landT * math.pi) * 0.10;
        } else {
          final midT = math.sin(segT * math.pi);
          scaleX = 1.0 - midT * 0.06;
          scaleY = 1.0 + midT * 0.10;
        }

        // Contact shadow remains on board ground
        final shadowScale = (1.0 - math.sin(segT * math.pi) * 0.35).clamp(0.65, 1.0);
        final shadowAlpha = (0.38 - math.sin(segT * math.pi) * 0.18).clamp(0.15, 0.45);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Board Surface Ground Shadow (stays on the board while piece jumps in air)
            Positioned(
              left: curX - pieceWidth * 0.42 * shadowScale,
              top: curY - pieceHeight * 0.08 * shadowScale,
              width: pieceWidth * 0.84 * shadowScale,
              height: pieceHeight * 0.18 * shadowScale,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: shadowAlpha),
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(
                        pieceWidth * 0.42 * shadowScale,
                        pieceHeight * 0.09 * shadowScale,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Hopping 3D Token in Midair
            Positioned(
              left: curX - anchorX,
              top: curY + hopDy - anchorY,
              width: pieceWidth,
              height: pieceHeight,
              child: Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.identity()..scale(scaleX, scaleY),
                child: PieceWidget(
                  piece: piece,
                  width: pieceWidth,
                  height: pieceHeight,
                  isHighlighted: false,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Physical Dice Input Bar (1 to 6 die face buttons)
// ---------------------------------------------------------------------------
class _BottomDiceInputDock extends ConsumerWidget {
  final GameState gameState;
  const _BottomDiceInputDock({required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeColor = _resolveColor(gameState.activePlayer.color);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2D54),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GhostDiceTheme.dockGold.withValues(alpha: 0.6), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.casino, color: GhostDiceTheme.dockGold, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    gameState.isAwaitingDice
                        ? (gameState.isActivePlayerRollingForPartner
                            ? '${gameState.activePlayer.name}: Roll for Partner (${gameState.activePartner?.name})'
                            : '${gameState.activePlayer.name}: Tap Rolled Value')
                        : (gameState.isAwaitingPiece
                            ? (gameState.isActivePlayerRollingForPartner
                                ? 'Move Partner\'s Piece (${gameState.pendingDiceValue})'
                                : 'Move Piece for Roll of ${gameState.pendingDiceValue}')
                            : 'Physical Dice Input'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (gameState.pendingDiceValue != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'DICE: ${gameState.pendingDiceValue}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          DiceNumberPicker(
            enabled: gameState.isAwaitingDice,
            selectedValue: gameState.pendingDiceValue,
            buttonSize: 44.0,
            onSelect: (number) {
              ref.read(gameControllerProvider.notifier).enterDiceValue(number);
            },
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
// Center Table Area: 3-Second Dice Popup or Tabletop UNDO Button
// ---------------------------------------------------------------------------
class _CenterTableArea extends StatelessWidget {
  final GameState gameState;
  final ({Player player, int diceValue})? activeAnnouncement;
  final double size;
  final VoidCallback onRequestUndo;

  const _CenterTableArea({
    required this.gameState,
    required this.activeAnnouncement,
    required this.size,
    required this.onRequestUndo,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Priority 1: 3-Second Dice Number Popup when a piece moves
    if (activeAnnouncement != null) {
      final ann = activeAnnouncement!;
      return _CenterDicePopup(
        player: ann.player,
        diceValue: ann.diceValue,
        size: size,
        onRequestUndo: !gameState.rules.useInGameDice
            ? () {
                if (gameState.recentEntries.isNotEmpty && !gameState.isVoting) {
                  onRequestUndo();
                }
              }
            : null,
      );
    }

    // 2. Priority 2: During Undo Voting
    if (gameState.isVoting) {
      final req = gameState.pendingUndoRequest;
      final votesCast = req?.votesByPlayerId.length ?? 0;
      final totalVoters = req?.eligibleVoterIds.length ?? 1;

      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF071426).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GhostDiceTheme.dockGold, width: 2),
            boxShadow: [
              BoxShadow(
                color: GhostDiceTheme.dockGold.withValues(alpha: 0.4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.how_to_vote_rounded, color: GhostDiceTheme.dockGold, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'VOTING',
                    style: TextStyle(
                      color: GhostDiceTheme.dockGold,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '$votesCast of $totalVoters Voted',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Priority 3: Tabletop UNDO Button in the center of the table
    if (!gameState.rules.useInGameDice && gameState.recentEntries.isNotEmpty && !gameState.isGameOver) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onRequestUndo,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D284D), Color(0xFF1B4985)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GhostDiceTheme.dockGold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: GhostDiceTheme.dockGold.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                  const BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.undo_rounded, color: GhostDiceTheme.dockGold, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'UNDO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _CenterDicePopup extends StatefulWidget {
  final Player player;
  final int diceValue;
  final double size;
  final VoidCallback? onRequestUndo;

  const _CenterDicePopup({
    required this.player,
    required this.diceValue,
    required this.size,
    this.onRequestUndo,
  });

  @override
  State<_CenterDicePopup> createState() => _CenterDicePopupState();
}

class _CenterDicePopupState extends State<_CenterDicePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerColor = _resolveColor(widget.player.color);
    final dieSize = (widget.size * 0.40).clamp(28.0, 50.0);

    return ScaleTransition(
      scale: CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
      child: Center(
        child: Container(
          width: widget.size * 0.96,
          height: widget.size * 0.96,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF061428).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: playerColor, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: playerColor.withValues(alpha: 0.6),
                blurRadius: 14,
                spreadRadius: 1,
              ),
              const BoxShadow(color: Colors.black54, blurRadius: 8),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Player badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: playerColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.player.teamName != null
                        ? '${widget.player.name.toUpperCase()} (${widget.player.teamName!.toUpperCase()})'
                        : widget.player.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Large 3D Die Face showing chosen number
                Container(
                  width: dieSize,
                  height: dieSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFFFFF), Color(0xFFECEFF1)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCFD8DC), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: CustomPaint(
                    painter: DiePipPainter(value: widget.diceValue),
                  ),
                ),
                const SizedBox(height: 3),

                // Number label
                Text(
                  'ROLLED: ${widget.diceValue}',
                  style: const TextStyle(
                    color: GhostDiceTheme.dockGold,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
                if (widget.onRequestUndo != null) ...[
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: widget.onRequestUndo,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.redAccent, width: 0.8),
                      ),
                      child: const Text(
                        'CHALLENGE / UNDO',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 7.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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





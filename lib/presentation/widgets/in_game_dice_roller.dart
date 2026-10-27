// InGameDiceRoller — Interactive 3D rolling dice with pure uniform RNG.
// When rolled, rapidly tumbles through faces and delivers an unbiased 1–6 number.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ghost_dice/application/state/game_state.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';
import 'package:ghost_dice/infrastructure/services/audio_service.dart';
import 'package:ghost_dice/presentation/widgets/ludo_corner_dock.dart';

class InGameDiceRoller extends StatefulWidget {
  final GameState gameState;
  final ValueChanged<int> onRoll;

  const InGameDiceRoller({
    super.key,
    required this.gameState,
    required this.onRoll,
  });

  @override
  State<InGameDiceRoller> createState() => _InGameDiceRollerState();
}

class _InGameDiceRollerState extends State<InGameDiceRoller>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  int _displayFace = 1;
  bool _isRolling = false;
  late final math.Random _rng;

  @override
  void initState() {
    super.initState();
    try { _rng = math.Random.secure(); } catch (_) { _rng = math.Random(); }
    _displayFace = widget.gameState.pendingDiceValue ?? 1;
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _anim.addListener(_onRollTick);
  }

  @override
  void didUpdateWidget(covariant InGameDiceRoller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gameState.pendingDiceValue != null) {
      _displayFace = widget.gameState.pendingDiceValue!;
    }
  }

  void _onRollTick() {
    if (_anim.value < 0.90) {
      // Rapidly randomize face during tumble
      setState(() {
        _displayFace = _rng.nextInt(6) + 1;
      });
    }
  }

  @override
  void dispose() {
    _anim.removeListener(_onRollTick);
    _anim.dispose();
    super.dispose();
  }

  void _triggerRoll() {
    if (_isRolling || !widget.gameState.isAwaitingDice) return;

    setState(() {
      _isRolling = true;
    });

    SoundEffectService.playDiceRollSound();

    // 100% Pure, Unbiased Uniform RNG (1 to 6) without any handicap or rigging
    final finalRoll = _rng.nextInt(6) + 1;

    _anim.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() {
        _displayFace = finalRoll;
        _isRolling = false;
      });
      // Touchdown sound
      SoundEffectService.playHopSound();
      // Notify game controller immediately
      widget.onRoll(finalRoll);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activePlayer = widget.gameState.activePlayer;
    final activeColor = _resolveColor(activePlayer.color);
    final isAwaitingDice = widget.gameState.isAwaitingDice && !_isRolling;
    final isAwaitingPiece = widget.gameState.isAwaitingPiece;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2244),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAwaitingDice
              ? GhostDiceTheme.dockGold
              : GhostDiceTheme.dockGold.withValues(alpha: 0.4),
          width: isAwaitingDice ? 1.8 : 1.2,
        ),
        boxShadow: [
          if (isAwaitingDice)
            BoxShadow(
              color: GhostDiceTheme.dockGold.withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Active Player Turn & Instructions
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeColor,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.gameState.isActivePlayerRollingForPartner
                            ? '${activePlayer.name} (Rolling for ${widget.gameState.activePartner?.name})'
                            : activePlayer.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _isRolling
                      ? 'Rolling dice...'
                      : (isAwaitingDice
                          ? 'Tap the die to roll (Pure RNG)'
                          : (isAwaitingPiece
                              ? 'Rolled $_displayFace! Tap highlighted piece'
                              : 'Waiting...')),
                  style: TextStyle(
                    color: isAwaitingDice
                        ? GhostDiceTheme.dockGold
                        : GhostDiceTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFF00E676), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Unbiased Uniform RNG (1 to 6)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Right: Large Interactive 3D Die
          GestureDetector(
            onTap: isAwaitingDice ? _triggerRoll : null,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, child) {
                // Shake and rotate while tumbling
                final angle = _isRolling
                    ? math.sin(_anim.value * math.pi * 8) * 0.25
                    : 0.0;
                final scale = _isRolling
                    ? 1.0 + math.sin(_anim.value * math.pi) * 0.18
                    : 1.0;

                return Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: angle,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFF0F4F8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAwaitingDice ? GhostDiceTheme.dockGold : activeColor,
                    width: isAwaitingDice ? 2.2 : 1.5,
                  ),
                  boxShadow: [
                    if (isAwaitingDice)
                      BoxShadow(
                        color: GhostDiceTheme.dockGold.withValues(alpha: 0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    const BoxShadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(7),
                child: CustomPaint(
                  painter: DiePipPainter(value: _displayFace),
                ),
              ),
            ),
          ),

          if (isAwaitingDice) ...[
            const SizedBox(width: 8),
            // Tap Roll Action Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GhostDiceTheme.dockGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              onPressed: _triggerRoll,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.casino_rounded, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'ROLL',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
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


// LudoCornerDock — Tabletop player dock matching Image 2, 3, and 4 reference.
// Shows ONLY the colored piece box and a larger squared 3D dice box (player names are in the home yard).
// Features an animated blinking arrow pointing toward the die for the player whose turn it is.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';
import 'package:ghost_dice/domain/entities/board_position.dart';
import 'package:ghost_dice/domain/entities/piece.dart';
import 'package:ghost_dice/domain/entities/player.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';
import 'package:ghost_dice/infrastructure/services/audio_service.dart';
import 'package:ghost_dice/presentation/board/piece_widget.dart';

class LudoCornerDock extends StatefulWidget {
  final Player player;
  final bool isActive;
  final bool useInGameDice;
  final bool isAwaitingDice;
  final bool isAwaitingPiece;
  final int? currentDiceValue;
  final ValueChanged<int>? onRoll;
  final VoidCallback? onDiceTap;
  final String? teamLabel;
  final bool isHelpingPartner;
  final bool isRightSide;

  const LudoCornerDock({
    super.key,
    required this.player,
    required this.isActive,
    this.useInGameDice = false,
    this.isAwaitingDice = false,
    this.isAwaitingPiece = false,
    this.currentDiceValue,
    this.onRoll,
    this.onDiceTap,
    this.teamLabel,
    this.isHelpingPartner = false,
    this.isRightSide = false,
  });

  @override
  State<LudoCornerDock> createState() => _LudoCornerDockState();
}

class _LudoCornerDockState extends State<LudoCornerDock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  int _displayFace = 1;
  bool _isRolling = false;
  late final math.Random _rng;

  @override
  void initState() {
    super.initState();
    try {
      _rng = math.Random.secure();
    } catch (_) {
      _rng = math.Random();
    }
    _displayFace = widget.currentDiceValue ?? 1;
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _anim.addListener(_onRollTick);
  }

  @override
  void didUpdateWidget(covariant LudoCornerDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentDiceValue != null) {
      _displayFace = widget.currentDiceValue!;
    }
  }

  void _onRollTick() {
    if (_anim.value < 0.90) {
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
    if (_isRolling || !widget.isActive || !widget.isAwaitingDice) return;

    setState(() {
      _isRolling = true;
    });

    SoundEffectService.playDiceRollSound();

    // 100% Pure, Unbiased Cryptographic RNG (1 to 6)
    final finalRoll = _rng.nextInt(6) + 1;

    _anim.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() {
        _displayFace = finalRoll;
        _isRolling = false;
      });
      SoundEffectService.playHopSound();
      widget.onRoll?.call(finalRoll);
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerColor = _resolveColor(widget.player.color);
    final isReadyToRoll = widget.isActive &&
        widget.isAwaitingDice &&
        widget.useInGameDice &&
        !_isRolling;

    // Show blinking arrow when it is this player's active turn
    final showArrow = widget.isActive && widget.isAwaitingDice;

    final dockBadge = Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F3E80),
            Color(0xFF092858),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isActive
              ? GhostDiceTheme.dockGold
              : const Color(0xFF1E4E94),
          width: widget.isActive ? 2.2 : 1.2,
        ),
        boxShadow: [
          if (widget.isActive)
            BoxShadow(
              color: GhostDiceTheme.dockGold.withValues(alpha: 0.45),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: widget.isRightSide
            ? [
                // Right-side dock: [ Big Squared Dice Box ] [ Colored Piece Box ]
                _buildDiceBox(playerColor, isReadyToRoll),
                const SizedBox(width: 6),
                _buildColoredPieceBox(playerColor),
              ]
            : [
                // Left-side dock: [ Colored Piece Box ] [ Big Squared Dice Box ]
                _buildColoredPieceBox(playerColor),
                const SizedBox(width: 6),
                _buildDiceBox(playerColor, isReadyToRoll),
              ],
      ),
    );

    // Arrow points toward the die:
    // Left docks: arrow is to the right pointing left (◄) into the die.
    // Right docks: arrow is to the left pointing right (►) into the die.
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: widget.isRightSide
          ? [
              if (showArrow) ...[
                const _BlinkingTurnArrow(isPointingRight: true),
                const SizedBox(width: 4),
              ],
              dockBadge,
            ]
          : [
              dockBadge,
              if (showArrow) ...[
                const SizedBox(width: 4),
                const _BlinkingTurnArrow(isPointingRight: false),
              ],
            ],
    );
  }

  /// Compact colored piece box (smaller than squared dice box) matching Image 2, 3, 4
  Widget _buildColoredPieceBox(Color playerColor) {
    return Container(
      width: 32,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF082245),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isActive
              ? playerColor.withValues(alpha: 0.8)
              : const Color(0xFF1E4E94).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: PieceWidget(
          piece: Piece(
            id: 'dock_${widget.player.id}',
            playerId: widget.player.id,
            color: widget.player.color,
            pieceIndex: 0,
            position: const BoardPosition.yard(),
          ),
          width: 20,
          height: 28,
          isHighlighted: false,
        ),
      ),
    );
  }

  /// Big squared dice box matching Image 2, 3, 4
  Widget _buildDiceBox(Color playerColor, bool isReadyToRoll) {
    const boxSize = 48.0;

    return GestureDetector(
      onTap: isReadyToRoll
          ? _triggerRoll
          : (widget.isActive ? widget.onDiceTap : null),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          final angle = _isRolling
              ? math.sin(_anim.value * math.pi * 8) * 0.22
              : 0.0;
          final scale = _isRolling
              ? 1.0 + math.sin(_anim.value * math.pi) * 0.15
              : (isReadyToRoll ? 1.05 : 1.0);

          return Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: angle,
              child: child,
            ),
          );
        },
        child: Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFF1F5F9),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isReadyToRoll
                  ? GhostDiceTheme.dockGold
                  : (widget.isActive ? playerColor : const Color(0xFFCBD5E1)),
              width: isReadyToRoll ? 2.4 : (widget.isActive ? 2.0 : 1.2),
            ),
            boxShadow: [
              if (isReadyToRoll)
                BoxShadow(
                  color: GhostDiceTheme.dockGold.withValues(alpha: 0.65),
                  blurRadius: 10,
                  spreadRadius: 1.5,
                ),
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(5),
          child: widget.useInGameDice
              ? CustomPaint(
                  painter: DiePipPainter(value: _displayFace),
                )
              : Center(
                  child: widget.currentDiceValue != null
                      ? CustomPaint(
                          size: const Size(36, 36),
                          painter: DiePipPainter(value: widget.currentDiceValue!),
                        )
                      : (widget.isActive
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.touch_app_rounded,
                                    size: 16,
                                    color: playerColor,
                                  ),
                                  Text(
                                    widget.isHelpingPartner ? 'PARTNER' : 'ROLL',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: widget.isHelpingPartner ? 6 : 7.5,
                                      fontWeight: FontWeight.w900,
                                      color: playerColor,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const Icon(
                              Icons.casino_outlined,
                              size: 22,
                              color: Color(0xFF94A3B8),
                            )),
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

/// Blinking turn arrow indicator matching Image 4 reference.
/// Size: ~1/3 size of dice (~16px), warm amber-gold color (prominent and non-annoying).
class _BlinkingTurnArrow extends StatefulWidget {
  final bool isPointingRight;

  const _BlinkingTurnArrow({
    required this.isPointingRight,
  });

  @override
  State<_BlinkingTurnArrow> createState() => _BlinkingTurnArrowState();
}

class _BlinkingTurnArrowState extends State<_BlinkingTurnArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat(reverse: true);
  }

  @override
  void disposeValidate() {
    _anim.dispose();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Arrow size: 16px wide, 18px high (~1/3 of 48px die)
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final opacity = 0.35 + _anim.value * 0.65;
        // Subtle horizontal nudge pointing towards the die
        final dx = widget.isPointingRight
            ? (_anim.value * 3.0)
            : (-_anim.value * 3.0);

        return Transform.translate(
          offset: Offset(dx, 0),
          child: Opacity(
            opacity: opacity,
            child: CustomPaint(
              size: const Size(16, 18),
              painter: _SolidArrowPainter(
                isPointingRight: widget.isPointingRight,
                color: const Color(0xFFFFA000), // Warm golden amber
                accentColor: const Color(0xFFFFD54F),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for a solid, thick pointer arrow matching Image 4
class _SolidArrowPainter extends CustomPainter {
  final bool isPointingRight;
  final Color color;
  final Color accentColor;

  _SolidArrowPainter({
    required this.isPointingRight,
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    if (isPointingRight) {
      // Arrow pointing right ► (head on right, shaft on left)
      path.moveTo(0, h * 0.28);
      path.lineTo(w * 0.45, h * 0.28);
      path.lineTo(w * 0.45, 0);
      path.lineTo(w, h * 0.5);
      path.lineTo(w * 0.45, h);
      path.lineTo(w * 0.45, h * 0.72);
      path.lineTo(0, h * 0.72);
      path.close();
    } else {
      // Arrow pointing left ◄ (head on left, shaft on right)
      path.moveTo(w, h * 0.28);
      path.lineTo(w * 0.55, h * 0.28);
      path.lineTo(w * 0.55, 0);
      path.lineTo(0, h * 0.5);
      path.lineTo(w * 0.55, h);
      path.lineTo(w * 0.55, h * 0.72);
      path.lineTo(w, h * 0.72);
      path.close();
    }

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [accentColor, color],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF5D2400) // Dark subtle outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SolidArrowPainter oldDelegate) =>
      oldDelegate.isPointingRight != isPointingRight ||
      oldDelegate.color != color ||
      oldDelegate.accentColor != accentColor;
}

/// CustomPainter rendering sharp authentic 3D dice pips (1 to 6)
class DiePipPainter extends CustomPainter {
  final int value;

  const DiePipPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pipRadius = (w * 0.10).clamp(2.5, 4.5);

    // Authentic dark slate/black pips with slight bevel
    final pipPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    void drawPip(double x, double y) {
      canvas.drawCircle(Offset(x, y), pipRadius, pipPaint);
      canvas.drawCircle(
        Offset(x - pipRadius * 0.28, y - pipRadius * 0.28),
        pipRadius * 0.35,
        highlightPaint,
      );
    }

    final left = w * 0.26;
    final center = w * 0.50;
    final right = w * 0.74;

    final top = h * 0.26;
    final middle = h * 0.50;
    final bottom = h * 0.74;

    switch (value) {
      case 1:
        drawPip(center, middle);
        break;
      case 2:
        drawPip(left, top);
        drawPip(right, bottom);
        break;
      case 3:
        drawPip(left, top);
        drawPip(center, middle);
        drawPip(right, bottom);
        break;
      case 4:
        drawPip(left, top);
        drawPip(right, top);
        drawPip(left, bottom);
        drawPip(right, bottom);
        break;
      case 5:
        drawPip(left, top);
        drawPip(right, top);
        drawPip(center, middle);
        drawPip(left, bottom);
        drawPip(right, bottom);
        break;
      case 6:
        drawPip(left, top);
        drawPip(right, top);
        drawPip(left, middle);
        drawPip(right, middle);
        drawPip(left, bottom);
        drawPip(right, bottom);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant DiePipPainter oldDelegate) =>
      oldDelegate.value != value;
}

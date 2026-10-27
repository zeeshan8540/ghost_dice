// LudoCornerDock — Tabletop player dock matching Image 2 & 3 reference.
// Shows player avatar pin, name, team badge, and interactive 3D die beside player name.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';
import 'package:ghost_dice/domain/entities/player.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';
import 'package:ghost_dice/infrastructure/services/audio_service.dart';

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

    final dockHeight = widget.useInGameDice ? 50.0 : 44.0;
    final minW = widget.useInGameDice ? 160.0 : 135.0;
    final maxW = widget.useInGameDice ? 195.0 : 155.0;

    return GestureDetector(
      onTap: isReadyToRoll
          ? _triggerRoll
          : (widget.isActive ? widget.onDiceTap : null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: dockHeight,
        constraints: BoxConstraints(minWidth: minW, maxWidth: maxW),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0F3A75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isActive
                ? GhostDiceTheme.dockGold
                : const Color(0xFF1E5BB0),
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
                  if (widget.isActive) ...[
                    _TurnArrowIndicator(
                      isPointingRight: true,
                      color: GhostDiceTheme.dockGold,
                    ),
                    const SizedBox(width: 2),
                  ],
                  _buildDiceBox(playerColor, isReadyToRoll),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPlayerInfo(
                      playerColor,
                      isReadyToRoll,
                      alignEnd: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildAvatarPin(playerColor),
                ]
              : [
                  _buildAvatarPin(playerColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPlayerInfo(
                      playerColor,
                      isReadyToRoll,
                      alignEnd: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildDiceBox(playerColor, isReadyToRoll),
                  if (widget.isActive) ...[
                    const SizedBox(width: 2),
                    _TurnArrowIndicator(
                      isPointingRight: false,
                      color: GhostDiceTheme.dockGold,
                    ),
                  ],
                ],
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(Color playerColor, bool isReadyToRoll,
      {required bool alignEnd}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          widget.player.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        if (widget.teamLabel != null)
          Text(
            widget.teamLabel!,
            style: TextStyle(
              color: widget.teamLabel == 'TEAM 1'
                  ? GhostDiceTheme.dockGold
                  : Colors.cyanAccent,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          )
        else if (isReadyToRoll)
          const Text(
            'TAP TO ROLL',
            style: TextStyle(
              color: GhostDiceTheme.dockGold,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          )
        else if (widget.isActive && widget.isAwaitingPiece)
          Text(
            'ROLLED ',
            style: TextStyle(
              color: playerColor,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarPin(Color playerColor) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: playerColor,
        border: Border.all(color: Colors.white, width: 2.2),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1.5)),
        ],
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDiceBox(Color playerColor, bool isReadyToRoll) {
    final boxSize = widget.useInGameDice ? 40.0 : 34.0;
    final dieSize = widget.useInGameDice ? 36.0 : 28.0;

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
              width: isReadyToRoll ? 2.4 : (widget.isActive ? 1.8 : 1.0),
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
                blurRadius: 3,
                offset: Offset(0, 1.5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: widget.useInGameDice
              ? CustomPaint(
                  painter: DiePipPainter(value: _displayFace),
                )
              : Center(
                  child: widget.currentDiceValue != null
                      ? _DieFace(value: widget.currentDiceValue!, size: dieSize)
                      : (widget.isActive
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.touch_app_rounded,
                                    size: 14,
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
                              size: 18,
                              color: Color(0xFFB0BEC5),
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

/// Small arrow indicator matching Image 4 active player prompt
class _TurnArrowIndicator extends StatefulWidget {
  final bool isPointingRight;
  final Color color;

  const _TurnArrowIndicator({
    required this.isPointingRight,
    required this.color,
  });

  @override
  State<_TurnArrowIndicator> createState() => _TurnArrowIndicatorState();
}

class _TurnArrowIndicatorState extends State<_TurnArrowIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.5, end: 1.0).animate(_anim),
      child: Icon(
        widget.isPointingRight
            ? Icons.arrow_right_rounded
            : Icons.arrow_left_rounded,
        color: widget.color,
        size: 18,
      ),
    );
  }
}

/// Renders a real 3D die face with accurate dot pips
class _DieFace extends StatelessWidget {
  final int value;
  final double size;

  const _DieFace({required this.value, this.size = 28.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(color: const Color(0xFFCFD8DC), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.12),
      child: CustomPaint(
        painter: DiePipPainter(value: value),
      ),
    );
  }
}

class DiePipPainter extends CustomPainter {
  final int value;
  DiePipPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = const Color(0xFF0F172A);
    final dotRadius = size.width * 0.11;

    final left = size.width * 0.22;
    final center = size.width * 0.5;
    final right = size.width * 0.78;

    final top = size.height * 0.22;
    final middle = size.height * 0.5;
    final bottom = size.height * 0.78;

    void draw(double x, double y) =>
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);

    switch (value) {
      case 1:
        draw(center, middle);
        break;
      case 2:
        draw(left, top);
        draw(right, bottom);
        break;
      case 3:
        draw(left, top);
        draw(center, middle);
        draw(right, bottom);
        break;
      case 4:
        draw(left, top);
        draw(right, top);
        draw(left, bottom);
        draw(right, bottom);
        break;
      case 5:
        draw(left, top);
        draw(right, top);
        draw(center, middle);
        draw(left, bottom);
        draw(right, bottom);
        break;
      case 6:
        draw(left, top);
        draw(right, top);
        draw(left, middle);
        draw(right, middle);
        draw(left, bottom);
        draw(right, bottom);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant DiePipPainter oldDelegate) =>
      oldDelegate.value != value;
}

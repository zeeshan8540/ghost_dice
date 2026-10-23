// LudoCornerDock — Compact tabletop player dock matching Image 4 reference.
// Shows player avatar pin, name, team badge, and compact 3D dice display with active turn arrow.
import 'package:flutter/material.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';
import 'package:ghost_dice/domain/entities/player.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';

class LudoCornerDock extends StatelessWidget {
  final Player player;
  final bool isActive;
  final int? currentDiceValue;
  final VoidCallback? onDiceTap;
  final String? teamLabel;
  final bool isHelpingPartner;
  final bool isRightSide;

  const LudoCornerDock({
    super.key,
    required this.player,
    required this.isActive,
    this.currentDiceValue,
    this.onDiceTap,
    this.teamLabel,
    this.isHelpingPartner = false,
    this.isRightSide = false,
  });

  @override
  Widget build(BuildContext context) {
    final playerColor = _resolveColor(player.color);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 42,
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3A75),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? GhostDiceTheme.dockGold : const Color(0xFF1E5BB0),
          width: isActive ? 2.0 : 1.2,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: GhostDiceTheme.dockGold.withValues(alpha: 0.45),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          const BoxShadow(
            color: Colors.black45,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: isRightSide
            ? [
                if (isActive) ...[
                  _TurnArrowIndicator(isPointingRight: true, color: GhostDiceTheme.dockGold),
                  const SizedBox(width: 2),
                ],
                _buildDiceBox(playerColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (teamLabel != null)
                        Text(
                          teamLabel!,
                          style: TextStyle(
                            color: teamLabel == 'TEAM 1'
                                ? GhostDiceTheme.dockGold
                                : Colors.cyanAccent,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                _buildAvatarPin(playerColor),
              ]
            : [
                _buildAvatarPin(playerColor),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (teamLabel != null)
                        Text(
                          teamLabel!,
                          style: TextStyle(
                            color: teamLabel == 'TEAM 1'
                                ? GhostDiceTheme.dockGold
                                : Colors.cyanAccent,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _buildDiceBox(playerColor),
                if (isActive) ...[
                  const SizedBox(width: 2),
                  _TurnArrowIndicator(isPointingRight: false, color: GhostDiceTheme.dockGold),
                ],
              ],
      ),
    );
  }

  Widget _buildAvatarPin(Color playerColor) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: playerColor,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
    );
  }

  Widget _buildDiceBox(Color playerColor) {
    return GestureDetector(
      onTap: onDiceTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8E7),
              Color(0xFFFFE0B2),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? GhostDiceTheme.dockGold : const Color(0xFFD7CCC8),
            width: isActive ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 3,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Center(
          child: currentDiceValue != null
              ? _DieFace(value: currentDiceValue!, size: 28)
              : (isActive
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
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
                              isHelpingPartner ? 'PARTNER' : 'ROLL',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isHelpingPartner ? 6 : 7.5,
                                fontWeight: FontWeight.w900,
                                color: playerColor,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.casino_outlined,
                      size: 18,
                      color: Color(0xFFB0BEC5),
                    )),
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
        widget.isPointingRight ? Icons.arrow_right_rounded : Icons.arrow_left_rounded,
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
    final dotPaint = Paint()..color = const Color(0xFF1E293B);
    final dotRadius = size.width * 0.11;

    final left = size.width * 0.22;
    final center = size.width * 0.5;
    final right = size.width * 0.78;

    final top = size.height * 0.22;
    final middle = size.height * 0.5;
    final bottom = size.height * 0.78;

    void draw(double x, double y) => canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);

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
  bool shouldRepaint(covariant DiePipPainter oldDelegate) => oldDelegate.value != value;
}

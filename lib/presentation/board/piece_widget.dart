// PieceWidget — Injection-Molded Plastic Ludo Pawn.
// Perfectly matches the reference image:
// - Cylindrical base puck disc
// - Tapered conical body with 2 horizontal groove rings dividing it into 3 stepped tiers
// - Narrow collar neck
// - Glossy spherical head with realistic directional lighting
// - Uniform molded plastic color (Yellow, Red, Blue, Green)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';
import 'package:ghost_dice/domain/entities/piece.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';

class PieceWidget extends StatefulWidget {
  final Piece piece;
  final bool isHighlighted;
  final bool isActive;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const PieceWidget({
    super.key,
    required this.piece,
    this.isHighlighted = false,
    this.isActive = false,
    this.width = 28.0,
    this.height = 38.0,
    this.onTap,
  });

  @override
  State<PieceWidget> createState() => _PieceWidgetState();
}

class _PieceWidgetState extends State<PieceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _bobAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _bobAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOutSine,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isHighlighted) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PieceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !_animController.isAnimating) {
      _animController.repeat(reverse: true);
    } else if (!widget.isHighlighted && _animController.isAnimating) {
      _animController.stop();
      _animController.reset();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _pieceColor(widget.piece.color);

    final content = SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          final lift = widget.isHighlighted ? _bobAnimation.value : 0.0;
          final pulse = widget.isHighlighted ? _pulseAnimation.value : 0.0;

          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _MoldedPlasticPawnPainter(
              color: color,
              playerColor: widget.piece.color,
              isHighlighted: widget.isHighlighted,
              lift: lift,
              pulse: pulse,
            ),
          );
        },
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }

  Color _pieceColor(PlayerColor c) => switch (c) {
        PlayerColor.yellow => const Color(0xFFFFC700),
        PlayerColor.red => const Color(0xFFE53935),
        PlayerColor.blue => const Color(0xFF1E88E5),
        PlayerColor.green => const Color(0xFF43A047),
      };
}

/// CustomPainter rendering an authentic injection-molded plastic pawn token.
/// Exactly matches the user's reference image:
/// - Puck cylindrical base
/// - 3-tier conical body with 2 engraved circular grooves
/// - Narrow neck
/// - Glossy spherical head
class _MoldedPlasticPawnPainter extends CustomPainter {
  final Color color;
  final PlayerColor playerColor;
  final bool isHighlighted;
  final double lift; // 0.0 to 1.0
  final double pulse; // 0.0 to 1.0

  _MoldedPlasticPawnPainter({
    required this.color,
    required this.playerColor,
    required this.isHighlighted,
    required this.lift,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    // Contact point on the board
    final groundY = h * 0.88;

    // Levitation height when highlighted (up to 4px)
    final liftDy = lift * (h * 0.10);

    // -------------------------------------------------------------------------
    // 1. Ground Contact Shadow (on the board beneath the pawn)
    // -------------------------------------------------------------------------
    final shadowScale = 1.0 - lift * 0.20;
    final shadowAlpha = (0.42 - lift * 0.16).clamp(0.0, 1.0);
    final shadowRect = Rect.fromCenter(
      center: Offset(cx, groundY + 1.0),
      width: w * 0.82 * shadowScale,
      height: h * 0.18 * shadowScale,
    );
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: shadowAlpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0 + lift * 1.5);
    canvas.drawOval(shadowRect, shadowPaint);

    // -------------------------------------------------------------------------
    // 2. Selection / Active Turn Aura (Prominent ground ring matching Image 1 & 3)
    // -------------------------------------------------------------------------
    if (isHighlighted) {
      final ringWidth = w * (1.10 + pulse * 0.12);
      final ringHeight = h * (0.32 + pulse * 0.04);
      final ringCenter = Offset(cx, groundY + 1.0);

      // A. Ground Glow Base
      final glowPaint = Paint()
        ..color = const Color(0xFFFF9800).withValues(alpha: 0.35 + pulse * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: ringCenter,
          width: ringWidth * 1.15,
          height: ringHeight * 1.15,
        ),
        glowPaint,
      );

      // B. Prominent Gear-Tooth / Cog Notches (Matching Image 1 & 3)
      // 12 radiating gear teeth around the perimeter
      final gearToothPaint = Paint()
        ..color = const Color(0xFF6B1110) // Deep burgundy/crimson matching reference
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;

      const numTeeth = 12;
      for (int i = 0; i < numTeeth; i++) {
        final angle = (i * 2 * math.pi) / numTeeth + (pulse * 0.2);
        final cosA = math.cos(angle);
        final sinA = math.sin(angle);
        final innerX = cx + (ringWidth * 0.44) * cosA;
        final innerY = ringCenter.dy + (ringHeight * 0.44) * sinA;
        final outerX = cx + (ringWidth * 0.58) * cosA;
        final outerY = ringCenter.dy + (ringHeight * 0.58) * sinA;
        canvas.drawLine(Offset(innerX, innerY), Offset(outerX, outerY), gearToothPaint);
      }

      // C. Heavy Outer Burgundy Ring (Matching Image 1 & 3)
      final outerRingPaint = Paint()
        ..color = const Color(0xFF781113) // Dark rich crimson
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2;
      canvas.drawOval(
        Rect.fromCenter(
          center: ringCenter,
          width: ringWidth,
          height: ringHeight,
        ),
        outerRingPaint,
      );

      // D. Brilliant Golden Core Ring
      final goldRingPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.85 + pulse * 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawOval(
        Rect.fromCenter(
          center: ringCenter,
          width: ringWidth * 0.82,
          height: ringHeight * 0.82,
        ),
        goldRingPaint,
      );

      // E. Crisp Inner White Halo Ring
      final innerWhitePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.70 + pulse * 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawOval(
        Rect.fromCenter(
          center: ringCenter,
          width: ringWidth * 0.60,
          height: ringHeight * 0.60,
        ),
        innerWhitePaint,
      );
    }

    // -------------------------------------------------------------------------
    // 3. Molded Plastic Pawn Token Body
    // -------------------------------------------------------------------------
    canvas.save();
    canvas.translate(0, -liftDy);

    // Palette derivatives for authentic 3D plastic lighting
    final darkShadow = Color.lerp(color, Colors.black, 0.58)!;
    final midShadow = Color.lerp(color, Colors.black, 0.28)!;
    final highlightTint = Color.lerp(color, Colors.white, 0.48)!;
    final softHighlight = Color.lerp(color, Colors.white, 0.25)!;

    // Key Vertical Coordinates
    final baseBottomY = groundY;
    final baseTopY = groundY - h * 0.15;
    final neckY = groundY - h * 0.58;
    final headCenterY = groundY - h * 0.74;
    final headRadius = w * 0.24;

    // -------------------------------------------------------------------------
    // A. Base Disc (Puck cylinder)
    // -------------------------------------------------------------------------
    final baseBottomRect = Rect.fromCenter(
      center: Offset(cx, baseBottomY),
      width: w * 0.78,
      height: h * 0.13,
    );
    final baseTopRect = Rect.fromCenter(
      center: Offset(cx, baseTopY),
      width: w * 0.74,
      height: h * 0.12,
    );

    // Cylindrical Wall / Skirt of the puck base
    final baseSkirtPath = Path()
      ..moveTo(baseTopRect.left, baseTopRect.center.dy)
      ..lineTo(baseBottomRect.left, baseBottomRect.center.dy)
      ..arcTo(baseBottomRect, math.pi, -math.pi, false)
      ..lineTo(baseTopRect.right, baseTopRect.center.dy)
      ..arcTo(baseTopRect, 0, math.pi, false)
      ..close();

    final baseWallGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        darkShadow,
        midShadow,
        highlightTint,
        color,
        midShadow,
        darkShadow,
      ],
      stops: const [0.0, 0.18, 0.38, 0.60, 0.85, 1.0],
    ).createShader(Rect.fromLTWH(0, baseTopY, w, baseBottomY - baseTopY));

    canvas.drawPath(baseSkirtPath, Paint()..shader = baseWallGradient);

    // Base puck bottom lip bevel
    canvas.drawArc(
      baseBottomRect,
      0,
      math.pi,
      false,
      Paint()
        ..color = darkShadow.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Top surface of the Base Puck
    final baseTopGradient = RadialGradient(
      center: const Alignment(-0.25, -0.30),
      radius: 0.85,
      colors: [
        softHighlight,
        color,
        midShadow,
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(baseTopRect);
    canvas.drawOval(baseTopRect, Paint()..shader = baseTopGradient);

    // -------------------------------------------------------------------------
    // B. Conical Body with 2 Horizontal Groove Rings (3 Stepped Tiers)
    // -------------------------------------------------------------------------
    final coneBottomW = w * 0.58;
    final coneTopW = w * 0.20;
    final coneHeight = baseTopY - neckY;

    // Ring groove heights
    // Groove 1 (lower): ~36% up the cone
    final g1Y = baseTopY - coneHeight * 0.36;
    final g1W = coneBottomW - (coneBottomW - coneTopW) * 0.36;

    // Groove 2 (upper): ~70% up the cone
    final g2Y = baseTopY - coneHeight * 0.70;
    final g2W = coneBottomW - (coneBottomW - coneTopW) * 0.70;

    // Main Conical Body Path
    final conePath = Path()
      ..moveTo(cx - coneBottomW * 0.5, baseTopY)
      ..lineTo(cx - coneTopW * 0.5, neckY)
      ..lineTo(cx + coneTopW * 0.5, neckY)
      ..lineTo(cx + coneBottomW * 0.5, baseTopY)
      ..close();

    final coneGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        darkShadow,
        midShadow,
        highlightTint,
        color,
        midShadow,
        darkShadow,
      ],
      stops: const [0.0, 0.16, 0.36, 0.58, 0.84, 1.0],
    ).createShader(Rect.fromLTWH(cx - coneBottomW * 0.5, neckY, coneBottomW, coneHeight));

    canvas.drawPath(conePath, Paint()..shader = coneGradient);

    // Subtle edge outline for crisp definition
    canvas.drawPath(
      conePath,
      Paint()
        ..color = darkShadow.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Draw the 2 horizontal molded groove rings
    _drawRingGroove(
      canvas: canvas,
      cx: cx,
      y: g1Y,
      width: g1W,
      h: h,
      darkShadow: darkShadow,
      softHighlight: softHighlight,
    );

    _drawRingGroove(
      canvas: canvas,
      cx: cx,
      y: g2Y,
      width: g2W,
      h: h,
      darkShadow: darkShadow,
      softHighlight: softHighlight,
    );

    // -------------------------------------------------------------------------
    // C. Narrow Collar Neck
    // -------------------------------------------------------------------------
    final collarRect = Rect.fromCenter(
      center: Offset(cx, neckY),
      width: coneTopW * 1.10,
      height: h * 0.06,
    );
    final collarGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        darkShadow,
        highlightTint,
        color,
        darkShadow,
      ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    ).createShader(collarRect);

    canvas.drawOval(collarRect, Paint()..shader = collarGradient);

    // -------------------------------------------------------------------------
    // D. Glossy Spherical Head (Solid molded plastic ball knob)
    // -------------------------------------------------------------------------
    final headCenter = Offset(cx, headCenterY);
    final headRect = Rect.fromCircle(center: headCenter, radius: headRadius);

    final sphereGradient = RadialGradient(
      center: const Alignment(-0.35, -0.38),
      radius: 0.88,
      colors: [
        Colors.white,
        softHighlight,
        color,
        midShadow,
        darkShadow,
      ],
      stops: const [0.0, 0.22, 0.55, 0.82, 1.0],
    ).createShader(headRect);

    canvas.drawCircle(headCenter, headRadius, Paint()..shader = sphereGradient);

    // Sphere contour outline
    canvas.drawCircle(
      headCenter,
      headRadius,
      Paint()
        ..color = darkShadow.withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // Specular Highlight Spot (glossy injection-molded shine on top-left)
    canvas.save();
    final shineCenter = Offset(
      headCenter.dx - headRadius * 0.34,
      headCenter.dy - headRadius * 0.34,
    );
    canvas.translate(shineCenter.dx, shineCenter.dy);
    canvas.rotate(-math.pi / 4.8);
    final glarePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: headRadius * 0.52,
        height: headRadius * 0.28,
      ),
      glarePaint,
    );
    canvas.restore();

    // Secondary soft ambient rim reflection (bottom-right)
    final bounceArcRect = Rect.fromCircle(center: headCenter, radius: headRadius - 0.8);
    final bouncePaint = Paint()
      ..color = highlightTint.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawArc(bounceArcRect, math.pi * 0.12, math.pi * 0.48, false, bouncePaint);

    canvas.restore();
  }

  /// Draws a clean horizontal engraved groove ring around the conical body.
  void _drawRingGroove({
    required Canvas canvas,
    required double cx,
    required double y,
    required double width,
    required double h,
    required Color darkShadow,
    required Color softHighlight,
  }) {
    final ringRect = Rect.fromCenter(
      center: Offset(cx, y),
      width: width,
      height: h * 0.038,
    );

    // 1. Shadow groove cut line
    final groovePaint = Paint()
      ..color = darkShadow.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawArc(ringRect, 0, math.pi, false, groovePaint);

    // 2. Highlight reflection line directly under the groove cut
    final highlightRect = Rect.fromCenter(
      center: Offset(cx, y + 0.8),
      width: width * 0.96,
      height: h * 0.034,
    );
    final highlightPaint = Paint()
      ..color = softHighlight.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawArc(highlightRect, 0, math.pi, false, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _MoldedPlasticPawnPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.playerColor != playerColor ||
      oldDelegate.isHighlighted != isHighlighted ||
      oldDelegate.lift != lift ||
      oldDelegate.pulse != pulse;
}

// LudoBoardPainter — Draws the authentic tabletop Ludo board matching Image 2:
// Red (Top-Left), Green (Top-Right), Yellow (Bottom-Right), Blue (Bottom-Left).
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';
import 'package:ghost_dice/domain/entities/player.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';

class LudoBoardPainter extends CustomPainter {
  final List<Player> players;

  LudoBoardPainter({required this.players});

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 15;

    _drawBoardBackground(canvas, size);
    _drawTrackGrid(canvas, cell);
    _drawHomeLanes(canvas, cell);
    _drawCenterHomeTriangles(canvas, cell);
    _drawYards(canvas, cell);
    _drawSafeStarsAndArrows(canvas, cell);
    _drawOuterBorder(canvas, size);
  }

  void _drawBoardBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );
  }

  void _drawOuterBorder(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      borderPaint,
    );
  }

  void _drawTrackGrid(Canvas canvas, double cell) {
    final gridLinePaint = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int col = 0; col < 15; col++) {
      for (int row = 0; row < 15; row++) {
        if (_isArmCell(col, row)) {
          canvas.drawRect(
            Rect.fromLTWH(col * cell, row * cell, cell, cell),
            gridLinePaint,
          );
        }
      }
    }
  }

  void _drawHomeLanes(Canvas canvas, double cell) {
    // Red home lane (cols 1..5, row 7) - Left arm heading to center
    _fillCells(canvas, cell, [
      (1, 7), (2, 7), (3, 7), (4, 7), (5, 7)
    ], GhostDiceTheme.pieceRed);

    // Green home lane (col 7, rows 1..5) - Top arm heading to center
    _fillCells(canvas, cell, [
      (7, 1), (7, 2), (7, 3), (7, 4), (7, 5)
    ], GhostDiceTheme.pieceGreen);

    // Yellow home lane (cols 9..13, row 7) - Right arm heading to center
    _fillCells(canvas, cell, [
      (9, 7), (10, 7), (11, 7), (12, 7), (13, 7)
    ], GhostDiceTheme.pieceYellow);

    // Blue home lane (col 7, rows 9..13) - Bottom arm heading to center
    _fillCells(canvas, cell, [
      (7, 9), (7, 10), (7, 11), (7, 12), (7, 13)
    ], GhostDiceTheme.pieceBlue);

    // Start squares colored backgrounds (from Image 2):
    _fillCells(canvas, cell, [(1, 6)], GhostDiceTheme.pieceRed);
    _fillCells(canvas, cell, [(8, 1)], GhostDiceTheme.pieceGreen);
    _fillCells(canvas, cell, [(13, 8)], GhostDiceTheme.pieceYellow);
    _fillCells(canvas, cell, [(6, 13)], GhostDiceTheme.pieceBlue);
  }

  void _fillCells(Canvas canvas, double cell, List<(int, int)> cells, Color color) {
    final fillPaint = Paint()..color = color;
    final strokePaint = Paint()
      ..color = const Color(0xFF263238).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final (col, row) in cells) {
      final rect = Rect.fromLTWH(col * cell, row * cell, cell, cell);
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);
    }
  }

  void _drawCenterHomeTriangles(Canvas canvas, double cell) {
    final center = Offset(cell * 7.5, cell * 7.5);

    // Left Triangle: Red
    final redPath = Path()
      ..moveTo(cell * 6, cell * 6)
      ..lineTo(center.dx, center.dy)
      ..lineTo(cell * 6, cell * 9)
      ..close();
    canvas.drawPath(redPath, Paint()..color = GhostDiceTheme.pieceRed);

    // Top Triangle: Green
    final greenPath = Path()
      ..moveTo(cell * 6, cell * 6)
      ..lineTo(cell * 9, cell * 6)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(greenPath, Paint()..color = GhostDiceTheme.pieceGreen);

    // Right Triangle: Yellow
    final yellowPath = Path()
      ..moveTo(cell * 9, cell * 6)
      ..lineTo(cell * 9, cell * 9)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = GhostDiceTheme.pieceYellow);

    // Bottom Triangle: Blue
    final bluePath = Path()
      ..moveTo(cell * 9, cell * 9)
      ..lineTo(cell * 6, cell * 9)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(bluePath, Paint()..color = GhostDiceTheme.pieceBlue);

    // Border lines between triangles
    final borderPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(redPath, borderPaint);
    canvas.drawPath(greenPath, borderPaint);
    canvas.drawPath(yellowPath, borderPaint);
    canvas.drawPath(bluePath, borderPaint);
  }

  void _drawYards(Canvas canvas, double cell) {
    // Yards matching Image 2:
    // Red (Top-Left), Green (Top-Right), Yellow (Bottom-Right), Blue (Bottom-Left)
    final yards = <(PlayerColor, double col, double row, Color color)>[
      (PlayerColor.red, 0, 0, GhostDiceTheme.pieceRed),
      (PlayerColor.green, 9, 0, GhostDiceTheme.pieceGreen),
      (PlayerColor.yellow, 9, 9, GhostDiceTheme.pieceYellow),
      (PlayerColor.blue, 0, 9, GhostDiceTheme.pieceBlue),
    ];

    for (final (colorEnum, startCol, startRow, color) in yards) {
      final yardRect = Rect.fromLTWH(startCol * cell, startRow * cell, cell * 6, cell * 6);

      // Yard main color background
      canvas.drawRect(yardRect, Paint()..color = color);

      // Yard outer border
      canvas.drawRect(
        yardRect,
        Paint()
          ..color = const Color(0xFF1E293B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // White inner square
      final whiteBox = Rect.fromLTWH(
        (startCol + 1) * cell,
        (startRow + 1) * cell,
        cell * 4,
        cell * 4,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(whiteBox, Radius.circular(cell * 0.4)),
        Paint()..color = Colors.white,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(whiteBox, Radius.circular(cell * 0.4)),
        Paint()
          ..color = const Color(0xFFB0BEC5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // 4 Circular pockets inside the white square
      final pockets = [
        Offset((startCol + 1.8) * cell, (startRow + 1.8) * cell),
        Offset((startCol + 3.6) * cell, (startRow + 1.8) * cell),
        Offset((startCol + 1.8) * cell, (startRow + 3.6) * cell),
        Offset((startCol + 3.6) * cell, (startRow + 3.6) * cell),
      ];

      for (final center in pockets) {
        canvas.drawCircle(center, cell * 0.58, Paint()..color = color);
        canvas.drawCircle(
          center,
          cell * 0.58,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
        canvas.drawCircle(
          center,
          cell * 0.45,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }

      // Draw player name along yard edge
      _drawYardPlayerName(canvas, cell, colorEnum, startCol, startRow);
    }
  }

  void _drawYardPlayerName(
    Canvas canvas,
    double cell,
    PlayerColor color,
    double startCol,
    double startRow,
  ) {
    final player = players.where((p) => p.color == color).firstOrNull;
    if (player == null) return;

    final textSpan = TextSpan(
      text: player.name,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 12.5,
        letterSpacing: 0.5,
        shadows: [
          Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1.5)),
          Shadow(color: Colors.black87, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final x = (startCol + 3) * cell - textPainter.width / 2;
    // Matching Image 2 & 4: Top yards (Red, Green) draw name in top rim,
    // bottom yards (Blue, Yellow) draw name in bottom rim.
    final y = startRow < 5
        ? (startRow + 0.28) * cell
        : (startRow + 5.18) * cell;
    textPainter.paint(canvas, Offset(x, y));
  }

  void _drawSafeStarsAndArrows(Canvas canvas, double cell) {
    // 8 Safe Squares matching Image 2 exactly:
    // 4 Arm stars:
    // - Top arm: (6, 2)
    // - Right arm: (12, 6)
    // - Bottom arm: (8, 12)
    // - Left arm: (2, 8)
    final pathStars = [
      (6, 2),
      (12, 6),
      (8, 12),
      (2, 8),
    ];

    for (final (col, row) in pathStars) {
      final center = Offset((col + 0.5) * cell, (row + 0.5) * cell);
      _drawStar(canvas, center, cell * 0.35, const Color(0xFF455A64));
    }

    // Directional arrows matching Image 2:
    // - Red arrow at left (col 0, row 6) pointing right into (1, 6)
    _drawArrow(canvas, Offset(0.5 * cell, 6.5 * cell), cell * 0.32, 0, GhostDiceTheme.pieceRed);
    // - Green arrow at top (col 8, row 0) pointing down into (8, 1)
    _drawArrow(canvas, Offset(8.5 * cell, 0.5 * cell), cell * 0.32, math.pi / 2, GhostDiceTheme.pieceGreen);
    // - Yellow arrow at right (col 14, row 8) pointing left into (13, 8)
    _drawArrow(canvas, Offset(14.5 * cell, 8.5 * cell), cell * 0.32, math.pi, GhostDiceTheme.pieceYellow);
    // - Blue arrow at bottom (col 6, row 14) pointing up into (6, 13)
    _drawArrow(canvas, Offset(6.5 * cell, 14.5 * cell), cell * 0.32, -math.pi / 2, GhostDiceTheme.pieceBlue);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    const points = 5;
    final innerRadius = radius * 0.45;

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      final angle = (i * math.pi / points) - (math.pi / 2);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  void _drawArrow(Canvas canvas, Offset center, double size, double rotation, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path()
      ..moveTo(size * 0.6, 0)
      ..lineTo(-size * 0.4, -size * 0.5)
      ..lineTo(-size * 0.1, 0)
      ..lineTo(-size * 0.4, size * 0.5)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  bool _isArmCell(int col, int row) {
    final isTopArm = col >= 6 && col <= 8 && row < 6;
    final isBottomArm = col >= 6 && col <= 8 && row > 8;
    final isLeftArm = row >= 6 && row <= 8 && col < 6;
    final isRightArm = row >= 6 && row <= 8 && col > 8;
    return isTopArm || isBottomArm || isLeftArm || isRightArm;
  }

  @override
  bool shouldRepaint(covariant LudoBoardPainter oldDelegate) => true;
}

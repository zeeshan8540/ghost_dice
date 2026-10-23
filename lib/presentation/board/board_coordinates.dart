// Board coordinate mapper — translates logical positions to screen coordinates.
// Maps the 52-square perimeter, 4 yards (with individual pockets), and home lanes to a 15×15 grid.
// Order matching Image 2: Red (Top-Left) -> Green (Top-Right) -> Yellow (Bottom-Right) -> Blue (Bottom-Left).

import 'package:flutter/material.dart';
import 'package:ghost_dice/domain/entities/board_position.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';

class BoardCoordinates {
  final double size;

  const BoardCoordinates({required this.size});

  double get cellSize => size / 15;

  /// Returns the exact target center point (X, Y) for a piece on the board.
  Offset positionToCenter(
    BoardPosition pos,
    PlayerColor color, {
    int pieceIndex = 0,
    int stackIndex = 0,
    int totalStacked = 1,
  }) {
    if (pos.isInYard) return _yardPocketCenter(color, pieceIndex);
    if (pos.isFinished) return _homeCenter(color, pieceIndex);
    if (pos.isInHomeLane) return _homeLaneCenter(color, pos.homeLaneIndex!);
    final baseCenter = _trackCenter(pos.trackIndex!);
    return _applyStackOffset(baseCenter, stackIndex, totalStacked);
  }

  /// Backward-compatible alias returning the piece's target center.
  Offset positionToOffset(
    BoardPosition pos,
    PlayerColor color, {
    int pieceIndex = 0,
  }) =>
      positionToCenter(pos, color, pieceIndex: pieceIndex);

  Offset _trackCenter(int index) {
    final c = cellSize;
    final coords = _trackCoords;
    if (index < 0 || index >= coords.length) return Offset.zero;
    final (col, row) = coords[index];
    return Offset((col + 0.5) * c, (row + 0.5) * c);
  }

  /// Canonical 52-square clockwise track mapping on a 15×15 grid matching Image 2.
  static const List<(int col, int row)> _trackCoords = [
    // 0–12: Red arm exit -> Top arm -> approach to Green (Red start = 0 at (1, 6))
    (1, 6),  // 0: Red Start (arrow pointing right)
    (2, 6),  // 1
    (3, 6),  // 2
    (4, 6),  // 3
    (5, 6),  // 4
    (6, 5),  // 5: Turn up into top arm
    (6, 4),  // 6
    (6, 3),  // 7
    (6, 2),  // 8: Top arm safe star
    (6, 1),  // 9
    (6, 0),  // 10
    (7, 0),  // 11: Top turn
    (8, 0),  // 12: Turn down towards Green

    // 13–25: Green start at (8, 1) -> Right arm -> approach to Yellow
    (8, 1),  // 13: Green Start (arrow pointing down)
    (8, 2),  // 14
    (8, 3),  // 15
    (8, 4),  // 16
    (8, 5),  // 17
    (9, 6),  // 18: Turn right into right arm
    (10, 6), // 19
    (11, 6), // 20
    (12, 6), // 21: Right arm safe star
    (13, 6), // 22
    (14, 6), // 23
    (14, 7), // 24: Right turn
    (14, 8), // 25: Turn left towards Yellow

    // 26–38: Yellow start at (13, 8) -> Bottom arm -> approach to Blue
    (13, 8), // 26: Yellow Start (arrow pointing left)
    (12, 8), // 27
    (11, 8), // 28
    (10, 8), // 29
    (9, 8),  // 30
    (8, 9),  // 31: Turn down into bottom arm
    (8, 10), // 32
    (8, 11), // 33
    (8, 12), // 34: Bottom arm safe star
    (8, 13), // 35
    (8, 14), // 36
    (7, 14), // 37: Bottom turn
    (6, 14), // 38: Turn up towards Blue

    // 39–51: Blue start at (6, 13) -> Left arm -> approach to Red
    (6, 13), // 39: Blue Start (arrow pointing up)
    (6, 12), // 40
    (6, 11), // 41
    (6, 10), // 42
    (6, 9),  // 43
    (5, 8),  // 44: Turn left into left arm
    (4, 8),  // 45
    (3, 8),  // 46
    (2, 8),  // 47: Left arm safe star
    (1, 8),  // 48
    (0, 8),  // 49
    (0, 7),  // 50: Left turn
    (0, 6),  // 51: Final square before Red enters home lane!
  ];

  /// Exact pocket centers matching LudoBoardPainter yard circles.
  Offset _yardPocketCenter(PlayerColor color, int pieceIndex) {
    final c = cellSize;
    final pocket = pieceIndex.clamp(0, 3);

    // Exact offsets used in LudoBoardPainter._drawYards
    final (dx, dy) = switch (pocket) {
      0 => (1.8, 1.8),
      1 => (3.6, 1.8),
      2 => (1.8, 3.6),
      _ => (3.6, 3.6),
    };

    final (baseCol, baseRow) = switch (color) {
      PlayerColor.red    => (0.0, 0.0),   // Top-Left
      PlayerColor.green  => (9.0, 0.0),   // Top-Right
      PlayerColor.yellow => (9.0, 9.0),   // Bottom-Right
      PlayerColor.blue   => (0.0, 9.0),   // Bottom-Left
    };

    return Offset((baseCol + dx) * c, (baseRow + dy) * c);
  }

  Offset _homeCenter(PlayerColor color, int pieceIndex) {
    final c = cellSize;
    final idx = pieceIndex.clamp(0, 3);
    final ox = (idx % 2 == 0 ? -0.22 : 0.22) * c;
    final oy = (idx < 2 ? -0.22 : 0.22) * c;

    return switch (color) {
      PlayerColor.red    => Offset(6.75 * c + ox, 7.5 * c + oy),
      PlayerColor.green  => Offset(7.5 * c + ox, 6.75 * c + oy),
      PlayerColor.yellow => Offset(8.25 * c + ox, 7.5 * c + oy),
      PlayerColor.blue   => Offset(7.5 * c + ox, 8.25 * c + oy),
    };
  }

  Offset _homeLaneCenter(PlayerColor color, int laneIndex) {
    final c = cellSize;
    final idx = laneIndex.clamp(0, 4);

    return switch (color) {
      PlayerColor.red    => Offset((1.5 + idx) * c, 7.5 * c),
      PlayerColor.green  => Offset(7.5 * c, (1.5 + idx) * c),
      PlayerColor.yellow => Offset((13.5 - idx) * c, 7.5 * c),
      PlayerColor.blue   => Offset(7.5 * c, (13.5 - idx) * c),
    };
  }

  Offset _applyStackOffset(Offset center, int stackIndex, int totalStacked) {
    if (totalStacked <= 1) return center;
    final c = cellSize;
    final offsets = switch (totalStacked) {
      2 => [
          Offset(-c * 0.16, 0),
          Offset(c * 0.16, 0),
        ],
      3 => [
          Offset(-c * 0.16, c * 0.10),
          Offset(c * 0.16, c * 0.10),
          Offset(0, -c * 0.14),
        ],
      _ => [
          Offset(-c * 0.15, -c * 0.12),
          Offset(c * 0.15, -c * 0.12),
          Offset(-c * 0.15, c * 0.14),
          Offset(c * 0.15, c * 0.14),
        ],
    };
    final delta = offsets[stackIndex.clamp(0, offsets.length - 1)];
    return center + delta;
  }
}

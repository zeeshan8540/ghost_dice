// Board configuration — all topology constants in one place.
// The perimeter loop has 52 squares (13 per side × 4 sides).
// Each color has a specific start square, home-lane entry square,
// and a set of safe squares.
//
// Track indices run clockwise: 0–51.
// Red starts at index 0, Blue at 13, Green at 26, Yellow at 39.
//
// Visual layout (clockwise):
//  Red start   = 0   → direction: 0→1→...→51→0
//  Blue start  = 13
//  Green start = 26
//  Yellow start= 39
//
// Home-lane length: 5 squares (0 = entry just off the loop, 4 = final home)

import 'package:ghost_dice/domain/entities/board_position.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';

class BoardConfig {
  static const int trackLength = 52;
  static const int homeLaneLength = 5;
  static const int piecesPerPlayer = 4;

  /// The track index at which a piece enters the track from the yard.
  /// Clockwise order: Red (Top-Left, 0) -> Green (Top-Right, 13) -> Yellow (Bottom-Right, 26) -> Blue (Bottom-Left, 39).
  static const Map<PlayerColor, int> startTrackIndex = {
    PlayerColor.red: 0,
    PlayerColor.green: 13,
    PlayerColor.yellow: 26,
    PlayerColor.blue: 39,
  };

  /// The track index AFTER which a piece turns into its home lane.
  static const Map<PlayerColor, int> homeLaneEntryTrackIndex = {
    PlayerColor.red: 50,    // (0, 7) directly faces red home lane (1, 7)
    PlayerColor.green: 11,  // (7, 0) directly faces green home lane (7, 1)
    PlayerColor.yellow: 24, // (14, 7) directly faces yellow home lane (13, 7)
    PlayerColor.blue: 37,   // (7, 14) directly faces blue home lane (7, 13)
  };

  /// Global safe squares (star squares) — pieces here cannot be captured
  /// regardless of color. Includes all 4 start squares + 4 arm safe stars.
  static const Set<int> globalSafeSquares = {
    0, 8, 13, 21, 26, 34, 39, 47
  };

  /// Returns the diagonally opposite color for 2-player games.
  static PlayerColor getOppositeColor(PlayerColor color) => switch (color) {
        PlayerColor.red => PlayerColor.yellow,
        PlayerColor.yellow => PlayerColor.red,
        PlayerColor.blue => PlayerColor.green,
        PlayerColor.green => PlayerColor.blue,
      };

  /// Returns the distance from [from] to [to] travelling clockwise.
  static int clockwiseDistance(int from, int to) =>
      (to - from + trackLength) % trackLength;

  /// Returns true if the given track index is safe for any piece.
  static bool isGlobalSafe(int trackIndex) =>
      globalSafeSquares.contains(trackIndex);

  /// Computes the absolute track index after moving [steps] clockwise from
  static const int totalStepsToFinish = 56; // 0..50 on track (51 track squares), 51..55 in home lane (5 squares), 56 finished

  /// [current], wrapping around.
  static int advanceTrack(int current, int steps) =>
      (current + steps) % trackLength;

  /// Returns the local step progress (0..56) for a piece.
  /// -1 if in yard.
  /// 0..50 if on track (0 is start square, 50 is entry square).
  /// 51..55 if in home lane (51 is home 1, 55 is home 5).
  /// 56 if finished in center triangle.
  static int getLocalStep(BoardPosition pos, PlayerColor color) {
    if (pos.isInYard) return -1;
    if (pos.isFinished) return totalStepsToFinish;
    if (pos.isInHomeLane) {
      return 51 + pos.homeLaneIndex!.clamp(0, 4);
    }
    if (pos.isOnTrack) {
      final start = startTrackIndex[color]!;
      return (pos.trackIndex! - start + trackLength) % trackLength;
    }
    return -1;
  }

  /// Converts local step progress (0..56) back into BoardPosition.
  static BoardPosition positionFromLocalStep(int step, PlayerColor color) {
    if (step < 0) return const BoardPosition.yard();
    if (step <= 50) {
      final start = startTrackIndex[color]!;
      return BoardPosition.track((start + step) % trackLength);
    }
    if (step <= 55) {
      return BoardPosition.homeLane(step - 51);
    }
    return const BoardPosition.finished();
  }

  /// Returns the number of steps remaining for a piece currently at
  /// [trackIndex] to reach the home-lane entry for [color].
  static int stepsToHomeLaneEntry(PlayerColor color, int trackIndex) {
    final start = startTrackIndex[color]!;
    final step = (trackIndex - start + trackLength) % trackLength;
    if (step >= 51) return 1;
    return 51 - step;
  }

  /// Returns the number of steps remaining for a piece in [homeLaneIndex]
  /// to reach the final home center.
  static int stepsRemainingInHomeLane(int homeLaneIndex) =>
      homeLaneLength - homeLaneIndex;

  /// Computes the step-by-step sequence of board positions when moving [diceValue] steps.
  static List<BoardPosition> computeForwardPath({
    required BoardPosition from,
    required BoardPosition to,
    required PlayerColor color,
    required int diceValue,
  }) {
    if (from.isInYard) {
      // 1 jump from yard pocket directly to starting track square
      return [from, to];
    }

    final startStep = getLocalStep(from, color);
    if (startStep < 0) return [from, to];

    final path = <BoardPosition>[from];
    for (int step = 1; step <= diceValue; step++) {
      final s = startStep + step;
      if (s > totalStepsToFinish) {
        path.add(const BoardPosition.finished());
        break;
      }
      path.add(positionFromLocalStep(s, color));
    }

    // Ensure target position is the final landing step
    if (path.isEmpty || path.last != to) {
      if (!path.contains(to)) {
        path.add(to);
      }
    }

    return path;
  }

  /// Computes the backward retreat path of a caught piece:
  /// Retracing all the track squares it covered from its start square up to the caught square, in reverse order, then into its yard pocket.
  static List<BoardPosition> computeBackwardPath({
    required BoardPosition caughtPosition,
    required PlayerColor color,
  }) {
    final path = <BoardPosition>[caughtPosition];

    if (caughtPosition.isOnTrack) {
      final currentStep = getLocalStep(caughtPosition, color);
      for (int s = currentStep - 1; s >= 0; s--) {
        path.add(positionFromLocalStep(s, color));
      }
    }

    path.add(const BoardPosition.yard());
    return path;
  }
}

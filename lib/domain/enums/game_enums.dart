// Domain enums for Ghost Dice
// Pure Dart — no Flutter, Riverpod, or persistence imports.

enum PlayerColor { red, blue, green, yellow }

enum GameMode { classic, teamUp }

enum PieceStatus { yard, track, homeLane, finished }

enum TurnPhase {
  awaitingDiceEntry,
  awaitingPieceSelection,
  moving,
  undoVoting,
  gameOver,
}

enum UndoVoteResult { pending, approved, rejected, timedOut }

enum BonusReason { rolledSix, capture, finishedPiece }

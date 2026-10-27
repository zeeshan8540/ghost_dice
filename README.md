# Ghost Dice 🎲👻

**Physical-Dice Digital Ludo** — Roll a real die, enter the number, let the app handle the board.

---

## What is Ghost Dice?

Ghost Dice is a local pass-and-play Ludo game for 2–4 players on one shared device. Players use a **real physical die** and enter the number they roll into the app. The app manages:

- Board state, legal moves, captures, safe squares
- Home-lane movement and exact-finish rules
- Bonus entries for rolling 6, capturing, or finishing a piece
- Three-consecutive-sixes forfeiture
- **Democratic undo voting** — up to the last 3 declared dice entries can be challenged and rolled back by group vote

No internet, no accounts, no camera. Pure tabletop honesty.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod (`flutter_riverpod`) |
| Navigation | `go_router` |
| Local Persistence | SQLite (`sqflite`) |
| Preferences | `shared_preferences` |

## Supported Platforms

- Android (phone & tablet)
- iOS (iPhone & iPad)
- Windows desktop
- macOS desktop
- Linux desktop

---

## Project Structure

```
lib/
├── main.dart             # Entry point
├── app.dart              # Root widget + theme + router
├── core/theme/           # GhostDiceTheme (dark, premium)
├── domain/
│   ├── entities/         # Player, Piece, BoardPosition, GameRules, etc.
│   ├── enums/            # PlayerColor, PieceStatus, TurnPhase, etc.
│   ├── services/         # LudoRulesEngine, UndoManager (pure Dart)
│   └── repositories/     # Interfaces for persistence
├── application/
│   ├── state/            # GameState (immutable)
│   └── controllers/      # GameController, SetupController (Riverpod)
├── infrastructure/       # SQLite persistence (Phase 4)
└── presentation/
    ├── board/            # LudoBoardPainter, PieceWidget, BoardCoordinates
    ├── widgets/          # DiceNumberPicker, PlayerPanel, MoveAnnouncement, UndoVoteDialog
    ├── screens/          # HomeScreen, GameSetupScreen, GameScreen, RulesScreen, GameSummaryScreen
    └── providers/        # AppRouter
```

---

## Getting Started

### Prerequisites

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (stable channel, 3.x+)
2. Run `flutter doctor` to verify your environment

### Run

```bash
cd ghost_dice
flutter pub get
flutter run
```

For a specific platform:

```bash
flutter run -d windows   # Windows desktop
flutter run -d macos     # macOS desktop
flutter run -d linux     # Linux desktop
flutter run -d <device>  # Android or iOS device
```

### Test

```bash
flutter test
flutter analyze
dart format .
```

---

## Implementation Phases

| Phase | Status | Description |
|---|---|---|
| 0 | ✅ Structure | Project dirs, pubspec, lints |
| 1 | ✅ Domain | Rules engine, entities, unit tests |
| 2 | ✅ UI | Screens, board painter, dice picker, player panels |
| 3 | 🚧 Undo | History snapshots, vote system, rollback |
| 4 | 🔜 Persistence | SQLite save/restore, settings |
| 5 | 🔜 Polish | Sound, keyboard nav, accessibility |
| 6 | 🔜 Release | Build targets, integration tests |

---

## Game Rules Summary

- Roll a real die → tap the number on screen
- Need a **6** to enter the board (configurable)
- Land on an opponent → they return to yard
- Starred squares (★) are safe from capture
- Finish all 4 pieces to win
- **Bonus entry** for: rolling 6, capturing, or finishing a piece (one bonus per move)
- **Three 6s in a row** → turn forfeited
- **Undo voting**: challenged entry rolls back to the state before it; a strict majority needed within 15 seconds

---

## Honest Design

Ghost Dice cannot verify what the physical die actually showed. The app records **declared numbers** and provides public announcements and democratic undo voting as the fairness mechanism. It does not claim to prevent physical cheating.

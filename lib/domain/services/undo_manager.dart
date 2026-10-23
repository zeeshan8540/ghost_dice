// UndoManager — manages the rolling 3-entry undo history and snapshot stack.
// Pure Dart domain service.

import 'package:ghost_dice/domain/entities/dice_entry.dart';
import 'package:ghost_dice/domain/entities/game_snapshot.dart';
import 'package:ghost_dice/domain/entities/game_rules.dart';

class UndoHistoryItem {
  /// The dice entry being recorded.
  final DiceEntry entry;

  /// Full game snapshot taken BEFORE this entry was committed.
  final GameSnapshot snapshotBefore;

  const UndoHistoryItem({required this.entry, required this.snapshotBefore});
}

class UndoManager {
  final int historyLimit;

  /// Ordered oldest→newest.
  final List<UndoHistoryItem> _history = [];

  UndoManager({required GameRules rules}) : historyLimit = rules.undoHistoryLimit;

  List<UndoHistoryItem> get history => List.unmodifiable(_history);

  /// Push a new entry + its before-snapshot. Trims oldest if over limit.
  void push(UndoHistoryItem item) {
    _history.add(item);
    while (_history.length > historyLimit) {
      _history.removeAt(0);
    }
  }

  /// Returns the entry IDs that can currently be undone (oldest to newest).
  List<String> get undoableEntryIds =>
      _history.map((h) => h.entry.id).toList();

  /// Returns whether [entryId] is in the current rollback window.
  bool canUndo(String entryId) =>
      _history.any((h) => h.entry.id == entryId);

  /// Returns the snapshot to restore if [entryId] is approved for undo.
  /// Also returns the list of entry IDs (target + later dependents) to remove.
  ({GameSnapshot snapshot, List<String> entriesToRemove})? prepareUndo(
      String entryId) {
    final idx = _history.indexWhere((h) => h.entry.id == entryId);
    if (idx == -1) return null;

    final snapshot = _history[idx].snapshotBefore;
    final entriesToRemove =
        _history.sublist(idx).map((h) => h.entry.id).toList();
    return (snapshot: snapshot, entriesToRemove: entriesToRemove);
  }

  /// Applies the undo by removing target + dependent entries.
  void applyUndo(List<String> entriesToRemove) {
    _history.removeWhere((h) => entriesToRemove.contains(h.entry.id));
  }

  /// Replaces the entire history (used when restoring a saved game).
  void restoreHistory(List<UndoHistoryItem> items) {
    _history
      ..clear()
      ..addAll(items);
  }

  void clear() => _history.clear();
}

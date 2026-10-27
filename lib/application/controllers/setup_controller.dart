// SetupController â€” manages game-setup screen state.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghost_dice/domain/entities/board_config.dart';
import 'package:ghost_dice/domain/entities/game_rules.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';

class SetupState {
  final int playerCount;
  final List<String> names;
  final List<PlayerColor> colors;
  final GameRules rules;
  final List<String?> validationErrors;
  final bool isTeamUp;

  const SetupState({
    this.playerCount = 2,
    required this.names,
    required this.colors,
    this.rules = GameRules.defaults,
    this.validationErrors = const [],
    this.isTeamUp = false,
  });

  SetupState copyWith({
    int? playerCount,
    List<String>? names,
    List<PlayerColor>? colors,
    GameRules? rules,
    List<String?>? validationErrors,
    bool? isTeamUp,
  }) =>
      SetupState(
        playerCount: playerCount ?? this.playerCount,
        names: names ?? this.names,
        colors: colors ?? this.colors,
        rules: rules ?? this.rules,
        validationErrors: validationErrors ?? this.validationErrors,
        isTeamUp: isTeamUp ?? this.isTeamUp,
      );

  bool get isValid => validationErrors.every((e) => e == null);
}

final setupControllerProvider =
    StateNotifierProvider<SetupController, SetupState>((ref) {
  return SetupController();
});

class SetupController extends StateNotifier<SetupState> {
  SetupController()
      : super(SetupState(
          names: const ['Player 1', 'Player 2', 'Player 3', 'Player 4'],
          // For 2 players, default to Red and Yellow (opposite sides)
          colors: const [
            PlayerColor.red,
            PlayerColor.yellow,
            PlayerColor.green,
            PlayerColor.blue,
          ],
        ));

  void setGameMode(bool isTeamUp) {
    final newRules = state.rules.copyWith(isTeamUp: isTeamUp);
    if (isTeamUp) {
      // 4 players fixed: Red, Green, Yellow, Blue
      final colors = const [
        PlayerColor.red,
        PlayerColor.green,
        PlayerColor.yellow,
        PlayerColor.blue,
      ];
      state = state.copyWith(
        isTeamUp: true,
        playerCount: 4,
        colors: colors,
        rules: newRules,
      );
    } else {
      state = state.copyWith(
        isTeamUp: false,
        rules: newRules,
      );
    }
    _validate();
  }

  void setPlayerCount(int count) {
    if (state.isTeamUp) return;
    assert(count >= 2 && count <= 4);
    final colors = List<PlayerColor>.from(state.colors);
    if (count == 2) {
      // Ensure 2 players are on completely opposite sides (e.g. Red vs Yellow, Blue vs Green)
      colors[0] = PlayerColor.red;
      colors[1] = PlayerColor.yellow;
    } else if (count == 3) {
      // For 3 players, always use the first 3 fields (Red, Green, Yellow).
      // The 4th field (Blue) ALWAYS remains empty!
      colors[0] = PlayerColor.red;
      colors[1] = PlayerColor.green;
      colors[2] = PlayerColor.yellow;
      colors[3] = PlayerColor.blue;
    } else {
      // 4 players: Red, Green, Yellow, Blue
      colors[0] = PlayerColor.red;
      colors[1] = PlayerColor.green;
      colors[2] = PlayerColor.yellow;
      colors[3] = PlayerColor.blue;
    }
    state = state.copyWith(playerCount: count, colors: colors);
    _validate();
  }

  void setName(int index, String name) {
    final names = List<String>.from(state.names);
    names[index] = name;
    state = state.copyWith(names: names);
    _validate();
  }

  void setColor(int index, PlayerColor color) {
    final colors = List<PlayerColor>.from(state.colors);
    if (state.playerCount == 2) {
      colors[index] = color;
      // Keep players on opposite sides
      final otherIdx = index == 0 ? 1 : 0;
      colors[otherIdx] = BoardConfig.getOppositeColor(color);
    } else if (state.playerCount == 3) {
      // For 3 players, 4th field (Blue) ALWAYS stays empty!
      // Allowed colors are strictly Red, Green, and Yellow.
      const allowed = [PlayerColor.red, PlayerColor.green, PlayerColor.yellow];
      if (!allowed.contains(color)) return;

      final oldColor = colors[index];
      // Swap with any other player among the 3 who has this color
      for (var i = 0; i < 3; i++) {
        if (i != index && colors[i] == color) {
          colors[i] = oldColor;
          break;
        }
      }
      colors[index] = color;
    } else {
      colors[index] = color;
    }
    state = state.copyWith(colors: colors);
    _validate();
  }

  void setRules(GameRules rules) {
    state = state.copyWith(rules: rules);
  }

  void setUseInGameDice(bool value) {
    state = state.copyWith(rules: state.rules.copyWith(useInGameDice: value));
  }

  void _validate() {
    final errors = List<String?>.filled(state.playerCount, null);
    for (var i = 0; i < state.playerCount; i++) {
      final name = state.names[i].trim();
      if (name.isEmpty) {
        errors[i] = 'Name cannot be empty';
      } else if (name.length > 20) {
        errors[i] = 'Name too long (max 20 chars)';
      }
    }
    // Check duplicate colors.
    final usedColors = <PlayerColor>{};
    for (var i = 0; i < state.playerCount; i++) {
      if (!usedColors.add(state.colors[i])) {
        errors[i] = 'Color already in use';
      }
    }
    state = state.copyWith(validationErrors: errors);
  }

  List<({String name, PlayerColor color})> get playerSetups =>
      List.generate(state.playerCount, (i) {
        return (name: state.names[i].trim(), color: state.colors[i]);
      });
}


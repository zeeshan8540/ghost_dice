// Configurable game rules — all rule variants in one place.
// Saved alongside each game so a resumed game uses the same rules.

class GameRules {
  /// A piece needs a 6 to leave the yard. (Default: true)
  final bool requireSixToLeaveYard;

  /// Three consecutive sixes from the same player forfeit the third. (Default: true)
  final bool threeSixesForfeitTurn;

  /// Pieces on designated safe squares cannot be captured. (Default: true)
  final bool useSafeSquares;

  /// A piece must land exactly on the finish square (cannot overshoot). (Default: true)
  final bool requireExactRollToFinish;

  /// Two pieces of the same color on one square form a blockade that blocks passage. (Default: false)
  final bool allowBlockades;

  /// Maximum number of committed dice entries available for undo. (Default: 3)
  final int undoHistoryLimit;

  /// Seconds before an undo vote auto-rejects. (Default: 15)
  final int undoVoteTimeoutSeconds;

  /// Whether this is a 2v2 Team Up match. (Default: false)
  final bool isTeamUp;

  /// Whether to play with in-game RNG dice roll instead of physical dice entry. (Default: false)
  final bool useInGameDice;

  const GameRules({
    this.requireSixToLeaveYard = true,
    this.threeSixesForfeitTurn = true,
    this.useSafeSquares = true,
    this.requireExactRollToFinish = true,
    this.allowBlockades = false,
    this.undoHistoryLimit = 3,
    this.undoVoteTimeoutSeconds = 15,
    this.isTeamUp = false,
    this.useInGameDice = false,
  });

  static const defaults = GameRules();

  GameRules copyWith({
    bool? requireSixToLeaveYard,
    bool? threeSixesForfeitTurn,
    bool? useSafeSquares,
    bool? requireExactRollToFinish,
    bool? allowBlockades,
    int? undoHistoryLimit,
    int? undoVoteTimeoutSeconds,
    bool? isTeamUp,
    bool? useInGameDice,
  }) =>
      GameRules(
        requireSixToLeaveYard:
            requireSixToLeaveYard ?? this.requireSixToLeaveYard,
        threeSixesForfeitTurn:
            threeSixesForfeitTurn ?? this.threeSixesForfeitTurn,
        useSafeSquares: useSafeSquares ?? this.useSafeSquares,
        requireExactRollToFinish:
            requireExactRollToFinish ?? this.requireExactRollToFinish,
        allowBlockades: allowBlockades ?? this.allowBlockades,
        undoHistoryLimit: undoHistoryLimit ?? this.undoHistoryLimit,
        undoVoteTimeoutSeconds:
            undoVoteTimeoutSeconds ?? this.undoVoteTimeoutSeconds,
        isTeamUp: isTeamUp ?? this.isTeamUp,
        useInGameDice: useInGameDice ?? this.useInGameDice,
      );

  Map<String, dynamic> toJson() => {
        'requireSixToLeaveYard': requireSixToLeaveYard,
        'threeSixesForfeitTurn': threeSixesForfeitTurn,
        'useSafeSquares': useSafeSquares,
        'requireExactRollToFinish': requireExactRollToFinish,
        'allowBlockades': allowBlockades,
        'undoHistoryLimit': undoHistoryLimit,
        'undoVoteTimeoutSeconds': undoVoteTimeoutSeconds,
        'isTeamUp': isTeamUp,
        'useInGameDice': useInGameDice,
      };

  factory GameRules.fromJson(Map<String, dynamic> json) => GameRules(
        requireSixToLeaveYard: json['requireSixToLeaveYard'] as bool? ?? true,
        threeSixesForfeitTurn: json['threeSixesForfeitTurn'] as bool? ?? true,
        useSafeSquares: json['useSafeSquares'] as bool? ?? true,
        requireExactRollToFinish:
            json['requireExactRollToFinish'] as bool? ?? true,
        allowBlockades: json['allowBlockades'] as bool? ?? false,
        undoHistoryLimit: json['undoHistoryLimit'] as int? ?? 3,
        undoVoteTimeoutSeconds: json['undoVoteTimeoutSeconds'] as int? ?? 15,
        isTeamUp: json['isTeamUp'] as bool? ?? false,
        useInGameDice: json['useInGameDice'] as bool? ?? false,
      );
}

// DiceEntry — records a declared dice value before any move is committed.
class DiceEntry {
  final String id;
  final String playerId;

  /// Declared value from the physical die (1–6).
  final int value;
  final DateTime enteredAt;

  const DiceEntry({
    required this.id,
    required this.playerId,
    required this.value,
    required this.enteredAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerId': playerId,
        'value': value,
        'enteredAt': enteredAt.toIso8601String(),
      };

  factory DiceEntry.fromJson(Map<String, dynamic> json) => DiceEntry(
        id: json['id'] as String,
        playerId: json['playerId'] as String,
        value: json['value'] as int,
        enteredAt: DateTime.parse(json['enteredAt'] as String),
      );
}

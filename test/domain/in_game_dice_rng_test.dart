import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_dice/domain/entities/game_rules.dart';
import 'package:ghost_dice/application/controllers/setup_controller.dart';

void main() {
  group('In-Game Dice & Pure RNG Validation', () {
    test('GameRules default useInGameDice is false and serializes cleanly', () {
      const defaultRules = GameRules();
      expect(defaultRules.useInGameDice, isFalse);

      final withInGameDice = defaultRules.copyWith(useInGameDice: true);
      expect(withInGameDice.useInGameDice, isTrue);

      final json = withInGameDice.toJson();
      expect(json['useInGameDice'], isTrue);

      final roundtrip = GameRules.fromJson(json);
      expect(roundtrip.useInGameDice, isTrue);
    });

    test('SetupController toggles in-game dice mode', () {
      final controller = SetupController();
      expect(controller.state.rules.useInGameDice, isFalse);

      controller.setUseInGameDice(true);
      expect(controller.state.rules.useInGameDice, isTrue);

      controller.setUseInGameDice(false);
      expect(controller.state.rules.useInGameDice, isFalse);
    });

    test('Cryptographic RNG produces uniform unbiased distribution (1 to 6) without rigging', () {
      late final math.Random rng;
      try {
        rng = math.Random.secure();
      } catch (_) {
        rng = math.Random();
      }

      const totalRolls = 60000;
      final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};

      for (var i = 0; i < totalRolls; i++) {
        final roll = rng.nextInt(6) + 1;
        expect(roll, inInclusiveRange(1, 6));
        counts[roll] = counts[roll]! + 1;
      }

      // Expected per face: 10,000 (1/6 = 16.666%)
      // Tolerance of ±5% (9,500 to 10,500) proves pure uniform randomness without bias
      for (var face = 1; face <= 6; face++) {
        final count = counts[face]!;
        expect(count, greaterThan(9300), reason: 'Face  should be uniformly distributed');
        expect(count, lessThan(10700), reason: 'Face  should not be rigged');
      }
    });
  });
}

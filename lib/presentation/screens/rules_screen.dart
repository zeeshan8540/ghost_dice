// RulesScreen — displays the game rules in a readable format.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GhostDiceTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
            color: GhostDiceTheme.textSecondary,
            onPressed: () => context.go('/')),
        title: const Text('How to Play',
            style: TextStyle(
                color: GhostDiceTheme.textPrimary,
                fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _RuleSection(
            title: '🎲 Physical Dice',
            body:
                'Ghost Dice uses your real physical die. Roll it at the table, then tap the number you rolled on screen. The app handles everything else.',
          ),
          _RuleSection(
            title: '🎯 Getting on the Board',
            body:
                'You need to roll a 6 to move a piece from your yard onto the starting square. Rolling a 6 also earns you a bonus entry.',
          ),
          _RuleSection(
            title: '🏠 Getting Home',
            body:
                'Move your pieces clockwise around the board. When they reach your home lane, guide them to the final home square. You must roll the exact number to finish a piece.',
          ),
          _RuleSection(
            title: '⚡ Bonuses',
            body:
                'You earn a bonus roll (another number entry) for:\n• Rolling a 6\n• Capturing an opponent\'s piece\n• Finishing a piece home\n\nOnly one bonus is granted per move, even if multiple apply.',
          ),
          _RuleSection(
            title: '💀 Captures',
            body:
                'Landing on an opponent\'s piece sends it back to their yard. Pieces on starred (★) safe squares cannot be captured.',
          ),
          _RuleSection(
            title: '⏪ Undo Voting',
            body:
                'If someone enters a wrong number, any player can request an undo. A vote opens — everyone except the person who made the move can vote Yes or No. A strict majority of Yes votes within 15 seconds approves the rollback.',
          ),
          _RuleSection(
            title: '🔢 Three Sixes',
            body:
                'Rolling three 6s in a row during your turn chain forfeits your remaining turn. This prevents excessive bonus chains.',
          ),
          _RuleSection(
            title: '🤝 Team Up Mode (2 vs 2)',
            body:
                'Team 1 (Red & Yellow) faces off against Team 2 (Green & Blue).\n\n• Friendly Fire Disabled: Teammates never capture each other and safely share squares on the track.\n• Blockade Immunity: Teammates pass through each other freely.\n• Rolling for Partner: When a player brings all 4 of their tokens home, they keep rolling on their turns to move their partner\'s tokens!\n• Victory: The first team to safely bring all 8 tokens (4 each) home wins the match!',
          ),
        ],
      ),
    );
  }
}

class _RuleSection extends StatelessWidget {
  final String title;
  final String body;

  const _RuleSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GhostDiceTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GhostDiceTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: GhostDiceTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  fontSize: 14,
                  color: GhostDiceTheme.textSecondary,
                  height: 1.6)),
        ],
      ),
    );
  }
}

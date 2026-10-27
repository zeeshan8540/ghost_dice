// GameSetupScreen — player name, color, count, and rules configuration.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_dice/application/controllers/game_controller.dart';
import 'package:ghost_dice/application/controllers/setup_controller.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';
import 'package:ghost_dice/domain/entities/game_rules.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';

class GameSetupScreen extends ConsumerWidget {
  const GameSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(setupControllerProvider);
    final controller = ref.read(setupControllerProvider.notifier);

    return Scaffold(
      backgroundColor: GhostDiceTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('New Game',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: GhostDiceTheme.textPrimary)),
        leading: BackButton(
            color: GhostDiceTheme.textSecondary,
            onPressed: () => context.go('/')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Game Mode selector
                const _SectionHeader(title: 'Game Mode'),
                const SizedBox(height: 12),
                _GameModeSelector(
                  isTeamUp: setup.isTeamUp,
                  onSelect: controller.setGameMode,
                ),
                const SizedBox(height: 24),

                // Dice Mode selector
                const _SectionHeader(title: 'Dice Mode'),
                const SizedBox(height: 12),
                _DiceModeSelector(
                  useInGameDice: setup.rules.useInGameDice,
                  onSelect: controller.setUseInGameDice,
                ),
                const SizedBox(height: 24),

                if (!setup.isTeamUp) ...[
                  // Player count selector
                  const _SectionHeader(title: 'Number of Players'),
                  const SizedBox(height: 12),
                  _PlayerCountSelector(
                    selected: setup.playerCount,
                    onSelect: controller.setPlayerCount,
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: GhostDiceTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: GhostDiceTheme.dockGold.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.handshake_rounded,
                            color: GhostDiceTheme.dockGold, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '2 vs 2 Team Match: Team 1 (Red & Yellow) vs Team 2 (Green & Blue).\nTeammates never capture each other. When one partner finishes, they keep rolling to move their teammate\'s pieces until all 8 tokens reach home!',
                            style: TextStyle(
                              color: GhostDiceTheme.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                const _SectionHeader(title: 'Players'),
                const SizedBox(height: 12),
                ...List.generate(setup.playerCount, (i) {
                  final teamBadge = setup.isTeamUp
                      ? (i % 2 == 0 ? 'TEAM 1' : 'TEAM 2')
                      : null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PlayerRow(
                      index: i,
                      name: setup.names[i],
                      color: setup.colors[i],
                      teamBadge: teamBadge,
                      error: i < setup.validationErrors.length
                          ? setup.validationErrors[i]
                          : null,
                      onNameChanged: (v) => controller.setName(i, v),
                      onColorChanged: setup.isTeamUp ? (_) {} : (c) => controller.setColor(i, c),
                      usedColors: setup.colors
                          .sublist(0, setup.playerCount)
                          .where((c) => c != setup.colors[i])
                          .toSet(),
                      allowedColors: setup.playerCount == 3
                          ? const [PlayerColor.red, PlayerColor.green, PlayerColor.yellow]
                          : PlayerColor.values,
                    ),
                  );
                }),
                const SizedBox(height: 28),
                const _SectionHeader(title: 'Rules'),
                const SizedBox(height: 12),
                _RulesPanel(
                  rules: setup.rules,
                  onChanged: controller.setRules,
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: setup.isValid
                        ? () {
                            ref
                                .read(gameControllerProvider.notifier)
                                .createGame(
                                  playerSetups: controller.playerSetups,
                                  rules: setup.rules,
                                );
                            context.go('/game');
                          }
                        : null,
                    child: const Text('Start Game'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiceModeSelector extends StatelessWidget {
  final bool useInGameDice;
  final ValueChanged<bool> onSelect;

  const _DiceModeSelector({
    required this.useInGameDice,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeOptionCard(
            title: 'In-Game Dice',
            subtitle: 'Auto RNG (1–6)',
            icon: Icons.casino_rounded,
            isSelected: useInGameDice,
            onTap: () => onSelect(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeOptionCard(
            title: 'Physical Dice',
            subtitle: 'Roll Real Die',
            icon: Icons.touch_app_rounded,
            isSelected: !useInGameDice,
            onTap: () => onSelect(false),
          ),
        ),
      ],
    );
  }
}

class _GameModeSelector extends StatelessWidget {
  final bool isTeamUp;
  final ValueChanged<bool> onSelect;

  const _GameModeSelector({
    required this.isTeamUp,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeOptionCard(
            title: 'Classic',
            subtitle: 'Free For All',
            icon: Icons.person_rounded,
            isSelected: !isTeamUp,
            onTap: () => onSelect(false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeOptionCard(
            title: 'Team Up',
            subtitle: '2 vs 2 Co-op',
            icon: Icons.groups_rounded,
            isSelected: isTeamUp,
            onTap: () => onSelect(true),
          ),
        ),
      ],
    );
  }
}

class _ModeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? GhostDiceTheme.surfaceElevated
              : const Color(0xFF07172C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? GhostDiceTheme.dockGold : GhostDiceTheme.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: GhostDiceTheme.dockGold.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? GhostDiceTheme.dockGold.withValues(alpha: 0.2)
                    : Colors.white10,
              ),
              child: Icon(
                icon,
                color: isSelected ? GhostDiceTheme.dockGold : GhostDiceTheme.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : GhostDiceTheme.textSecondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? GhostDiceTheme.dockGold : GhostDiceTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: GhostDiceTheme.textMuted,
            letterSpacing: 1.5),
      );
}

class _PlayerCountSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _PlayerCountSelector(
      {required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [2, 3, 4].map((count) {
        final isSelected = selected == count;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => onSelect(count),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? GhostDiceTheme.accent
                    : GhostDiceTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isSelected
                        ? GhostDiceTheme.accentGlow
                        : GhostDiceTheme.border),
              ),
              child: Center(
                child: Text('$count',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : GhostDiceTheme.textSecondary)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}class _PlayerRow extends StatelessWidget {
  final int index;
  final String name;
  final PlayerColor color;
  final String? teamBadge;
  final String? error;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<PlayerColor> onColorChanged;
  final Set<PlayerColor> usedColors;

  final Iterable<PlayerColor> allowedColors;

  const _PlayerRow({
    required this.index,
    required this.name,
    required this.color,
    this.teamBadge,
    this.error,
    required this.onNameChanged,
    required this.onColorChanged,
    required this.usedColors,
    this.allowedColors = PlayerColor.values,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Color token / picker
        if (teamBadge != null)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GhostDiceTheme.playerColor(color),
              border: Border.all(
                color: Colors.white,
                width: 2.2,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
          )
        else
          PopupMenuButton<PlayerColor>(
            onSelected: onColorChanged,
            color: GhostDiceTheme.surfaceElevated,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GhostDiceTheme.playerColor(color),
                border: Border.all(
                    color: GhostDiceTheme.playerColor(color).withOpacity(0.5),
                    width: 2),
              ),
            ),
            itemBuilder: (_) => allowedColors
                .where((c) => !usedColors.contains(c))
                .map((c) => PopupMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: GhostDiceTheme.playerColor(c)),
                          ),
                          const SizedBox(width: 10),
                          Text(c.name.toUpperCase(),
                              style: const TextStyle(
                                  color: GhostDiceTheme.textPrimary)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        const SizedBox(width: 14),
        Expanded(
          child: TextFormField(
            initialValue: name,
            maxLength: 20,
            decoration: InputDecoration(
              labelText: teamBadge != null
                  ? 'Player ${index + 1} ($teamBadge)'
                  : 'Player ${index + 1}',
              errorText: error,
              counterText: '',
              suffixIcon: teamBadge != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(
                          teamBadge!,
                          style: TextStyle(
                            color: teamBadge == 'TEAM 1'
                                ? GhostDiceTheme.dockGold
                                : Colors.cyanAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        backgroundColor: teamBadge == 'TEAM 1'
                            ? GhostDiceTheme.dockGold.withValues(alpha: 0.15)
                            : Colors.cyanAccent.withValues(alpha: 0.15),
                        side: BorderSide(
                          color: teamBadge == 'TEAM 1'
                              ? GhostDiceTheme.dockGold
                              : Colors.cyanAccent,
                          width: 1,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                  : null,
            ),
            style: const TextStyle(color: GhostDiceTheme.textPrimary),
            onChanged: onNameChanged,
          ),
        ),
      ],
    );
  }
}

class _RulesPanel extends StatelessWidget {
  final GameRules rules;
  final ValueChanged<GameRules> onChanged;

  const _RulesPanel({required this.rules, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GhostDiceTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GhostDiceTheme.border),
      ),
      child: Column(
        children: [
          _RuleToggle(
            label: 'Need a 6 to enter the board',
            value: rules.requireSixToLeaveYard,
            onChanged: (v) =>
                onChanged(rules.copyWith(requireSixToLeaveYard: v)),
          ),
          _divider(),
          _RuleToggle(
            label: 'Three 6s in a row forfeits the turn',
            value: rules.threeSixesForfeitTurn,
            onChanged: (v) =>
                onChanged(rules.copyWith(threeSixesForfeitTurn: v)),
          ),
          _divider(),
          _RuleToggle(
            label: 'Safe squares (no captures on stars)',
            value: rules.useSafeSquares,
            onChanged: (v) => onChanged(rules.copyWith(useSafeSquares: v)),
          ),
          _divider(),
          _RuleToggle(
            label: 'Exact roll required to finish',
            value: rules.requireExactRollToFinish,
            onChanged: (v) =>
                onChanged(rules.copyWith(requireExactRollToFinish: v)),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, color: GhostDiceTheme.border);
}

class _RuleToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RuleToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: GhostDiceTheme.textPrimary, fontSize: 14))),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: GhostDiceTheme.accent,
          ),
        ],
      ),
    );
  }
}


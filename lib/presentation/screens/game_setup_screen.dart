// GameSetupScreen — Tabletop Match Setup companion screen.
// Styled in the dark neon tabletop aesthetic of stitch_ghost_dice_tabletop_companion.
// Features 3D molded pawn piece tokens for player color selection.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_dice/application/controllers/game_controller.dart';
import 'package:ghost_dice/application/controllers/setup_controller.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';
import 'package:ghost_dice/domain/entities/board_position.dart';
import 'package:ghost_dice/domain/entities/game_rules.dart';
import 'package:ghost_dice/domain/entities/piece.dart';
import 'package:ghost_dice/domain/enums/game_enums.dart';
import 'package:ghost_dice/presentation/board/piece_widget.dart';

class GameSetupScreen extends ConsumerWidget {
  const GameSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(setupControllerProvider);
    final controller = ref.read(setupControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF03132B),
      body: Stack(
        children: [
          // Ambient neon background glows
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7AD0FF).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3C90FF).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content with Custom Header
          Column(
            children: [
              _SetupHeader(
                onBackTap: () => context.go('/'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Game Mode Selector
                          const _SetupSectionHeader(
                            title: 'GAME MODE',
                            icon: Icons.sports_esports_rounded,
                          ),
                          const SizedBox(height: 10),
                          _GameModeSelector(
                            isTeamUp: setup.isTeamUp,
                            onSelect: controller.setGameMode,
                          ),
                          const SizedBox(height: 20),

                          // 2. Dice Mode Selector
                          const _SetupSectionHeader(
                            title: 'DICE MODE',
                            icon: Icons.casino_rounded,
                          ),
                          const SizedBox(height: 10),
                          _DiceModeSelector(
                            useInGameDice: setup.rules.useInGameDice,
                            onSelect: controller.setUseInGameDice,
                          ),
                          const SizedBox(height: 20),

                          // 3. Team Up Banner OR Player Count Selector
                          if (!setup.isTeamUp) ...[
                            const _SetupSectionHeader(
                              title: 'NUMBER OF PLAYERS',
                              icon: Icons.people_rounded,
                            ),
                            const SizedBox(height: 10),
                            _PlayerCountSelector(
                              selected: setup.playerCount,
                              onSelect: controller.setPlayerCount,
                            ),
                            const SizedBox(height: 20),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF102038),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFF7BE00)
                                      .withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.handshake_rounded,
                                      color: Color(0xFFF7BE00), size: 24),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '2 vs 2 Team Match: Team 1 (Red & Yellow) vs Team 2 (Green & Blue).\nTeammates never capture each other. When one partner finishes, they keep rolling to move their teammate\'s pieces until all 8 reach home!',
                                      style: TextStyle(
                                        color: Color(0xFFC0C6D6),
                                        fontSize: 11.5,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // 4. Players Section with 3D Molded Pawn Tokens
                          const _SetupSectionHeader(
                            title: 'PLAYERS & PIECES',
                            icon: Icons.person_pin_circle_rounded,
                          ),
                          const SizedBox(height: 10),
                          ...List.generate(setup.playerCount, (i) {
                            final teamBadge = setup.isTeamUp
                                ? (i % 2 == 0 ? 'TEAM 1' : 'TEAM 2')
                                : null;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _PlayerRow(
                                index: i,
                                name: setup.names[i],
                                color: setup.colors[i],
                                teamBadge: teamBadge,
                                error: i < setup.validationErrors.length
                                    ? setup.validationErrors[i]
                                    : null,
                                onNameChanged: (v) => controller.setName(i, v),
                                onColorChanged: setup.isTeamUp
                                    ? (_) {}
                                    : (c) => controller.setColor(i, c),
                                usedColors: setup.colors
                                    .sublist(0, setup.playerCount)
                                    .where((c) => c != setup.colors[i])
                                    .toSet(),
                                allowedColors: setup.playerCount == 3
                                    ? const [
                                        PlayerColor.red,
                                        PlayerColor.green,
                                        PlayerColor.yellow
                                      ]
                                    : PlayerColor.values,
                              ),
                            );
                          }),
                          const SizedBox(height: 20),

                          // 5. House Rules Panel
                          const _SetupSectionHeader(
                            title: 'HOUSE RULES',
                            icon: Icons.gavel_rounded,
                          ),
                          const SizedBox(height: 10),
                          _RulesPanel(
                            rules: setup.rules,
                            onChanged: controller.setRules,
                          ),
                          const SizedBox(height: 28),

                          // 6. Hero Start Game Button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00A9E3),
                                foregroundColor: Colors.white,
                                elevation: 6,
                                shadowColor: const Color(0xFF00A9E3)
                                    .withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: setup.isValid
                                  ? () {
                                      ref
                                          .read(gameControllerProvider.notifier)
                                          .createGame(
                                            playerSetups:
                                                controller.playerSetups,
                                            rules: setup.rules,
                                          );
                                      context.go('/game');
                                    }
                                  : null,
                              icon: const Icon(Icons.play_arrow_rounded, size: 26),
                              label: const Text(
                                'START MATCH',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header matching HomeScreen style
// ---------------------------------------------------------------------------
class _SetupHeader extends StatelessWidget {
  final VoidCallback onBackTap;

  const _SetupHeader({required this.onBackTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C1B34).withValues(alpha: 0.94),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF1C2A43), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBackTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF102038),
                      border: Border.all(
                        color: const Color(0xFF2C4C7C),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF7AD0FF),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TABLETOP SETUP',
                    style: TextStyle(
                      color: Color(0xFFD6E3FF),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Configure players, tokens & house rules',
                    style: TextStyle(
                      color: Color(0xFF7AD0FF),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SetupSectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7AD0FF), size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFC3E8FF),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Game Mode Selector Card
// ---------------------------------------------------------------------------
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
          child: _OptionCard(
            title: 'Classic',
            subtitle: 'Free For All',
            icon: Icons.person_rounded,
            isSelected: !isTeamUp,
            onTap: () => onSelect(false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OptionCard(
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

// ---------------------------------------------------------------------------
// Dice Mode Selector Card
// ---------------------------------------------------------------------------
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
          child: _OptionCard(
            title: 'In-Game Dice',
            subtitle: 'Auto RNG (1–6)',
            icon: Icons.casino_rounded,
            isSelected: useInGameDice,
            onTap: () => onSelect(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OptionCard(
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

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF183866)
                : const Color(0xFF102038),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF7AD0FF)
                  : const Color(0xFF1C2A43),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF00A9E3).withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              const BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF000E26),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF7AD0FF)
                        : const Color(0xFF2C4C7C),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? const Color(0xFF7AD0FF)
                      : const Color(0xFFC0C6D6),
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
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFD6E3FF),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFC0C6D6),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Player Count Selector (2, 3, 4)
// ---------------------------------------------------------------------------
class _PlayerCountSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _PlayerCountSelector({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [2, 3, 4].map((count) {
        final isSelected = selected == count;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(count),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 46,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00A9E3)
                        : const Color(0xFF102038),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF7AD0FF)
                          : const Color(0xFF1C2A43),
                      width: isSelected ? 2.0 : 1.2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: const Color(0xFF00A9E3).withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$count Players',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : const Color(0xFFC0C6D6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Player Row with 3D Molded Pawn Token Piece
// ---------------------------------------------------------------------------
class _PlayerRow extends StatelessWidget {
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
    final playerColor = GhostDiceTheme.playerColor(color);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF102038),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1C2A43), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // 3D Molded Pawn Piece Token Display (Instead of flat color circle)
          if (teamBadge != null)
            _buildPiecePedestal(playerColor, color)
          else
            PopupMenuButton<PlayerColor>(
              onSelected: onColorChanged,
              color: const Color(0xFF102038),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF2C4C7C)),
              ),
              child: _buildPiecePedestal(playerColor, color, isTappable: true),
              itemBuilder: (_) => allowedColors
                  .where((c) => !usedColors.contains(c))
                  .map((c) => PopupMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF000E26),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: GhostDiceTheme.playerColor(c)
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              child: Center(
                                child: PieceWidget(
                                  piece: Piece(
                                    id: 'menu_${c.name}',
                                    playerId: 'menu_${c.name}',
                                    color: c,
                                    pieceIndex: 0,
                                    position: const BoardPosition.yard(),
                                  ),
                                  width: 20,
                                  height: 28,
                                  isHighlighted: false,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              c.name.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFFD6E3FF),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),

          const SizedBox(width: 12),

          // Name Input Field
          Expanded(
            child: TextFormField(
              initialValue: name,
              maxLength: 20,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF000E26),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2C4C7C)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1C2A43)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7AD0FF), width: 1.5),
                ),
                labelText: teamBadge != null
                    ? 'Player ${index + 1} ($teamBadge)'
                    : 'Player ${index + 1}',
                labelStyle: const TextStyle(color: Color(0xFFC0C6D6), fontSize: 12),
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
                                  ? const Color(0xFFF7BE00)
                                  : Colors.cyanAccent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          backgroundColor: teamBadge == 'TEAM 1'
                              ? const Color(0xFFF7BE00).withValues(alpha: 0.15)
                              : Colors.cyanAccent.withValues(alpha: 0.15),
                          side: BorderSide(
                            color: teamBadge == 'TEAM 1'
                                ? const Color(0xFFF7BE00)
                                : Colors.cyanAccent,
                            width: 1,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                    : null,
              ),
              style: const TextStyle(
                color: Color(0xFFD6E3FF),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              onChanged: onNameChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPiecePedestal(Color playerColor, PlayerColor colorEnum,
      {bool isTappable = false}) {
    return Container(
      width: 44,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF000E26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: playerColor.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: playerColor.withValues(alpha: 0.35),
            blurRadius: 8,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieceWidget(
            piece: Piece(
              id: 'setup_$index',
              playerId: 'setup_$index',
              color: colorEnum,
              pieceIndex: index,
              position: const BoardPosition.yard(),
            ),
            width: 24,
            height: 33,
            isHighlighted: false,
          ),
          if (isTappable)
            Positioned(
              bottom: 2,
              right: 2,
              child: Icon(
                Icons.arrow_drop_down,
                color: playerColor,
                size: 14,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// House Rules Panel
// ---------------------------------------------------------------------------
class _RulesPanel extends StatelessWidget {
  final GameRules rules;
  final ValueChanged<GameRules> onChanged;

  const _RulesPanel({required this.rules, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF102038),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1C2A43), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
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
      const Divider(height: 1, color: Color(0xFF1C2A43));
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFD6E3FF),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: const Color(0xFF7AD0FF),
            activeTrackColor: const Color(0xFF00A9E3).withValues(alpha: 0.5),
            inactiveThumbColor: const Color(0xFFC0C6D6),
            inactiveTrackColor: const Color(0xFF000E26),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

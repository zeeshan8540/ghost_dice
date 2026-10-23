// DiceNumberPicker — the six tappable die-face buttons for physical dice input.
// Dynamically sizes and arranges to fit single row or clean 3x2 grid.
import 'package:flutter/material.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';

class DiceNumberPicker extends StatelessWidget {
  final int? selectedValue;
  final bool enabled;
  final ValueChanged<int> onSelect;
  final double buttonSize;

  const DiceNumberPicker({
    super.key,
    this.selectedValue,
    required this.enabled,
    required this.onSelect,
    this.buttonSize = 46.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final singleRowWidth = 6 * buttonSize + 5 * 8;
        final fitInSingleRow = constraints.maxWidth >= singleRowWidth;

        if (fitInSingleRow) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final value = i + 1;
              final isSelected = selectedValue == value;
              return Padding(
                padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
                child: _DieFaceButton(
                  value: value,
                  size: buttonSize,
                  isSelected: isSelected,
                  enabled: enabled,
                  onTap: enabled ? () => onSelect(value) : null,
                ),
              );
            }),
          );
        }

        // Clean 3x2 grid
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final value = i + 1;
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  child: _DieFaceButton(
                    value: value,
                    size: buttonSize,
                    isSelected: selectedValue == value,
                    enabled: enabled,
                    onTap: enabled ? () => onSelect(value) : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final value = i + 4;
                return Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  child: _DieFaceButton(
                    value: value,
                    size: buttonSize,
                    isSelected: selectedValue == value,
                    enabled: enabled,
                    onTap: enabled ? () => onSelect(value) : null,
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _DieFaceButton extends StatefulWidget {
  final int value;
  final double size;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  const _DieFaceButton({
    required this.value,
    required this.size,
    required this.isSelected,
    required this.enabled,
    this.onTap,
  });

  @override
  State<_DieFaceButton> createState() => _DieFaceButtonState();
}

class _DieFaceButtonState extends State<_DieFaceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.90).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = _dieDots(widget.value);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size * 0.22),
            color: widget.isSelected
                ? GhostDiceTheme.accent
                : GhostDiceTheme.surfaceElevated,
            border: Border.all(
              color: widget.isSelected
                  ? GhostDiceTheme.accentGlow
                  : GhostDiceTheme.border,
              width: widget.isSelected ? 2 : 1.2,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: GhostDiceTheme.accent.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : [
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(0, 1.5),
                    ),
                  ],
          ),
          child: Opacity(
            opacity: widget.enabled ? 1.0 : 0.35,
            child: Padding(
              padding: EdgeInsets.all(widget.size * 0.16),
              child: CustomPaint(
                painter: _DotsPainter(
                    dots: dots,
                    color: widget.isSelected
                        ? Colors.white
                        : GhostDiceTheme.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Offset> _dieDots(int value) => switch (value) {
        1 => [const Offset(0.5, 0.5)],
        2 => [const Offset(0.25, 0.25), const Offset(0.75, 0.75)],
        3 => [
            const Offset(0.25, 0.25),
            const Offset(0.5, 0.5),
            const Offset(0.75, 0.75)
          ],
        4 => [
            const Offset(0.25, 0.25),
            const Offset(0.75, 0.25),
            const Offset(0.25, 0.75),
            const Offset(0.75, 0.75)
          ],
        5 => [
            const Offset(0.25, 0.25),
            const Offset(0.75, 0.25),
            const Offset(0.5, 0.5),
            const Offset(0.25, 0.75),
            const Offset(0.75, 0.75)
          ],
        6 => [
            const Offset(0.25, 0.2),
            const Offset(0.75, 0.2),
            const Offset(0.25, 0.5),
            const Offset(0.75, 0.5),
            const Offset(0.25, 0.8),
            const Offset(0.75, 0.8)
          ],
        _ => [],
      };
}

class _DotsPainter extends CustomPainter {
  final List<Offset> dots;
  final Color color;

  const _DotsPainter({required this.dots, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final dot in dots) {
      canvas.drawCircle(
        Offset(dot.dx * size.width, dot.dy * size.height),
        size.width * 0.11,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) =>
      old.dots != dots || old.color != color;
}

// MoveAnnouncement — animated overlay banner for move events.
import 'package:flutter/material.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';

class MoveAnnouncement extends StatefulWidget {
  final String message;
  final VoidCallback? onDismiss;

  const MoveAnnouncement({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  State<MoveAnnouncement> createState() => _MoveAnnouncementState();
}

class _MoveAnnouncementState extends State<MoveAnnouncement>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _opacity =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    ));
    _slide = Tween<Offset>(
            begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                GhostDiceTheme.accent.withOpacity(0.15),
                GhostDiceTheme.surfaceElevated,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: GhostDiceTheme.accent.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: GhostDiceTheme.accentGlow, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: GhostDiceTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

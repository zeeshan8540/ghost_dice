// CapturedPieceFlyBackOverlay — Comical backward flight animation when a piece is killed.
// Plays a funny cartoon sound effect and animates the captured piece traveling backwards
// through all the boxes it covered on the track, back to its start square, and into its yard pocket.

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:ghost_dice/application/state/game_state.dart';
import 'package:ghost_dice/domain/entities/board_config.dart';
import 'package:ghost_dice/domain/entities/board_position.dart';
import 'package:ghost_dice/domain/entities/piece.dart';
import 'package:ghost_dice/infrastructure/services/audio_service.dart';
import 'package:ghost_dice/presentation/board/board_coordinates.dart';
import 'package:ghost_dice/presentation/board/piece_widget.dart';

class CapturedPieceFlyBackOverlay extends StatefulWidget {
  final List<CapturedPieceAnimation> activeCaptures;
  final BoardCoordinates coords;
  final VoidCallback onComplete;

  const CapturedPieceFlyBackOverlay({
    super.key,
    required this.activeCaptures,
    required this.coords,
    required this.onComplete,
  });

  @override
  State<CapturedPieceFlyBackOverlay> createState() =>
      _CapturedPieceFlyBackOverlayState();
}

class _CapturedPieceFlyBackOverlayState
    extends State<CapturedPieceFlyBackOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flightAnimation;

  @override
  void initState() {
    super.initState();

    int maxSteps = 1;
    for (final cap in widget.activeCaptures) {
      final path = BoardConfig.computeBackwardPath(
        caughtPosition: cap.fromPosition,
        color: cap.color,
      );
      if (path.length > maxSteps) maxSteps = path.length;
    }

    final durationMs = (480 + (maxSteps - 1) * 160).clamp(800, 2600);

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    _flightAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    // 1. Play the funny cartoon slide whistle & boing sound immediately!
    SoundEffectService.playFunnyKillSound();

    // 2. Start backward traveling animation
    _controller.forward().then((_) {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coords.cellSize;
    final pieceWidth = (c * 0.68).clamp(18.0, 36.0) + 2.2;
    final pieceHeight = pieceWidth * 1.36;
    final anchorX = pieceWidth * 0.5;
    final anchorY = pieceHeight * 0.88;

    return AnimatedBuilder(
      animation: _flightAnimation,
      builder: (context, _) {
        final t = _flightAnimation.value;

        return Stack(
          clipBehavior: Clip.none,
          children: widget.activeCaptures.map((cap) {
            final backwardPath = BoardConfig.computeBackwardPath(
              caughtPosition: cap.fromPosition,
              color: cap.color,
            );

            final points = backwardPath
                .map((pos) => widget.coords.positionToCenter(
                      pos,
                      cap.color,
                      pieceIndex: cap.pieceIndex,
                    ))
                .toList();

            final numSegments = points.length - 1;
            Offset currentCenter;
            double hopDy = 0.0;
            double segScale = 1.0;

            if (numSegments <= 0) {
              currentCenter = widget.coords.positionToCenter(
                const BoardPosition.yard(),
                cap.color,
                pieceIndex: cap.pieceIndex,
              );
            } else {
              final progress = (t * numSegments).clamp(0.0, numSegments.toDouble());
              final segIndex = progress.floor().clamp(0, numSegments - 1);
              final segT = (progress - segIndex).clamp(0.0, 1.0);

              final p0 = points[segIndex];
              final p1 = points[segIndex + 1];

              final curX = ui.lerpDouble(p0.dx, p1.dx, segT)!;
              final curY = ui.lerpDouble(p0.dy, p1.dy, segT)!;

              // Parabolic hop on each box jump
              hopDy = -math.sin(segT * math.pi) * (c * 0.40);
              segScale = 1.0 + math.sin(segT * math.pi) * 0.16;
              currentCenter = Offset(curX, curY + hopDy);
            }

            // Backward tumble rotation
            final rotation = -t * math.pi * 3.5;

            // Touchdown squish on final yard landing
            double squashX = 1.0;
            double squashY = 1.0;
            if (t > 0.88) {
              final landT = (t - 0.88) / 0.12;
              squashX = 1.0 + math.sin(landT * math.pi) * 0.28;
              squashY = 1.0 - math.sin(landT * math.pi) * 0.20;
            }

            final dummyPiece = Piece(
              id: cap.pieceId,
              playerId: cap.playerId,
              color: cap.color,
              pieceIndex: cap.pieceIndex,
              position: const BoardPosition.yard(),
            );

            return Positioned(
              left: currentCenter.dx - anchorX,
              top: currentCenter.dy - anchorY,
              width: pieceWidth,
              height: pieceHeight,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(segScale * squashX, segScale * squashY)
                  ..rotateZ(rotation),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Flying/tumbling 3D Piece Token
                    PieceWidget(
                      piece: dummyPiece,
                      width: pieceWidth,
                      height: pieceHeight,
                    ),

                    // Funny Dizzy Comic Stars in flight
                    if (t < 0.88)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Transform.rotate(
                          angle: t * math.pi * 6,
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.amberAccent,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}


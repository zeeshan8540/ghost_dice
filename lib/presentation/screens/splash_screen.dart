import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;
  late final Animation<double> _glow;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    _glow = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _ctrl.forward();

    _navTimer = Timer(const Duration(milliseconds: 1900), () {
      if (mounted) {
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _skip() {
    _navTimer?.cancel();
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03132B),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: Stack(
          children: [
            // Ambient neon background glows
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7AD0FF).withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 340,
                height: 340,
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

            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),

                          // 3D Geometric Emblem Card
                          AnimatedBuilder(
                            animation: _glow,
                            builder: (context, child) {
                              return Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF000E26),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFF7AD0FF)
                                        .withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00A9E3)
                                          .withValues(alpha: 0.35 * _glow.value),
                                      blurRadius: 28,
                                      spreadRadius: 2,
                                    ),
                                    const BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 16,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.asset(
                                    'assets/images/ghost_dice_app_icon.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      'assets/images/ghost_dice_app_icon.jpg',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.casino_rounded,
                                        size: 48,
                                        color: Color(0xFF7AD0FF),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Brand Title with Gradient
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFFFFFFF),
                                Color(0xFF7AD0FF),
                                Color(0xFFA9C7FF),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'GHOST DICE',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4.5,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Version Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7AD0FF).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF7AD0FF).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'v1.1 LIVE',
                              style: TextStyle(
                                color: Color(0xFF7AD0FF),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Physical dice. Digital board.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFFC3E8FF),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.wifi_tethering_rounded,
                                size: 14,
                                color: Color(0xFF7AD0FF),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Pass & Play Tabletop Companion',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFC0C6D6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Bottom Status Indicator
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF7AD0FF),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF7AD0FF),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'INITIALIZING TABLETOP SESSION...',
                                style: TextStyle(
                                  color: Color(0xFF7AD0FF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// app.dart — root widget.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghost_dice/core/theme/app_theme.dart';
import 'package:ghost_dice/presentation/providers/app_router.dart';

class GhostDiceApp extends ConsumerWidget {
  const GhostDiceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Ghost Dice',
      debugShowCheckedModeBanner: false,
      theme: GhostDiceTheme.dark,
      routerConfig: appRouter,
    );
  }
}

// App router — all routes defined in one place.
import 'package:go_router/go_router.dart';
import 'package:ghost_dice/presentation/screens/home_screen.dart';
import 'package:ghost_dice/presentation/screens/game_setup_screen.dart';
import 'package:ghost_dice/presentation/screens/game_screen.dart';
import 'package:ghost_dice/presentation/screens/game_summary_screen.dart';
import 'package:ghost_dice/presentation/screens/rules_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/setup',
      builder: (_, __) => const GameSetupScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (_, __) => const GameScreen(),
    ),
    GoRoute(
      path: '/summary',
      builder: (_, __) => const GameSummaryScreen(),
    ),
    GoRoute(
      path: '/rules',
      builder: (_, __) => const RulesScreen(),
    ),
  ],
);

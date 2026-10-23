// Ghost Dice app theme — dark, moody, premium tabletop aesthetic.
import 'package:flutter/material.dart';

class GhostDiceTheme {
  GhostDiceTheme._();

  // Brand colors
  static const Color background = Color(0xFF081830);
  static const Color surface = Color(0xFF10284C);
  static const Color surfaceElevated = Color(0xFF183866);
  static const Color border = Color(0xFF2C4C7C);
  static const Color accent = Color(0xFF0084FF);
  static const Color accentGlow = Color(0xFF40C4FF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0C4DE);
  static const Color textMuted = Color(0xFF6B82A6);

  // Classic Tabletop Ludo colors
  static const Color pieceRed = Color(0xFFE52521);
  static const Color pieceBlue = Color(0xFF0084FF);
  static const Color pieceGreen = Color(0xFF00C853);
  static const Color pieceYellow = Color(0xFFFFC400);

  // Tabletop & Board colors
  static const Color tabletopBlue = Color(0xFF0C2B59);
  static const Color tabletopBlueDark = Color(0xFF071833);
  static const Color dockGold = Color(0xFFFFD54F);
  static const Color dockBlue = Color(0xFF104A8E);
  static const Color boardBase = Color(0xFFFFFFFF);
  static const Color boardLine = Color(0xFFCCD1D9);
  static const Color safeSquare = Color(0xFFF0F4F8);
  static const Color homeRed = Color(0xFFE52521);
  static const Color homeBlue = Color(0xFF0084FF);
  static const Color homeGreen = Color(0xFF00C853);
  static const Color homeYellow = Color(0xFFFFC400);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          onPrimary: Colors.white,
          secondary: accentGlow,
          surface: surface,
          onSurface: textPrimary,
          error: Color(0xFFFF5C5C),
        ),
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -1),
          headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.5),
          headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: textPrimary),
          titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary),
          titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textPrimary),
          bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
          bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
          labelLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
              letterSpacing: 0.5),
        ),
        cardTheme: CardThemeData(
          color: surfaceElevated,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: accentGlow,
            side: const BorderSide(color: accent, width: 1.5),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
          labelStyle: const TextStyle(color: textSecondary),
          hintStyle: const TextStyle(color: textMuted),
        ),
        dividerTheme: const DividerThemeData(color: border, thickness: 1),
      );

  /// Returns the player color for a [PlayerColor] enum value.
  static Color playerColor(color) {
    switch (color.toString()) {
      case 'PlayerColor.red':
        return pieceRed;
      case 'PlayerColor.blue':
        return pieceBlue;
      case 'PlayerColor.green':
        return pieceGreen;
      case 'PlayerColor.yellow':
        return pieceYellow;
      default:
        return textSecondary;
    }
  }

  static Color homeColor(color) {
    switch (color.toString()) {
      case 'PlayerColor.red':
        return homeRed;
      case 'PlayerColor.blue':
        return homeBlue;
      case 'PlayerColor.green':
        return homeGreen;
      case 'PlayerColor.yellow':
        return homeYellow;
      default:
        return surfaceElevated;
    }
  }
}

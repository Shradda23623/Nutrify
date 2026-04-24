import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  // ── Shared constants ─────────────────────────────────────────────────────
  static const _pageBackground = Color(0xFFF7F8FA);
  static const _cardBackground = Colors.white;
  static const _inputFill      = Color(0xFFF0F1F3);
  static const _titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: Colors.black87,
    letterSpacing: 0,
  );

  // ── Light theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: _pageBackground,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: Brightness.light,
      surface: _cardBackground,
      primary: AppColors.green,
    ),

    // AppBar — matches profile screen style
    appBarTheme: const AppBarTheme(
      backgroundColor: _pageBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.black87,
      iconTheme: IconThemeData(color: Colors.black87, size: 22),
      titleTextStyle: _titleStyle,
    ),

    // Cards — white with soft shadow
    cardTheme: CardThemeData(
      color: _cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),

    // Input fields — white fill so they stand out on the gray background
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _inputFill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide:
            const BorderSide(color: AppColors.green, width: 1.5),
      ),
      hintStyle: const TextStyle(
          fontSize: 13,
          color: Colors.black38,
          fontWeight: FontWeight.w400),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.green,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: Colors.black.withOpacity(0.05),
      thickness: 1,
      space: 1,
    ),

    // List tiles
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.green
              : Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.green.withOpacity(0.4)
              : Colors.black12),
    ),

    fontFamily: null, // use device default
  );

  // ── Dark theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0F14),
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: Brightness.dark,
      surface: const Color(0xFF1A1A24),
      primary: AppColors.green,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F0F14),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white70, size: 22),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A24),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF242433),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide:
            const BorderSide(color: AppColors.green, width: 1.5),
      ),
      hintStyle: const TextStyle(
          fontSize: 13,
          color: Colors.white30,
          fontWeight: FontWeight.w400),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
    ),

    dividerTheme: DividerThemeData(
      color: Colors.white.withOpacity(0.06),
      thickness: 1,
      space: 1,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.green
              : Colors.white54),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.green.withOpacity(0.4)
              : Colors.white12),
    ),
  );
}

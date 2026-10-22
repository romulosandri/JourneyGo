import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class JourneyColors {
  static const paper = Color(0xFFF3EEE4);
  static const card = Color(0xFFFFFBF6);
  static const ink = Color(0xFF1E1A16);
  static const inkSoft = Color(0xFF5E564C);
  static const line = Color(0xFFD9D0C3);
  static const terracotta = Color(0xFFC24D2C);
  static const sea = Color(0xFF1C6B64);
  static const night = Color(0xFF24324A);
  static const gold = Color(0xFFA97612);
  static const amber = Color(0xFFC47B2B);
  static const moss = Color(0xFF2C6B3C);
  static const rose = Color(0xFF8C4A6F);
  static const dune = Color(0xFFE7D7C3);
  static const onAccent = Color(0xFFFFF8F3);
}

ThemeData buildJourneyTheme() {
  const outfit = TextStyle(fontFamily: 'Outfit', color: JourneyColors.ink);
  const fraunces = TextStyle(fontFamily: 'Fraunces', color: JourneyColors.ink);
  final textTheme = TextTheme(
    displaySmall: fraunces.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 36,
      height: 1.05,
    ),
    headlineMedium: fraunces.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 30,
      height: 1.1,
    ),
    headlineSmall: fraunces.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 26,
      height: 1.15,
    ),
    titleLarge: fraunces.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 22,
      height: 1.2,
    ),
    titleMedium: outfit.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 16,
      height: 1.3,
    ),
    titleSmall: outfit.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      height: 1.3,
    ),
    bodyLarge: outfit.copyWith(fontSize: 16, height: 1.45),
    bodyMedium: outfit.copyWith(
      fontSize: 14,
      height: 1.4,
      color: JourneyColors.inkSoft,
    ),
    bodySmall: outfit.copyWith(
      fontSize: 12,
      height: 1.35,
      color: JourneyColors.inkSoft,
    ),
    labelLarge: outfit.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 16,
      height: 1.2,
    ),
    labelMedium: outfit.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      letterSpacing: 0.8,
      color: JourneyColors.inkSoft,
    ),
  );

  final scheme =
      ColorScheme.fromSeed(
        seedColor: JourneyColors.terracotta,
        surface: JourneyColors.paper,
      ).copyWith(
        primary: JourneyColors.terracotta,
        onPrimary: JourneyColors.onAccent,
        secondary: JourneyColors.sea,
        onSecondary: JourneyColors.paper,
        surface: JourneyColors.paper,
        onSurface: JourneyColors.ink,
        error: const Color(0xFF9C2F1A),
      );

  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: JourneyColors.line),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: JourneyColors.paper,
    textTheme: textTheme,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: JourneyColors.paper,
      foregroundColor: JourneyColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: textTheme.titleLarge,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: JourneyColors.ink,
        foregroundColor: JourneyColors.onAccent,
        disabledBackgroundColor: JourneyColors.dune,
        disabledForegroundColor: JourneyColors.inkSoft,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textTheme.labelLarge?.copyWith(
          color: JourneyColors.onAccent,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: JourneyColors.ink,
        minimumSize: const Size(44, 44),
        textStyle: textTheme.titleSmall,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: JourneyColors.ink,
      contentTextStyle: outfit.copyWith(color: JourneyColors.onAccent),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: JourneyColors.card,
      labelStyle: textTheme.bodyMedium,
      hintStyle: textTheme.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: JourneyColors.ink, width: 1.4),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: JourneyColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: JourneyColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: JourneyColors.terracotta,
      linearTrackColor: JourneyColors.line,
    ),
  );
}

import 'package:flutter/material.dart';

import 'brand.dart';

ThemeData _build(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  // Neutral "container" tone — kills the blue tint Material gives tonal
  // surfaces (chips, segmented button, tonal buttons).
  final container = isDark ? const Color(0xFF2E2E33) : const Color(0xFFE4E4E7);
  final onContainer = isDark ? Brand.darkInk : Brand.ink;

  final scheme =
      ColorScheme.fromSeed(
        seedColor: Brand.neutralSeed,
        brightness: brightness,
      ).copyWith(
        primary: isDark ? Brand.darkInk : Brand.ink,
        onPrimary: isDark ? const Color(0xFF18181B) : Colors.white,
        secondary: isDark ? Brand.darkInk : Brand.ink,
        surface: isDark ? Brand.darkBg : Brand.lightBg,
        onSurface: isDark ? Brand.darkInk : Brand.ink,
        onSurfaceVariant: isDark ? Brand.darkMuted : Brand.muted,
        primaryContainer: container,
        onPrimaryContainer: onContainer,
        secondaryContainer: container,
        onSecondaryContainer: onContainer,
        tertiaryContainer: container,
        onTertiaryContainer: onContainer,
      );

  final card = isDark ? Brand.darkSurface : Colors.white;
  final field = isDark ? const Color(0xFF26262A) : const Color(0xFFEDEDEF);

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'PlusJakartaSans',
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'PlusJakartaSans',
        color: scheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: card,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: field,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    tabBarTheme: const TabBarThemeData(dividerColor: Colors.transparent),
  );
}

final lightTheme = _build(Brightness.light);
final darkTheme = _build(Brightness.dark);

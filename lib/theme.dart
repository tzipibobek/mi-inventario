import 'package:flutter/material.dart';

import 'models/app_settings.dart';

ThemeData buildTheme(AppSettings settings, Brightness brightness) {
  final isDarkMode = brightness == Brightness.dark;
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: appColors[settings.colorIndex],
        brightness: brightness,
      ).copyWith(
        surface: isDarkMode ? const Color(0xFF191B1E) : const Color(0xFFFFFDFC),
      );
  final baseTheme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: colorScheme.surface,
  );
  return baseTheme.copyWith(
    textTheme: baseTheme.textTheme.copyWith(
      headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: colorScheme.primaryContainer,
      backgroundColor: colorScheme.surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

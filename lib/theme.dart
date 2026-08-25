import 'package:flutter/material.dart';

/// One seed, two schemes.
///
/// The palette is warm rather than the usual blue: this is used outdoors, and
/// a warm ground is easier on the eye at low brightness than a cold one. Dark
/// is not an afterthought — a barn at six in the morning is the actual setting.
const _seed = Color(0xFF0F5545);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        // 48 rather than the default 40. This is tapped with cold hands, in
        // gloves, on a phone held in one hand.
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

/// Colour for a condition, resolved against the current scheme so it stays
/// legible on both grounds.
Color conditionColour(BuildContext context, String condition) {
  final scheme = Theme.of(context).colorScheme;
  return switch (condition) {
    'urgent' => scheme.error,
    'attention' => Brightness.dark == scheme.brightness
        ? const Color(0xFFE8A86A)
        : const Color(0xFF8A4B12),
    _ => scheme.primary,
  };
}

import 'package:flutter/material.dart';

import '../engine/models.dart';

/// Phase/traffic hexes are contract (AGENTS.md) — state colours only,
/// never chrome.
const phaseColors = {
  Phase.menstrual: Color(0xFFC2333D),
  Phase.follicular: Color(0xFF3E8E5A),
  Phase.ovulation: Color(0xFFD9A404),
  Phase.luteal: Color(0xFFB26A2B),
  Phase.pms: Color(0xFF7B4FA6),
};

const trafficColors = {
  Traffic.green: Color(0xFF2E7D32),
  Traffic.yellow: Color(0xFFF9A825),
  Traffic.red: Color(0xFFC62828),
};

/// Warm, fixed Material 3 chrome. Phase and traffic swatches remain separate
/// state indicators; neither is used as a theme seed.
ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF865D50),
    brightness: brightness,
  ).copyWith(
    surface: dark ? const Color(0xFF191716) : const Color(0xFFFFFAF6),
    surfaceContainerLow: dark ? const Color(0xFF231F1D) : const Color(0xFFFBF3ED),
    surfaceContainer: dark ? const Color(0xFF292422) : const Color(0xFFF7EEE7),
    surfaceContainerHigh: dark ? const Color(0xFF332D29) : const Color(0xFFF1E6DD),
    surfaceContainerHighest: dark ? const Color(0xFF3D3530) : const Color(0xFFEADDD3),
  );
  return ThemeData(useMaterial3: true, colorScheme: scheme).copyWith(
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    segmentedButtonTheme: const SegmentedButtonThemeData(
      style: ButtonStyle(padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 6, vertical: 10))),
    ),
  );
}

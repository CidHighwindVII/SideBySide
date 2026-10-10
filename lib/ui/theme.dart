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

/// Approved slate + teal tokens (`new-implementation.md`, Visual direction).
/// Light: cool off-white background, white surfaces, charcoal primary text,
/// slate secondary text, deep teal actions, pale teal emphasis. Dark: graphite
/// surfaces with a lighter teal accent. State colours stay separate.
const lightTokens = (
  background: Color(0xFFF5F7F8),
  surface: Color(0xFFFFFFFF),
  textPrimary: Color(0xFF202B30),
  textSecondary: Color(0xFF596970),
  action: Color(0xFF006B64),
  onAction: Color(0xFFFFFFFF),
  emphasis: Color(0xFFE5F3F0),
);

const darkTokens = (
  background: Color(0xFF141819),
  surface: Color(0xFF1B2124),
  textPrimary: Color(0xFFE7ECEE),
  textSecondary: Color(0xFFA6B2B7),
  action: Color(0xFF63D2C4),
  onAction: Color(0xFF00382F),
  emphasis: Color(0xFF1D3B38),
);

ColorScheme _scheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final t = dark ? darkTokens : lightTokens;
  final surfaceTint = dark ? const Color(0xFF23292C) : const Color(0xFFEDF0F1);
  return ColorScheme(
    brightness: brightness,
    primary: t.action,
    onPrimary: t.onAction,
    primaryContainer: t.emphasis,
    onPrimaryContainer: dark ? const Color(0xFFB9EDE4) : const Color(0xFF00382F),
    secondary: dark ? const Color(0xFF8FCFC6) : const Color(0xFF2F6E66),
    onSecondary: t.onAction,
    secondaryContainer: t.emphasis,
    onSecondaryContainer: dark ? const Color(0xFFB9EDE4) : const Color(0xFF00382F),
    tertiary: t.textSecondary,
    onTertiary: dark ? t.background : Colors.white,
    tertiaryContainer: surfaceTint,
    onTertiaryContainer: t.textPrimary,
    error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E),
    onError: dark ? const Color(0xFF601410) : Colors.white,
    errorContainer: dark ? const Color(0xFF8C1D18) : const Color(0xFFF9DEDC),
    onErrorContainer: dark ? const Color(0xFFFFDAD6) : const Color(0xFF410E0B),
    surface: t.surface,
    onSurface: t.textPrimary,
    surfaceDim: dark ? const Color(0xFF101415) : const Color(0xFFDDE3E5),
    surfaceBright: dark ? const Color(0xFF374043) : const Color(0xFFF7FAFB),
    surfaceContainerLowest:
        dark ? const Color(0xFF0C1011) : const Color(0xFFFCFDFD),
    surfaceContainerLow: dark ? const Color(0xFF191F21) : t.background,
    surfaceContainer: dark ? const Color(0xFF1D2426) : const Color(0xFFF0F3F4),
    surfaceContainerHigh: dark ? const Color(0xFF272E30) : const Color(0xFFEAEFF1),
    surfaceContainerHighest: dark ? const Color(0xFF32393B) : const Color(0xFFE4E9EB),
    onSurfaceVariant: t.textSecondary,
    outline: dark ? const Color(0xFF899399) : const Color(0xFF707A80),
    outlineVariant: dark ? const Color(0xFF3F494D) : const Color(0xFFBFC9CD),
    inverseSurface: dark ? const Color(0xFFE7ECEE) : const Color(0xFF364145),
    onInverseSurface: dark ? const Color(0xFF202B30) : const Color(0xFFECF1F3),
    inversePrimary: dark ? const Color(0xFF006B64) : const Color(0xFF63D2C4),
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: surfaceTint,
  );
}

/// Slate + teal Material 3 chrome. Phase and traffic swatches remain separate
/// state indicators; neither is used as a theme seed.
ThemeData buildTheme(Brightness brightness) {
  final scheme = _scheme(brightness);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surfaceContainerLow,
    textTheme: base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    segmentedButtonTheme: const SegmentedButtonThemeData(
      style: ButtonStyle(padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 6, vertical: 10))),
    ),
  );
}

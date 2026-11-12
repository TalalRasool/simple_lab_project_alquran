import 'package:flutter/material.dart';

/// Brand colors, plus the semantic colors that follow the active theme.
class AppColors {
  const AppColors._();

  /// Splash, footer, and the deepest green surfaces.
  static const Color primaryDark = Color(0xFF083028);

  /// App bars and primary brand green.
  static const Color primary = Color(0xFF0B362D);

  /// Solid buttons such as Log In.
  static const Color primaryButton = Color(0xFF0F4F3F);

  /// Sage green used for icons, selection, and lighter accents.
  static const Color lightGreen = Color(0xFF5A9B87);

  /// Gold mark from the logo.
  static const Color gold = Color(0xFFD6BA74);

  /// Text and icons that sit on the green brand surfaces.
  static const Color white = Color(0xFFFFFFFF);

  /// Required-field asterisks and form errors.
  static const Color error = Color(0xFFC62828);

  static const light = AppPalette(
    background: Color(0xFFF6F6EE),
    surface: Color(0xFFFAF9F4),
    card: Color(0xFFFFFFFF),
    appBar: Color(0xFFF6F6EE),
    input: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1B2A24),
    textSecondary: Color(0xFF6E7F76),
    border: Color(0xFFE4E0D6),
    shadow: Color(0x140B362D),
    icon: primary,
    accent: primaryButton,
  );

  static const dark = AppPalette(
    background: Color(0xFF070908),
    surface: Color(0xFF1A211E),
    card: Color(0xFF121816),
    appBar: Color(0xFF101614),
    input: Color(0xFF1C2622),
    textPrimary: Color(0xFFF4F7F5),
    textSecondary: Color(0xFFA8B4AD),
    border: Color(0xFF2E3B36),
    shadow: Color(0x66000000),
    icon: Color(0xFFE0C98A),
    accent: Color(0xFFE7D3A1),
  );

  static Color background = light.background;
  static Color surface = light.surface;
  static Color card = light.card;
  static Color appBar = light.appBar;
  static Color input = light.input;
  static Color textPrimary = light.textPrimary;
  static Color textSecondary = light.textSecondary;
  static Color border = light.border;
  static Color shadow = light.shadow;
  static Color icon = light.icon;
  static Color accent = light.accent;

  static void apply(ThemeMode mode) {
    final palette = mode == ThemeMode.dark ? dark : light;
    background = palette.background;
    surface = palette.surface;
    card = palette.card;
    appBar = palette.appBar;
    input = palette.input;
    textPrimary = palette.textPrimary;
    textSecondary = palette.textSecondary;
    border = palette.border;
    shadow = palette.shadow;
    icon = palette.icon;
    accent = palette.accent;
  }
}

/// Colors that change between Light and Dark. Brand green and gold do not.
class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.card,
    required this.appBar,
    required this.input,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.shadow,
    required this.icon,
    required this.accent,
  });

  final Color background;
  final Color surface;
  final Color card;
  final Color appBar;
  final Color input;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color shadow;
  final Color icon;
  final Color accent;
}

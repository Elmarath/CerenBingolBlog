import 'package:flutter/material.dart';

import 'app_palette.dart';

/// A theme visitors can pick from the palette menu in the nav bar.
class AppThemePreset {
  const AppThemePreset({required this.id, required this.name, required this.palette});

  /// Saved in the visitor's browser; `web/index.html` reads it too.
  final String id;
  final String name;
  final AppPalette palette;
}

/// Pastels for light themes. Shared, so a subject keeps its colour.
const _lightPastels = {
  'pink': Color(0xFFFFD9E4),
  'peach': Color(0xFFFFE2CC),
  'butter': Color(0xFFFFF0BA),
  'mint': Color(0xFFD2F1DD),
  'sky': Color(0xFFD5E9FA),
  'lilac': Color(0xFFE7DDFA),
  'coral': Color(0xFFFFD6D1),
  'sage': Color(0xFFE1EDD2),
};

/// Pink and cream with chocolate outlines, after pusheen.com. The default.
const strawberryMilk = AppThemePreset(
  id: 'strawberry-milk',
  name: 'Strawberry Milk',
  palette: AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFFFF7F3),
    pattern: Color(0x17E8668B),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFFDEDEE),
    border: Color(0xFFF0D9D5),
    outline: Color(0xFF4A2F27),
    textPrimary: Color(0xFF4A2F27),
    textSecondary: Color(0xFF6E554C),
    textMuted: Color(0xFF8C7067),
    accent: Color(0xFFE8668B),
    accentSoft: Color(0xFFFFDDE7),
    button: Color(0xFF4A2F27),
    onButton: Color(0xFFFFF7F3),
    link: Color(0xFFC2416A),
    done: Color(0xFF3E9F6E),
    doing: Color(0xFFE0912B),
    pastels: _lightPastels,
    onPastel: Color(0xFF4A2F27),
  ),
);

/// Soft green tea and oat milk.
const matchaLatte = AppThemePreset(
  id: 'matcha-latte',
  name: 'Matcha Latte',
  palette: AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF5F8EE),
    pattern: Color(0x1C6BA368),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE8F1DC),
    border: Color(0xFFDCE6CF),
    outline: Color(0xFF35422F),
    textPrimary: Color(0xFF35422F),
    textSecondary: Color(0xFF56634F),
    textMuted: Color(0xFF737F6B),
    accent: Color(0xFF6BA368),
    accentSoft: Color(0xFFDCEFD6),
    button: Color(0xFF35422F),
    onButton: Color(0xFFF5F8EE),
    link: Color(0xFF3F7D45),
    done: Color(0xFF3E9F6E),
    doing: Color(0xFFD98E2B),
    pastels: _lightPastels,
    onPastel: Color(0xFF35422F),
  ),
);

/// Late-night studying: deep plum with pink highlights.
const midnightKitty = AppThemePreset(
  id: 'midnight-kitty',
  name: 'Midnight Kitty',
  palette: AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF1C1727),
    pattern: Color(0x14FF8FB3),
    surface: Color(0xFF261F35),
    surfaceAlt: Color(0xFF2F2742),
    border: Color(0xFF3D3454),
    outline: Color(0xFF0B0812),
    textPrimary: Color(0xFFF8ECF2),
    textSecondary: Color(0xFFD3C3D6),
    textMuted: Color(0xFFA593AE),
    accent: Color(0xFFFF8FB3),
    accentSoft: Color(0xFF4A2A40),
    button: Color(0xFFFF8FB3),
    onButton: Color(0xFF2A0F1D),
    link: Color(0xFFFF9EBF),
    done: Color(0xFF6FD3A2),
    doing: Color(0xFFF4B860),
    pastels: {
      'pink': Color(0xFF5B3950),
      'peach': Color(0xFF5C4434),
      'butter': Color(0xFF595033),
      'mint': Color(0xFF31513F),
      'sky': Color(0xFF2F4A63),
      'lilac': Color(0xFF453C68),
      'coral': Color(0xFF5E3A39),
      'sage': Color(0xFF43503A),
    },
    onPastel: Color(0xFFF8ECF2),
  ),
);

/// Every theme in the palette menu, default first. Add a preset here to offer it.
const appThemes = [strawberryMilk, matchaLatte, midnightKitty];

/// What visitors who prefer a dark screen see until they pick a theme.
const darkTheme = midnightKitty;

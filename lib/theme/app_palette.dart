import 'package:flutter/material.dart';

/// Every colour the site uses, in one place.
///
/// Widgets read it with `context.palette`. To make a new look, add an
/// [AppPalette] to `app_themes.dart`; nothing else needs to change.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.pattern,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentSoft,
    required this.button,
    required this.onButton,
    required this.link,
    required this.done,
    required this.doing,
    required this.pastels,
    required this.onPastel,
  });

  final Brightness brightness;

  /// Page background.
  final Color background;

  /// The faint paw prints scattered over the background.
  final Color pattern;

  /// Cards and the nav bar.
  final Color surface;

  /// Tinted panels: the roadmap board, the footer, hovered things.
  final Color surfaceAlt;

  /// Soft separators.
  final Color border;

  /// The chunky sticker outlines and their offset shadows.
  final Color outline;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Progress, paw prints, highlights.
  final Color accent;

  /// A pale wash of [accent]: selected pills, the hero blob.
  final Color accentSoft;

  /// Filled buttons.
  final Color button;
  final Color onButton;

  /// Links in text.
  final Color link;

  /// Finished topics and subjects.
  final Color done;

  /// Topics and subjects in progress.
  final Color doing;

  /// Pastel fills by name (see `pastelNames` in `content/models.dart`).
  final Map<String, Color> pastels;

  /// Text and outlines on a pastel fill.
  final Color onPastel;

  bool get isDark => brightness == Brightness.dark;

  Color pastel(String name) => pastels[name] ?? pastels.values.first;

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? background,
    Color? pattern,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? outline,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentSoft,
    Color? button,
    Color? onButton,
    Color? link,
    Color? done,
    Color? doing,
    Map<String, Color>? pastels,
    Color? onPastel,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      pattern: pattern ?? this.pattern,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      outline: outline ?? this.outline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      button: button ?? this.button,
      onButton: onButton ?? this.onButton,
      link: link ?? this.link,
      done: done ?? this.done,
      doing: doing ?? this.doing,
      pastels: pastels ?? this.pastels,
      onPastel: onPastel ?? this.onPastel,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: l(background, other.background),
      pattern: l(pattern, other.pattern),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      border: l(border, other.border),
      outline: l(outline, other.outline),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      button: l(button, other.button),
      onButton: l(onButton, other.onButton),
      link: l(link, other.link),
      done: l(done, other.done),
      doing: l(doing, other.doing),
      pastels: {for (final e in pastels.entries) e.key: l(e.value, other.pastels[e.key] ?? e.value)},
      onPastel: l(onPastel, other.onPastel),
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

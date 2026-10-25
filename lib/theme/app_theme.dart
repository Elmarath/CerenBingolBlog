import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';
import 'tokens.dart';

/// Builds a Material [ThemeData] from an [AppPalette].
///
/// Fonts: Fredoka (round and bouncy) for headings and buttons, Nunito for
/// reading, Caveat for little handwritten notes.
abstract final class AppTheme {
  /// Tests turn this off: they can't download fonts.
  static bool useGoogleFonts = true;

  /// The handwritten font, for notes like "you've got this!".
  static TextStyle hand({double fontSize = 24, Color? color}) {
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: color, height: 1.1);
    return useGoogleFonts ? GoogleFonts.caveat(textStyle: style) : style;
  }

  /// Monospace, for code blocks.
  static TextStyle code({double fontSize = 14, Color? color}) {
    final style = TextStyle(fontSize: fontSize, height: 1.6, color: color);
    return useGoogleFonts ? GoogleFonts.robotoMono(textStyle: style) : style.copyWith(fontFamily: 'monospace');
  }

  /// Fetches the fonts on the first screen before the first frame, so text
  /// never shows (and gets measured) in a fallback font first. Gives up after
  /// a couple of seconds offline.
  static Future<void> preloadFonts() async {
    if (!useGoogleFonts) return;
    GoogleFonts.nunito(fontWeight: FontWeight.w400);
    GoogleFonts.nunito(fontWeight: FontWeight.w700);
    GoogleFonts.fredoka(fontWeight: FontWeight.w600);
    try {
      await GoogleFonts.pendingFonts().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  static ThemeData build(AppPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.button,
      onPrimary: p.onButton,
      secondary: p.accent,
      onSecondary: p.onButton,
      error: const Color(0xFFD9534F),
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceAlt,
      surfaceContainerHighest: p.surfaceAlt,
      outline: p.outline,
      outlineVariant: p.border,
    );

    final base = ThemeData(brightness: p.brightness, useMaterial3: true);
    final text = _textTheme(base.textTheme, p);
    final buttonText = WidgetStatePropertyAll<TextStyle?>(text.titleMedium?.copyWith(fontSize: 16));
    const buttonPadding = WidgetStatePropertyAll<EdgeInsetsGeometry>(
      EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      textTheme: text,
      dividerColor: p.border,
      hoverColor: p.accent.withValues(alpha: 0.08),
      focusColor: p.accent.withValues(alpha: 0.18),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accent.withValues(alpha: 0.3),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1.5, space: 1.5),
      iconTheme: IconThemeData(color: p.textSecondary, size: 20),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          padding: buttonPadding,
          textStyle: buttonText,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return Color.lerp(p.button, p.accent, 0.18);
            return p.button;
          }),
          foregroundColor: WidgetStatePropertyAll(p.onButton),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          padding: buttonPadding,
          textStyle: buttonText,
          foregroundColor: WidgetStatePropertyAll(p.textPrimary),
          side: WidgetStatePropertyAll(BorderSide(color: p.outline, width: Strokes.outline)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered) ? p.accentSoft : p.surface,
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          foregroundColor: WidgetStatePropertyAll(p.link),
          overlayColor: WidgetStatePropertyAll(p.accent.withValues(alpha: 0.08)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered) ? p.textPrimary : p.textSecondary,
          ),
          overlayColor: WidgetStatePropertyAll(p.accent.withValues(alpha: 0.12)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
        selectedColor: p.textPrimary,
        selectedTileColor: p.accentSoft,
        shape: const StadiumBorder(),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.mdAll,
          side: BorderSide(color: p.outline, width: Strokes.outline),
        ),
        textStyle: text.bodyMedium?.copyWith(color: p.textPrimary),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: p.textPrimary, borderRadius: Radii.smAll),
        textStyle: text.labelMedium?.copyWith(color: p.background),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        waitDuration: const Duration(milliseconds: 350),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(7),
        radius: const Radius.circular(7),
        thumbColor: WidgetStatePropertyAll(p.accent.withValues(alpha: 0.45)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
      extensions: [p],
    );
  }

  static TextTheme _textTheme(TextTheme base, AppPalette p) {
    final body = useGoogleFonts ? GoogleFonts.nunitoTextTheme(base) : base;
    TextStyle? round(TextStyle? s, double size, {double height = 1.15}) {
      final style = s?.copyWith(
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: height,
        letterSpacing: 0,
        color: p.textPrimary,
      );
      return useGoogleFonts ? GoogleFonts.fredoka(textStyle: style) : style;
    }

    return body.copyWith(
      displayLarge: round(body.displayLarge, 58, height: 1.05),
      displayMedium: round(body.displayMedium, 46, height: 1.08),
      displaySmall: round(body.displaySmall, 36, height: 1.1),
      headlineLarge: round(body.headlineLarge, 31),
      headlineMedium: round(body.headlineMedium, 25),
      headlineSmall: round(body.headlineSmall, 21),
      titleLarge: round(body.titleLarge, 19, height: 1.25),
      titleMedium: round(body.titleMedium, 16.5, height: 1.25),
      titleSmall: body.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: p.textPrimary),
      bodyLarge: body.bodyLarge?.copyWith(fontSize: 17, height: 1.7, color: p.textSecondary),
      bodyMedium: body.bodyMedium?.copyWith(fontSize: 15, height: 1.6, color: p.textSecondary),
      bodySmall: body.bodySmall?.copyWith(fontSize: 13, height: 1.5, color: p.textMuted),
      labelLarge: body.labelLarge?.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.textPrimary),
      labelMedium: body.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: p.textSecondary),
      labelSmall: body.labelSmall?.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
        color: p.textMuted,
      ),
    );
  }
}

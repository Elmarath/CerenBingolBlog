import 'package:flutter/widgets.dart';

/// Spacing scale. Use these instead of raw numbers so the rhythm stays consistent.
abstract final class Insets {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Vertical space between page sections.
  static const double section = 80;
}

abstract final class Radii {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 30;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

/// The sticker look: chunky outlines and a solid offset shadow.
abstract final class Strokes {
  static const double outline = 2;
  static const double shadow = 4;
}

abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 420);
  static const Curve curve = Curves.easeOutCubic;
}

/// Max content widths.
abstract final class ContentWidths {
  /// Home, roadmap, blog list, profile.
  static const double page = 1160;

  /// Posts: a comfortable line length for reading.
  static const double reading = 760;

  /// Subject pages: a little wider than a post, for the checklist.
  static const double subject = 880;
}

/// Width breakpoints.
enum ScreenSize {
  compact,
  medium,
  expanded;

  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 720) return ScreenSize.compact;
    if (width < 1100) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  bool get isCompact => this == ScreenSize.compact;
  bool get isExpanded => this == ScreenSize.expanded;

  /// Horizontal page padding.
  double get gutter => switch (this) {
    ScreenSize.compact => 16,
    ScreenSize.medium => 24,
    ScreenSize.expanded => 32,
  };
}

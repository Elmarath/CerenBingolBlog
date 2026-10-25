import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/tokens.dart';
import '../cats/cat_painter.dart';

/// A rounded rectangle with two cat ears on top, after the cat-head panels
/// on nekoatsume.com. The ears stick out [earHeight] above the rectangle.
class CatEarsBorder extends ShapeBorder {
  const CatEarsBorder({
    this.side = BorderSide.none,
    this.radius = Radii.xl,
    this.earHeight = 28,
    this.earWidth = 58,
    this.earInset = 26,
    this.innerEarColor,
  });

  final BorderSide side;
  final double radius;
  final double earHeight;
  final double earWidth;

  /// Distance from the card's side to the ear.
  final double earInset;
  final Color? innerEarColor;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  /// (base start, tip, base end) of each ear.
  List<(Offset, Offset, Offset)> _ears(Rect rect) {
    final base = rect.top + 12;
    final tipY = rect.top - earHeight;
    final left = rect.left + earInset;
    final right = rect.right - earInset;
    return [
      (Offset(left, base), Offset(left + earWidth * 0.18, tipY), Offset(left + earWidth, base)),
      (Offset(right - earWidth, base), Offset(right - earWidth * 0.18, tipY), Offset(right, base)),
    ];
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final body = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final ears = Path();
    for (final (a, tip, b) in _ears(rect)) {
      ears.addPath(roundedTriangle(a, tip, b, 9), Offset.zero);
    }
    return Path.combine(PathOperation.union, body, ears);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect.deflate(side.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (innerEarColor != null) {
      final paint = Paint()..color = innerEarColor!;
      for (final (a, tip, b) in _ears(rect)) {
        // The same triangle, shrunk towards a point just above the card's edge.
        final center = Offset((a.dx + tip.dx + b.dx) / 3, rect.top - 8);
        Offset shrink(Offset o) => center + (o - center) * 0.55;
        canvas.drawPath(roundedTriangle(shrink(a), shrink(tip), shrink(b), 5), paint);
      }
    }
    if (side.style == BorderStyle.solid && side.width > 0) {
      canvas.drawPath(getOuterPath(rect), side.toPaint()..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  ShapeBorder scale(double t) => CatEarsBorder(
    side: side.scale(t),
    radius: radius * t,
    earHeight: earHeight * t,
    earWidth: earWidth * t,
    earInset: earInset * t,
    innerEarColor: innerEarColor,
  );
}

/// A sticker card with cat ears, for the things that matter most on a page.
class CatEarsCard extends StatelessWidget {
  const CatEarsCard({super.key, required this.child, this.color, this.padding = const EdgeInsets.all(Insets.lg)});

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;

  static const earHeight = 28.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: earHeight),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: color ?? p.surface,
          shape: CatEarsBorder(
            side: BorderSide(color: p.outline, width: Strokes.outline),
            innerEarColor: CatColors.pink.withValues(alpha: p.isDark ? 0.55 : 0.9),
          ),
          shadows: [BoxShadow(color: p.outline, offset: const Offset(Strokes.shadow, Strokes.shadow))],
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

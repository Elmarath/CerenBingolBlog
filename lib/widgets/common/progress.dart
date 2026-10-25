import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/tokens.dart';
import '../cats/cat_painter.dart';
import '../cats/cats.dart';

/// A ring that fills clockwise from the top, with [child] in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.size,
    this.stroke = 5,
    this.color,
    this.trackColor,
    this.child,
  });

  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Color? trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: Motion.slow * 2,
      curve: Motion.curve,
      builder: (context, v, child) => CustomPaint(
        painter: _RingPainter(value: v, stroke: stroke, color: color ?? p.accent, track: trackColor ?? p.border),
        child: child,
      ),
      child: SizedBox.square(dimension: size, child: Center(child: child)),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.stroke, required this.color, required this.track});

  final double value;
  final double stroke;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = track);
    if (value > 0) canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color || oldDelegate.track != track || oldDelegate.stroke != stroke;
}

/// A rounded progress bar; tall ones carry a little paw at the front.
class PawProgressBar extends StatelessWidget {
  const PawProgressBar({super.key, required this.value, this.height = 14, this.color});

  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final thick = height >= 12;
    return Semantics(
      value: '${(value * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: Motion.slow * 2,
        curve: Motion.curve,
        builder: (context, t, _) => Container(
          height: height,
          padding: EdgeInsets.all(thick ? 2.5 : 1.5),
          alignment: Alignment.centerLeft,
          decoration: ShapeDecoration(
            color: p.surfaceAlt,
            shape: StadiumBorder(side: BorderSide(color: p.outline, width: thick ? Strokes.outline : 1.5)),
          ),
          child: t <= 0
              ? null
              : FractionallySizedBox(
                  widthFactor: t,
                  child: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 3),
                    decoration: ShapeDecoration(color: color ?? p.accent, shape: const StadiumBorder()),
                    child: height >= 14 && t > 0.08
                        ? Paw(size: height - 7, color: Colors.white.withValues(alpha: 0.9), angle: math.pi / 2)
                        : null,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Faint paw prints scattered over a page's background.
class PawPattern extends StatelessWidget {
  const PawPattern({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: CustomPaint(painter: _PawPatternPainter(context.palette.pattern), size: Size.infinite));
  }
}

class _PawPatternPainter extends CustomPainter {
  _PawPatternPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dx = 132.0;
    const dy = 118.0;
    const pawSize = 20.0;
    final paint = Paint()..color = color;
    var row = 0;
    for (var y = 40.0; y < size.height + dy; y += dy, row++) {
      var col = 0;
      for (var x = (row.isOdd ? dx / 2 : 0.0) + 24; x < size.width + dx; x += dx, col++) {
        // Same scatter on every visit: the angle comes from the grid position.
        final angle = 0.12 * ((row * 7 + col * 13) % 10 - 5);
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(angle);
        canvas.drawPath(pawPath(const Rect.fromLTWH(-pawSize / 2, -pawSize / 2, pawSize, pawSize)), paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_PawPatternPainter oldDelegate) => oldDelegate.color != color;
}

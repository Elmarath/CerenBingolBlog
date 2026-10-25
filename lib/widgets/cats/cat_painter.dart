import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The mascot's colours. The cat looks the same in every theme.
abstract final class CatColors {
  static const fur = Color(0xFFFFE0BD);
  static const stripes = Color(0xFFF2AE76);
  static const pink = Color(0xFFFFB6CA);
  static const nose = Color(0xFFF08AA8);
  static const outline = Color(0xFF4A2F27);
  static const belly = Color(0xFFFFF6EB);
  static const tube = Color(0xFF7CC6C0);
  static const steel = Color(0xFFE3E9EF);
  static const bookPink = Color(0xFFFFC2D4);
  static const bookMint = Color(0xFFBFE8CF);
}

enum CatMood { happy, sleepy, wink, surprised }

/// How shut the eyes are (0 open … 1 shut) at point [t] of a 0 → 1 loop:
/// a quick double blink near the end of each loop.
double blinkAt(double t) {
  double bump(double at) => (1 - (t - at).abs() / 0.025).clamp(0.0, 1.0);
  return math.max(bump(0.9), bump(0.955));
}

/// A paw print filling [rect]: one bean-shaped pad and four toes, toes up.
Path pawPath(Rect rect) {
  final path = Path()
    ..moveTo(50, 46)
    ..cubicTo(64, 46, 80, 62, 78, 74)
    ..cubicTo(76, 86, 62, 87, 50, 82)
    ..cubicTo(38, 87, 24, 86, 22, 74)
    ..cubicTo(20, 62, 36, 46, 50, 46)
    ..close()
    ..addOval(Rect.fromCenter(center: const Offset(19, 42), width: 18, height: 24))
    ..addOval(Rect.fromCenter(center: const Offset(37, 22), width: 19, height: 25))
    ..addOval(Rect.fromCenter(center: const Offset(63, 22), width: 19, height: 25))
    ..addOval(Rect.fromCenter(center: const Offset(81, 42), width: 18, height: 24));
  final s = rect.width / 100;
  return path.transform(Matrix4.diagonal3Values(s, s, 1).storage).shift(rect.topLeft);
}

Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

// The head, in a 100 × 100 box: a wide oval with two big rounded ears.
Path _ear({required bool right}) {
  double x(double v) => right ? 100 - v : v;
  return Path()
    ..moveTo(x(12), 56)
    ..lineTo(x(14), 17)
    ..quadraticBezierTo(x(15), 6, x(24), 11)
    ..lineTo(x(48), 30)
    ..close();
}

Path _innerEar({required bool right}) {
  double x(double v) => right ? 100 - v : v;
  return Path()
    ..moveTo(x(19.5), 37)
    ..lineTo(x(20.5), 21)
    ..quadraticBezierTo(x(21.5), 15.5, x(26.5), 18.5)
    ..lineTo(x(38), 28)
    ..close();
}

final Path _silhouette = Path.combine(
  PathOperation.union,
  Path()..addOval(const Rect.fromLTRB(8, 24, 92, 92)),
  Path()
    ..addPath(_ear(right: false), Offset.zero)
    ..addPath(_ear(right: true), Offset.zero),
);

final Path _innerEars = Path()
  ..addPath(_innerEar(right: false), Offset.zero)
  ..addPath(_innerEar(right: true), Offset.zero);

Path _stripes({double dy = 0}) => Path()
  ..moveTo(50, 27 + dy)
  ..lineTo(50, 35 + dy)
  ..moveTo(41.5, 29 + dy)
  ..lineTo(43, 35.5 + dy)
  ..moveTo(58.5, 29 + dy)
  ..lineTo(57, 35.5 + dy);

/// Head and ears in a 100 × 100 box. [line] is the outline width in box units.
void paintCatHead(Canvas canvas, {required double line, Color outline = CatColors.outline, bool stripes = true}) {
  canvas.drawPath(_silhouette, Paint()..color = CatColors.fur);
  canvas.drawPath(_innerEars, Paint()..color = CatColors.pink);
  if (stripes) canvas.drawPath(_stripes(), _stroke(CatColors.stripes, 3.4));
  canvas.drawPath(_silhouette, _stroke(outline, line));
}

/// The face on a head drawn by [paintCatHead]: eyes, glasses, nose, the ω
/// mouth, whiskers and blush. [blink] shuts open eyes (0 open … 1 shut).
void paintCatFace(
  Canvas canvas, {
  required double line,
  CatMood mood = CatMood.happy,
  bool glasses = false,
  double blink = 0,
  Color outline = CatColors.outline,
}) {
  final ink = Paint()..color = outline;
  final pen = _stroke(outline, line * 0.8);

  final blush = Paint()..color = CatColors.pink.withValues(alpha: 0.65);
  canvas.drawOval(Rect.fromCenter(center: const Offset(22, 72), width: 12, height: 7), blush);
  canvas.drawOval(Rect.fromCenter(center: const Offset(78, 72), width: 12, height: 7), blush);

  const left = Offset(34, 60);
  const right = Offset(66, 60);

  // ^ for a happy closed eye, ‿ for a sleeping one.
  void arcEye(Offset c, {required bool smile}) {
    final y0 = c.dy + (smile ? 2 : -1);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 5.5, y0)
        ..quadraticBezierTo(c.dx, c.dy + (smile ? -5 : 4.5), c.dx + 5.5, y0),
      pen,
    );
  }

  void openEye(Offset c, {double size = 1}) {
    final height = 12.5 * size * (1 - blink);
    if (height < 2.5) {
      arcEye(c, smile: false);
      return;
    }
    canvas.drawOval(Rect.fromCenter(center: c, width: 10 * size, height: height), ink);
    if (height > 7) canvas.drawCircle(c + Offset(-1.8 * size, -2.6 * size), 2.2 * size, Paint()..color = Colors.white);
  }

  switch (mood) {
    case CatMood.happy:
      openEye(left);
      openEye(right);
    case CatMood.sleepy:
      arcEye(left, smile: false);
      arcEye(right, smile: false);
    case CatMood.wink:
      openEye(left);
      arcEye(right, smile: true);
    case CatMood.surprised:
      openEye(left, size: 1.2);
      openEye(right, size: 1.2);
  }

  if (glasses) {
    final frame = _stroke(outline, line * 0.75);
    canvas.drawCircle(left, 11, frame);
    canvas.drawCircle(right, 11, frame);
    canvas.drawPath(
      Path()
        ..moveTo(45, 58.5)
        ..quadraticBezierTo(50, 55, 55, 58.5),
      frame,
    );
  }

  final nose = Path()
    ..moveTo(46, 66.5)
    ..quadraticBezierTo(50, 64.5, 54, 66.5)
    ..quadraticBezierTo(52, 70.5, 50, 70.8)
    ..quadraticBezierTo(48, 70.5, 46, 66.5)
    ..close();
  canvas.drawPath(nose, Paint()..color = CatColors.nose);

  if (mood == CatMood.surprised) {
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 77), width: 6, height: 7), pen);
  } else {
    canvas.drawPath(
      Path()
        ..moveTo(50, 70.5)
        ..quadraticBezierTo(48.5, 76.5, 44, 75)
        ..moveTo(50, 70.5)
        ..quadraticBezierTo(51.5, 76.5, 56, 75),
      pen,
    );
  }

  final whisker = _stroke(outline.withValues(alpha: 0.7), line * 0.45);
  const whiskers = [
    (Offset(20, 67), Offset(4, 63)),
    (Offset(20, 72), Offset(5, 74.5)),
    (Offset(80, 67), Offset(96, 63)),
    (Offset(80, 72), Offset(95, 74.5)),
  ];
  for (final (from, to) in whiskers) {
    canvas.drawLine(from, to, whisker);
  }
}

/// Outline width in box units that stays at least [minPixels] on screen.
double _lineFor(double scale, {double base = 2.8, double minPixels = 1.5}) => math.max(base, minPixels / scale);

/// A cat's head, centred in its canvas.
class CatFacePainter extends CustomPainter {
  CatFacePainter({
    this.mood = CatMood.happy,
    this.glasses = false,
    this.stripes = true,
    this.blink,
    this.outline = CatColors.outline,
  }) : super(repaint: blink);

  final CatMood mood;
  final bool glasses;
  final bool stripes;

  /// Drives blinking (0 open … 1 shut); null keeps the eyes open.
  final Animation<double>? blink;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate((size.width - 100 * scale) / 2, (size.height - 100 * scale) / 2);
    canvas.scale(scale);
    final line = _lineFor(scale);
    paintCatHead(canvas, line: line, outline: outline, stripes: stripes);
    paintCatFace(canvas, line: line, mood: mood, glasses: glasses, blink: blink?.value ?? 0, outline: outline);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CatFacePainter oldDelegate) =>
      oldDelegate.mood != mood ||
      oldDelegate.glasses != glasses ||
      oldDelegate.stripes != stripes ||
      oldDelegate.outline != outline ||
      oldDelegate.blink != blink;
}

/// Just the face (no head outline or ears), for a round avatar.
class CatAvatarFacePainter extends CustomPainter {
  CatAvatarFacePainter({required this.outline});

  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate((size.width - 100 * scale) / 2, (size.height - 100 * scale) / 2);
    canvas.scale(scale);
    // The face sits a little lower on a head; lift it to the circle's middle.
    canvas.translate(0, -6);
    canvas.drawPath(_stripes(dy: -6), _stroke(CatColors.stripes, 3.4));
    paintCatFace(canvas, line: _lineFor(scale), glasses: true, outline: outline);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CatAvatarFacePainter oldDelegate) => oldDelegate.outline != outline;
}

/// The home page mascot: a cat with glasses and a stethoscope, sitting on a
/// pile of books. Blinks and swishes its tail as [clock] loops from 0 to 1.
class StudyCatPainter extends CustomPainter {
  StudyCatPainter({required this.clock, this.outline = CatColors.outline}) : super(repaint: clock);

  final Animation<double> clock;
  final Color outline;

  /// The drawing's own coordinate box; it's scaled to fit the canvas.
  static const box = Size(200, 250);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / box.width, size.height / box.height);
    canvas.save();
    canvas.translate((size.width - box.width * scale) / 2, (size.height - box.height * scale) / 2);
    canvas.scale(scale);
    final line = _lineFor(scale, base: 3.2);
    final t = clock.value;
    final swish = math.sin(t * 2 * math.pi);

    _book(canvas, const Rect.fromLTWH(14, 222, 172, 22), CatColors.bookMint, line);
    _book(canvas, const Rect.fromLTWH(30, 200, 140, 22), CatColors.bookPink, line);

    final tail = Path()
      ..moveTo(140, 196)
      ..cubicTo(178, 204, 196 + swish * 2, 166, 180 + swish * 7, 140)
      ..quadraticBezierTo(173 + swish * 9, 128, 182 + swish * 10, 120);
    canvas.drawPath(tail, _stroke(outline, 13 + line * 2));
    canvas.drawPath(tail, _stroke(CatColors.fur, 13));

    final body = Path()
      ..moveTo(100, 100)
      ..cubicTo(140, 100, 156, 150, 152, 182)
      ..quadraticBezierTo(150, 204, 100, 204)
      ..quadraticBezierTo(50, 204, 48, 182)
      ..cubicTo(44, 150, 60, 100, 100, 100)
      ..close();
    canvas.drawPath(body, Paint()..color = CatColors.fur);
    canvas.drawOval(Rect.fromCenter(center: const Offset(100, 168), width: 56, height: 58), Paint()..color = CatColors.belly);
    canvas.drawPath(body, _stroke(outline, line));

    // The stethoscope hangs from behind the head.
    final tube = Path()
      ..moveTo(74, 108)
      ..cubicTo(70, 150, 88, 166, 100, 166)
      ..cubicTo(112, 166, 130, 150, 126, 108)
      ..moveTo(100, 166)
      ..lineTo(100, 176);
    canvas.drawPath(tube, _stroke(outline, 4.5 + line * 1.4));
    canvas.drawPath(tube, _stroke(CatColors.tube, 4.5));
    canvas.drawCircle(const Offset(100, 183), 9, Paint()..color = CatColors.steel);
    canvas.drawCircle(const Offset(100, 183), 9, _stroke(outline, line * 0.9));
    canvas.drawCircle(const Offset(100, 183), 4, Paint()..color = const Color(0xFFC7D1DB));

    for (final x in const [80.0, 120.0]) {
      final paw = Rect.fromCenter(center: Offset(x, 202), width: 30, height: 16);
      canvas.drawOval(paw, Paint()..color = CatColors.fur);
      canvas.drawOval(paw, _stroke(outline, line));
      canvas.drawLine(Offset(x - 4, 199), Offset(x - 4, 205), _stroke(outline, line * 0.6));
      canvas.drawLine(Offset(x + 4, 199), Offset(x + 4, 205), _stroke(outline, line * 0.6));
    }

    canvas.save();
    canvas.translate(40, 8);
    canvas.scale(1.2);
    paintCatHead(canvas, line: line / 1.2, outline: outline);
    paintCatFace(canvas, line: line / 1.2, glasses: true, blink: blinkAt(t), outline: outline);
    canvas.restore();

    canvas.restore();
  }

  void _book(Canvas canvas, Rect r, Color cover, double line) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(6));
    canvas.drawRRect(rr, Paint()..color = cover);
    final pages = RRect.fromLTRBR(r.left + 14, r.top + 5, r.right - 5, r.bottom - 5, const Radius.circular(3));
    canvas.drawRRect(pages, Paint()..color = Colors.white);
    final y = pages.center.dy;
    canvas.drawLine(Offset(pages.left + 6, y), Offset(pages.right - 6, y), _stroke(outline.withValues(alpha: 0.25), 1.2));
    canvas.drawRRect(pages, _stroke(outline, line * 0.5));
    canvas.drawRRect(rr, _stroke(outline, line));
  }

  @override
  bool shouldRepaint(StudyCatPainter oldDelegate) => oldDelegate.clock != clock || oldDelegate.outline != outline;
}

/// Two cat ears on top of a circle that fills the bottom of the canvas
/// (the circle itself is drawn by the widget on top).
class CatEarsPainter extends CustomPainter {
  CatEarsPainter({required this.outline, required this.line, this.fill = CatColors.fur});

  final Color outline;
  final Color fill;
  final double line;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, size.height - r);
    Offset at(double angle, double distance) => center + Offset(math.cos(angle), math.sin(angle)) * distance;

    for (final angle in const [-2.2, -0.94]) {
      final a = at(angle - 0.34, r * 0.9);
      final b = at(angle + 0.34, r * 0.9);
      final tip = at(angle, r * 1.6);
      final ear = roundedTriangle(a, tip, b, r * 0.14);
      canvas.drawPath(ear, Paint()..color = fill);
      canvas.drawPath(ear, _stroke(outline, line));

      final baseMid = Offset.lerp(a, b, 0.5)!;
      final inner = roundedTriangle(
        Offset.lerp(Offset.lerp(a, b, 0.2)!, tip, 0.2)!,
        Offset.lerp(tip, baseMid, 0.22)!,
        Offset.lerp(Offset.lerp(a, b, 0.8)!, tip, 0.2)!,
        r * 0.08,
      );
      canvas.drawPath(inner, Paint()..color = CatColors.pink);
    }
  }

  @override
  bool shouldRepaint(CatEarsPainter oldDelegate) =>
      oldDelegate.outline != outline || oldDelegate.line != line || oldDelegate.fill != fill;
}

/// A triangle from [a] through [tip] to [b] with the tip rounded off.
Path roundedTriangle(Offset a, Offset tip, Offset b, double radius) {
  final toA = a - tip;
  final toB = b - tip;
  final pa = tip + toA / toA.distance * radius;
  final pb = tip + toB / toB.distance * radius;
  return Path()
    ..moveTo(a.dx, a.dy)
    ..lineTo(pa.dx, pa.dy)
    ..quadraticBezierTo(tip.dx, tip.dy, pb.dx, pb.dy)
    ..lineTo(b.dx, b.dy)
    ..close();
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../common/app_image.dart';
import 'cat_painter.dart';

export 'cat_painter.dart' show CatMood;

/// Runs a looping 0 → 1 clock for a cat's blinks and swishes, unless the
/// visitor asked for less motion.
mixin _CatClock<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  AnimationController? clock;

  Duration get loop;
  bool get animates;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = animates && !MediaQuery.disableAnimationsOf(context);
    if (run && clock == null) {
      // Start somewhere random so several cats on a page don't blink in unison.
      clock = AnimationController(vsync: this, duration: loop, value: math.Random().nextDouble() * 0.8)..repeat();
    } else if (!run && clock != null) {
      clock!.dispose();
      clock = null;
    }
  }

  @override
  void dispose() {
    clock?.dispose();
    super.dispose();
  }
}

class _Blink extends Animatable<double> {
  const _Blink();

  @override
  double transform(double t) => blinkAt(t);
}

/// A cat's head. With [blinks], it blinks every few seconds.
class CatFace extends StatefulWidget {
  const CatFace({super.key, this.size = 40, this.mood = CatMood.happy, this.glasses = false, this.blinks = false});

  final double size;
  final CatMood mood;
  final bool glasses;
  final bool blinks;

  @override
  State<CatFace> createState() => _CatFaceState();
}

class _CatFaceState extends State<CatFace> with TickerProviderStateMixin, _CatClock {
  @override
  Duration get loop => const Duration(milliseconds: 4600);

  @override
  bool get animates => widget.blinks && widget.mood != CatMood.sleepy;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: CatFacePainter(
          mood: widget.mood,
          glasses: widget.glasses,
          blink: clock?.drive(const _Blink()),
          outline: CatColors.outline,
        ),
      ),
    );
  }
}

/// The home page mascot: a cat with glasses and a stethoscope on a pile of books.
class StudyCat extends StatefulWidget {
  const StudyCat({super.key, required this.height});

  final double height;

  @override
  State<StudyCat> createState() => _StudyCatState();
}

class _StudyCatState extends State<StudyCat> with TickerProviderStateMixin, _CatClock {
  @override
  Duration get loop => const Duration(seconds: 6);

  @override
  bool get animates => true;

  @override
  Widget build(BuildContext context) {
    final box = StudyCatPainter.box;
    return Semantics(
      image: true,
      label: 'A cat with glasses and a stethoscope, sitting on a pile of books',
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(widget.height * box.width / box.height, widget.height),
          painter: StudyCatPainter(clock: clock ?? const AlwaysStoppedAnimation(0.3)),
        ),
      ),
    );
  }
}

/// A paw print. Toes point up; turn it with [angle] (radians).
class Paw extends StatelessWidget {
  const Paw({super.key, this.size = 16, this.color, this.angle = 0});

  final double size;
  final Color? color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final paw = CustomPaint(
      size: Size.square(size),
      painter: _PawPainter(color ?? context.palette.accent),
    );
    return angle == 0 ? paw : Transform.rotate(angle: angle, child: paw);
  }
}

class _PawPainter extends CustomPainter {
  _PawPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(pawPath(Offset.zero & size), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PawPainter oldDelegate) => oldDelegate.color != color;
}

/// A round avatar with cat ears: [image] (a photo) if there is one, else a
/// drawn cat face.
class CatAvatar extends StatelessWidget {
  const CatAvatar({super.key, required this.size, this.image, this.shadow = true});

  /// Diameter of the circle. The ears add a little on top.
  final double size;
  final String? image;
  final bool shadow;

  /// Height including the ears.
  static double heightFor(double size) => size * 1.18;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final line = math.max(2.0, size * 0.022);
    final circle = const BoxDecoration(shape: BoxShape.circle);
    return SizedBox(
      width: size,
      height: heightFor(size),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(painter: CatEarsPainter(outline: p.outline, line: line))),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size,
            child: Container(
              decoration: circle.copyWith(
                color: CatColors.fur,
                boxShadow: [if (shadow) BoxShadow(color: p.outline, offset: Offset(size * 0.035, size * 0.035))],
              ),
              foregroundDecoration: circle.copyWith(border: Border.all(color: p.outline, width: line)),
              clipBehavior: Clip.antiAlias,
              child: image != null
                  ? AppImage(image!, semanticLabel: 'Profile photo')
                  : CustomPaint(painter: CatAvatarFacePainter(outline: CatColors.outline)),
            ),
          ),
        ],
      ),
    );
  }
}

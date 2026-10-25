import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../content/models.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../cats/cat_painter.dart';
import '../cats/cats.dart';
import '../common/bits.dart';
import '../common/progress.dart';
import '../common/sticker_card.dart';
import 'subject_badge.dart';

/// Subjects as tiles on a board-game trail, after Duolingo's learning path.
///
/// Tiles snake left to right, then right to left on the next row, with paw
/// prints walking from one to the next (pink once the subject before is
/// done). A cat peeks over the top of [here], the subject being studied.
class RoadmapBoard extends StatelessWidget {
  const RoadmapBoard({super.key, required this.subjects, this.here});

  final List<Subject> subjects;
  final Subject? here;

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) return const SizedBox.shrink();
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = BoardLayout(
          width: constraints.maxWidth,
          count: subjects.length,
          textScale: MediaQuery.textScalerOf(context).scale(16) / 16,
        );
        final hereIndex = here == null ? -1 : subjects.indexOf(here!);
        final hereTile = hereIndex >= 0 ? layout.tile(hereIndex) : null;
        return SizedBox(
          width: constraints.maxWidth,
          height: layout.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrailPainter(
                    layout: layout,
                    walked: [for (final s in subjects) s.status == SubjectStatus.done],
                    walkedColor: p.accent,
                    restColor: p.textMuted.withValues(alpha: p.isDark ? 0.45 : 0.4),
                  ),
                ),
              ),
              if (hereTile != null) ..._peekingCat(context, hereTile, subjects[hereIndex]),
              for (var i = 0; i < subjects.length; i++)
                Positioned.fromRect(
                  rect: layout.tile(i),
                  child: Appear(
                    delay: Duration(milliseconds: 35 * i),
                    distance: 0,
                    child: SubjectTile(subject: subjects[i]),
                  ),
                ),
              if (hereTile != null) ..._paws(hereTile),
            ],
          ),
        );
      },
    );
  }

  static const _catSize = 50.0;

  /// The cat sits behind the tile with its eyes just over the top edge,
  /// with a note in handwriting beside it.
  List<Widget> _peekingCat(BuildContext context, Rect tile, Subject subject) {
    final studying = subject.status == SubjectStatus.doing;
    return [
      Positioned(
        left: tile.right - _catSize - 14,
        top: tile.top - _catSize * 0.74,
        width: _catSize,
        height: _catSize,
        child: const _Peek(child: CatFace(size: _catSize, blinks: true)),
      ),
      Positioned(
        left: tile.left + 10,
        width: tile.width - _catSize - 28,
        top: tile.top - 30,
        child: Text(
          studying ? 'studying!' : 'next up!',
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
          textAlign: TextAlign.right,
          style: AppTheme.hand(fontSize: 21, color: context.palette.accent),
        ),
      ),
    ];
  }

  /// Two front paws holding on to the tile's edge.
  List<Widget> _paws(Rect tile) {
    final center = tile.right - _catSize / 2 - 14;
    return [
      for (final dx in const [-11.0, 11.0])
        Positioned(
          left: center + dx - 8,
          top: tile.top - 6,
          width: 16,
          height: 11,
          child: const IgnorePointer(child: CustomPaint(painter: _HoldingPawPainter())),
        ),
    ];
  }
}

/// Where the tiles go: as many columns as fit (at least two), rows balanced
/// so the last one isn't lonely, odd rows running right to left.
class BoardLayout {
  BoardLayout({required double width, required this.count, double textScale = 1}) {
    final compact = width < 560;
    gapX = compact ? 24 : 40;
    gapY = compact ? 40 : 46;
    tileHeight = (compact ? 146.0 : 152.0) + 34 * textScale;
    final maxColumns = math.max(2, ((width + gapX) / (176 + gapX)).floor());
    rows = (count / maxColumns).ceil();
    columns = math.max(1, math.min(count, (count / rows).ceil()));
    tileWidth = math.min(212.0, (width - (columns - 1) * gapX) / columns);
    left = (width - (columns * tileWidth + (columns - 1) * gapX)) / 2;
  }

  final int count;
  late final double gapX;
  late final double gapY;
  late final double tileWidth;
  late final double tileHeight;
  late final int rows;
  late final int columns;
  late final double left;

  /// Room above the first row for the peeking cat.
  static const top = 46.0;

  double get height => top + rows * tileHeight + (rows - 1) * gapY + 8;

  Rect tile(int i) {
    final row = i ~/ columns;
    var column = i % columns;
    if (row.isOdd) column = columns - 1 - column;
    return Rect.fromLTWH(left + column * (tileWidth + gapX), top + row * (tileHeight + gapY), tileWidth, tileHeight);
  }
}

class SubjectTile extends StatelessWidget {
  const SubjectTile({super.key, required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final done = subject.status == SubjectStatus.done;
    final next = subject.nextTopic;
    return StickerCard(
      onTap: () => context.go(subject.route),
      semanticLabel: '${subject.title}: ${subject.doneCount} of ${subject.topicCount} topics done',
      tooltip: done ? 'All done!' : (next == null ? subject.description : 'Next: ${next.text}'),
      color: done ? p.pastel(subject.color) : p.surface,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        children: [
          SubjectBadge(subject: subject, size: 62),
          const SizedBox(height: 10),
          Text(
            subject.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(fontSize: 15.5, height: 1.15, color: done ? p.onPastel : null),
          ),
          if (subject.titleTr != null)
            Text(
              subject.titleTr!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(fontSize: 12, color: done ? p.onPastel.withValues(alpha: 0.7) : null),
            ),
          const Spacer(),
          Row(
            children: [
              Expanded(child: PawProgressBar(value: subject.progress, height: 9, color: done ? p.done : p.accent)),
              const SizedBox(width: 8),
              Text(
                '${subject.doneCount}/${subject.topicCount}',
                style: text.labelMedium?.copyWith(fontSize: 12, color: done ? p.onPastel : null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Gently bobs its child up and down, like a cat peeking over a wall.
class _Peek extends StatefulWidget {
  const _Peek({required this.child});

  final Widget child;

  @override
  State<_Peek> createState() => _PeekState();
}

class _PeekState extends State<_Peek> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -3 * Curves.easeInOut.transform(_controller.value)),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _HoldingPawPainter extends CustomPainter {
  const _HoldingPawPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(rect, Paint()..color = CatColors.fur);
    canvas.drawOval(
      rect,
      Paint()
        ..color = CatColors.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    final toe = Paint()
      ..color = CatColors.outline
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.38, size.height * 0.55), Offset(size.width * 0.38, size.height * 0.95), toe);
    canvas.drawLine(Offset(size.width * 0.62, size.height * 0.55), Offset(size.width * 0.62, size.height * 0.95), toe);
  }

  @override
  bool shouldRepaint(_HoldingPawPainter oldDelegate) => false;
}

/// Paw prints walking from each tile to the next.
class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.layout, required this.walked, required this.walkedColor, required this.restColor});

  final BoardLayout layout;

  /// Per subject: whether it's done, so the steps after it are walked.
  final List<bool> walked;
  final Color walkedColor;
  final Color restColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < layout.count - 1; i++) {
      final a = layout.tile(i);
      final b = layout.tile(i + 1);
      final (from, to) = (a.top - b.top).abs() < 1
          ? (b.left > a.left ? (a.centerRight, b.centerLeft) : (a.centerLeft, b.centerRight))
          : (a.bottomCenter, b.topCenter);
      _steps(canvas, from, to, walked[i] ? walkedColor : restColor);
    }
  }

  void _steps(Canvas canvas, Offset from, Offset to, Color color) {
    const pawSize = 11.0;
    const stride = 15.0;
    final delta = to - from;
    final length = delta.distance;
    if (length < pawSize) return;
    final direction = delta / length;
    final side = Offset(-direction.dy, direction.dx);
    final steps = math.max(1, ((length - 8) / stride).floor());
    final spacing = length / (steps + 1);
    final angle = math.atan2(direction.dy, direction.dx) + math.pi / 2;
    final paint = Paint()..color = color;
    for (var k = 1; k <= steps; k++) {
      // Left, right, left…: footprints, not a dotted line.
      final c = from + direction * (spacing * k) + side * (k.isEven ? 3.5 : -3.5);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      canvas.drawPath(pawPath(Rect.fromCenter(center: Offset.zero, width: pawSize, height: pawSize)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_TrailPainter oldDelegate) =>
      oldDelegate.layout.count != layout.count ||
      oldDelegate.layout.columns != layout.columns ||
      oldDelegate.layout.tileWidth != layout.tileWidth ||
      oldDelegate.layout.tileHeight != layout.tileHeight ||
      oldDelegate.walkedColor != walkedColor ||
      oldDelegate.restColor != restColor ||
      !_sameList(oldDelegate.walked, walked);

  static bool _sameList(List<bool> a, List<bool> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

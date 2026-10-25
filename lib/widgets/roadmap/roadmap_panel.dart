import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../theme/app_palette.dart';
import '../../theme/tokens.dart';
import '../common/bits.dart';
import '../common/progress.dart';
import 'roadmap_board.dart';

/// One part of the roadmap (basic sciences, clinical, …) on a dotted
/// notebook-paper panel: its title and progress, then its board.
class RoadmapPanel extends StatelessWidget {
  const RoadmapPanel({super.key, required this.part, this.here});

  final RoadmapPart part;

  /// The subject being studied; the cat only shows if it's in this part.
  final Subject? here;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pad = ScreenSize.of(context).isCompact ? 14.0 : 28.0;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: Radii.xlAll,
        border: Border.all(color: p.border, width: 1.5),
      ),
      child: CustomPaint(
        painter: _DotGridPainter(p.border),
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PartHeader(part: part),
              const SizedBox(height: Insets.sm),
              RoadmapBoard(subjects: part.subjects, here: part.subjects.contains(here) ? here : null),
            ],
          ),
        ),
      ),
    );
  }
}

class PartHeader extends StatelessWidget {
  const PartHeader({super.key, required this.part});

  final RoadmapPart part;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final compact = ScreenSize.of(context).isCompact;
    final counts = Text(
      '${part.doneCount} of ${part.topicCount} topics · ${(part.progress * 100).round()}%',
      style: text.labelMedium,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.surface,
                border: Border.all(color: p.outline, width: Strokes.outline),
              ),
              child: Text(part.emoji, style: const TextStyle(fontSize: 23, height: 1.15)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(part.title, style: text.headlineSmall),
                  if (part.titleTr != null) Text(part.titleTr!, style: text.bodySmall),
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: Insets.md),
              SizedBox(
                width: 190,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [counts, const SizedBox(height: 6), PawProgressBar(value: part.progress, height: 14)],
                ),
              ),
            ],
          ],
        ),
        if (compact) ...[
          const SizedBox(height: 12),
          PawProgressBar(value: part.progress, height: 14),
          const SizedBox(height: 6),
          counts,
        ],
        if (part.description != null) ...[
          const SizedBox(height: 10),
          Text(part.description!, style: text.bodyMedium),
        ],
      ],
    );
  }
}

/// Pills to switch between the parts of the roadmap.
class PartTabs extends StatelessWidget {
  const PartTabs({super.key, required this.parts, required this.selected, required this.onSelected});

  final List<RoadmapPart> parts;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < parts.length; i++)
          Pill(
            label: '${parts[i].shortTitle} · ${(parts[i].progress * 100).round()}%',
            leading: Text(parts[i].emoji, style: const TextStyle(fontSize: 16, height: 1.15)),
            selected: i == selected,
            onTap: () => onSelected(i),
          ),
      ],
    );
  }
}

/// Dots like a bullet-journal page.
class _DotGridPainter extends CustomPainter {
  _DotGridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 22.0;
    final paint = Paint()..color = color;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => oldDelegate.color != color;
}

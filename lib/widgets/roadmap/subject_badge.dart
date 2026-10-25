import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../theme/app_palette.dart';
import '../../theme/tokens.dart';
import '../common/progress.dart';

/// A subject's emoji in its pastel circle, ringed by its progress, with a
/// check (done) or pencil (studying) stamp in the corner.
class SubjectBadge extends StatelessWidget {
  const SubjectBadge({super.key, required this.subject, this.size = 64});

  final Subject subject;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final status = subject.status;
    final ring = (size * 0.075).clamp(3.0, 8.0);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ProgressRing(
            value: subject.progress,
            size: size,
            stroke: ring,
            color: status == SubjectStatus.done ? p.done : p.accent,
            child: Container(
              width: size - ring * 2 - 5,
              height: size - ring * 2 - 5,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.pastel(subject.color),
                border: Border.all(color: p.outline, width: Strokes.outline),
              ),
              child: Text(subject.emoji, style: TextStyle(fontSize: size * 0.34, height: 1.15)),
            ),
          ),
          if (status != SubjectStatus.todo)
            Positioned(right: -3, top: -3, child: StatusStamp(status: status, size: (size * 0.34).clamp(18.0, 34.0))),
        ],
      ),
    );
  }
}

/// A round stamp: a check for done, a pencil for studying.
class StatusStamp extends StatelessWidget {
  const StatusStamp({super.key, required this.status, this.size = 22});

  final SubjectStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final done = status == SubjectStatus.done;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? p.done : p.doing,
        border: Border.all(color: p.outline, width: Strokes.outline),
      ),
      child: Icon(done ? Icons.check_rounded : Icons.edit_rounded, size: size * 0.58, color: Colors.white),
    );
  }
}

/// "Done", "Studying" or "Not started", as a coloured pill.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final SubjectStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (label, color) = switch (status) {
      SubjectStatus.done => ('Done!', p.done),
      SubjectStatus.doing => ('Studying', p.doing),
      SubjectStatus.todo => ('Not started yet', p.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.16),
        shape: StadiumBorder(side: BorderSide(color: color, width: 1.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            switch (status) {
              SubjectStatus.done => Icons.check_circle_rounded,
              SubjectStatus.doing => Icons.edit_rounded,
              SubjectStatus.todo => Icons.schedule_rounded,
            },
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: p.textPrimary)),
        ],
      ),
    );
  }
}

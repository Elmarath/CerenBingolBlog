import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../content/content_repository.dart';
import '../../content/markdown_blocks.dart';
import '../../content/models.dart';
import '../../content/text_utils.dart';
import '../../theme/app_palette.dart';
import '../../theme/tokens.dart';
import '../cats/cats.dart';
import '../common/cat_ears_card.dart';
import '../common/progress.dart';
import '../common/sticker_card.dart';
import 'subject_badge.dart';

/// The subject being studied (or next up), with its progress and next topic.
/// Once every subject is done, a little celebration instead.
class NowStudyingCard extends StatelessWidget {
  const NowStudyingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.content;
    final subject = content.currentSubject;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    if (subject == null) {
      return CatEarsCard(
        color: p.pastel('butter'),
        child: Column(
          children: [
            const CatFace(size: 72, mood: CatMood.wink),
            const SizedBox(height: Insets.md),
            Text('Every subject is done!', style: text.headlineSmall?.copyWith(color: p.onPastel), textAlign: TextAlign.center),
            const SizedBox(height: Insets.xs),
            Text('The whole roadmap is ticked off. Good luck in the exam!', style: text.bodyMedium?.copyWith(color: p.onPastel), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final studying = subject.status == SubjectStatus.doing;
    final next = subject.nextTopic;
    final onPastel = p.onPastel;
    return CatEarsCard(
      color: p.pastel(subject.color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(studying ? 'NOW STUDYING' : 'NEXT UP', style: text.labelSmall?.copyWith(color: onPastel.withValues(alpha: 0.75))),
          const SizedBox(height: 12),
          Row(
            children: [
              SubjectBadge(subject: subject, size: 72),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject.title, style: text.headlineSmall?.copyWith(color: onPastel)),
                    if (subject.titleTr != null)
                      Text(subject.titleTr!, style: text.bodySmall?.copyWith(color: onPastel.withValues(alpha: 0.75))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          PawProgressBar(value: subject.progress),
          const SizedBox(height: 8),
          Text(
            '${subject.doneCount} of ${subject.topicCount} topics done',
            style: text.labelMedium?.copyWith(color: onPastel),
          ),
          if (next != null) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(top: 3), child: Paw(size: 16, color: onPastel.withValues(alpha: 0.8))),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: next.state == CheckState.doing ? 'On the desk: ' : 'Next topic: '),
                        TextSpan(text: next.text, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                    style: text.bodyMedium?.copyWith(color: onPastel),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          StickerButton(
            label: 'Open ${subject.title}',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.go(subject.route),
          ),
        ],
      ),
    );
  }
}

/// The latest topics and subjects ticked off.
class RecentWinsCard extends StatelessWidget {
  const RecentWinsCard({super.key, this.limit = 5});

  final int limit;

  @override
  Widget build(BuildContext context) {
    final wins = context.content.wins;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return StickerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Paw(size: 22, color: p.accent, angle: -0.3),
              const SizedBox(width: 10),
              Expanded(child: Text('Recent paw-prints', style: text.titleLarge)),
            ],
          ),
          const SizedBox(height: 2),
          Text('Topics ticked off lately.', style: text.bodySmall),
          const SizedBox(height: Insets.md),
          if (wins.isEmpty)
            Row(
              children: [
                const CatFace(size: 48, mood: CatMood.sleepy),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Nothing ticked off yet. The first paw-print shows up here as soon as a topic is done.',
                    style: text.bodyMedium,
                  ),
                ),
              ],
            )
          else
            for (final (i, win) in wins.take(limit).indexed) ...[
              if (i > 0) Divider(color: p.border, height: 1),
              _WinRow(win: win),
            ],
        ],
      ),
    );
  }
}

class _WinRow extends StatelessWidget {
  const _WinRow({required this.win});

  final Win win;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final subject = win.subject;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(subject.route),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.pastel(subject.color),
                  border: Border.all(color: p.outline, width: 1.5),
                ),
                child: Text(win.isSubject ? '🎉' : subject.emoji, style: const TextStyle(fontSize: 17, height: 1.15)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      win.isSubject ? 'Finished ${subject.title}!' : win.topic!.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall,
                    ),
                    Text(win.isSubject ? 'Every topic done' : subject.title, style: text.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: Insets.sm),
              Text(formatShortDate(win.date), style: text.labelMedium?.copyWith(color: p.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small sticker with an icon, a number and what it counts.
class StatSticker extends StatelessWidget {
  const StatSticker({super.key, required this.icon, required this.value, required this.label, this.color});

  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final tint = color ?? p.accent;
    return StickerCard(
      depth: 3,
      radius: Radii.md,
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: tint.withValues(alpha: 0.18)),
            child: Icon(icon, size: 19, color: tint),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: text.headlineSmall?.copyWith(height: 1.1)),
              Text(label, style: text.labelMedium?.copyWith(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The numbers behind the roadmap, as stat stickers.
List<Widget> roadmapStats(BuildContext context, ContentRepository content) {
  final p = context.palette;
  final days = content.profile.daysUntilExam(DateTime.now());
  return [
    StatSticker(
      icon: Icons.check_circle_rounded,
      value: '${content.doneTopicCount}/${content.topicCount}',
      label: 'topics done',
      color: p.done,
    ),
    StatSticker(
      icon: Icons.flag_rounded,
      value: '${content.subjectsDone}/${content.subjects.length}',
      label: 'subjects finished',
      color: p.doing,
    ),
    StatSticker(icon: Icons.edit_note_rounded, value: '${content.posts.length}', label: 'blog posts'),
    if (days != null)
      StatSticker(
        icon: Icons.event_rounded,
        value: '$days',
        label: days == 1 ? 'day to ${content.profile.exam ?? 'the exam'}' : 'days to ${content.profile.exam ?? 'the exam'}',
        color: const Color(0xFF7C8CE0),
      ),
  ];
}

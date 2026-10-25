import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../content/models.dart';
import '../../theme/app_palette.dart';
import '../../theme/tokens.dart';
import '../../widgets/blog/post_card.dart';
import '../../widgets/common/bits.dart';
import '../../widgets/common/cat_ears_card.dart';
import '../../widgets/common/neighbours.dart';
import '../../widgets/common/progress.dart';
import '../../widgets/layout/page_frame.dart';
import '../../widgets/markdown/markdown_view.dart';
import '../../widgets/roadmap/subject_badge.dart';
import '../not_found_page.dart';

/// One stop on the roadmap: its progress, its notes and topic checklist (the
/// subject's Markdown file), posts about it, and the stops on either side.
class SubjectPage extends StatelessWidget {
  const SubjectPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final content = context.content;
    final subject = content.subject(id);
    if (subject == null) return const NotFoundPage();
    final posts = content.postsAbout(subject);
    final previous = content.subjectAround(subject, -1);
    final next = content.subjectAround(subject, 1);
    final text = Theme.of(context).textTheme;

    return PageFrame(
      title: subject.title,
      maxWidth: ContentWidths.subject,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            const ArrowLink(label: 'Roadmap', href: '/roadmap', back: true),
            Text('/  ${subject.part.title}', style: text.labelLarge?.copyWith(color: context.palette.textMuted)),
          ],
        ),
        const SizedBox(height: Insets.md),
        Appear(child: _SubjectHeader(subject: subject)),
        const SizedBox(height: Insets.xl + 4),
        if (subject.parsed.blocks.isEmpty)
          const CatEmptyState(title: 'No topics here yet', message: 'This subject’s checklist is coming soon.')
        else
          MarkdownView(blocks: subject.parsed.blocks, sourcePath: subject.assetPath),
        if (posts.isNotEmpty) ...[
          const SizedBox(height: Insets.xxl + 8),
          SectionHeader(kicker: 'From the blog', title: 'Posts about ${subject.title}'),
          const SizedBox(height: 20),
          ResponsiveGrid(maxColumns: 2, minItemWidth: 280, children: [for (final post in posts) PostCard(post: post)]),
        ],
        const SizedBox(height: Insets.xxl + 8),
        NeighbourCards(
          previous: previous == null
              ? null
              : NeighbourLink(label: 'Previous stop', title: previous.title, route: previous.route, emoji: previous.emoji),
          next: next == null
              ? null
              : NeighbourLink(label: 'Next stop', title: next.title, route: next.route, emoji: next.emoji),
        ),
      ],
    );
  }
}

class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final compact = ScreenSize.of(context).isCompact;
    final ink = p.onPastel;
    final percent = (subject.progress * 100).round();

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subject.part.title.toUpperCase(), style: text.labelSmall?.copyWith(color: ink.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        Text(subject.title, style: (compact ? text.headlineLarge : text.displaySmall)?.copyWith(color: ink)),
        if (subject.titleTr != null)
          Text(subject.titleTr!, style: text.titleMedium?.copyWith(color: ink.withValues(alpha: 0.75))),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusPill(status: subject.status),
            Text(
              '${subject.doneCount} of ${subject.topicCount} topics · $percent%',
              style: text.labelLarge?.copyWith(color: ink),
            ),
          ],
        ),
        const SizedBox(height: 14),
        PawProgressBar(value: subject.progress, height: 16),
        if (subject.description != null) ...[
          const SizedBox(height: 14),
          Text(subject.description!, style: text.bodyLarge?.copyWith(color: ink)),
        ],
      ],
    );

    return CatEarsCard(
      color: p.pastel(subject.color),
      padding: EdgeInsets.all(compact ? 20 : 32),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [SubjectBadge(subject: subject, size: 88), const SizedBox(height: Insets.md), details],
            )
          : Row(
              children: [
                SubjectBadge(subject: subject, size: 120),
                const SizedBox(width: 28),
                Expanded(child: details),
              ],
            ),
    );
  }
}

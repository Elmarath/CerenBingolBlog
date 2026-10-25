import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../content/markdown_blocks.dart';
import '../../content/models.dart';
import '../../theme/app_palette.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/bits.dart';
import '../../widgets/common/progress.dart';
import '../../widgets/common/sticker_card.dart';
import '../../widgets/layout/page_frame.dart';
import '../../widgets/markdown/markdown_view.dart';
import '../../widgets/roadmap/roadmap_panel.dart';

/// The whole roadmap: overall progress, then every part's board.
class RoadmapPage extends StatelessWidget {
  const RoadmapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.content;
    final here = content.currentSubject;
    return PageFrame(
      title: 'Roadmap',
      children: [
        const SectionHeader(
          kicker: 'Roadmap',
          title: 'The road to TUS',
          subtitle: 'Every TUS subject, stop by stop. Tap one to see its topics and how far along it is.',
          large: true,
        ),
        const SizedBox(height: 28),
        const Appear(child: _Summary()),
        for (final part in content.parts) ...[
          const SizedBox(height: Insets.xxl),
          Appear(child: RoadmapPanel(part: part, here: here)),
        ],
        if (content.parts.isEmpty)
          const CatEmptyState(title: 'The roadmap is empty', message: 'Subjects will show up here soon.'),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary();

  @override
  Widget build(BuildContext context) {
    final content = context.content;
    final text = Theme.of(context).textTheme;
    final compact = ScreenSize.of(context).isCompact;
    final percent = (content.progress * 100).round();
    final studying = content.subjects.where((s) => s.status == SubjectStatus.doing).length;
    final todo = content.subjects.where((s) => s.status == SubjectStatus.todo).length;

    final ring = ProgressRing(
      value: content.progress,
      size: compact ? 96 : 116,
      stroke: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$percent%', style: text.headlineMedium),
          Text('DONE', style: text.labelSmall),
        ],
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${content.doneTopicCount} of ${content.topicCount} topics ticked off', style: text.titleLarge),
        const SizedBox(height: 12),
        PawProgressBar(value: content.progress, height: 18),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _Legend(state: CheckState.done, label: '${content.subjectsDone} subjects finished'),
            _Legend(state: CheckState.doing, label: '$studying studying'),
            _Legend(state: CheckState.todo, label: '$todo still to go'),
          ],
        ),
      ],
    );
    return StickerCard(
      padding: EdgeInsets.all(compact ? Insets.lg - 4 : Insets.xl),
      child: compact
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ring, const SizedBox(height: 20), details])
          : Row(children: [ring, const SizedBox(width: Insets.xl), Expanded(child: details)]),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.state, required this.label});

  final CheckState state;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Pill(label: label, leading: PawCheck(state: state, size: 20), color: context.palette.surface);
  }
}

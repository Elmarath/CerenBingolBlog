import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../content/models.dart';
import '../../theme/app_palette.dart';
import '../../theme/tokens.dart';
import '../../widgets/cats/cat_painter.dart';
import '../../widgets/cats/cats.dart';
import '../../widgets/common/bits.dart';
import '../../widgets/common/cat_ears_card.dart';
import '../../widgets/common/sticker_card.dart';
import '../../widgets/layout/page_frame.dart';
import '../../widgets/markdown/markdown_view.dart';
import '../../widgets/roadmap/progress_cards.dart';
import '../home/home_page.dart';

/// About Ceren, from `content/profile.md`: the bio, quick facts, milestones,
/// and where she is on the roadmap.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.content.profile;
    final expanded = ScreenSize.of(context).isExpanded;

    final main = <Widget>[
      _Card(
        title: 'About me',
        child: MarkdownView(blocks: profile.parsed.blocks, sourcePath: profile.assetPath),
      ),
      if (profile.milestones.isNotEmpty) _Card(title: 'Milestones', child: _Milestones(milestones: profile.milestones)),
    ];
    final side = <Widget>[
      if (profile.facts.isNotEmpty) _Card(title: 'Quick facts', child: _Facts(facts: profile.facts)),
      if (context.content.subjects.isNotEmpty) ...[const NowStudyingCard(), const RecentWinsCard()],
    ];

    return PageFrame(
      title: profile.name,
      children: [
        const Appear(child: _ProfileHeader()),
        const SizedBox(height: Insets.xxl),
        if (expanded)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: _Stack(children: main)),
              const SizedBox(width: 28),
              Expanded(flex: 5, child: _Stack(children: side)),
            ],
          )
        else
          _Stack(children: [...main, ...side]),
        const SizedBox(height: Insets.section),
        const LatestPostsSection(title: 'Latest posts'),
      ],
    );
  }
}

/// Cards one under the other.
class _Stack extends StatelessWidget {
  const _Stack({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, child) in children.indexed) ...[if (i > 0) const SizedBox(height: Insets.lg + 4), child],
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final content = context.content;
    final profile = content.profile;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final compact = ScreenSize.of(context).isCompact;
    final ink = p.onPastel;
    final days = profile.daysUntilExam(DateTime.now());

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HELLO, I’M', style: text.labelSmall?.copyWith(color: ink.withValues(alpha: 0.7))),
        const SizedBox(height: 4),
        Text(profile.name, style: (compact ? text.displaySmall : text.displayMedium)?.copyWith(color: ink)),
        const SizedBox(height: 6),
        Text(profile.title, style: text.titleMedium?.copyWith(color: ink.withValues(alpha: 0.8))),
        const SizedBox(height: Insets.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (profile.location != null)
              Pill(label: profile.location!, leading: Icon(Icons.place_rounded, size: 16, color: p.accent)),
            if (profile.exam != null)
              Pill(label: 'Preparing for ${profile.exam}', leading: Icon(Icons.school_rounded, size: 16, color: p.accent)),
            if (days != null)
              Pill(label: '$days days to go', leading: Icon(Icons.event_rounded, size: 16, color: p.accent)),
          ],
        ),
        if (profile.socials.isNotEmpty) ...[
          const SizedBox(height: Insets.md + 4),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final social in profile.socials)
                StickerButton(
                  label: social.label,
                  icon: social.url.startsWith('mailto:') ? Icons.mail_rounded : Icons.link_rounded,
                  onPressed: () => openLink(context, social.url),
                ),
            ],
          ),
        ],
      ],
    );

    return CatEarsCard(
      color: p.pastel('pink'),
      padding: EdgeInsets.all(compact ? 20 : 36),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [CatAvatar(size: 112, image: profile.avatar), const SizedBox(height: Insets.lg), details],
            )
          : Row(
              children: [
                CatAvatar(size: 156, image: profile.avatar),
                const SizedBox(width: 36),
                Expanded(child: details),
              ],
            ),
    );
  }
}

/// A plain sticker card with a paw-stamped title.
class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StickerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Paw(size: 22, color: context.palette.accent, angle: -0.3),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
            ],
          ),
          const SizedBox(height: Insets.md),
          child,
        ],
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.facts});

  final List<ProfileFact> facts;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, fact) in facts.indexed) ...[
          if (i > 0) Divider(color: context.palette.border, height: 20),
          Row(
            children: [
              Text(fact.emoji, style: const TextStyle(fontSize: 22, height: 1.15)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (fact.label.isNotEmpty) Text(fact.label.toUpperCase(), style: text.labelSmall),
                    Text(fact.value, style: text.titleSmall),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A timeline with a paw stamp at each milestone.
class _Milestones extends StatelessWidget {
  const _Milestones({required this.milestones});

  final List<Milestone> milestones;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, m) in milestones.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 30,
                  child: CustomPaint(
                    painter: _TimelinePainter(
                      first: i == 0,
                      last: i == milestones.length - 1,
                      line: p.border,
                      stamp: p.accent,
                      outline: p.outline,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i == milestones.length - 1 ? 0 : 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.dateLabel, style: text.labelMedium?.copyWith(color: p.accent)),
                        const SizedBox(height: 2),
                        Text([if (m.emoji != null) m.emoji!, m.title].join(' '), style: text.titleMedium),
                        if (m.text != null) ...[const SizedBox(height: 2), Text(m.text!, style: text.bodyMedium)],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({required this.first, required this.last, required this.line, required this.stamp, required this.outline});

  final bool first;
  final bool last;
  final Color line;
  final Color stamp;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    const y = 14.0;
    final pen = Paint()
      ..color = line
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, first ? y : 0), Offset(x, last ? y : size.height), pen);
    canvas.drawCircle(Offset(x, y), 12, Paint()..color = stamp);
    canvas.drawCircle(
      Offset(x, y),
      12,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawPath(pawPath(Rect.fromCenter(center: Offset(x, y), width: 13, height: 13)), Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_TimelinePainter oldDelegate) =>
      oldDelegate.first != first || oldDelegate.last != last || oldDelegate.line != line || oldDelegate.stamp != stamp;
}

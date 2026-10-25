import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/blog/post_card.dart';
import '../../widgets/cats/cats.dart';
import '../../widgets/common/bits.dart';
import '../../widgets/common/sticker_card.dart';
import '../../widgets/layout/page_frame.dart';
import '../../widgets/roadmap/progress_cards.dart';
import '../../widgets/roadmap/roadmap_panel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageFrame(
      title: null,
      children: [
        Appear(child: _Hero()),
        SizedBox(height: Insets.section),
        _RoadmapSection(),
        SizedBox(height: Insets.section * 0.8),
        Appear(child: _ProgressRow()),
        SizedBox(height: Insets.section),
        LatestPostsSection(),
      ],
    );
  }
}

/// "Hi, I'm Ceren!", the intro from `content/profile.md`, two buttons, the
/// roadmap's numbers, and the study cat.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final content = context.content;
    final profile = content.profile;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final compact = ScreenSize.of(context).isCompact;

    final greeting = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Pill(label: profile.title, leading: Icon(Icons.medical_services_rounded, size: 16, color: p.accent)),
        const SizedBox(height: 20),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Hi, I’m ${profile.firstName}! '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Paw(size: compact ? 34 : 46, angle: 0.4),
              ),
            ],
          ),
          style: compact ? text.displayMedium : text.displayLarge,
        ),
        const SizedBox(height: Insets.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            profile.intro ?? 'A study diary on the road to TUS.',
            style: text.bodyLarge?.copyWith(fontSize: compact ? 17 : 18.5),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            StickerButton(
              label: 'Read the blog',
              icon: Icons.auto_stories_rounded,
              filled: true,
              onPressed: () => context.go('/blog'),
            ),
            StickerButton(label: 'See the roadmap', icon: Icons.route_rounded, onPressed: () => context.go('/roadmap')),
          ],
        ),
        const SizedBox(height: Insets.xl),
        Wrap(spacing: 12, runSpacing: 12, children: roadmapStats(context, content)),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [const Center(child: _HeroArt(height: 230)), const SizedBox(height: Insets.lg), greeting],
      );
    }
    return Row(
      children: [
        Expanded(flex: 6, child: greeting),
        const SizedBox(width: Insets.xl),
        const Expanded(flex: 5, child: Center(child: _HeroArt(height: 340))),
      ],
    );
  }
}

/// The study cat on a pink blob, with a few things floating around it.
class _HeroArt extends StatelessWidget {
  const _HeroArt({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final width = height * 1.12;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: width * 0.06,
            right: width * 0.06,
            top: height * 0.02,
            bottom: height * 0.02,
            child: DecoratedBox(decoration: BoxDecoration(color: p.accentSoft, shape: BoxShape.circle)),
          ),
          Positioned(
            left: width * 0.02,
            top: height * 0.2,
            child: _Floaty(phase: 0, child: Paw(size: height * 0.09, angle: -0.5, color: p.accent)),
          ),
          Positioned(
            right: width * 0.08,
            top: height * 0.04,
            child: _Floaty(phase: 0.35, child: Icon(Icons.favorite_rounded, size: height * 0.09, color: p.accent)),
          ),
          Positioned(
            left: width * 0.1,
            bottom: height * 0.14,
            child: _Floaty(phase: 0.6, child: Paw(size: height * 0.06, angle: 0.4, color: p.accent.withValues(alpha: 0.6))),
          ),
          Positioned(bottom: 0, child: StudyCat(height: height * 0.92)),
          Positioned(
            right: -width * 0.04,
            bottom: height * 0.3,
            child: _Floaty(
              phase: 0.8,
              child: Transform.rotate(
                angle: 0.1,
                child: StickerCard(
                  color: p.pastel('butter'),
                  depth: 3,
                  radius: Radii.sm,
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                  child: Text('you’ve got this!', style: AppTheme.hand(fontSize: height * 0.068, color: p.onPastel)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floats its child gently up and down; [phase] (0–1) staggers several.
class _Floaty extends StatefulWidget {
  const _Floaty({required this.child, this.phase = 0});

  final Widget child;
  final double phase;

  @override
  State<_Floaty> createState() => _FloatyState();
}

class _FloatyState extends State<_Floaty> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
    value: widget.phase,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
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
        offset: Offset(0, 6 * math.sin(_controller.value * 2 * math.pi)),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// The roadmap, one part at a time, starting with the part being studied.
class _RoadmapSection extends StatefulWidget {
  const _RoadmapSection();

  @override
  State<_RoadmapSection> createState() => _RoadmapSectionState();
}

class _RoadmapSectionState extends State<_RoadmapSection> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final content = context.content;
    final parts = content.parts;
    if (parts.isEmpty) return const SizedBox.shrink();
    final here = content.currentSubject;
    final selected = _selected ?? math.max(0, parts.indexWhere((p) => p.subjects.contains(here)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          kicker: 'Roadmap',
          title: 'The road to TUS',
          subtitle: 'Every stop is a TUS subject. Topics get ticked off one by one, and the paw prints light up along the way.',
          action: ArrowLink(label: 'Every subject at once', href: '/roadmap'),
        ),
        const SizedBox(height: Insets.lg),
        PartTabs(parts: parts, selected: selected, onSelected: (i) => setState(() => _selected = i)),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: Motion.normal,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, if (current != null) current],
          ),
          child: RoadmapPanel(key: ValueKey(parts[selected].id), part: parts[selected], here: here),
        ),
      ],
    );
  }
}

/// What's on the desk now, and what was ticked off lately.
class _ProgressRow extends StatelessWidget {
  const _ProgressRow();

  @override
  Widget build(BuildContext context) {
    if (context.content.subjects.isEmpty) return const SizedBox.shrink();
    if (!ScreenSize.of(context).isExpanded) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [NowStudyingCard(), SizedBox(height: Insets.lg), RecentWinsCard()],
      );
    }
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: NowStudyingCard()),
        SizedBox(width: Insets.lg + 4),
        Expanded(flex: 6, child: Padding(padding: EdgeInsets.only(top: 28), child: RecentWinsCard())),
      ],
    );
  }
}

/// The newest posts as cards.
class LatestPostsSection extends StatelessWidget {
  const LatestPostsSection({super.key, this.title = 'Fresh from the notebook', this.limit = 3});

  final String title;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final posts = context.content.posts.take(limit).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(kicker: 'Blog', title: title, action: const ArrowLink(label: 'All posts', href: '/blog')),
        const SizedBox(height: Insets.lg),
        if (posts.isEmpty)
          const CatEmptyState(title: 'No posts yet', message: 'The first one is on its way, right after this nap.')
        else
          ResponsiveGrid(
            minItemWidth: 290,
            children: [
              for (final (i, post) in posts.indexed) Appear(delay: Duration(milliseconds: 80 * i), child: PostCard(post: post)),
            ],
          ),
      ],
    );
  }
}

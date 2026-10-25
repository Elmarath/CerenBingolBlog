import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_palette.dart';
import '../../theme/tokens.dart';
import '../cats/cats.dart';

bool isExternalLink(String href) => RegExp(r'^[a-z][a-z0-9+.-]*:', caseSensitive: false).hasMatch(href);

/// Opens a page of this site with go_router, or anything else in a new tab
/// (email and phone links hand off to their app).
Future<void> openLink(BuildContext context, String href) async {
  if (isExternalLink(href)) {
    final handOff = href.startsWith('mailto:') || href.startsWith('tel:');
    await launchUrl(Uri.parse(href), webOnlyWindowName: handOff ? '_self' : '_blank');
  } else {
    context.go(href);
  }
}

/// Fades and floats its child in when it first appears, after [delay].
/// Inside a scrolling list that's when it scrolls into view.
class Appear extends StatelessWidget {
  const Appear({super.key, required this.child, this.delay = Duration.zero, this.distance = 18});

  final Widget child;
  final Duration delay;
  final double distance;

  static const _duration = Duration(milliseconds: 520);

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final total = _duration + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(delay.inMilliseconds / total.inMilliseconds, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * distance), child: child),
      ),
      child: child,
    );
  }
}

/// A small rounded label: tags, statuses, filters. Tappable with [onTap].
class Pill extends StatefulWidget {
  const Pill({
    super.key,
    required this.label,
    this.leading,
    this.color,
    this.textColor,
    this.onTap,
    this.selected = false,
    this.dense = false,
  });

  final String label;
  final Widget? leading;
  final Color? color;
  final Color? textColor;
  final VoidCallback? onTap;
  final bool selected;
  final bool dense;

  @override
  State<Pill> createState() => _PillState();
}

class _PillState extends State<Pill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final interactive = widget.onTap != null;
    final fill = widget.color ?? (widget.selected ? p.accentSoft : (_hovered ? p.surfaceAlt : p.surface));
    final pill = AnimatedContainer(
      duration: Motion.fast,
      padding: EdgeInsets.symmetric(horizontal: widget.dense ? 10 : 14, vertical: widget.dense ? 3 : 7),
      decoration: ShapeDecoration(
        color: fill,
        shape: StadiumBorder(
          side: BorderSide(
            color: widget.selected || _hovered ? p.outline : p.border,
            width: widget.selected ? Strokes.outline : 1.5,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.leading != null) ...[widget.leading!, SizedBox(width: widget.dense ? 4 : 6)],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (widget.dense ? Theme.of(context).textTheme.labelMedium : Theme.of(context).textTheme.labelLarge)
                  ?.copyWith(color: widget.textColor ?? (widget.selected ? p.textPrimary : p.textSecondary)),
            ),
          ),
        ],
      ),
    );
    if (!interactive) return pill;
    return Semantics(
      button: true,
      selected: widget.selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(onTap: widget.onTap, child: pill),
      ),
    );
  }
}

/// A section title with a small paw-stamped kicker above it.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, this.kicker, required this.title, this.subtitle, this.action, this.large = false});

  final String? kicker;
  final String title;
  final String? subtitle;

  /// A link at the end of the title row ("All posts →").
  final Widget? action;

  /// Page titles are bigger than section titles.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final compact = ScreenSize.of(context).isCompact;
    final titleStyle = large ? (compact ? text.displaySmall : text.displayMedium) : text.headlineLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (kicker != null) ...[
          Row(
            children: [
              Paw(size: 15, color: p.accent, angle: 0.35),
              const SizedBox(width: 7),
              Flexible(child: Text(kicker!.toUpperCase(), style: text.labelSmall?.copyWith(color: p.accent))),
            ],
          ),
          const SizedBox(height: Insets.sm),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text(title, style: titleStyle)),
            if (action != null && !compact) ...[const SizedBox(width: Insets.md), action!],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: Insets.sm + 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(subtitle!, style: text.bodyLarge),
          ),
        ],
        if (action != null && compact) ...[const SizedBox(height: Insets.sm), action!],
      ],
    );
  }
}

/// A text link with an arrow that nudges on hover.
class ArrowLink extends StatefulWidget {
  const ArrowLink({super.key, required this.label, required this.href, this.back = false});

  final String label;
  final String href;

  /// Points left, for "back" links.
  final bool back;

  @override
  State<ArrowLink> createState() => _ArrowLinkState();
}

class _ArrowLinkState extends State<ArrowLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = Theme.of(context).textTheme.labelLarge!.copyWith(
      color: p.link,
      decoration: _hovered ? TextDecoration.underline : null,
      decorationColor: p.link,
    );
    final arrow = AnimatedSlide(
      offset: Offset(_hovered ? (widget.back ? -0.25 : 0.25) : 0, 0),
      duration: Motion.fast,
      child: Icon(widget.back ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, size: 18, color: p.link),
    );
    return Semantics(
      link: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => openLink(context, widget.href),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.back) ...[arrow, const SizedBox(width: 6)],
                Flexible(child: Text(widget.label, style: style)),
                if (!widget.back) ...[const SizedBox(width: 6), arrow],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown where a list is empty: a cat, a title and a line of text.
class CatEmptyState extends StatelessWidget {
  const CatEmptyState({super.key, required this.title, this.message, this.mood = CatMood.sleepy, this.action});

  final String title;
  final String? message;
  final CatMood mood;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xl),
      child: Column(
        children: [
          CatFace(size: 84, mood: mood, blinks: true),
          const SizedBox(height: Insets.md),
          Text(title, style: text.titleLarge, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: Insets.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(message!, style: text.bodyMedium, textAlign: TextAlign.center),
            ),
          ],
          if (action != null) ...[const SizedBox(height: Insets.md), action!],
        ],
      ),
    );
  }
}

/// Cards in as many equal columns as fit, rows as tall as their tallest card.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 300,
    this.maxColumns = 3,
    this.spacing = Insets.lg,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ((constraints.maxWidth + spacing) / (minItemWidth + spacing)).floor().clamp(1, maxColumns);
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += columns) {
          if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
          if (columns == 1) {
            rows.add(children[i]);
            continue;
          }
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) SizedBox(width: spacing),
                    Expanded(child: i + j < children.length ? children[i + j] : const SizedBox()),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
      },
    );
  }
}

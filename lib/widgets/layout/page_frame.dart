import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../config/site_config.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../cats/cats.dart';
import '../common/progress.dart';
import '../common/sticker_card.dart';

/// A scrolling page: [children] centred at [maxWidth] over the paw-print
/// background, then the footer. Sets the browser tab's title.
class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.title, required this.children, this.maxWidth = ContentWidths.page});

  /// Page name for the browser tab; null on the home page.
  final String? title;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final gutter = ScreenSize.of(context).gutter;
    return Title(
      title: title == null
          ? '${SiteConfig.siteName} · ${context.content.profile.name}'
          : '$title · ${SiteConfig.siteName}',
      color: p.accent,
      child: ColoredBox(
        color: p.background,
        child: Stack(
          children: [
            const Positioned.fill(child: PawPattern()),
            ListView(
              // Keeps sections built a while after they scroll away, so they
              // don't fade in all over again when they come back.
              cacheExtent: 2000,
              padding: const EdgeInsets.only(top: Insets.xl),
              children: [
                for (final child in children)
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth + 2 * gutter),
                      child: Padding(padding: EdgeInsets.symmetric(horizontal: gutter), child: child),
                    ),
                  ),
                const SizedBox(height: Insets.section),
                const SiteFooter(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final size = ScreenSize.of(context);
    final profile = context.content.profile;

    final brand = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            const CatFace(size: 54, mood: CatMood.sleepy),
            Positioned(right: -18, top: -10, child: Text('z z', style: AppTheme.hand(fontSize: 20, color: p.accent))),
          ],
        ),
        const SizedBox(width: Insets.md + 4),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(SiteConfig.siteName, style: text.titleLarge),
              const SizedBox(height: 2),
              Text(SiteConfig.tagline, style: text.bodySmall),
            ],
          ),
        ),
      ],
    );
    final links = Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final item in SiteConfig.navItems)
          TextButton(onPressed: () => context.go(item.path), child: Text(item.label)),
      ],
    );
    final backToTop = StickerButton(
      label: 'Back to top',
      icon: Icons.arrow_upward_rounded,
      onPressed: () => Scrollable.maybeOf(context)?.position.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      ),
    );

    return Column(
      children: [
        SizedBox(
          height: 22,
          width: double.infinity,
          child: CustomPaint(painter: _ScallopPainter(fill: p.surfaceAlt, line: p.outline)),
        ),
        ColoredBox(
          color: p.surfaceAlt,
          child: Padding(
            padding: EdgeInsets.fromLTRB(size.gutter, Insets.lg, size.gutter, Insets.xl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: ContentWidths.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (size.isCompact) ...[
                      brand,
                      const SizedBox(height: Insets.lg),
                      links,
                      const SizedBox(height: Insets.md),
                      backToTop,
                    ] else
                      Row(
                        children: [
                          Expanded(child: Align(alignment: Alignment.centerLeft, child: brand)),
                          links,
                          const SizedBox(width: Insets.lg),
                          backToTop,
                        ],
                      ),
                    const SizedBox(height: Insets.lg),
                    Divider(color: p.border),
                    const SizedBox(height: Insets.md),
                    Text('© ${DateTime.now().year} ${profile.name} · ${SiteConfig.footerNote}', style: text.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A row of little scallops along the top of the footer, like a café awning.
class _ScallopPainter extends CustomPainter {
  _ScallopPainter({required this.fill, required this.line});

  final Color fill;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 16.0;
    final base = size.height;
    final count = (size.width / (radius * 2)).ceil();
    final width = size.width / count;
    final edge = Path()..moveTo(0, base);
    for (var i = 0; i < count; i++) {
      edge.arcToPoint(Offset((i + 1) * width, base), radius: Radius.elliptical(width / 2, base - 2));
    }
    final shape = Path.from(edge)
      ..lineTo(size.width, size.height + 1)
      ..lineTo(0, size.height + 1)
      ..close();
    canvas.drawPath(shape, Paint()..color = fill);
    canvas.drawPath(
      edge,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = Strokes.outline
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ScallopPainter oldDelegate) => oldDelegate.fill != fill || oldDelegate.line != line;
}

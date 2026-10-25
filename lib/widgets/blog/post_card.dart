import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../content/models.dart';
import '../../content/text_utils.dart';
import '../../theme/app_palette.dart';
import '../../theme/tokens.dart';
import '../cats/cat_painter.dart';
import '../common/app_image.dart';
import '../common/bits.dart';
import '../common/sticker_card.dart';

/// A post in a grid: cover, date, title, excerpt and tags.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.coverHeight = 168});

  final BlogPost post;
  final double coverHeight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return StickerCard(
      onTap: () => context.go(post.route),
      semanticLabel: post.title,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: coverHeight, child: PostCover(post: post)),
          Container(height: Strokes.outline, color: p.outline),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PostMeta(post: post),
                const SizedBox(height: Insets.sm),
                Text(post.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: text.titleLarge),
                const SizedBox(height: Insets.sm),
                Text(post.excerpt, maxLines: 3, overflow: TextOverflow.ellipsis, style: text.bodyMedium),
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final tag in post.tags.take(3)) Pill(label: tag, dense: true)],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Oct 25, 2026 · 3 min read", plus a "Draft" label while it is one.
class PostMeta extends StatelessWidget {
  const PostMeta({super.key, required this.post});

  final BlogPost post;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('${formatDate(post.date)} · ${post.readingMinutes} min read', style: text.labelMedium?.copyWith(color: p.textMuted)),
        if (post.draft) Pill(label: 'Draft', dense: true, color: p.pastel('butter'), textColor: p.onPastel),
      ],
    );
  }
}

/// The post's image, or its emoji on a pastel tile sprinkled with paws.
class PostCover extends StatelessWidget {
  const PostCover({super.key, required this.post, this.emojiSize = 56});

  final BlogPost post;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    if (post.image != null) return AppImage(post.image!, semanticLabel: post.title);
    final p = context.palette;
    return ColoredBox(
      color: p.pastel(post.color),
      child: CustomPaint(
        painter: _ScatteredPaws(p.onPastel.withValues(alpha: 0.09)),
        child: Center(
          child: Transform.rotate(
            angle: -0.08,
            child: Text(post.emoji, style: TextStyle(fontSize: emojiSize, height: 1.15)),
          ),
        ),
      ),
    );
  }
}

class _ScatteredPaws extends CustomPainter {
  _ScatteredPaws(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    // A fixed, hand-placed scatter (fractions of the cover's size).
    const spots = [(0.1, 0.2, 0.5), (0.26, 0.72, -0.4), (0.78, 0.18, 0.3), (0.9, 0.66, -0.2), (0.62, 0.86, 0.6), (0.42, 0.1, -0.7)];
    final pawSize = (size.shortestSide * 0.16).clamp(14.0, 34.0);
    for (final (x, y, angle) in spots) {
      canvas.save();
      canvas.translate(size.width * x, size.height * y);
      canvas.rotate(angle);
      canvas.drawPath(pawPath(Rect.fromCenter(center: Offset.zero, width: pawSize, height: pawSize)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ScatteredPaws oldDelegate) => oldDelegate.color != color;
}

/// The pinned post (`featured: true`), wide at the top of the blog.
class FeaturedPostCard extends StatelessWidget {
  const FeaturedPostCard({super.key, required this.post});

  final BlogPost post;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final compact = ScreenSize.of(context).isCompact;
    final details = Padding(
      padding: EdgeInsets.all(compact ? 20 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Pill(label: 'Featured', dense: true, leading: Icon(Icons.push_pin_rounded, size: 14, color: p.accent), selected: true),
          const SizedBox(height: 14),
          PostMeta(post: post),
          const SizedBox(height: Insets.sm),
          Text(post.title, style: compact ? text.headlineMedium : text.headlineLarge),
          const SizedBox(height: Insets.sm + 2),
          Text(post.excerpt, style: text.bodyLarge, maxLines: 4, overflow: TextOverflow.ellipsis),
          const SizedBox(height: Insets.md),
          Text('Read the post →', style: text.titleMedium?.copyWith(color: p.link)),
        ],
      ),
    );
    return StickerCard(
      onTap: () => context.go(post.route),
      semanticLabel: post.title,
      padding: EdgeInsets.zero,
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 190, child: PostCover(post: post, emojiSize: 72)),
                Container(height: Strokes.outline, color: p.outline),
                details,
              ],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 300), child: PostCover(post: post, emojiSize: 96))),
                  Container(width: Strokes.outline, color: p.outline),
                  Expanded(flex: 6, child: details),
                ],
              ),
            ),
    );
  }
}

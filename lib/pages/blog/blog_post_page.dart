import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../content/text_utils.dart';
import '../../theme/app_palette.dart';
import '../../theme/tokens.dart';
import '../../widgets/blog/post_card.dart';
import '../../widgets/cats/cats.dart';
import '../../widgets/common/bits.dart';
import '../../widgets/common/neighbours.dart';
import '../../widgets/common/sticker_card.dart';
import '../../widgets/layout/page_frame.dart';
import '../../widgets/markdown/markdown_view.dart';
import '../not_found_page.dart';

class BlogPostPage extends StatelessWidget {
  const BlogPostPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final content = context.content;
    final post = content.post(slug);
    if (post == null) return const NotFoundPage();
    final profile = content.profile;
    final subjects = content.subjectsOf(post);
    final newer = content.postAround(post, -1);
    final older = content.postAround(post, 1);
    final text = Theme.of(context).textTheme;
    final compact = ScreenSize.of(context).isCompact;

    return PageFrame(
      title: post.title,
      maxWidth: ContentWidths.reading,
      children: [
        const Align(alignment: Alignment.centerLeft, child: ArrowLink(label: 'All posts', href: '/blog', back: true)),
        const SizedBox(height: Insets.md),
        if (post.tags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in post.tags)
                Pill(label: tag, dense: true, onTap: () => context.go('/blog?tag=${slugify(tag)}')),
            ],
          ),
          const SizedBox(height: 14),
        ],
        Text(post.title, style: compact ? text.displaySmall : text.displayMedium),
        const SizedBox(height: Insets.md),
        Row(
          children: [
            CatAvatar(size: 36, image: profile.avatar, shadow: false),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(profile.name, style: text.titleSmall), PostMeta(post: post)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        StickerCard(
          padding: EdgeInsets.zero,
          child: SizedBox(height: compact ? 200 : 300, child: PostCover(post: post, emojiSize: compact ? 72 : 96)),
        ),
        const SizedBox(height: 36),
        MarkdownView(blocks: post.parsed.blocks, sourcePath: post.assetPath),
        if (subjects.isNotEmpty) ...[
          const SizedBox(height: 40),
          Text('ON THE ROADMAP', style: text.labelSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in subjects)
                Pill(
                  label: s.title,
                  leading: Text(s.emoji, style: const TextStyle(fontSize: 15, height: 1.15)),
                  color: context.palette.pastel(s.color),
                  textColor: context.palette.onPastel,
                  onTap: () => context.go(s.route),
                ),
            ],
          ),
        ],
        const SizedBox(height: Insets.xxl),
        const _AuthorCard(),
        const SizedBox(height: Insets.xl),
        NeighbourCards(
          previous: older == null ? null : NeighbourLink(label: 'Older post', title: older.title, route: older.route),
          next: newer == null ? null : NeighbourLink(label: 'Newer post', title: newer.title, route: newer.route),
        ),
      ],
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard();

  @override
  Widget build(BuildContext context) {
    final profile = context.content.profile;
    final text = Theme.of(context).textTheme;
    return StickerCard(
      child: Row(
        children: [
          CatAvatar(size: 76, image: profile.avatar),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WRITTEN BY', style: text.labelSmall),
                const SizedBox(height: 2),
                Text(profile.name, style: text.titleLarge),
                Text(profile.title, style: text.bodyMedium),
                const SizedBox(height: 4),
                const ArrowLink(label: 'More about me', href: '/profile'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

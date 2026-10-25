import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../content/text_utils.dart';
import '../../theme/tokens.dart';
import '../../widgets/blog/post_card.dart';
import '../../widgets/common/bits.dart';
import '../../widgets/layout/page_frame.dart';

/// Every post, newest first: tag filters, the featured post, then a grid.
class BlogListPage extends StatelessWidget {
  const BlogListPage({super.key, this.tag});

  /// Slug of the tag to filter by (`/blog?tag=study-tips`).
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final content = context.content;
    final tags = content.tags;
    final selected = tags.where((t) => slugify(t) == tag).firstOrNull;
    final posts = selected == null ? content.posts : content.posts.where((p) => p.tags.contains(selected)).toList();
    final featured = selected == null ? posts.where((p) => p.featured).firstOrNull : null;
    final rest = [for (final post in posts) if (post != featured) post];

    return PageFrame(
      title: selected == null ? 'Blog' : 'Posts about $selected',
      children: [
        const SectionHeader(
          kicker: 'Blog',
          title: 'Study notes & diaries',
          subtitle: 'How I study, what I studied, and what I learned along the way.',
          large: true,
        ),
        const SizedBox(height: Insets.lg),
        if (tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(label: 'All posts · ${content.posts.length}', selected: selected == null, onTap: () => context.go('/blog')),
              for (final t in tags)
                Pill(
                  label: '$t · ${content.postsTagged(t)}',
                  selected: t == selected,
                  onTap: () => context.go('/blog?tag=${slugify(t)}'),
                ),
            ],
          ),
        const SizedBox(height: Insets.xl),
        if (featured != null) ...[Appear(child: FeaturedPostCard(post: featured)), const SizedBox(height: Insets.xl)],
        if (posts.isEmpty)
          const CatEmptyState(title: 'No posts yet', message: 'The first one is on its way, right after this nap.')
        else if (rest.isNotEmpty)
          ResponsiveGrid(
            minItemWidth: 290,
            children: [
              for (final (i, post) in rest.indexed) Appear(delay: Duration(milliseconds: 60 * (i % 3)), child: PostCard(post: post)),
            ],
          ),
      ],
    );
  }
}

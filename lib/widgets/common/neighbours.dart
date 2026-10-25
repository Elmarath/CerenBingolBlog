import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_palette.dart';
import '../../theme/tokens.dart';
import 'sticker_card.dart';

class NeighbourLink {
  const NeighbourLink({required this.label, required this.title, required this.route, this.emoji});

  /// "Previous stop", "Older post", …
  final String label;
  final String title;
  final String route;
  final String? emoji;
}

/// Previous and next cards at the bottom of a subject or post.
class NeighbourCards extends StatelessWidget {
  const NeighbourCards({super.key, this.previous, this.next});

  final NeighbourLink? previous;
  final NeighbourLink? next;

  @override
  Widget build(BuildContext context) {
    if (previous == null && next == null) return const SizedBox.shrink();
    if (ScreenSize.of(context).isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (previous != null) _NeighbourCard(link: previous!, forward: false),
          if (previous != null && next != null) const SizedBox(height: 14),
          if (next != null) _NeighbourCard(link: next!, forward: true),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: previous == null ? const SizedBox.shrink() : _NeighbourCard(link: previous!, forward: false)),
        const SizedBox(width: Insets.lg - 4),
        Expanded(child: next == null ? const SizedBox.shrink() : _NeighbourCard(link: next!, forward: true)),
      ],
    );
  }
}

class _NeighbourCard extends StatelessWidget {
  const _NeighbourCard({required this.link, required this.forward});

  final NeighbourLink link;
  final bool forward;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return StickerCard(
      onTap: () => context.go(link.route),
      semanticLabel: '${link.label}: ${link.title}',
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: forward ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(link.label.toUpperCase(), style: text.labelSmall),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!forward) ...[Icon(Icons.arrow_back_rounded, size: 18, color: p.accent), const SizedBox(width: 8)],
              if (link.emoji != null) ...[
                Text(link.emoji!, style: const TextStyle(fontSize: 18, height: 1.15)),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  link.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: forward ? TextAlign.right : TextAlign.left,
                  style: text.titleMedium,
                ),
              ),
              if (forward) ...[const SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, size: 18, color: p.accent)],
            ],
          ),
        ],
      ),
    );
  }
}

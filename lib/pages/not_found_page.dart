import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';
import '../widgets/cats/cats.dart';
import '../widgets/common/sticker_card.dart';
import '../widgets/layout/page_frame.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageFrame(
      title: 'Page not found',
      children: [
        const SizedBox(height: Insets.xl),
        const CatFace(size: 132, mood: CatMood.surprised, blinks: true),
        const SizedBox(height: Insets.lg),
        Text('This page wandered off', style: text.displaySmall, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              'Like cats do. It’s probably napping somewhere warm. Let’s head back home.',
              style: text.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: [
            StickerButton(label: 'Take me home', icon: Icons.home_rounded, filled: true, onPressed: () => context.go('/')),
            StickerButton(label: 'Read the blog', icon: Icons.auto_stories_rounded, onPressed: () => context.go('/blog')),
          ],
        ),
      ],
    );
  }
}

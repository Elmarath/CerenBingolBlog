import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

/// An image from the asset bundle (`content/blog/…/photo.jpg`) or the web
/// (`https://…`). Shows a soft placeholder if it can't load.
class AppImage extends StatelessWidget {
  const AppImage(this.source, {super.key, this.fit = BoxFit.cover, this.semanticLabel});

  final String source;
  final BoxFit fit;
  final String? semanticLabel;

  bool get isUrl => RegExp(r'^(https?|data):', caseSensitive: false).hasMatch(source);

  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext context, Object error, StackTrace? stack) => ColoredBox(
      color: context.palette.surfaceAlt,
      child: Center(child: Icon(Icons.image_not_supported_outlined, color: context.palette.textMuted)),
    );
    return isUrl
        ? Image.network(source, fit: fit, semanticLabel: semanticLabel, errorBuilder: fallback)
        : Image.asset(source, fit: fit, semanticLabel: semanticLabel, errorBuilder: fallback);
  }
}

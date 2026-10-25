import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/tokens.dart';

/// The site's card: a rounded sticker with a chunky outline and a solid
/// offset shadow (after the outlined cartoons on nekoatsume.com).
///
/// With [onTap] it lifts on hover and squishes down when pressed.
class StickerCard extends StatefulWidget {
  const StickerCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding = const EdgeInsets.all(Insets.lg),
    this.radius = Radii.lg,
    this.depth = Strokes.shadow,
    this.semanticLabel,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Fill; defaults to the theme's surface.
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// How far the shadow sits from the card.
  final double depth;
  final String? semanticLabel;
  final String? tooltip;

  @override
  State<StickerCard> createState() => _StickerCardState();
}

class _StickerCardState extends State<StickerCard> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final interactive = widget.onTap != null;
    final lift = !interactive
        ? 0.0
        : _pressed
        ? -widget.depth * 0.75
        : _hovered
        ? 2.0
        : 0.0;
    final shadow = widget.depth + lift;
    final radius = BorderRadius.circular(widget.radius);

    Widget card = AnimatedContainer(
      duration: Motion.fast,
      curve: Motion.curve,
      transform: Matrix4.translationValues(-lift, -lift, 0),
      decoration: BoxDecoration(
        color: widget.color ?? p.surface,
        borderRadius: radius,
        boxShadow: [if (shadow > 0) BoxShadow(color: p.outline, offset: Offset(shadow, shadow))],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: _focused ? p.accent : p.outline, width: _focused ? 3 : Strokes.outline),
      ),
      clipBehavior: Clip.antiAlias,
      padding: widget.padding,
      child: widget.child,
    );
    if (!interactive) return card;

    card = Semantics(
      button: true,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap!();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: card,
        ),
      ),
    );
    return widget.tooltip == null ? card : Tooltip(message: widget.tooltip!, child: card);
  }
}

/// A pill-shaped button in the sticker style. [filled] for the main action.
class StickerButton extends StatelessWidget {
  const StickerButton({super.key, required this.label, required this.onPressed, this.icon, this.filled = false});

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = filled ? p.onButton : p.textPrimary;
    return StickerCard(
      onTap: onPressed,
      semanticLabel: label,
      color: filled ? p.button : p.surface,
      radius: 999,
      depth: 3.5,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 19, color: color), const SizedBox(width: 9)],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

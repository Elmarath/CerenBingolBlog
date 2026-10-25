import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../../app_scope.dart';
import '../../content/content_repository.dart';
import '../../content/markdown_blocks.dart';
import '../../content/text_utils.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../cats/cats.dart';
import '../common/app_image.dart';
import '../common/bits.dart';
import '../common/sticker_card.dart';

/// Renders parsed Markdown in the site's style: paw bullets, paw
/// checklists, cat callouts and outlined images.
///
/// [sourcePath] is the .md file's asset path; relative images and links are
/// resolved against it.
class MarkdownView extends StatelessWidget {
  const MarkdownView({super.key, required this.blocks, required this.sourcePath});

  final List<MdBlock> blocks;
  final String sourcePath;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final block in blocks) {
      if (children.isNotEmpty) children.add(SizedBox(height: block is MdHeading ? Insets.xl : Insets.md));
      children.add(_block(context, block));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  Widget _block(BuildContext context, MdBlock block) {
    final text = Theme.of(context).textTheme;
    switch (block) {
      case MdText(:final markdown):
        return _markdown(context, markdown);
      case MdHeading(:final level, text: final title):
        final style = switch (level) {
          1 => text.headlineLarge,
          2 => text.headlineMedium,
          3 => text.headlineSmall,
          _ => text.titleLarge,
        };
        if (level != 2) return Text(title, style: style);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 6), child: Paw(size: 20, angle: 0.3, color: context.palette.accent)),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: style)),
          ],
        );
      case MdCallout():
        return Callout(
          type: block.type,
          title: block.title,
          child: MarkdownView(blocks: block.children, sourcePath: sourcePath),
        );
      case MdChecklist(:final items):
        return PawChecklist(items: items, sourcePath: sourcePath);
    }
  }

  Widget _markdown(BuildContext context, String data) {
    final content = context.content;
    final p = context.palette;
    return MarkdownBody(
      data: data,
      styleSheet: markdownStyleSheet(context),
      extensionSet: md.ExtensionSet.gitHubFlavored,
      bulletBuilder: (params) => params.style == BulletStyle.unorderedList
          ? Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Paw(size: 12, color: params.nestLevel == 0 ? p.accent : p.textMuted, angle: 0.3),
            )
          : Text('${params.index + 1}.', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: p.accent, height: 1.9)),
      imageBuilder: (uri, title, alt) => MarkdownImage(source: ContentRepository.resolveAsset(sourcePath, uri.toString()), alt: alt),
      onTapLink: (text, href, title) {
        if (href == null) return;
        openLink(context, content.internalRoute(href, sourcePath: sourcePath) ?? href);
      },
    );
  }
}

MarkdownStyleSheet markdownStyleSheet(BuildContext context) {
  final p = context.palette;
  final text = Theme.of(context).textTheme;
  final body = text.bodyLarge!;
  return MarkdownStyleSheet(
    p: body,
    pPadding: EdgeInsets.zero,
    a: body.copyWith(
      color: p.link,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: p.accent.withValues(alpha: 0.5),
      decorationThickness: 2,
    ),
    strong: TextStyle(fontWeight: FontWeight.w800, color: p.textPrimary),
    em: const TextStyle(fontStyle: FontStyle.italic),
    del: TextStyle(decoration: TextDecoration.lineThrough, color: p.textMuted),
    h1: text.headlineLarge,
    h2: text.headlineMedium,
    h3: text.headlineSmall,
    h4: text.titleLarge,
    h5: text.titleMedium,
    h6: text.titleSmall,
    code: AppTheme.code(fontSize: 14.5, color: p.textPrimary).copyWith(backgroundColor: p.surfaceAlt),
    codeblockPadding: const EdgeInsets.all(Insets.md),
    codeblockDecoration: BoxDecoration(
      color: p.surfaceAlt,
      borderRadius: Radii.mdAll,
      border: Border.all(color: p.border, width: 1.5),
    ),
    blockSpacing: Insets.md,
    listIndent: 28,
    listBullet: body.copyWith(color: p.accent),
    listBulletPadding: const EdgeInsets.only(right: 8),
    blockquote: body.copyWith(color: p.textSecondary, fontStyle: FontStyle.italic),
    blockquotePadding: const EdgeInsets.fromLTRB(Insets.md, Insets.sm + 2, Insets.md, Insets.sm + 2),
    blockquoteDecoration: BoxDecoration(
      color: p.surfaceAlt,
      borderRadius: Radii.mdAll,
      border: Border(left: BorderSide(color: p.accent, width: 4)),
    ),
    horizontalRuleDecoration: BoxDecoration(border: Border(top: BorderSide(color: p.border, width: 2))),
    tableHead: text.titleSmall,
    tableBody: text.bodyMedium,
    tableBorder: TableBorder.all(color: p.border, width: 1.5, borderRadius: Radii.mdAll),
    tableHeadAlign: TextAlign.left,
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    tableCellsDecoration: BoxDecoration(color: p.surface),
    tableColumnWidth: const _SafeIntrinsicColumnWidth(),
    tableScrollbarThumbVisibility: false,
    checkbox: body.copyWith(color: p.accent),
  );
}

/// Sizes table columns to their content (wide tables scroll sideways).
///
/// Adds a couple of pixels: on the web the measured text width can come out
/// a fraction too small, wrapping the last character onto a new line.
class _SafeIntrinsicColumnWidth extends IntrinsicColumnWidth {
  const _SafeIntrinsicColumnWidth();

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) =>
      super.minIntrinsicWidth(cells, containerWidth) + 2;

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) =>
      super.maxIntrinsicWidth(cells, containerWidth) + 2;
}

/// An image in a post: rounded, outlined, with its alt text as a caption.
class MarkdownImage extends StatelessWidget {
  const MarkdownImage({super.key, required this.source, this.alt});

  final String source;
  final String? alt;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.sm),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: StickerCard(
              padding: EdgeInsets.zero,
              radius: Radii.md,
              depth: 3,
              child: AppImage(source, fit: BoxFit.contain, semanticLabel: alt),
            ),
          ),
          if (alt != null && alt!.trim().isNotEmpty) ...[
            const SizedBox(height: Insets.sm),
            Text(alt!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: p.textMuted), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// `:::tip` and friends: a pastel box with a cat that matches the mood.
class Callout extends StatelessWidget {
  const Callout({super.key, required this.type, required this.title, required this.child});

  final String type;
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (emoji, label, color) = switch (type) {
      'tip' => ('😺', 'Tip', 'mint'),
      'info' => ('🐈', 'Good to know', 'lilac'),
      'warning' => ('🙀', 'Careful', 'butter'),
      'danger' => ('😾', 'Watch out', 'coral'),
      _ => ('🐱', 'Note', 'sky'),
    };
    return StickerCard(
      color: p.pastel(color),
      depth: 3,
      padding: const EdgeInsets.fromLTRB(Insets.md + 2, Insets.md, Insets.md + 2, Insets.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22, height: 1.15)),
              const SizedBox(width: 10),
              Expanded(child: Text(title ?? label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: p.onPastel))),
            ],
          ),
          const SizedBox(height: Insets.sm),
          DefaultTextStyle.merge(style: TextStyle(color: p.onPastel), child: child),
        ],
      ),
    );
  }
}

/// `- [ ]` lists, with paws for checkboxes: an outline to do, half-filled in
/// progress, a filled stamp when done, plus the date when there is one.
class PawChecklist extends StatelessWidget {
  const PawChecklist({super.key, required this.items, required this.sourcePath});

  final List<CheckItem> items;
  final String sourcePath;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.lgAll,
        border: Border.all(color: p.border, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) Divider(color: p.border, height: 1),
            _CheckRow(item: item, sourcePath: sourcePath),
          ],
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.item, required this.sourcePath});

  final CheckItem item;
  final String sourcePath;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final date = item.date;
    final link = item.link;
    final (dateLabel, dateColor) = item.isDone ? ('done ${formatShortDate(date ?? DateTime(0))}', p.done) : ('planned ${formatShortDate(date ?? DateTime(0))}', p.textMuted);
    final row = Padding(
      padding: EdgeInsets.only(left: item.depth * 26.0, top: 10, bottom: 10),
      child: Row(
        children: [
          PawCheck(state: item.state),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.text,
              style: text.bodyLarge?.copyWith(
                height: 1.4,
                color: item.state == CheckState.todo ? p.textSecondary : p.textPrimary,
                fontWeight: item.isDone ? FontWeight.w700 : null,
              ),
            ),
          ),
          if (item.state == CheckState.doing) ...[
            const SizedBox(width: Insets.sm),
            Text('studying', style: AppTheme.hand(fontSize: 19, color: p.doing)),
          ],
          if (date != null) ...[
            const SizedBox(width: Insets.sm),
            Text(dateLabel, style: text.labelMedium?.copyWith(color: dateColor)),
          ],
          if (link != null) ...[
            const SizedBox(width: Insets.xs),
            Icon(Icons.north_east_rounded, size: 16, color: p.link),
          ],
        ],
      ),
    );
    final label = '${item.text}, ${switch (item.state) {
      CheckState.done => 'done',
      CheckState.doing => 'in progress',
      CheckState.todo => 'not done yet',
    }}';
    if (link == null) return Semantics(label: label, excludeSemantics: true, child: row);
    return Semantics(
      link: true,
      label: label,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => openLink(context, context.content.internalRoute(link, sourcePath: sourcePath) ?? link),
          child: row,
        ),
      ),
    );
  }
}

/// A round paw checkbox.
class PawCheck extends StatelessWidget {
  const PawCheck({super.key, required this.state, this.size = 28});

  final CheckState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (fill, border, paw) = switch (state) {
      CheckState.done => (p.accent, p.outline, Colors.white),
      CheckState.doing => (p.doing.withValues(alpha: 0.22), p.doing, p.doing),
      CheckState.todo => (Colors.transparent, p.border, p.border),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: border, width: Strokes.outline),
      ),
      child: Paw(size: size * 0.56, color: paw),
    );
  }
}

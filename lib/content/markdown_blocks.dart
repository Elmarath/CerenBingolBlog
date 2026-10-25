import 'text_utils.dart';

/// A Markdown body split into blocks the site renders with its own widgets.
///
/// Plain Markdown stays [MdText]. On top of that:
///
/// * `## Heading` → [MdHeading]
/// * `- [ ] topic`, `- [/] topic`, `- [x] topic (2026-10-25)` → [MdChecklist],
///   drawn with paw checkboxes. In a roadmap subject these are its topics.
/// * `:::tip Title` … `:::` and GitHub's `> [!TIP]` → [MdCallout]
///
/// HTML comments (`<!-- … -->`) are notes to yourself and never show.
sealed class MdBlock {
  const MdBlock();
}

class MdText extends MdBlock {
  const MdText(this.markdown);
  final String markdown;
}

class MdHeading extends MdBlock {
  const MdHeading({required this.level, required this.text});

  final int level;

  /// Plain text (Markdown stripped).
  final String text;
}

class MdCallout extends MdBlock {
  const MdCallout({required this.type, required this.title, required this.children});

  /// note, tip, info, warning or danger.
  final String type;
  final String? title;
  final List<MdBlock> children;
}

class MdChecklist extends MdBlock {
  const MdChecklist(this.items);
  final List<CheckItem> items;
}

enum CheckState { todo, doing, done }

/// One `- [ ]` line.
///
/// `[x]` is done, `[/]` (or `[~]`) is in progress, `[ ]` is still to do. A
/// date at the end of the line, like `(2026-10-25)`, is when it was done, or
/// for unfinished items, when it's planned.
class CheckItem {
  const CheckItem({required this.text, required this.state, this.date, this.link, this.depth = 0});

  final String text;
  final CheckState state;
  final DateTime? date;

  /// The first link on the line, if any: tapping the item opens it.
  final String? link;

  /// Indentation level, for nested lists.
  final int depth;

  bool get isDone => state == CheckState.done;

  static final _line = RegExp(r'^(\s*)[-*+]\s+\[([ xX/~])\]\s+(.*\S)\s*$');
  static final _trailingDate = RegExp(r'\s*(?:[-–—·•@|,]\s*)?\(?\s*(\d{4}-\d{2}-\d{2})\s*\)?\s*$');
  static final _link = RegExp(r'\[[^\]]*\]\(([^)\s]+)[^)]*\)');

  static CheckItem? tryParse(String line) {
    final match = _line.firstMatch(line);
    if (match == null) return null;
    var text = match.group(3)!;
    DateTime? date;
    final dateMatch = _trailingDate.firstMatch(text);
    if (dateMatch != null && dateMatch.start > 0) {
      date = DateTime.tryParse(dateMatch.group(1)!);
      if (date != null) text = text.substring(0, dateMatch.start);
    }
    final indent = match.group(1)!.replaceAll('\t', '    ').length;
    return CheckItem(
      text: plainText(text),
      state: switch (match.group(2)!) {
        'x' || 'X' => CheckState.done,
        '/' || '~' => CheckState.doing,
        _ => CheckState.todo,
      },
      date: date,
      link: _link.firstMatch(text)?.group(1),
      depth: indent ~/ 2,
    );
  }
}

class ParsedMarkdown {
  const ParsedMarkdown(this.blocks);

  final List<MdBlock> blocks;

  /// Items of the checklists at the top level (not inside callouts).
  List<CheckItem> get checkItems => [
    for (final block in blocks)
      if (block is MdChecklist) ...block.items,
  ];

  static ParsedMarkdown parse(String body) {
    final text = body.replaceAll('\r\n', '\n').replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
    return ParsedMarkdown(_parseBlocks(text.split('\n'), topLevel: true));
  }
}

const _calloutTypes = {
  'note': 'note',
  'tip': 'tip',
  'info': 'info',
  'important': 'info',
  'warning': 'warning',
  'caution': 'warning',
  'danger': 'danger',
};

final _fence = RegExp(r'^\s*(```|~~~)');
final _calloutStart = RegExp(r'^\s*:::\s*([a-zA-Z]+)\s*(.*)$');
final _calloutEnd = RegExp(r'^\s*:::\s*$');
final _githubAlert = RegExp(
  r'^\s*>\s*\[!(NOTE|TIP|INFO|IMPORTANT|WARNING|CAUTION|DANGER)\]\s*(.*)$',
  caseSensitive: false,
);
final _heading = RegExp(r'^(#{1,6})\s+(.+?)\s*#*\s*$');

List<MdBlock> _parseBlocks(List<String> lines, {required bool topLevel}) {
  final blocks = <MdBlock>[];
  final buffer = <String>[];
  final checklist = <CheckItem>[];
  var inFence = false;
  String? fenceMarker;

  void flushText() {
    final text = buffer.join('\n').trim();
    if (text.isNotEmpty) blocks.add(MdText(text));
    buffer.clear();
  }

  void flushChecklist() {
    if (checklist.isNotEmpty) blocks.add(MdChecklist(List.of(checklist)));
    checklist.clear();
  }

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    final fence = _fence.firstMatch(line);
    if (fence != null || inFence) {
      if (fence != null && !inFence) {
        flushChecklist();
        inFence = true;
        fenceMarker = fence.group(1);
      } else if (fence != null && line.trim().startsWith(fenceMarker!)) {
        inFence = false;
      }
      buffer.add(line);
      continue;
    }

    if (line.trim().isEmpty) {
      // Blank lines inside a checklist don't end it.
      if (checklist.isEmpty) buffer.add(line);
      continue;
    }

    final item = CheckItem.tryParse(line);
    if (item != null) {
      flushText();
      checklist.add(item);
      continue;
    }
    flushChecklist();

    final callout = _calloutStart.firstMatch(line);
    if (callout != null && _calloutTypes.containsKey(callout.group(1)!.toLowerCase())) {
      flushText();
      final inner = <String>[];
      var depth = 1;
      var innerFence = false;
      i++;
      for (; i < lines.length; i++) {
        final l = lines[i];
        if (_fence.hasMatch(l)) innerFence = !innerFence;
        if (!innerFence) {
          if (_calloutEnd.hasMatch(l)) {
            depth--;
            if (depth == 0) break;
          } else if (_calloutStart.hasMatch(l)) {
            depth++;
          }
        }
        inner.add(l);
      }
      blocks.add(MdCallout(
        type: _calloutTypes[callout.group(1)!.toLowerCase()]!,
        title: _cleanTitle(callout.group(2)),
        children: _parseBlocks(_dedent(inner), topLevel: false),
      ));
      continue;
    }

    final alert = _githubAlert.firstMatch(line);
    if (alert != null) {
      flushText();
      final inner = <String>[if (alert.group(2)!.trim().isNotEmpty) alert.group(2)!.trim()];
      while (i + 1 < lines.length && lines[i + 1].trimLeft().startsWith('>')) {
        i++;
        inner.add(lines[i].trimLeft().replaceFirst(RegExp(r'^>\s?'), ''));
      }
      blocks.add(MdCallout(
        type: _calloutTypes[alert.group(1)!.toLowerCase()] ?? 'note',
        title: null,
        children: _parseBlocks(inner, topLevel: false),
      ));
      continue;
    }

    final heading = _heading.firstMatch(line);
    if (heading != null && topLevel) {
      flushText();
      blocks.add(MdHeading(level: heading.group(1)!.length, text: plainText(heading.group(2)!)));
      continue;
    }

    buffer.add(line);
  }
  flushText();
  flushChecklist();
  return blocks;
}

String? _cleanTitle(String? raw) {
  final t = raw?.replaceAll('*', '').trim();
  return t == null || t.isEmpty ? null : t;
}

/// Removes the indentation shared by all non-empty lines (tabs count as 4).
List<String> _dedent(List<String> lines) {
  final expanded = lines.map((l) => l.replaceAll('\t', '    ')).toList();
  int? minIndent;
  for (final l in expanded) {
    if (l.trim().isEmpty) continue;
    final indent = l.length - l.trimLeft().length;
    if (minIndent == null || indent < minIndent) minIndent = indent;
  }
  final indent = minIndent ?? 0;
  if (indent == 0) return expanded;
  return expanded.map((l) => l.length >= indent ? l.substring(indent) : l.trimLeft()).toList();
}

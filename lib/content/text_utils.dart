import 'package:yaml/yaml.dart';

const _turkish = {'ç': 'c', 'ğ': 'g', 'ı': 'i', 'İ': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u', 'Ç': 'c', 'Ğ': 'g', 'Ö': 'o', 'Ş': 's', 'Ü': 'u'};

/// Turns a file name, title or tag into a URL-safe id.
///
/// `01-anatomy.md` → `anatomy`, `Küçük Stajlar` → `kucuk-stajlar`,
/// `Study Tips` → `study-tips`.
String slugify(String input, {bool stripNumberPrefix = true}) {
  var s = input;
  try {
    s = Uri.decodeComponent(s);
  } catch (_) {}
  s = s.replaceAll(RegExp(r'\.(md|ya?ml)$', caseSensitive: false), '');
  if (stripNumberPrefix) s = s.replaceFirst(RegExp(r'^\d+[-_.\s]+(?=\S)'), '');
  s = s.split('').map((c) => _turkish[c] ?? c).join();
  s = s.replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]}-${m[2]}');
  s = s.toLowerCase().replaceAll(RegExp(r"['’]"), '');
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return s.replaceAll(RegExp(r'^-+|-+$'), '');
}

/// `02-general-surgery` → `General surgery`.
String humanize(String input) {
  var s = input.replaceAll(RegExp(r'\.md$'), '');
  s = s.replaceFirst(RegExp(r'^\d+[-_.\s]+(?=\S)'), '');
  s = s.replaceAll(RegExp(r'[-_]+'), ' ').trim();
  return s.isEmpty ? input : s[0].toUpperCase() + s.substring(1);
}

/// Strips Markdown syntax to get readable text (excerpts, topics, search).
String plainText(String markdown) {
  var s = markdown;
  s = s.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
  s = s.replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ');
  s = s.replaceAll(RegExp(r'!\[([^\]]*)\]\([^)]*\)'), '');
  s = s.replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m[1]!);
  s = s.replaceAll(RegExp(r'<[^>]+>'), '');
  s = s.replaceAll(RegExp(r'^\s{0,3}(#{1,6}|>|[-*+]|\d+\.)\s+(\[[ xX/~]\]\s+)?', multiLine: true), '');
  s = s.replaceAll(RegExp(r'^:{2,}.*$', multiLine: true), '');
  s = s.replaceAll(RegExp(r'[*_`~|]'), '');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// `Oct 25, 2026`.
String formatDate(DateTime date) => '${_months[date.month - 1]} ${date.day}, ${date.year}';

/// `Oct 25`, with the year only when it isn't [now]'s year.
String formatShortDate(DateTime date, {DateTime? now}) {
  final thisYear = (now ?? DateTime.now()).year;
  final day = '${_months[date.month - 1]} ${date.day}';
  return date.year == thisYear ? day : '$day, ${date.year}';
}

/// A date written loosely: a day (`2026-10-25`), a month (`2026-10`) or a
/// year (`2026`). Returns the date to sort by and how to show it.
(DateTime?, String) parseLooseDate(Object? value) {
  final s = value?.toString().trim() ?? '';
  final day = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(s);
  if (day != null) {
    final date = DateTime(int.parse(day[1]!), int.parse(day[2]!), int.parse(day[3]!));
    return (date, formatDate(date));
  }
  final month = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(s);
  if (month != null) {
    final m = int.parse(month[2]!).clamp(1, 12);
    return (DateTime(int.parse(month[1]!), m), '${_months[m - 1]} ${month[1]}');
  }
  final year = RegExp(r'^(\d{4})$').firstMatch(s);
  if (year != null) return (DateTime(int.parse(year[1]!)), year[1]!);
  return (null, s);
}

/// A Markdown file split into its YAML front matter and body.
class FrontMatterDocument {
  const FrontMatterDocument(this.data, this.body);

  final Map<String, dynamic> data;
  final String body;

  static FrontMatterDocument parse(String raw) {
    final text = raw.replaceAll('\r\n', '\n');
    final match = RegExp(r'^---[ \t]*\n([\s\S]*?)\n---[ \t]*(\n|$)').firstMatch(text);
    if (match == null) return FrontMatterDocument(const {}, text);
    return FrontMatterDocument(parseYamlMap(match.group(1)!), text.substring(match.end));
  }

  String? string(String key) {
    final value = data[key];
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  bool flag(String key) => data[key] == true || data[key]?.toString() == 'true';

  /// A YAML list (`[a, b]` or one item per line) or a comma-separated string.
  List<String> list(String key) {
    final value = data[key];
    if (value is List) return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    if (value is String) {
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  /// A YAML list of maps, such as `milestones:`.
  List<Map<String, dynamic>> maps(String key) {
    final value = data[key];
    if (value is! List) return const [];
    return [for (final item in value) if (item is Map<String, dynamic>) item];
  }
}

/// Parses YAML (or JSON, which is valid YAML) into plain Dart maps and lists.
Map<String, dynamic> parseYamlMap(String source) {
  if (source.trim().isEmpty) return {};
  final value = _plain(loadYaml(source));
  return value is Map<String, dynamic> ? value : {};
}

dynamic _plain(dynamic node) {
  if (node is YamlMap) {
    return <String, dynamic>{for (final e in node.entries) e.key.toString(): _plain(e.value)};
  }
  if (node is YamlList) return node.map(_plain).toList();
  return node;
}

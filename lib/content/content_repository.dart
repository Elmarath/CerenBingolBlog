import 'models.dart';
import 'text_utils.dart';

/// All the site's content, parsed once at startup from the files in `content/`:
///
/// * `content/profile.md`                    → [profile]
/// * `content/roadmap/<part>/_part_.yaml`    → a part of the roadmap (basic sciences, …)
/// * `content/roadmap/<part>/NN-subject.md`  → a subject; its `- [ ]` lines are the topics
/// * `content/blog/YYYY-MM-DD-slug.md`       → a post (or `…-slug/index.md`, with images beside it)
///
/// Plain Dart, so `tool/content.dart` reads the content exactly like the site does.
class ContentRepository {
  ContentRepository._({required this.profile, required this.parts, required this.posts});

  /// [files] maps paths like `content/blog/2026-10-25-hello.md` to their text.
  factory ContentRepository.fromFiles(Map<String, String> files, {bool includeDrafts = false}) {
    final normalized = {for (final e in files.entries) e.key.replaceAll(r'\', '/'): e.value};
    return ContentRepository._(
      profile: _parseProfile(normalized),
      parts: _parseRoadmap(normalized),
      posts: _parsePosts(normalized, includeDrafts: includeDrafts),
    );
  }

  final Profile profile;
  final List<RoadmapPart> parts;

  /// Newest first.
  final List<BlogPost> posts;

  /// Every subject, in roadmap order.
  late final List<Subject> subjects = [for (final p in parts) ...p.subjects];
  late final Map<String, Subject> _subjectsById = {for (final s in subjects.reversed) s.id: s};

  Subject? subject(String id) => _subjectsById[id];
  BlogPost? post(String slug) => posts.where((p) => p.slug == slug).firstOrNull;

  int get topicCount => subjects.fold(0, (n, s) => n + s.topicCount);
  int get doneTopicCount => subjects.fold(0, (n, s) => n + s.doneCount);
  int get subjectsDone => subjects.where((s) => s.status == SubjectStatus.done).length;
  double get progress => topicCount == 0 ? 0 : doneTopicCount / topicCount;

  /// The subject being studied now (the first one in progress), else the next one to start.
  Subject? get currentSubject =>
      subjects.where((s) => s.status == SubjectStatus.doing).firstOrNull ??
      subjects.where((s) => s.status == SubjectStatus.todo).firstOrNull;

  /// Everything ticked off with a date, newest first. A finished subject
  /// comes before the topic that finished it.
  late final List<Win> wins = () {
    final wins = <Win>[];
    for (final s in subjects) {
      for (final t in s.topics) {
        if (t.isDone && t.date != null) wins.add(Win(date: t.date!, subject: s, topic: t));
      }
      final finished = s.finishedOn;
      if (finished != null) wins.add(Win(date: finished, subject: s));
    }
    wins.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return (a.isSubject ? 0 : 1).compareTo(b.isSubject ? 0 : 1);
    });
    return wins;
  }();

  /// Tags by how many posts use them.
  List<String> get tags {
    final counts = <String, int>{};
    for (final p in posts) {
      for (final t in p.tags) {
        counts.update(t, (c) => c + 1, ifAbsent: () => 1);
      }
    }
    return counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }

  int postsTagged(String tag) => posts.where((p) => p.tags.contains(tag)).length;

  List<BlogPost> postsAbout(Subject subject) => posts.where((p) => p.subjectIds.contains(subject.id)).toList();

  List<Subject> subjectsOf(BlogPost post) => [
    for (final id in post.subjectIds)
      if (subject(id) case final s?) s,
  ];

  /// The subject [delta] stops away on the roadmap.
  Subject? subjectAround(Subject s, int delta) {
    final i = subjects.indexOf(s) + delta;
    return i >= 0 && i < subjects.length ? subjects[i] : null;
  }

  /// Older ([delta] = 1) or newer ([delta] = -1) post.
  BlogPost? postAround(BlogPost p, int delta) {
    final i = posts.indexOf(p) + delta;
    return i >= 0 && i < posts.length ? posts[i] : null;
  }

  /// Resolves an image path written in Markdown, relative to the file it's in.
  ///
  /// URLs stay as they are, `/assets/x.png` is the asset `assets/x.png`, other
  /// absolute paths are under `content/`, and relative paths sit next to the file.
  static String resolveAsset(String sourcePath, String src) {
    final s = src.trim();
    if (RegExp(r'^(https?|data):', caseSensitive: false).hasMatch(s)) return s;
    if (s.startsWith('/assets/')) return s.substring(1);
    if (s.startsWith('/')) return 'content$s';
    try {
      return Uri.decodeFull(Uri(path: sourcePath).resolve(s).path);
    } catch (_) {
      return '${sourcePath.substring(0, sourcePath.lastIndexOf('/'))}/$s';
    }
  }

  /// Maps a Markdown link to a page on this site, or null if it goes elsewhere.
  ///
  /// Understands site paths (`/roadmap/anatomy`) and links to content files
  /// (`../roadmap/basic/01-anatomy.md`, `./2026-10-25-hello.md`).
  String? internalRoute(String href, {required String sourcePath}) {
    final link = href.trim();
    if (link.isEmpty || RegExp(r'^[a-z][a-z0-9+.-]*:', caseSensitive: false).hasMatch(link)) return null;
    if (link.startsWith('#')) return null;
    if (!link.endsWith('.md')) return link.startsWith('/') ? link : null;
    final path = link.startsWith('/') ? 'content$link' : resolveAsset(sourcePath, link);
    for (final s in subjects) {
      if (s.assetPath == path) return s.route;
    }
    for (final p in posts) {
      if (p.assetPath == path) return p.route;
    }
    return null;
  }

  static Profile _parseProfile(Map<String, String> files) {
    const path = 'content/profile.md';
    final fm = FrontMatterDocument.parse(files[path] ?? '');
    final avatar = fm.string('avatar');
    return Profile(
      name: fm.string('name') ?? 'Ceren Bingöl',
      title: fm.string('title') ?? 'Medical doctor',
      intro: fm.string('intro'),
      avatar: avatar == null ? null : resolveAsset(path, avatar),
      location: fm.string('location'),
      exam: fm.string('exam'),
      examDate: DateTime.tryParse(fm.string('exam_date') ?? ''),
      socials: [
        for (final s in fm.maps('socials'))
          if (s['url'] != null) SocialLink(label: (s['label'] ?? s['url']).toString(), url: s['url'].toString()),
      ],
      facts: [
        for (final f in fm.maps('facts'))
          if (f['value'] != null)
            ProfileFact(emoji: f['emoji']?.toString() ?? '🐾', label: f['label']?.toString() ?? '', value: f['value'].toString()),
      ],
      milestones: [
        for (final m in fm.maps('milestones'))
          if (m['title'] != null)
            () {
              final (date, label) = parseLooseDate(m['date']);
              return Milestone(
                date: date,
                dateLabel: label,
                title: m['title'].toString(),
                emoji: m['emoji']?.toString(),
                text: m['text']?.toString(),
              );
            }(),
      ],
      bio: fm.body,
      assetPath: path,
    );
  }

  static List<RoadmapPart> _parseRoadmap(Map<String, String> files) {
    const root = 'content/roadmap/';
    final partMeta = <String, Map<String, dynamic>>{};
    final subjectsByPart = <String, List<Subject>>{};

    for (final MapEntry(key: path, value: text) in files.entries) {
      if (!path.startsWith(root)) continue;
      final relative = path.substring(root.length).split('/');
      if (relative.length != 2) continue;
      final [folder, file] = relative;
      if (RegExp(r'^_part_\.ya?ml$').hasMatch(file)) {
        partMeta[folder] = parseYamlMap(text);
        continue;
      }
      if (!file.endsWith('.md')) continue;

      final fm = FrontMatterDocument.parse(text);
      final (h1, body) = _extractTitle(fm.body);
      final baseName = file.substring(0, file.length - 3);
      subjectsByPart.putIfAbsent(folder, () => []).add(
        Subject(
          id: slugify(fm.string('id') ?? baseName),
          title: fm.string('title') ?? h1 ?? humanize(baseName),
          titleTr: fm.string('title_tr'),
          emoji: fm.string('emoji') ?? '📘',
          description: fm.string('description'),
          statusOverride: _status(fm.string('status')),
          position: _position(fm.data['position'], baseName),
          body: body,
          assetPath: path,
        )..color = _pastel(fm.string('color')) ?? '',
      );
    }

    final parts = <RoadmapPart>[];
    for (final folder in {...partMeta.keys, ...subjectsByPart.keys}) {
      final subjects = subjectsByPart[folder] ?? [];
      if (subjects.isEmpty) continue;
      subjects.sort((a, b) {
        final byPosition = a.position.compareTo(b.position);
        return byPosition != 0 ? byPosition : a.title.compareTo(b.title);
      });
      final meta = partMeta[folder] ?? const {};
      final title = meta['title']?.toString() ?? humanize(folder);
      parts.add(
        RoadmapPart(
          id: slugify(folder),
          title: title,
          titleTr: meta['title_tr']?.toString(),
          shortTitle: meta['short']?.toString() ?? title,
          emoji: meta['emoji']?.toString() ?? '🐾',
          description: meta['description']?.toString(),
          position: _position(meta['position'], folder),
          subjects: subjects,
        ),
      );
    }
    parts.sort((a, b) => a.position.compareTo(b.position));

    // Subjects without a `color:` take the next pastel along the road.
    var index = 0;
    for (final part in parts) {
      for (final subject in part.subjects) {
        subject.part = part;
        if (subject.color.isEmpty) subject.color = pastelNames[index % pastelNames.length];
        index++;
      }
    }
    return parts;
  }

  static List<BlogPost> _parsePosts(Map<String, String> files, {required bool includeDrafts}) {
    final posts = <BlogPost>[];
    for (final MapEntry(key: path, value: text) in files.entries) {
      if (!path.startsWith('content/blog/') || !path.endsWith('.md')) continue;
      final relative = path.substring('content/blog/'.length).split('/');
      final String baseName;
      if (relative.length == 1) {
        baseName = relative.first.substring(0, relative.first.length - 3);
      } else if (relative.length == 2 && relative.last == 'index.md') {
        baseName = relative.first;
      } else {
        continue;
      }

      final fm = FrontMatterDocument.parse(text);
      final draft = fm.flag('draft');
      if (draft && !includeDrafts) continue;

      final nameMatch = RegExp(r'^(\d{4}-\d{2}-\d{2})[-_]?(.*)$').firstMatch(baseName);
      final date =
          DateTime.tryParse(fm.string('date') ?? '') ?? DateTime.tryParse(nameMatch?.group(1) ?? '') ?? DateTime(2000);
      final (h1, body) = _extractTitle(fm.body);
      final title = fm.string('title') ?? h1 ?? humanize(nameMatch?.group(2) ?? baseName);
      final slug = slugify(fm.string('slug') ?? (nameMatch?.group(2)?.isNotEmpty == true ? nameMatch!.group(2)! : title));

      var excerpt = fm.string('description');
      if (excerpt == null) {
        final cut = body.indexOf('<!-- truncate -->');
        final intro = cut >= 0 ? body.substring(0, cut) : body.trim().split(RegExp(r'\n\s*\n')).first;
        excerpt = plainText(intro);
      }
      if (excerpt.length > 220) excerpt = '${excerpt.substring(0, 217).trimRight()}…';

      final image = fm.string('image');
      posts.add(
        BlogPost(
          slug: slug,
          title: title,
          date: date,
          tags: fm.list('tags'),
          subjectIds: fm.list('subjects').map(slugify).toList(),
          excerpt: excerpt,
          body: body,
          assetPath: path,
          image: image == null ? null : resolveAsset(path, image),
          emoji: fm.string('emoji') ?? '🐾',
          color: _pastel(fm.string('color')) ?? pastelNames[slug.codeUnits.fold(0, (a, b) => a + b) % pastelNames.length],
          draft: draft,
          featured: fm.flag('featured'),
          readingMinutes: (plainText(body).split(' ').length / 200).ceil().clamp(1, 999),
        ),
      );
    }
    posts.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      return byDate != 0 ? byDate : a.title.compareTo(b.title);
    });
    return posts;
  }

  static SubjectStatus? _status(String? value) => switch (value?.toLowerCase()) {
    'done' || 'finished' || 'complete' || 'completed' => SubjectStatus.done,
    'doing' || 'studying' || 'started' || 'in progress' => SubjectStatus.doing,
    'todo' || 'to do' || 'not started' => SubjectStatus.todo,
    _ => null,
  };

  static String? _pastel(String? name) {
    final n = name?.toLowerCase();
    return pastelNames.contains(n) ? n : null;
  }

  /// Front matter position, else a numeric file prefix (`02-physiology.md`), else last.
  static double _position(Object? value, String name) {
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
    final prefix = RegExp(r'^(\d+)[-_.\s]').firstMatch(name);
    return prefix != null ? double.parse(prefix.group(1)!) : 1e6;
  }

  /// Pulls a leading `# Title` out of the body, since pages show titles themselves.
  static (String?, String) _extractTitle(String body) {
    final match = RegExp(r'^\s*#\s+(.+?)\s*#*\s*(\n|$)').firstMatch(body);
    if (match == null) return (null, body);
    return (plainText(match.group(1)!), body.substring(match.end));
  }
}

/// The files the site reads: Markdown and YAML.
bool isContentTextFile(String path) => path.endsWith('.md') || path.endsWith('.yaml') || path.endsWith('.yml');

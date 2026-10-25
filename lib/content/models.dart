import 'markdown_blocks.dart';

/// The pastel colours a subject or post can use (`color: mint`). Each theme
/// has its own shade of every one.
const pastelNames = ['pink', 'peach', 'butter', 'mint', 'sky', 'lilac', 'coral', 'sage'];

/// `content/profile.md`: the Profile page, the home page greeting and the
/// author box under posts.
class Profile {
  Profile({
    required this.name,
    required this.title,
    required this.intro,
    required this.avatar,
    required this.location,
    required this.exam,
    required this.examDate,
    required this.socials,
    required this.facts,
    required this.milestones,
    required this.bio,
    required this.assetPath,
  });

  final String name;

  /// One line under the name, e.g. "Medical doctor · Preparing for TUS".
  final String title;

  /// The text under "Hi, I'm …" on the home page.
  final String? intro;

  /// A photo (asset path or URL). Without one, a drawn cat stands in.
  final String? avatar;
  final String? location;

  /// The exam being prepared for, e.g. "TUS".
  final String? exam;

  /// Exam day, for the countdown.
  final DateTime? examDate;
  final List<SocialLink> socials;
  final List<ProfileFact> facts;
  final List<Milestone> milestones;
  final String bio;
  final String assetPath;

  late final ParsedMarkdown parsed = ParsedMarkdown.parse(bio);

  String get firstName => name.split(' ').first;

  /// Whole days from [today] until the exam; null without a date or once it's passed.
  int? daysUntilExam(DateTime today) {
    if (examDate == null) return null;
    final days = DateTime(examDate!.year, examDate!.month, examDate!.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    return days < 0 ? null : days;
  }
}

class SocialLink {
  const SocialLink({required this.label, required this.url});
  final String label;
  final String url;
}

class ProfileFact {
  const ProfileFact({required this.emoji, required this.label, required this.value});
  final String emoji;
  final String label;
  final String value;
}

class Milestone {
  const Milestone({required this.date, required this.dateLabel, required this.title, this.emoji, this.text});

  final DateTime? date;

  /// The date as it should read: "Oct 25, 2026", "Jun 2025" or "2024".
  final String dateLabel;
  final String title;
  final String? emoji;
  final String? text;
}

/// A group of subjects on the roadmap, from `content/roadmap/<folder>/_part_.yaml`.
class RoadmapPart {
  RoadmapPart({
    required this.id,
    required this.title,
    required this.titleTr,
    required this.shortTitle,
    required this.emoji,
    required this.description,
    required this.position,
    required this.subjects,
  });

  final String id;
  final String title;

  /// The Turkish name, shown under the English one.
  final String? titleTr;

  /// For tabs, where the full title is too long.
  final String shortTitle;
  final String emoji;
  final String? description;
  final double position;
  final List<Subject> subjects;

  int get topicCount => subjects.fold(0, (n, s) => n + s.topicCount);
  int get doneCount => subjects.fold(0, (n, s) => n + s.doneCount);
  int get subjectsDone => subjects.where((s) => s.status == SubjectStatus.done).length;
  double get progress => topicCount == 0 ? 0 : doneCount / topicCount;
}

enum SubjectStatus { todo, doing, done }

/// A stop on the roadmap: one `content/roadmap/<part>/NN-name.md` file. Its
/// checklist items are the topics.
class Subject {
  Subject({
    required this.id,
    required this.title,
    required this.titleTr,
    required this.emoji,
    required this.description,
    required this.statusOverride,
    required this.position,
    required this.body,
    required this.assetPath,
  });

  final String id;
  final String title;
  final String? titleTr;
  final String emoji;
  final String? description;

  /// `status:` in front matter, which wins over the checklist.
  final SubjectStatus? statusOverride;
  final double position;
  final String body;
  final String assetPath;

  late final RoadmapPart part;

  /// One of [pastelNames]: `color:` in front matter, else the next one along the road.
  late String color;

  late final ParsedMarkdown parsed = ParsedMarkdown.parse(body);
  late final List<CheckItem> topics = parsed.checkItems;

  String get route => '/roadmap/$id';
  int get topicCount => topics.length;
  int get doneCount => topics.where((t) => t.isDone).length;

  SubjectStatus get status {
    if (statusOverride != null) return statusOverride!;
    if (topics.isNotEmpty && topics.every((t) => t.isDone)) return SubjectStatus.done;
    if (topics.any((t) => t.state != CheckState.todo)) return SubjectStatus.doing;
    return SubjectStatus.todo;
  }

  double get progress {
    if (status == SubjectStatus.done) return 1;
    return topicCount == 0 ? 0 : doneCount / topicCount;
  }

  /// The topic being studied now, else the first one not done yet.
  CheckItem? get nextTopic =>
      topics.where((t) => t.state == CheckState.doing).firstOrNull ?? topics.where((t) => t.state == CheckState.todo).firstOrNull;

  /// When the last topic was ticked, for a finished subject whose topics all
  /// have dates (without them there's no telling when it was finished).
  DateTime? get finishedOn {
    if (topics.isEmpty || !topics.every((t) => t.isDone && t.date != null)) return null;
    return topics.map((t) => t.date!).reduce((a, b) => a.isAfter(b) ? a : b);
  }
}

/// Something ticked off: a topic, or a whole subject when [topic] is null.
class Win {
  const Win({required this.date, required this.subject, this.topic});

  final DateTime date;
  final Subject subject;
  final CheckItem? topic;

  bool get isSubject => topic == null;
}

class BlogPost {
  BlogPost({
    required this.slug,
    required this.title,
    required this.date,
    required this.tags,
    required this.subjectIds,
    required this.excerpt,
    required this.body,
    required this.assetPath,
    required this.image,
    required this.emoji,
    required this.color,
    required this.draft,
    required this.featured,
    required this.readingMinutes,
  });

  final String slug;
  final String title;
  final DateTime date;
  final List<String> tags;

  /// Roadmap subjects the post is about (`subjects: [anatomy]`).
  final List<String> subjectIds;
  final String excerpt;
  final String body;

  /// Path of the .md file in the asset bundle, for resolving relative images.
  final String assetPath;

  /// Cover image: an asset path or a URL.
  final String? image;

  /// Shown on the cover when there's no image.
  final String emoji;

  /// One of [pastelNames].
  final String color;
  final bool draft;
  final bool featured;
  final int readingMinutes;

  String get route => '/blog/$slug';

  late final ParsedMarkdown parsed = ParsedMarkdown.parse(body);
}

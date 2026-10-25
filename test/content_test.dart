import 'package:ceren_bingol_blog/content/content_loader.dart';
import 'package:ceren_bingol_blog/content/content_repository.dart';
import 'package:ceren_bingol_blog/content/markdown_blocks.dart';
import 'package:ceren_bingol_blog/content/models.dart';
import 'package:ceren_bingol_blog/content/text_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tiny site: one part with two subjects, a few posts and a profile.
Map<String, String> fixture({String anatomy = '', String physiology = ''}) => {
  'content/profile.md': '---\n'
      'name: Ceren Bingöl\n'
      'title: Medical doctor\n'
      'exam: TUS\n'
      'exam_date: 2027-03-21\n'
      'milestones:\n'
      '  - date: 2026-10\n'
      '    title: Started the blog\n'
      '---\n\nHello!',
  'content/roadmap/basic/_part_.yaml': 'title: Basic Medical Sciences\nshort: Basic\nemoji: 🧪\nposition: 1\n',
  'content/roadmap/basic/01-anatomy.md': '---\ntitle: Anatomy\nemoji: 🦴\n---\n\n$anatomy',
  'content/roadmap/basic/02-physiology.md': '---\ntitle: Physiology\ncolor: mint\n---\n\n$physiology',
  'content/blog/2026-10-01-older.md': '---\ntitle: Older\ntags: [TUS]\nsubjects: [anatomy]\n---\n\nFirst paragraph.\n\nSecond.',
  'content/blog/2026-10-20-newer/index.md': '---\ntitle: Newer\ndescription: Short.\n---\n\nBody',
  'content/blog/2026-10-21-secret.md': '---\ntitle: Secret\ndraft: true\n---\n\nShh',
};

void main() {
  group('checklists', () {
    test('lines become items with their state, date and link', () {
      final items = ParsedMarkdown.parse('''
- [x] Upper limb (2026-09-14)
- [X] Lower limb — 2026-09-20
- [/] Thorax
- [~] Abdomen
- [ ] Pelvis 2026-12-01
- [ ] [Head & neck](/blog/head-and-neck)
  - [ ] Nested
''').checkItems;
      expect(items.map((i) => i.text), ['Upper limb', 'Lower limb', 'Thorax', 'Abdomen', 'Pelvis', 'Head & neck', 'Nested']);
      expect(items.map((i) => i.state), [
        CheckState.done,
        CheckState.done,
        CheckState.doing,
        CheckState.doing,
        CheckState.todo,
        CheckState.todo,
        CheckState.todo,
      ]);
      expect(items[0].date, DateTime(2026, 9, 14));
      expect(items[1].date, DateTime(2026, 9, 20));
      expect(items[2].date, isNull);
      expect(items[4].date, DateTime(2026, 12, 1));
      expect(items[5].link, '/blog/head-and-neck');
      expect(items[6].depth, 1);
    });

    test('items in comments, code and callouts are not topics', () {
      final parsed = ParsedMarkdown.parse('''
<!-- - [x] in a comment -->
```
- [x] in code
```
:::tip
- [x] in a tip
:::
- [ ] real
''');
      expect(parsed.checkItems.map((i) => i.text), ['real']);
      expect(parsed.blocks.whereType<MdCallout>(), hasLength(1));
    });

    test('blank lines inside a checklist keep it together', () {
      final parsed = ParsedMarkdown.parse('- [ ] a\n\n- [ ] b\n\nText\n');
      expect(parsed.blocks.first, isA<MdChecklist>());
      expect((parsed.blocks.first as MdChecklist).items, hasLength(2));
      expect(parsed.blocks.last, isA<MdText>());
    });
  });

  group('subjects', () {
    Subject anatomy(String topics) => ContentRepository.fromFiles(fixture(anatomy: topics)).subject('anatomy')!;

    test('status follows the topics', () {
      expect(anatomy('- [ ] a\n- [ ] b').status, SubjectStatus.todo);
      expect(anatomy('- [/] a\n- [ ] b').status, SubjectStatus.doing);
      expect(anatomy('- [x] a\n- [ ] b').status, SubjectStatus.doing);
      final done = anatomy('- [x] a (2026-10-01)\n- [x] b (2026-10-03)');
      expect(done.status, SubjectStatus.done);
      expect(done.progress, 1);
      expect(done.finishedOn, DateTime(2026, 10, 3));
      expect(anatomy('- [x] a (2026-10-01)\n- [x] b').finishedOn, isNull);
    });

    test('`status:` in front matter wins', () {
      final repo = ContentRepository.fromFiles({
        ...fixture(),
        'content/roadmap/basic/01-anatomy.md': '---\ntitle: Anatomy\nstatus: done\n---\n- [ ] a',
      });
      expect(repo.subject('anatomy')!.status, SubjectStatus.done);
      expect(repo.subject('anatomy')!.finishedOn, isNull);
    });

    test('ids, order, colours and parts', () {
      final repo = ContentRepository.fromFiles(fixture());
      expect(repo.subjects.map((s) => s.id), ['anatomy', 'physiology']);
      expect(repo.subject('anatomy')!.color, pastelNames.first);
      expect(repo.subject('physiology')!.color, 'mint');
      expect(repo.subject('anatomy')!.part.title, 'Basic Medical Sciences');
      expect(repo.parts.single.shortTitle, 'Basic');
    });

    test('the current subject is the first in progress, else the first not started', () {
      String? current(String a, String b) =>
          ContentRepository.fromFiles(fixture(anatomy: a, physiology: b)).currentSubject?.id;
      expect(current('- [x] a', '- [ ] b'), 'physiology');
      expect(current('- [ ] a', '- [/] b'), 'physiology');
      expect(current('- [ ] a', '- [ ] b'), 'anatomy');
      expect(current('- [x] a', '- [x] b'), isNull);
    });

    test('wins are newest first, a finished subject before its last topic', () {
      final repo = ContentRepository.fromFiles(
        fixture(anatomy: '- [x] a (2026-10-01)\n- [x] b (2026-10-05)', physiology: '- [x] c (2026-10-03)\n- [x] d'),
      );
      expect(
        [for (final w in repo.wins) w.isSubject ? 'finished ${w.subject.id}' : w.topic!.text],
        ['finished anatomy', 'b', 'c', 'a'],
      );
    });
  });

  test('posts: dates, slugs, excerpts, drafts and subjects', () {
    final repo = ContentRepository.fromFiles(fixture());
    expect(repo.posts.map((p) => p.slug), ['newer', 'older']);
    expect(repo.post('older')!.excerpt, 'First paragraph.');
    expect(repo.post('newer')!.excerpt, 'Short.');
    expect(repo.post('newer')!.date, DateTime(2026, 10, 20));
    expect(repo.postsAbout(repo.subject('anatomy')!).map((p) => p.slug), ['older']);
    expect(ContentRepository.fromFiles(fixture(), includeDrafts: true).post('secret'), isNotNull);
  });

  test('profile', () {
    final profile = ContentRepository.fromFiles(fixture()).profile;
    expect(profile.firstName, 'Ceren');
    expect(profile.daysUntilExam(DateTime(2027, 3, 20)), 1);
    expect(profile.daysUntilExam(DateTime(2027, 3, 22)), isNull);
    expect(profile.milestones.single.dateLabel, 'Oct 2026');
  });

  test('slugify knows Turkish letters', () {
    expect(slugify('Küçük Stajlar'), 'kucuk-stajlar');
    expect(slugify('İç Hastalıkları'), 'ic-hastaliklari');
    expect(slugify('01-anatomy.md'), 'anatomy');
  });

  group('the real content', () {
    late ContentRepository content;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      content = ContentRepository.fromFiles(await loadContentFiles(rootBundle), includeDrafts: true);
    });

    test('every subject has topics and its own id', () {
      expect(content.parts, isNotEmpty);
      for (final s in content.subjects) {
        expect(s.topics, isNotEmpty, reason: s.assetPath);
      }
      expect(content.subjects.map((s) => s.id).toSet(), hasLength(content.subjects.length));
    });

    test('posts only mention subjects that exist', () {
      for (final post in content.posts) {
        for (final id in post.subjectIds) {
          expect(content.subject(id), isNotNull, reason: '${post.assetPath} mentions "$id"');
        }
      }
    });

    test('links to pages of the site lead somewhere', () {
      bool exists(String href) {
        final path = Uri.parse(href).path;
        if (const ['/', '/roadmap', '/blog', '/profile', '/about'].contains(path)) return true;
        if (path.startsWith('/roadmap/')) return content.subject(path.substring('/roadmap/'.length)) != null;
        if (path.startsWith('/blog/')) return content.post(path.substring('/blog/'.length)) != null;
        return false;
      }

      final pages = {
        content.profile.assetPath: content.profile.bio,
        for (final s in content.subjects) s.assetPath: s.body,
        for (final p in content.posts) p.assetPath: p.body,
      };
      for (final MapEntry(key: path, value: body) in pages.entries) {
        final prose = body.replaceAll(RegExp(r'```[\s\S]*?```'), '').replaceAll(RegExp(r'`[^`\n]*`'), '');
        for (final link in RegExp(r'\]\((/[^)\s]*)\)').allMatches(prose)) {
          expect(exists(link.group(1)!), isTrue, reason: '$path links to ${link.group(1)}');
        }
      }
    });
  });
}

// Renders the whole site: every route at phone, tablet and desktop sizes, in
// every theme, with no progress and with some. Any overflow or exception while
// building a page fails the test.
import 'package:ceren_bingol_blog/app.dart';
import 'package:ceren_bingol_blog/content/content_loader.dart';
import 'package:ceren_bingol_blog/content/content_repository.dart';
import 'package:ceren_bingol_blog/content/text_utils.dart';
import 'package:ceren_bingol_blog/theme/app_theme.dart';
import 'package:ceren_bingol_blog/theme/app_themes.dart';
import 'package:ceren_bingol_blog/theme/theme_controller.dart';
import 'package:ceren_bingol_blog/widgets/layout/site_shell.dart';
import 'package:ceren_bingol_blog/widgets/roadmap/roadmap_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

late Map<String, String> files;

const sizes = {'phone': Size(375, 812), 'tablet': Size(900, 1100), 'desktop': Size(1440, 900)};

final _todo = RegExp(r'^- \[ \] (.+)$', multiLine: true);

/// The real content with some progress made, so every state gets drawn:
/// Anatomy finished, Physiology under way, an exam date for the countdown.
Map<String, String> withProgress() {
  final result = Map.of(files);
  for (final key in result.keys.toList()) {
    if (key.endsWith('/01-anatomy.md')) {
      result[key] = result[key]!.replaceAllMapped(_todo, (m) => '- [x] ${m[1]} (2026-10-01)');
    }
    if (key.endsWith('/02-physiology.md')) {
      var n = 0;
      result[key] = result[key]!.replaceAllMapped(_todo, (m) {
        n++;
        return n <= 2 ? '- [x] ${m[1]} (2026-10-1$n)' : (n == 3 ? '- [/] ${m[1]}' : m[0]!);
      });
    }
  }
  result['content/profile.md'] = result['content/profile.md']!.replaceFirst('# exam_date:', 'exam_date:');
  return result;
}

List<String> allRoutes(ContentRepository content) => [
  '/',
  '/roadmap',
  for (final s in content.subjects) s.route,
  '/blog',
  for (final t in content.tags) '/blog?tag=${slugify(t)}',
  for (final p in content.posts) p.route,
  '/profile',
  '/about',
  '/this-page-does-not-exist',
  '/roadmap/no-such-subject',
  '/blog/no-such-post',
];

Future<void> pumpSite(WidgetTester tester, Size size, ContentRepository content, {AppThemePreset? theme}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({if (theme != null) 'theme': theme.id});
  final controller = await ThemeController.load();
  await tester.pumpWidget(MeowdicalApp(content: content, theme: controller));
  await tester.pump();
}

/// Navigates and lets the page transition and entrance animations finish.
Future<void> visit(WidgetTester tester, String route) async {
  GoRouter.of(tester.element(find.byType(SiteShell).first)).go(route);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(seconds: 2));
}

/// Visits every route and returns what went wrong on each.
Future<List<String>> visitAll(WidgetTester tester, List<String> routes) async {
  final failures = <String>[];
  for (final route in routes) {
    await visit(tester, route);
    final error = tester.takeException();
    if (error != null) failures.add('$route: $error');
  }
  return failures;
}

/// Disposes the app so its looping animations stop.
Future<void> tearDownSite(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    AppTheme.useGoogleFonts = false;
    files = await loadContentFiles(rootBundle);
  });

  for (final MapEntry(key: name, value: size) in sizes.entries) {
    testWidgets('every route renders on $name', (tester) async {
      final content = ContentRepository.fromFiles(files, includeDrafts: true);
      await pumpSite(tester, size, content);
      final failures = await visitAll(tester, allRoutes(content));
      await tearDownSite(tester);
      expect(failures, isEmpty);
    });
  }

  for (final theme in appThemes) {
    for (final MapEntry(key: name, value: size) in sizes.entries) {
      testWidgets('${theme.name}, with progress made, renders on $name', (tester) async {
        final content = ContentRepository.fromFiles(withProgress(), includeDrafts: true);
        await pumpSite(tester, size, content, theme: theme);
        final failures = await visitAll(tester, [
          '/',
          '/roadmap',
          '/roadmap/anatomy',
          '/roadmap/physiology',
          '/blog',
          content.posts.first.route,
          '/profile',
          '/no-such-page',
        ]);
        await tearDownSite(tester);
        expect(failures, isEmpty);
      });
    }
  }

  testWidgets('the cat sits on the subject being studied, and tiles open their subject', (tester) async {
    final content = ContentRepository.fromFiles(withProgress(), includeDrafts: true);
    await pumpSite(tester, sizes['desktop']!, content);
    await visit(tester, '/');
    final tile = find.descendant(of: find.byType(SubjectTile), matching: find.text('Physiology'));
    await tester.scrollUntilVisible(tile, 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(tile);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('studying!'), findsOneWidget);

    await tester.tap(tile);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final router = GoRouter.of(tester.element(find.byType(SiteShell).first));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/roadmap/physiology');
    await tearDownSite(tester);
  });

  testWidgets('the tabs on the home page switch between parts of the roadmap', (tester) async {
    final content = ContentRepository.fromFiles(files, includeDrafts: true);
    await pumpSite(tester, sizes['desktop']!, content);
    await visit(tester, '/');
    final clinical = content.parts[1];
    final tab = find.textContaining(clinical.shortTitle);
    await tester.scrollUntilVisible(tab, 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(tab);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(clinical.subjects.first.title), findsNothing);
    await tester.tap(tab);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(clinical.subjects.first.title), findsOneWidget);
    await tearDownSite(tester);
  });

  testWidgets('drafts stay hidden unless asked for', (tester) async {
    final published = ContentRepository.fromFiles(files);
    final everything = ContentRepository.fromFiles(files, includeDrafts: true);
    expect(published.posts.where((p) => p.draft), isEmpty);
    expect(everything.posts.length, greaterThan(published.posts.length));
  });
}

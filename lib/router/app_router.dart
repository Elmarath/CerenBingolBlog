import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/blog/blog_list_page.dart';
import '../pages/blog/blog_post_page.dart';
import '../pages/home/home_page.dart';
import '../pages/not_found_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/roadmap/roadmap_page.dart';
import '../pages/roadmap/subject_page.dart';
import '../widgets/layout/site_shell.dart';

/// All routes of the site. Every page sits inside [SiteShell] (the nav bar).
///
/// * `/`                → home: greeting, roadmap, latest posts
/// * `/roadmap`         → the whole roadmap
/// * `/roadmap/<id>`    → one subject and its topics
/// * `/blog`, `/blog?tag=<tag>`, `/blog/<slug>`
/// * `/profile`         → about Ceren (`/about` leads here too)
GoRouter buildRouter() {
  return GoRouter(
    redirect: (context, state) {
      final path = state.uri.path;
      if (path.length > 1 && path.endsWith('/')) return path.replaceFirst(RegExp(r'/+$'), '');
      if (path == '/about') return '/profile';
      return null;
    },
    errorBuilder: (context, state) => SiteShell(location: state.uri.path, child: const NotFoundPage()),
    routes: [
      ShellRoute(
        builder: (context, state, child) => SiteShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', pageBuilder: (context, state) => _page(state, const HomePage())),
          GoRoute(
            path: '/roadmap',
            pageBuilder: (context, state) => _page(state, const RoadmapPage()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _page(state, SubjectPage(id: state.pathParameters['id']!)),
              ),
            ],
          ),
          GoRoute(
            path: '/blog',
            pageBuilder: (context, state) => _page(state, BlogListPage(tag: state.uri.queryParameters['tag'])),
            routes: [
              GoRoute(
                path: ':slug',
                pageBuilder: (context, state) => _page(state, BlogPostPage(slug: state.pathParameters['slug']!)),
              ),
            ],
          ),
          GoRoute(path: '/profile', pageBuilder: (context, state) => _page(state, const ProfilePage())),
        ],
      ),
    ],
  );
}

/// Pages fade in and float up a touch. Keyed by location, so every subject
/// and post gets a fresh page (and scroll position); `?tag=` changes keep it.
Page<void> _page(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: ValueKey<String>(state.matchedLocation),
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.015), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Everything about the site itself, in one place.
///
/// What Ceren writes (posts, the roadmap, her profile) lives in `content/`,
/// so updating the blog never means touching Dart code.
abstract final class SiteConfig {
  /// The blog's name: nav bar, footer, browser tab.
  static const siteName = 'Meowdical Notes';

  /// One line under the name in the footer.
  static const tagline = 'A cat-themed study diary on the road to TUS';

  /// Small print at the very bottom of every page.
  static const footerNote = 'Made with love, tea and plenty of cat naps.';

  static const navItems = <NavItem>[
    NavItem('Home', '/', Icons.home_rounded),
    NavItem('Roadmap', '/roadmap', Icons.route_rounded),
    NavItem('Blog', '/blog', Icons.auto_stories_rounded),
    NavItem('Profile', '/profile', Icons.pets_rounded),
  ];

  /// Posts with `draft: true` show only while running locally (debug builds),
  /// or in a build made with `--dart-define=SHOW_DRAFTS=true`.
  static const showDrafts = kDebugMode || bool.fromEnvironment('SHOW_DRAFTS');
}

class NavItem {
  const NavItem(this.label, this.path, this.icon);

  final String label;
  final String path;
  final IconData icon;
}

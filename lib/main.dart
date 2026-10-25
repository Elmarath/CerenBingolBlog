import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'content/content_loader.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  // Clean URLs: /blog/hello instead of /#/blog/hello.
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  final (content, theme, _) = await (
    loadContent(rootBundle),
    ThemeController.load(),
    AppTheme.preloadFonts(),
  ).wait;

  runApp(MeowdicalApp(content: content, theme: theme));
}

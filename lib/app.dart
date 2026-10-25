import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_scope.dart';
import 'config/site_config.dart';
import 'content/content_repository.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class MeowdicalApp extends StatefulWidget {
  const MeowdicalApp({super.key, required this.content, required this.theme});

  final ContentRepository content;
  final ThemeController theme;

  @override
  State<MeowdicalApp> createState() => _MeowdicalAppState();
}

class _MeowdicalAppState extends State<MeowdicalApp> {
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      content: widget.content,
      theme: widget.theme,
      child: ListenableBuilder(
        listenable: widget.theme,
        builder: (context, _) => MaterialApp.router(
          title: SiteConfig.siteName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(widget.theme.current.palette),
          routerConfig: _router,
        ),
      ),
    );
  }
}

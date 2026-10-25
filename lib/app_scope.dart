import 'package:flutter/widgets.dart';

import 'content/content_repository.dart';
import 'theme/theme_controller.dart';

/// Makes the app-wide services available to every widget:
/// `context.content`, `AppScope.of(context).theme`.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.content, required this.theme, required super.child});

  final ContentRepository content;
  final ThemeController theme;

  static AppScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) => content != oldWidget.content || theme != oldWidget.theme;
}

extension AppScopeContext on BuildContext {
  ContentRepository get content => AppScope.of(this).content;
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_themes.dart';

/// Holds the selected theme and remembers it in the visitor's browser.
///
/// Until a visitor picks one, they get [darkTheme] if their system prefers a
/// dark screen, else the first theme in [appThemes].
class ThemeController extends ChangeNotifier {
  ThemeController._(this._prefs, this._current);

  /// `web/index.html` reads this (as `flutter.theme`) to colour the loading screen.
  static const _storageKey = 'theme';

  final SharedPreferences? _prefs;
  AppThemePreset _current;

  AppThemePreset get current => _current;
  List<AppThemePreset> get presets => appThemes;

  static Future<ThemeController> load() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // Storage can be blocked (private mode); fall back to the default theme.
    }
    final savedId = prefs?.getString(_storageKey);
    final prefersDark = PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    final preset = appThemes.where((t) => t.id == savedId).firstOrNull ?? (prefersDark ? darkTheme : appThemes.first);
    return ThemeController._(prefs, preset);
  }

  void select(AppThemePreset preset) {
    if (preset.id == _current.id) return;
    _current = preset;
    _prefs?.setString(_storageKey, preset.id);
    notifyListeners();
  }
}

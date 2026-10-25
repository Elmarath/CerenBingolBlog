import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/site_config.dart';
import 'content_repository.dart';

/// Loads and parses everything under `content/`.
Future<ContentRepository> loadContent(AssetBundle bundle) async =>
    ContentRepository.fromFiles(await loadContentFiles(bundle), includeDrafts: SiteConfig.showDrafts);

/// Every Markdown and YAML file under `content/`, by path.
///
/// Release builds read `assets/generated/content.json` (written by
/// `dart run tool/content.dart bundle` during the Netlify build): one request
/// on startup instead of one per file. Otherwise, and when it's missing, each
/// file is read on its own, so local edits always show.
Future<Map<String, String>> loadContentFiles(AssetBundle bundle) async =>
    (kReleaseMode ? await _loadBundled(bundle) : null) ?? await _loadSeparately(bundle);

Future<Map<String, String>?> _loadBundled(AssetBundle bundle) async {
  try {
    final json = jsonDecode(await bundle.loadString('assets/generated/content.json')) as Map<String, dynamic>;
    return {for (final MapEntry(:key, :value) in json.entries) key: value as String};
  } catch (_) {
    return null;
  }
}

Future<Map<String, String>> _loadSeparately(AssetBundle bundle) async {
  final manifest = await AssetManifest.loadFromAssetBundle(bundle);
  final paths = manifest.listAssets().where((a) => a.startsWith('content/') && isContentTextFile(a)).toList()..sort();
  final texts = await Future.wait(paths.map(bundle.loadString));
  return Map.fromIterables(paths, texts);
}

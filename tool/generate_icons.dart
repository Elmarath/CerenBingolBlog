// Draws the favicon and app icons from the same cat as the logo:
//
//   flutter test tool/generate_icons.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ceren_bingol_blog/widgets/cats/cat_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _pink = Color(0xFFFFD9E4);

/// A [size] × [size] PNG with the cat at [catScale] of the width, on
/// [background] (transparent when null).
Future<void> _icon(String path, int size, {Color? background, double catScale = 0.94}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  if (background != null) canvas.drawRect(Rect.fromLTWH(0, 0, s, s), Paint()..color = background);
  final cat = s * catScale;
  canvas.translate((s - cat) / 2, (s - cat) / 2);
  CatFacePainter(glasses: true).paint(canvas, Size.square(cat));
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  test('draw the icons', () async {
    await _icon('web/favicon.png', 64);
    await _icon('web/icons/Icon-192.png', 192, background: _pink, catScale: 0.8);
    await _icon('web/icons/Icon-512.png', 512, background: _pink, catScale: 0.8);
    // Maskable icons get cropped to a circle, so the cat stays inside the middle 80%.
    await _icon('web/icons/Icon-maskable-192.png', 192, background: _pink, catScale: 0.62);
    await _icon('web/icons/Icon-maskable-512.png', 512, background: _pink, catScale: 0.62);
  });
}

// Pictures for a review: New
// request's selects at 600, 1024, 1440 and 1920 wide, closed and with Type
// open, by day and by night, under a pointer (macOS), as a desktop or a
// tablet's browser draws them, shadows blurred. It runs only with FLUENT2_SHOTS_DIR set,
// writing <dir>/app-request_<width>_<brightness>[_open].png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gallery_support.dart';

const _shot = ValueKey('width-shot');

Future<void> _write(WidgetTester t, String path) async {
  final box = t.renderObject<RenderRepaintBoundary>(find.byKey(_shot));
  final bytes = await t.runAsync(() async {
    final image = await box.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  });
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

void main() {
  final dir = Platform.environment['FLUENT2_SHOTS_DIR'];
  setUpAll(loadFluent2TestFonts);
  final page = galleryPages.firstWhere((p) => p.id == 'app-request');
  for (final width in const [600.0, 1024.0, 1440.0, 1920.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'app-request at ${width.round()}, ${brightness.name}: its selects '
        'closed and open',
        skip: dir == null,
        // Drawn pixels, the rasterizer's, as a golden's.
        tags: const ['goldens'],
        (t) async {
          debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
          // Shadows blurred as a browser draws them (flutter_test draws
          // them unblurred, a solid band under a raised surface).
          debugDisableShadows = false;
          try {
            t.view.devicePixelRatio = 1;
            t.view.physicalSize = Size(width, 1100);
            addTearDown(t.view.reset);
            await t.pumpWidget(
              RepaintBoundary(key: _shot, child: page.build(brightness)),
            );
            await settle(t);
            final name = '$dir/app-request_${width.round()}_${brightness.name}';
            await _write(t, '$name.png');
            await t.tap(find.text('Equipment').hitTestable().first);
            await settle(t);
            await _write(t, '${name}_open.png');
            await t.pumpWidget(const SizedBox());
            await t.pump(const Duration(seconds: 1));
          } finally {
            debugDisableShadows = true;
            debugDefaultTargetPlatformOverride = null;
          }
        },
      );
    }
  }
}

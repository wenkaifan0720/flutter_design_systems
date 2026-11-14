// The trip planner's screens and the ordinary pages at a phone's, a
// tablet's and a desktop's width, using the actual example pages.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/everyday.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'gallery_guidelines_test.dart' show galleryGuidelineFailures;
import 'gallery_support.dart';

void main() {
  final output = Platform.environment['EXPRESSIVE_DESIGN_REVIEW_OUT'];
  final recorded =
      autoUpdateGoldenFiles || Directory('test/goldens').existsSync();
  final figures = <Map<String, Object>>[];
  setUpAll(loadExpressiveFonts);
  tearDown(() {
    kitShownTheme = null;
    kitShownPreset = 'baseline';
  });
  tearDownAll(() {
    if (output != null) {
      final root = Directory(output)..createSync(recursive: true);
      File(
        '${root.path}/manifest.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(figures));
    }
  });

  for (final page in everydayGalleryPages) {
    for (final mode in Brightness.values) {
      for (final width in [390.0, 768.0, 1440.0]) {
        // CI (Linux) leaves out the pixels variant (`goldens`): the golden
        // and text contrast, both read from the drawn pixels. The layout,
        // tap-target and label checks run everywhere.
        for (final golden in [false, true]) {
          testWidgets(
            '${page.id} ${mode.name} ${width.round()}: ${golden ? 'pixels' : 'ordinary layout and guidelines'}',
            (tester) async {
              tester.view.devicePixelRatio = 1;
              tester.view.physicalSize = Size(width, 900);
              addTearDown(tester.view.reset);
              final semantics = tester.ensureSemantics();
              const capture = ValueKey('everyday-design-capture');
              await tester.pumpWidget(
                RepaintBoundary(key: capture, child: page.build(mode)),
              );
              await settle(tester);
              final scrolls = tester
                  .stateList<ScrollableState>(find.byType(Scrollable))
                  .where((state) => state.position.axis == Axis.vertical);
              // The tallest scroll (a list beside its detail scrolls in
              // each pane), so the capture shows the whole screen.
              final extent = scrolls.fold(
                0.0,
                (most, s) => s.position.maxScrollExtent > most
                    ? s.position.maxScrollExtent
                    : most,
              );
              if (extent > 0) {
                tester.view.physicalSize = Size(width, 900 + extent);
                await settle(tester);
              }
              if (page.id == 'everyday-dialog') {
                await tester.tap(
                  find.byKey(const ValueKey('everyday-open-dialog')),
                );
                await settle(tester);
              }
              expect(tester.takeException(), isNull);
              final failures = await galleryGuidelineFailures(
                tester,
                page.id,
                'baseline',
                mode,
                targets: !golden,
                contrast: golden,
              );
              expect(failures, isEmpty, reason: failures.join('\n'));
              if (golden) {
                await expectLater(
                  find.byKey(capture),
                  matchesGoldenFile(
                    'goldens/${page.id}/width_${width.round()}/baseline_${mode.name}.png',
                  ),
                );
              }
              if (!golden && output != null) {
                final name = '${page.id}_${mode.name}_${width.round()}.png';
                final root = Directory(output)..createSync(recursive: true);
                final boundary = tester.renderObject<RenderRepaintBoundary>(
                  find.byKey(capture),
                );
                await tester.runAsync(() async {
                  final image = await boundary.toImage(pixelRatio: 1);
                  try {
                    final bytes = await image.toByteData(
                      format: ui.ImageByteFormat.png,
                    );
                    File('${root.path}/$name')
                        .writeAsBytesSync(bytes!.buffer.asUint8List());
                    figures.add({
                      'screen': page.id,
                      'title': page.title,
                      'mode': mode.name,
                      'width': width.round(),
                      'height': image.height,
                      'path': '${root.path}/$name',
                      'background':
                          '#${ExpressiveThemeData.preset('baseline', mode).colors.surface.toARGB32().toRadixString(16).substring(2)}',
                    });
                  } finally {
                    image.dispose();
                  }
                });
              }
              semantics.dispose();
            },
            tags: golden ? const ['goldens'] : null,
            skip: golden && !recorded,
          );
        }
      }
    }
  }
}

// A slid row's actions stand level as painted. shared_checks_test leaves out its row reader's one misreading here (the
// night's ground-coloured Delete face); this measures the faces themselves, so the property stays held.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

// ignore_for_file: avoid_relative_lib_imports — the gallery under test is the example app, not a package dependency.
import '../example/lib/main.dart';
import 'gallery_support.dart' show loadBundledFonts, settle;
import 'support.dart' show loadNeumorphicFonts;

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });

  for (final density in [GalleryDensity.standard, GalleryDensity.compact]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'the open row\'s Delete and Archive are level as painted, ${density.name} ${brightness.name}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(390, 2600);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            GalleryApp(
              initialPage: 'collections',
              initialBrightness: brightness,
              initialCustom: GalleryCustom(density: density),
            ),
          );
          await settle(tester);
          // The open row's actions: the pair in view on one line (the shut row's lie under its tile).
          final pairs = [
            for (final delete in find.text('Delete').hitTestable().evaluate())
              for (final archive
                  in find.text('Archive').hitTestable().evaluate())
                if ((tester
                                .getCenter(
                                  find.byElementPredicate(
                                    (e) => identical(e, delete),
                                  ),
                                )
                                .dy -
                            tester
                                .getCenter(
                                  find.byElementPredicate(
                                    (e) => identical(e, archive),
                                  ),
                                )
                                .dy)
                        .abs() <
                    2)
                  (delete, archive),
          ];
          expect(pairs, hasLength(1), reason: 'one open row of actions');
          final (delete, archive) = pairs.single;
          // Each action's face: the first box round its words as tall as a key.
          Rect face(Element words) {
            var box = words.renderObject! as RenderBox;
            while (box.size.height < 40) {
              box = box.parent! as RenderBox;
            }
            return box.localToGlobal(Offset.zero) & box.size;
          }

          final view = tester.binding.renderViews.first;
          late final ByteData bytes;
          late final int width;
          await tester.runAsync(() async {
            final image = await (view.debugLayer! as OffsetLayer).toImage(
              view.paintBounds,
              pixelRatio: 1,
            );
            width = image.width;
            bytes = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            image.dispose();
          });
          final ground = NeumorphicTheme.of(delete).colors.ground;
          int channel(double c) => (c * 255).round();
          final g = [channel(ground.r), channel(ground.g), channel(ground.b)];
          // The painted rows of a column just inside a face's start edge, clear of its words: its rim or its pigment
          // on top, its face or its shadow below, all that stands off the ground.
          (int, int) painted(Rect at) {
            final x = (at.left + 6).round();
            int? top, bottom;
            for (
              var y = (at.top - 12).round();
              y <= (at.bottom + 12).round();
              y++
            ) {
              final i = (y * width + x) * 4;
              final off =
                  (bytes.getUint8(i) - g[0]).abs() +
                  (bytes.getUint8(i + 1) - g[1]).abs() +
                  (bytes.getUint8(i + 2) - g[2]).abs();
              if (off > 6) {
                top ??= y;
                bottom = y;
              }
            }
            expect(top, isNotNull, reason: 'a face painted at $at');
            return (top!, bottom!);
          }

          final a = painted(face(delete)), b = painted(face(archive));
          expect(
            (a.$1 - b.$1).abs(),
            lessThanOrEqualTo(1),
            reason: 'tops: Delete ${a.$1}, Archive ${b.$1}',
          );
          expect(
            (a.$2 - b.$2).abs(),
            lessThanOrEqualTo(1),
            reason: 'bottoms: Delete ${a.$2}, Archive ${b.$2}',
          );
        },
      );
    }
  }
}

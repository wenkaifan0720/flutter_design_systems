// A plate sits in the middle of the round thing round it. Terminal draws no
// rounded box (its panes, brackets and inverse cells are square, on the
// character grid); the one round container is the radio's `( )`, and its
// dot stands in the middle of it, measured on the painted pixels, under a
// finger and under a pointer, either way round.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

// The example's app host is the one under test.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import 'faces.dart';

/// The painted ink's columns in runs (an empty column between runs), each
/// run's centre of ink, at [scale] pixels a point.
List<Offset> inkRuns(ByteData rgba, int width, int height, double scale) {
  final column = List<double>.filled(width, 0);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      column[x] += rgba.getUint8((y * width + x) * 4 + 3) / 255;
    }
  }
  final runs = <Offset>[];
  var x = 0;
  while (x < width) {
    if (column[x] < 0.02) {
      x++;
      continue;
    }
    final start = x;
    while (x < width && column[x] >= 0.02) {
      x++;
    }
    var mass = 0.0, sx = 0.0, sy = 0.0;
    for (var y = 0; y < height; y++) {
      for (var c = start; c < x; c++) {
        final a = rgba.getUint8((y * width + c) * 4 + 3) / 255;
        mass += a;
        sx += a * (c + 0.5);
        sy += a * (y + 0.5);
      }
    }
    runs.add(Offset(sx / mass / scale, sy / mass / scale));
  }
  return runs;
}

void main() {
  setUpAll(loadFaces);

  for (final width in [390.0, 1440.0]) {
    for (final dir in TextDirection.values) {
      testWidgets(
        "a radio's dot is in the middle of its ( ) at ${width.toInt()} "
        '${dir.name}',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 900);
          addTearDown(tester.view.reset);
          const boundary = Key('radio');
          await tester.pumpWidget(
            kitApp(
              brightness: Brightness.dark,
              direction: dir,
              home: Center(
                child: RepaintBoundary(
                  key: boundary,
                  child: TermRadio<int>(
                    value: 1,
                    groupValue: 1,
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          );
          for (var i = 0; i < 16; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }
          const scale = 4.0;
          final render = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(boundary),
          );
          final image = (await tester.runAsync(
            () => render.toImage(pixelRatio: scale),
          ))!;
          final rgba = (await tester.runAsync(
            () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
          ))!;
          final runs = inkRuns(rgba, image.width, image.height, scale);
          image.dispose();
          // The left bracket, the dot, the right bracket.
          expect(runs, hasLength(3), reason: '$runs');
          final [left, dot, right] = runs;
          final middle = Offset.lerp(left, right, 0.5)!;
          final reason = 'dot $dot, brackets $left and $right (middle $middle)';
          expect((dot.dx - middle.dx).abs(), lessThan(0.5), reason: reason);
          expect((dot.dy - middle.dy).abs(), lessThan(0.5), reason: reason);
          expect((left.dy - right.dy).abs(), lessThan(0.5), reason: reason);
        },
      );
    }
  }
}

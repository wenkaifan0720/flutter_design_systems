// A part on the wall with every shadow gone (NeumorphicFlatScope), on a stage whose pixels a test reads, and the
// look's source files and example pages a scan reads.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

/// The look's source files.
Iterable<File> lookLibrary() sync* {
  for (final f in Directory(
    'lib/src/neumorphism',
  ).listSync(recursive: true).whereType<File>()) {
    if (f.path.endsWith('.dart')) yield f;
  }
}

/// The example pages the tests build.
Iterable<File> examplePages() =>
    Directory('test/pages')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

/// The key of the stage [pumpFlat] lays a part on.
const flatStage = ValueKey('flat-stage');

/// The stage's pixels: its width, its height and its RGBA bytes.
Future<(int, int, Uint8List)> stagePixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(flatStage),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final out = (image.width, image.height, bytes!.buffer.asUint8List());
    image.dispose();
    return out;
  }))!;
}

/// How many pixels are near the pigment: blue-dominant, far from the wall's greys, by the preset's own colour.
int pigmentPixels(Uint8List px, Color pigment) {
  var n = 0;
  final r0 = (pigment.r * 255).round(),
      g0 = (pigment.g * 255).round(),
      b0 = (pigment.b * 255).round();
  for (var i = 0; i < px.length; i += 4) {
    if (px[i + 3] < 200) continue;
    final d =
        (px[i] - r0).abs() + (px[i + 1] - g0).abs() + (px[i + 2] - b0).abs();
    if (d < 60) n++;
  }
  return n;
}

/// Pumps [part] on the wall of [theme], centred on a 390 wide stage, with every shadow gone ([NeumorphicFlatScope]).
Future<void> pumpFlat(
  WidgetTester tester,
  Widget part,
  NeumorphicThemeData theme, {
  double height = 300,
}) async {
  tester.view.physicalSize = Size(390, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        type: MaterialType.transparency,
        child: NeumorphicTheme(
          data: theme,
          child: RepaintBoundary(
            key: flatStage,
            child: ColoredBox(
              color: theme.colors.ground,
              child: Center(child: NeumorphicFlatScope(child: part)),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}

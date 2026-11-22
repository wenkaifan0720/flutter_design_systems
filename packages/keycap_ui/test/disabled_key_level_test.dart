// A key that does nothing stands as a level, matte plate: no dish, no rim,
// no walls of another shade, no shadow, and never brighter than a key in
// use. A key in use keeps its moulding.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show Material;

import '../example/lib/kit_gallery/kit.dart';

final _key = GlobalKey();

/// The luminance of every pixel down the cap's middle and across it, a few
/// pixels in from its foot's edge.
Future<List<double>> _middle(WidgetTester tester) async {
  final boundary =
      _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final (w, h, bytes) = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    final out = (image.width, image.height, data!.buffer.asUint8List());
    image.dispose();
    return out;
  }))!;
  double lum(int x, int y) {
    final i = (y * w + x) * 4;
    return Color.fromARGB(
      255,
      bytes[i],
      bytes[i + 1],
      bytes[i + 2],
    ).computeLuminance();
  }

  const inset = 4;
  return [
    for (var y = inset; y < h - inset; y++) lum(w ~/ 2, y),
    for (var x = inset; x < w - inset; x++) lum(x, h ~/ 2),
  ];
}

Future<List<double>> _cap(
  WidgetTester tester,
  Brightness brightness, {
  required bool enabled,
}) async {
  await tester.pumpWidget(
    kitApp(
      brightness: brightness,
      home: Material(
        child: Center(
          child: RepaintBoundary(
            key: _key,
            child: KeycapButton(
              onPressed: enabled ? () {} : null,
              // No legend: only the plastic is measured.
              child: const SizedBox(width: 72, height: 12),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _middle(tester);
}

double _spread(List<double> l) =>
    l.reduce((a, b) => a > b ? a : b) - l.reduce((a, b) => a < b ? a : b);

double _mean(List<double> l) => l.reduce((a, b) => a + b) / l.length;

void main() {
  for (final b in Brightness.values) {
    testWidgets('a disabled key is a level plate, no brighter than a key in '
        'use (${b.name})', (tester) async {
      final on = await _cap(tester, b, enabled: true);
      final off = await _cap(tester, b, enabled: false);
      expect(_spread(on), greaterThan(0.02), reason: 'a key in use is moulded');
      expect(
        _spread(off),
        lessThan(0.006),
        reason: 'a key out of use is level',
      );
      expect(_mean(off), lessThanOrEqualTo(_mean(on)));
    });
  }
}

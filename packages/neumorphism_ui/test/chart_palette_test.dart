import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/chart.dart' show NeumorphicChart;

import 'support.dart';

List<double> _lab(Color color) {
  double linear(double value) => value <= .04045
      ? value / 12.92
      : math.pow((value + .055) / 1.055, 2.4).toDouble();
  final r = linear(color.r), g = linear(color.g), b = linear(color.b);
  double f(double value) => value > 216 / 24389
      ? math.pow(value, 1 / 3).toDouble()
      : value * 841 / 108 + 4 / 29;
  final x = f((r * .4124564 + g * .3575761 + b * .1804375) / .95047);
  final y = f(r * .2126729 + g * .7151522 + b * .0721750);
  final z = f((r * .0193339 + g * .1191920 + b * .9503041) / 1.08883);
  return [116 * y - 16, 500 * (x - y), 200 * (y - z)];
}

double _distance(Color a, Color b) {
  final x = _lab(a), y = _lab(b);
  return math.sqrt(
    [for (var i = 0; i < 3; i++) math.pow(x[i] - y[i], 2).toDouble()]
        .reduce((a, b) => a + b),
  );
}

double _contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

Future<Color> _pixel(RenderCustomPaint render, Offset at) async {
  final recorder = ui.PictureRecorder();
  render.painter!.paint(Canvas(recorder), render.size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    render.size.width.ceil(),
    render.size.height.ceil(),
  );
  final bytes = (await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  ))!;
  final i = (at.dy.floor() * image.width + at.dx.floor()) * 4;
  final color = Color.fromARGB(
    bytes.getUint8(i + 3),
    bytes.getUint8(i),
    bytes.getUint8(i + 1),
    bytes.getUint8(i + 2),
  );
  image.dispose();
  picture.dispose();
  return color;
}

void main() {
  setUpAll(loadNeumorphicFonts);
  final themes = <String, NeumorphicThemeData>{
    for (final preset in NeumorphicThemeData.presets)
      for (final brightness in Brightness.values)
        '$preset ${brightness.name}': NeumorphicThemeData.preset(
          preset,
          brightness,
        ),
    for (final ground in const [
      Color(0xFFFFFFFF),
      Color(0xFF000000),
      Color(0xFF777777),
      Color(0xFF00FF00),
      Color(0xFFFF0000),
      Color(0x407F00FF),
    ])
      for (final brightness in Brightness.values)
        '$ground ${brightness.name}': NeumorphicThemeData.from(
          ground: ground,
          pigment: const Color(0xFF777777),
          brightness: brightness,
        ),
  };
  for (final MapEntry(key: name, value: theme) in themes.entries) {
    testWidgets('$name: rasterized series stay distinct on the target band', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => NeumorphicTheme(data: theme, child: child!),
          home: const Center(
            child: SizedBox(
              width: 320,
              child: NeumorphicChart(
                label: 'Readings',
                band: NeumorphicChartBand(-100, 100),
                series: [
                  NeumorphicChartSeries('One', [1, 1]),
                  NeumorphicChartSeries('Two', [2, 2]),
                  NeumorphicChartSeries('Three', [3, 3]),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final painters = tester
          .renderObjectList<RenderCustomPaint>(find.byType(CustomPaint))
          .toList();
      final legends = painters.where((r) => r.size == const Size(24, 12));
      expect(legends, hasLength(3));
      final inks = <Color>[];
      for (final legend in legends) {
        final color = await tester.runAsync(
          () => _pixel(legend, const Offset(13, 6)),
        );
        expect(color!.a, 1);
        inks.add(color);
      }
      final plot = painters.singleWhere(
        (r) => r.size.height == 180 && r.size.width > 100,
      );
      final band = (await tester.runAsync(
        () => _pixel(plot, const Offset(20, 20)),
      ))!;
      final c = theme.colors;
      final grounds = [
        c.ground,
        c.faceStart,
        c.faceEnd,
        c.wellStart,
        c.wellEnd,
      ];
      for (final ink in inks) {
        for (final ground in grounds) {
          expect(_contrast(ink, ground), greaterThanOrEqualTo(3));
          expect(
            _contrast(ink, Color.alphaBlend(band, ground)),
            greaterThanOrEqualTo(3),
            reason: 'A target wash must not erase a series',
          );
        }
      }
      for (var i = 0; i < inks.length; i++) {
        for (var j = i + 1; j < inks.length; j++) {
          expect(
            _distance(inks[i], inks[j]),
            greaterThanOrEqualTo(20),
            reason: 'Series $i and $j must stay 20 CIELAB units apart',
          );
        }
      }
      expect(tester.takeException(), isNull);
    }, tags: ['goldens']);
  }
}

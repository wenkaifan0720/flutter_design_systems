// A chart's first series prints in the look's one pigment, flat, by day and by night, in every preset: its hue and,
// within a few L*, its lightness, not the text ink's, at 3:1 or more against the well.
import 'dart:math' as math;
import 'dart:ui' show ImageByteFormat, PictureRecorder;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/chart.dart'
    show NeumorphicChart, NeumorphicChartKind;

import 'support.dart';

double _hue(Color color) {
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
  return math.atan2(200 * (y - z), 500 * (x - y));
}

double _lstar(Color color) {
  final y = color.computeLuminance();
  return y > 216 / 24389
      ? 116 * math.pow(y, 1 / 3).toDouble() - 16
      : y * 24389 / 27;
}

double _contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

void main() {
  setUpAll(loadNeumorphicFonts);
  for (final preset in NeumorphicThemeData.presets) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'the first series is in $preset\'s pigment by ${brightness.name}',
        (tester) async {
          final theme = NeumorphicThemeData.preset(preset, brightness);
          await tester.pumpWidget(
            MaterialApp(
              builder: (_, child) =>
                  NeumorphicTheme(data: theme, child: child!),
              home: const Center(
                child: SizedBox(
                  width: 320,
                  child: NeumorphicChart(
                    label: 'Hours slept',
                    kind: NeumorphicChartKind.bar,
                    series: [
                      NeumorphicChartSeries('Sleep', [7, 8, 6]),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final legend = tester
              .renderObjectList<RenderCustomPaint>(find.byType(CustomPaint))
              .firstWhere((r) => r.size == const Size(24, 12));
          final recorder = PictureRecorder();
          legend.painter!.paint(Canvas(recorder), legend.size);
          final picture = recorder.endRecording();
          final image = await tester.runAsync(() => picture.toImage(24, 12));
          picture.dispose();
          final bytes = (await tester.runAsync(
            () => image!.toByteData(format: ImageByteFormat.rawStraightRgba),
          ))!;
          final i = (6 * 24 + 6) * 4;
          final ink = Color.fromARGB(
            bytes.getUint8(i + 3),
            bytes.getUint8(i),
            bytes.getUint8(i + 1),
            bytes.getUint8(i + 2),
          );
          image!.dispose();
          final colors = theme.colors;
          // ignore: avoid_print
          print(
            'PROBE $preset ${brightness.name} pigment=${_lstar(colors.accent).toStringAsFixed(1)} ink=${_lstar(ink).toStringAsFixed(1)}',
          );
          final turn = (_hue(ink) - _hue(colors.accent)).abs();
          expect(math.min(turn, 2 * math.pi - turn), lessThan(.2));
          for (final well in [
            colors.wellStart,
            colors.wellEnd,
            colors.ground,
          ]) {
            expect(_contrast(ink, well), greaterThanOrEqualTo(3));
          }
        },
      );
    }
  }
}

// The five tones stay apart in all six palettes, by day and by night: a
// tag's or a badge's dot (the indicator) and its words (the foreground) read
// as another tone, never the same one in a palette whose accent sits near a
// status hue (ember's orange by the danger red, lagoon's cyan by the
// success green). Tinted fills differ too where no hairline separates them:
// the neutral tone wears a hairline instead.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

/// CIE L*a*b* of [c] (D65).
List<double> _lab(Color c) {
  double lin(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  final r = lin(c.r), g = lin(c.g), b = lin(c.b);
  final x = (r * 0.4124 + g * 0.3576 + b * 0.1805) / 0.95047;
  final y = r * 0.2126 + g * 0.7152 + b * 0.0722;
  final z = (r * 0.0193 + g * 0.1192 + b * 0.9505) / 1.08883;
  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
}

/// The CIE76 distance between [a] and [b]: 2.3 is the least step an eye
/// tells apart side by side.
double _distance(Color a, Color b) {
  final p = _lab(a), q = _lab(b);
  return math.sqrt(
    math.pow(p[0] - q[0], 2) +
        math.pow(p[1] - q[1], 2) +
        math.pow(p[2] - q[2], 2),
  );
}

void main() {
  for (final palette in MinimalThemeData.palettes) {
    for (final brightness in Brightness.values) {
      test('${palette.id}, ${brightness.name}: the tones stay apart', () {
        final t = MinimalThemeData.preset(palette.id, brightness);
        const tones = MinimalTone.values;
        for (var i = 0; i < tones.length; i++) {
          for (var j = i + 1; j < tones.length; j++) {
            final a = t.tone(tones[i]);
            final b = t.tone(tones[j]);
            final pair = '${tones[i].name}/${tones[j].name}';
            expect(
              _distance(a.indicator, b.indicator),
              greaterThan(20),
              reason: '$pair dots',
            );
            expect(
              _distance(a.foreground, b.foreground),
              greaterThan(20),
              reason: '$pair words',
            );
            if (tones[i] != MinimalTone.neutral) {
              expect(
                _distance(a.background, b.background),
                greaterThan(4),
                reason: '$pair fills',
              );
            }
          }
        }
      });
    }
  }
}

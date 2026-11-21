// A chart's series weigh the same. By day the first series is the accent
// itself, and every other piece, bar and line is its pastel's hue at the
// accent's OKLCH lightness and chroma (as much chroma as sRGB holds at that
// hue), so none says it matters more; each is told from the next by its hue.
// No contrast target: legends, labels and values carry the data. By night the
// accent leads and the pastels follow, chalky, as before.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clay_ui/clay_ui.dart';

double _linear(double v) =>
    v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

double _cbrt(double v) => math.pow(v, 1 / 3).toDouble();

/// [color]'s OKLCH lightness, chroma and hue in degrees.
(double, double, double) _lch(Color color) {
  final r = _linear(color.r);
  final g = _linear(color.g);
  final b = _linear(color.b);
  final l = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  final m = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  final s = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  final okA = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
  final okB = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;
  return (
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    math.sqrt(okA * okA + okB * okB),
    math.atan2(okB, okA) * 180 / math.pi % 360,
  );
}

void main() {
  const day = ClayColors.light();
  const night = ClayColors.dark();

  test('by day the first series is the accent, unchanged', () {
    expect(claySliceColor(day, 0), day.accent);
    expect(claySeriesColor(day, 0), day.accent);
  });

  test('by day every other series has the accent\'s lightness and chroma', () {
    final (lightness, chroma, _) = _lch(day.accent);
    for (var i = 1; i < 7; i++) {
      final (l, c, _) = _lch(claySliceColor(day, i));
      expect(l, closeTo(lightness, 0.01), reason: 'series $i lightness');
      // As much of the accent's chroma as sRGB holds at the pastel's hue:
      // never more, and at most 0.03 less (sky's limit at this lightness).
      expect(c, lessThanOrEqualTo(chroma + 0.005), reason: 'series $i');
      expect(c, greaterThan(chroma - 0.035), reason: 'series $i chroma');
      expect(claySeriesColor(day, i), claySliceColor(day, i));
    }
  });

  test('by day each series keeps its pastel\'s hue', () {
    const pastels = [
      ClayTint.sky,
      ClayTint.mint,
      ClayTint.lilac,
      ClayTint.butter,
      ClayTint.rose,
      ClayTint.peach,
    ];
    for (var i = 1; i < 7; i++) {
      final (_, _, hue) = _lch(claySliceColor(day, i));
      final (_, _, want) = _lch(day.tint(pastels[i - 1]));
      final apart = (hue - want).abs() % 360;
      expect(math.min(apart, 360 - apart), lessThan(4), reason: 'series $i');
    }
  });

  test('by night the accent leads and lines stand 3:1', () {
    expect(claySliceColor(night, 0), night.accent);
    expect(claySeriesColor(night, 0), night.accent);
    for (var i = 1; i < 7; i++) {
      expect(
        clayContrast(claySeriesColor(night, i), night.clay),
        greaterThanOrEqualTo(3),
      );
    }
  });
}

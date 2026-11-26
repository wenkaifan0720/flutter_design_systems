// By day moss's olive at the silver's own tones read as khaki; its metal now
// stands two tones lighter, a pale anodised olive. Every word reads at least
// as well as on the unlifted metal (the walked accents at their bar), a key's
// top stays under white, proud of the panel, and nothing else moves.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

const _light = Color(0xFF7BD34F);
const _finish = Color(0xFF5C6B45);

double _tone(Color c) => RawHct.fromColor(c).tone;

double _worst(Color c, Iterable<Color> on) =>
    on.map((g) => RawPalette.contrastRatio(c, g)).reduce(math.min);

// Each word: its worst ratio, its bar, and whether it is an accent walked to
// its bar on whatever metal it lands (the lit legend, the focus ring).
List<(String, double, double, bool)> _words(StudioColors c) {
  final metals = [c.chassis, c.panel, c.panelLow, c.bar, c.barLow];
  final glass = [c.display, c.displayLow];
  final keys = [c.key, c.keyLow];
  return [
    ('legend', _worst(c.legend, metals), 4.5, false),
    ('legendMuted', _worst(c.legendMuted, metals), 4.5, false),
    (
      'onDisplayMuted',
      _worst(c.onDisplayMuted, [...glass, ...metals]),
      4.5,
      false,
    ),
    (
      'litLegend',
      _worst(c.litLegend, [...metals, ...glass, ...keys]),
      4.5,
      true,
    ),
    ('dangerLegend', _worst(c.dangerLegend, [...metals, ...glass]), 4.5, false),
    ('focusRing', _worst(c.focusRing, [...metals, ...keys]), 3, true),
    ('onKey', _worst(c.onKey, keys), 4.5, false),
  ];
}

void main() {
  final day = StudioThemeData.preset('moss', Brightness.light).colors;
  final unlifted = StudioThemeData.from(
    indicator: _light,
    finish: _finish,
  ).colors;

  test("by day moss's metal stands two tones over the silver's", () {
    for (final (name, lifted, own) in [
      ('chassis', day.chassis, unlifted.chassis),
      ('chassisLow', day.chassisLow, unlifted.chassisLow),
      ('panel', day.panel, unlifted.panel),
      ('panelLow', day.panelLow, unlifted.panelLow),
      ('bar', day.bar, unlifted.bar),
      ('barLow', day.barLow, unlifted.barLow),
      ('key', day.key, unlifted.key),
      ('keyLow', day.keyLow, unlifted.keyLow),
    ]) {
      expect(_tone(lifted) - _tone(own), closeTo(2, 0.35), reason: name);
    }
    expect(day.display, unlifted.display, reason: 'the glass keeps its tone');
  });

  test("a key's top stays under white, proud of the panel", () {
    expect(_tone(day.key), lessThan(99.6));
    expect(
      RawPalette.contrastRatio(day.key, day.panel),
      greaterThanOrEqualTo(1.17),
    );
  });

  test('every word reads at least as well as on the unlifted metal', () {
    final now = _words(day);
    final before = _words(unlifted);
    for (var i = 0; i < now.length; i++) {
      final (name, ratio, bar, walked) = now[i];
      expect(ratio, greaterThanOrEqualTo(bar), reason: name);
      if (walked) continue;
      expect(
        ratio,
        greaterThanOrEqualTo(before[i].$2),
        reason:
            '$name read ${before[i].$2.toStringAsFixed(3)}:1 before, '
            '${ratio.toStringAsFixed(3)}:1 now',
      );
    }
  });

  test('moss by night and the other presets keep their metal', () {
    expect(
      StudioThemeData.preset('moss', Brightness.dark).colors,
      StudioThemeData.from(
        indicator: _light,
        finish: _finish,
        brightness: Brightness.dark,
      ).colors,
    );
    final silver = StudioThemeData.preset('anodised', Brightness.light).colors;
    for (final id in ['cobalt', 'teal', 'violet', 'graphite']) {
      final c = StudioThemeData.preset(id, Brightness.light).colors;
      expect(_tone(c.panel), closeTo(_tone(silver.panel), 0.5), reason: id);
    }
  });
}

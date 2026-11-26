// RetroDesktopThemeData.from in ui_core's palette maths: the machine's grey keeps the supplied colour's hue at the
// period's lightness (no darker than tone 85 by day, no lighter than 34 by night), and the highlight keeps the brand
// colour's hue as it takes a tone that reads.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

// How far apart two colours' hues stand round the wheel, in degrees.
double _hueGap(Color a, Color b) {
  final d = (RawHct.fromColor(a).hue - RawHct.fromColor(b).hue).abs() % 360;
  return d > 180 ? 360 - d : d;
}

void main() {
  for (final (surface, brightness) in const [
    (Color(0xff2255aa), Brightness.light),
    (Color(0xffe5dfcf), Brightness.dark),
  ]) {
    test('the machine keeps $surface\'s hue at the period\'s lightness by '
        '${brightness.name}', () {
      final c = RetroDesktopThemeData.from(
        primary: const Color(0xff803b1c),
        brightness: brightness,
        surface: surface,
      ).colors;
      final tone = RawHct.fromColor(c.platinum).tone;
      if (brightness == Brightness.light) {
        expect(tone, greaterThanOrEqualTo(84.5));
      } else {
        expect(tone, lessThanOrEqualTo(34.5));
      }
      expect(_hueGap(c.platinum, surface), lessThan(12));
    });
  }

  for (final primary in const [
    Color(0xff66ccff),
    Color(0xffffcc00),
    Color(0xff2255aa),
    Color(0xffcc2244),
  ]) {
    for (final brightness in Brightness.values) {
      test('the highlight keeps $primary\'s hue by ${brightness.name}', () {
        final c = RetroDesktopThemeData.from(
          primary: primary,
          brightness: brightness,
        ).colors;
        expect(_hueGap(c.highlight, primary), lessThan(12));
      });
    }
  }
}

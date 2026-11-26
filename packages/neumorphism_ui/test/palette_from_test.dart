// NeumorphicThemeData.from in ui_core's palette maths: the wall keeps the ground's hue in a soft material's band (no
// darker than tone 85 by day, no lighter than tone 20 by night), the pigment keeps its hue as it takes a tone that
// reads, and the pigment's fill carries white words by day and the wall's ink by night.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

// How far apart two colours' hues stand round the wheel, in degrees.
double _hueGap(Color a, Color b) {
  final d = (RawHct.fromColor(a).hue - RawHct.fromColor(b).hue).abs() % 360;
  return d > 180 ? 360 - d : d;
}

void main() {
  for (final (ground, brightness) in const [
    (Color(0xff1f3a68), Brightness.light),
    (Color(0xff101010), Brightness.light),
    (Color(0xffe5dfcf), Brightness.dark),
    (Color(0xffffffff), Brightness.dark),
  ]) {
    test(
      "the wall keeps $ground's hue in the material's band by ${brightness.name}",
      () {
        final c = NeumorphicThemeData.from(
          ground: ground,
          pigment: const Color(0xff7542a3),
          brightness: brightness,
        ).colors;
        final tone = RawHct.fromColor(c.ground).tone;
        if (brightness == Brightness.light) {
          expect(tone, inInclusiveRange(84.5, 93.5));
        } else {
          expect(tone, inInclusiveRange(9.5, 20.5));
        }
        if (RawHct.fromColor(ground).chroma > 8) {
          expect(_hueGap(c.ground, ground), lessThan(12));
        }
      },
    );
  }

  for (final pigment in const [
    Color(0xff1f3a68),
    Color(0xff2e7d32),
    Color(0xff7542a3),
    Color(0xffc9a227),
    Color(0xfff4b6c2),
  ]) {
    for (final brightness in Brightness.values) {
      test(
        "the pigment keeps $pigment's hue, its fill the look's words, by ${brightness.name}",
        () {
          final c = NeumorphicThemeData.from(
            ground: const Color(0xffe4e8ee),
            pigment: pigment,
            brightness: brightness,
          ).colors;
          expect(_hueGap(c.accent, pigment), lessThan(12));
          expect(_hueGap(c.accentInk, pigment), lessThan(12));
          if (brightness == Brightness.light) {
            expect(c.onAccent, const Color(0xffffffff));
          } else {
            expect(c.onAccent, isNot(const Color(0xffffffff)));
            expect(RawHct.fromColor(c.onAccent).tone, lessThan(20));
          }
          expect(
            RawPalette.contrastRatio(c.onAccent, c.accent),
            greaterThanOrEqualTo(4.5),
          );
          for (final g in [
            c.ground,
            c.faceStart,
            c.faceEnd,
            c.wellStart,
            c.wellEnd,
          ]) {
            expect(
              RawPalette.contrastRatio(c.accentInk, g),
              greaterThanOrEqualTo(4.5),
            );
            // The fill reads on the wall too: the look's one live colour (an LED, a slot, a chart's series).
            expect(
              RawPalette.contrastRatio(c.accent, g),
              greaterThanOrEqualTo(4.5),
            );
            expect(RawPalette.contrastRatio(c.ink, g), greaterThanOrEqualTo(7));
          }
        },
      );
    }
  }
}

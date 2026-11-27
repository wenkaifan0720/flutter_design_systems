// The tones (information, success, warning, danger) stay apart from each other and from the quiet ink in
// every preset, by day and by night: a tag's or a note's colour says which it is. By night the page's
// words keep 6:1 on the brightest wash, so a tone's ink has room for its colour.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

double _hueGap(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}

void main() {
  const coloured = [
    FrostedTone.info,
    FrostedTone.success,
    FrostedTone.warning,
    FrostedTone.danger,
  ];
  for (final id in [for (final p in FrostedThemeData.palettes) p.id]) {
    for (final brightness in Brightness.values) {
      final where = '$id, ${brightness.name}';
      final t = FrostedThemeData.preset(id, brightness);
      test('$where: each tone has a colour of its own', () {
        final quiet = RawHct.fromColor(t.toneInk(FrostedTone.quiet));
        final inks = {
          for (final tone in coloured) tone: RawHct.fromColor(t.toneInk(tone)),
        };
        for (final MapEntry(key: tone, value: ink) in inks.entries) {
          expect(
            ink.chroma,
            greaterThanOrEqualTo(10),
            reason: '$where: ${tone.name} keeps a colour',
          );
          if (_hueGap(ink.hue, quiet.hue) < 30) {
            expect(
              ink.chroma,
              greaterThanOrEqualTo(quiet.chroma + 10),
              reason: '$where: ${tone.name} stands apart from the quiet ink',
            );
          }
          for (final MapEntry(key: other, value: o) in inks.entries) {
            if (other.index <= tone.index) continue;
            expect(
              _hueGap(ink.hue, o.hue),
              greaterThanOrEqualTo(40),
              reason: '$where: ${tone.name} and ${other.name} differ in hue',
            );
          }
        }
      });
      test('$where: each tone reads on its tint', () {
        final cs = t.colorScheme;
        for (final tone in coloured) {
          for (final ground in [cs.background, cs.surface]) {
            expect(
              FrostedThemeData.contrast(
                t.toneInk(tone),
                Color.alphaBlend(t.toneTint(tone), ground),
              ),
              greaterThanOrEqualTo(4.5),
              reason: '$where: ${tone.name}',
            );
          }
        }
      });
    }
    test('$id by night: the page\'s words read 6:1 on every wash', () {
      final t = FrostedThemeData.preset(id, Brightness.dark);
      final cs = t.colorScheme;
      for (final peak in t.lights.peaksOver(cs.background, night: true)) {
        expect(
          FrostedThemeData.contrast(cs.textPrimary, peak),
          greaterThanOrEqualTo(6),
          reason: '$id: on $peak',
        );
      }
    });
  }
}

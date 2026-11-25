// The HCT ui_core carries (internal/hct.dart) gives what
// material_color_utilities 0.13.0 gives, value for value: the same tones as
// a Material scheme.
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/src/internal/hct.dart' as kit;
import 'package:material_color_utilities/material_color_utilities.dart' as mcu;

void main() {
  test('every sRGB colour on a 29-step grid reads as Material reads it', () {
    var n = 0;
    for (var r = 0; r < 256; r += 9) {
      for (var g = 0; g < 256; g += 9) {
        for (var b = 0; b < 256; b += 9) {
          final argb = 0xFF000000 | r << 16 | g << 8 | b;
          final ours = kit.Hct.fromInt(argb);
          final theirs = mcu.Hct.fromInt(argb);
          expect(ours.hue, theirs.hue);
          expect(ours.chroma, theirs.chroma);
          expect(ours.tone, theirs.tone);
          expect(ours.toInt(), theirs.toInt());
          n++;
        }
      }
    }
    expect(n, 29 * 29 * 29);
  });

  test('every hue, chroma and tone solves to the colour Material solves', () {
    for (var h = 0.0; h < 360; h += 7.5) {
      for (var c = 0.0; c <= 150; c += 6) {
        for (var t = 0.0; t <= 100; t += 2.5) {
          expect(
            kit.Hct.from(h, c, t).toInt(),
            mcu.Hct.from(h, c, t).toInt(),
            reason: 'hue $h, chroma $c, tone $t',
          );
        }
      }
    }
  });

  test('tone contrast reads as Material reads it', () {
    for (var a = 0.0; a <= 100; a += 5) {
      for (var b = 0.0; b <= 100; b += 5) {
        expect(
          kit.Contrast.ratioOfTones(a, b),
          mcu.Contrast.ratioOfTones(a, b),
        );
      }
      expect(
        kit.Contrast.darker(tone: a, ratio: 4.5),
        mcu.Contrast.darker(tone: a, ratio: 4.5),
      );
      expect(
        kit.Contrast.lighter(tone: a, ratio: 4.5),
        mcu.Contrast.lighter(tone: a, ratio: 4.5),
      );
    }
  });
}

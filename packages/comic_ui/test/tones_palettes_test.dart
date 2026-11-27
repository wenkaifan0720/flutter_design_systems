// Status tones stay apart in every print run, by day and by night: info, success, warning and danger are four hues, none
// of them a grey, each reading on the panel.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

double _hueGap(Color a, Color b) {
  final d = (HSVColor.fromColor(a).hue - HSVColor.fromColor(b).hue).abs();
  return d > 180 ? 360 - d : d;
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}

void main() {
  for (final palette in ComicThemeData.palettes) {
    for (final brightness in Brightness.values) {
      test(
        '${palette.id} by ${brightness == Brightness.dark ? 'night' : 'day'}: four status tones apart',
        () {
          final colors = ComicThemeData(
            palette: palette,
            brightness: brightness,
          ).colors;
          final t = colors.tones;
          final tones = {
            'info': t.info,
            'success': t.success,
            'warning': t.warning,
            'danger': t.danger,
          };
          final names = tones.keys.toList();
          for (var i = 0; i < names.length; i++) {
            final tone = tones[names[i]]!;
            expect(
              HSLColor.fromColor(tone).saturation,
              greaterThan(.3),
              reason: '${names[i]} is a hue, not a grey',
            );
            expect(
              _contrast(tone, colors.card),
              greaterThanOrEqualTo(3),
              reason: '${names[i]} reads on the panel',
            );
            for (var j = i + 1; j < names.length; j++) {
              expect(
                _hueGap(tone, tones[names[j]]!),
                greaterThan(20),
                reason: '${names[i]} and ${names[j]} read apart',
              );
            }
          }
        },
      );
    }
  }
}

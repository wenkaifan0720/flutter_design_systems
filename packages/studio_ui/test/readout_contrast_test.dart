// A readout reads in both rooms: by day pale glass lit amber from behind
// under dark figures, by night dark glass under lit figures, the figures at
// 4.5:1 or more on the glass's darker end and the dim figures at 3:1, for
// Studio's own colours and for a brand's.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

double _ratio(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
}

void main() {
  final themes = <String, StudioThemeData>{
    'Studio by day': StudioThemeData.light(),
    'Studio by night': StudioThemeData.dark(),
    for (final (name, indicator) in [
      ('teal', const Color(0xFF4FD1C5)),
      ('red', const Color(0xFFE5484D)),
      ('violet', const Color(0xFF8E4EC6)),
      ('yellow', const Color(0xFFFFE629)),
    ])
      for (final brightness in Brightness.values)
        'a $name brand by ${brightness == Brightness.light ? 'day' : 'night'}':
            StudioThemeData.from(indicator: indicator, brightness: brightness),
  };
  for (final MapEntry(key: name, value: theme) in themes.entries) {
    test('$name: a readout\'s figures read on its glass', () {
      final c = theme.colors;
      final day = theme.colors.brightness == Brightness.light;
      expect(c.litReadout, day, reason: 'by day the glass is lit');
      for (final glass in [c.readout, c.readoutLow]) {
        expect(_ratio(c.readoutLit, glass), greaterThanOrEqualTo(4.5));
        expect(_ratio(c.onReadout, glass), greaterThanOrEqualTo(4.5));
        expect(_ratio(c.readoutDim, glass), greaterThanOrEqualTo(3));
      }
      expect(c.readoutGlow(c.readoutLit), day ? isEmpty : isNotEmpty);
    });
  }
}

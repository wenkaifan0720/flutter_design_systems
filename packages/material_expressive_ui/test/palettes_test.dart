// Expressive's six presets (ExpressiveThemeData.presets): baseline first,
// Compose's own scheme and the default, then slate, bloom, grove, ember and
// tide. Each is its own seed, and by day and by night every content pair
// and boundary meets its contrast floor (ExpressiveColors.contrastShortfalls
// is empty), at standard contrast and at high.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

void main() {
  test('six presets, baseline first and the default', () {
    expect(ExpressiveThemeData.presets, [
      'baseline',
      'slate',
      'bloom',
      'grove',
      'ember',
      'tide',
    ]);
    expect(ExpressiveThemeData.defaultPreset, 'baseline');
  });

  for (final b in Brightness.values) {
    test('${b.name}: each preset its own primary', () {
      final primaries = {
        for (final name in ExpressiveThemeData.presets)
          ExpressiveThemeData.preset(name, b).colors.primary,
      };
      expect(primaries, hasLength(ExpressiveThemeData.presets.length));
    });

    for (final name in ExpressiveThemeData.presets) {
      for (final level in [0.0, 1.0]) {
        test('${b.name}, $name at contrast $level: no shortfalls', () {
          final theme = ExpressiveThemeData.preset(
            name,
            b,
            contrastLevel: level,
          );
          expect(theme.brightness, b);
          expect(theme.colors.contrastShortfalls(), isEmpty);
        });
      }
    }
  }
}

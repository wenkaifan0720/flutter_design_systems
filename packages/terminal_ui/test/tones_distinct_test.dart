// Terminal's status tones stay apart in each palette that draws them in
// colour, by day and by night. The three one-ink palettes (mono, phosphor,
// amber) draw every tone in the words' ink, as a monochrome terminal does: a
// state there reads by its glyph (✓ ✗ ! i), never by its colour.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

void main() {
  test('the tones stay apart in the colour palettes', () {
    const DesignToneCheck(look: 'Terminal').check([
      for (final id in ['standard', 'harbor', 'dusk'])
        for (final b in Brightness.values)
          DesignToneSet(
            palette: id,
            brightness: b,
            tones: {
              'info': TermThemeData.preset(id, b).info,
              'success': TermThemeData.preset(id, b).success,
              'warning': TermThemeData.preset(id, b).warning,
              'danger': TermThemeData.preset(id, b).danger,
            },
          ),
    ]).verify();
  });

  test('the one-ink palettes draw every tone in the words\' ink', () {
    for (final id in ['mono', 'phosphor', 'amber']) {
      for (final b in Brightness.values) {
        final t = TermThemeData.preset(id, b);
        for (final tone in [t.info, t.success, t.warning, t.danger]) {
          expect(tone, t.foreground, reason: '\$id ${b.name}');
        }
      }
    }
  });
}

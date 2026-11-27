// Tones at night: the informative badge, the quiet neutral, stands no farther
// from the page than the brand's and success's badges, filled or tinted; a
// filled one's words are no stronger than theirs, and they hold 4.5:1.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/src/fluent2_design/components/badge/badge.dart'
    show Fluent2BadgeFace;

double _ratio(Color a, Color b) => RawPalette.contrastRatio(a, b);

void main() {
  test('by night the informative badge is the quietest', () {
    for (final palette in Fluent2ThemeData.palettes) {
      final t = Fluent2ThemeData.preset(palette.id, Brightness.dark);
      for (final appearance in const [
        Fluent2BadgeAppearance.filled,
        Fluent2BadgeAppearance.tint,
      ]) {
        Fluent2BadgeFace face(Fluent2BadgeColor color) =>
            Fluent2BadgeFace.of(t, appearance, color);
        Color fill(Fluent2BadgeFace f) =>
            Color.alphaBlend(f.fill, t.background);
        final quiet = face(Fluent2BadgeColor.informative);
        final why = '${palette.id} ${appearance.name}';
        for (final loud in [
          Fluent2BadgeColor.brand,
          Fluent2BadgeColor.success,
        ]) {
          final other = face(loud);
          expect(
            _ratio(fill(quiet), t.background),
            lessThanOrEqualTo(_ratio(fill(other), t.background) + 0.25),
            reason: '$why: its fill against the page, beside ${loud.name}',
          );
          // A filled badge's words: Fluent's first ink on its black step
          // read at 13.6:1, the loudest words of any badge.
          if (appearance == Fluent2BadgeAppearance.filled) {
            expect(
              _ratio(quiet.ink, fill(quiet)),
              lessThanOrEqualTo(_ratio(other.ink, fill(other)) + 0.5),
              reason: '$why: its words, beside ${loud.name}',
            );
          }
        }
        expect(
          _ratio(quiet.ink, fill(quiet)),
          greaterThanOrEqualTo(4.5),
          reason: '$why: its words hold 4.5:1',
        );
      }
    }
  });
}

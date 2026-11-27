// Every preset the look ships holds the bars by day and by night: words at
// 7:1 and secondary words at 4.5:1 on every ground, a field's rim at 3:1,
// the primary's label at 4.5:1 on it, the primary 3:1 off the page, and the
// accent's ink at 4.5:1 on every ground and its wash, and the focus ring
// 3:1 off every ground.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

double _worst(Color ink, Iterable<Color> grounds) => grounds
    .map((g) => RawPalette.contrastRatio(ink, g))
    .reduce((a, b) => a < b ? a : b);

void main() {
  test('the look ships six presets, the standard one first', () {
    final ids = [for (final palette in MinimalThemeData.palettes) palette.id];
    expect(ids, hasLength(6));
    expect(ids.first, 'standard');
    expect({...ids}, hasLength(6));
  });

  for (final id in [
    for (final palette in MinimalThemeData.palettes) palette.id,
  ]) {
    for (final brightness in Brightness.values) {
      test('$id, ${brightness.name}: every bar holds', () {
        final t = MinimalThemeData.preset(id, brightness);
        expect(t.id, id);
        expect(t.brightness, brightness);
        final grounds = [t.background, t.card, t.muted];
        expect(_worst(t.foreground, grounds), greaterThanOrEqualTo(7));
        expect(
          _worst(t.mutedForeground, [...grounds, t.sunken]),
          greaterThanOrEqualTo(4.5),
        );
        expect(_worst(t.input, grounds), greaterThanOrEqualTo(3));
        expect(
          RawPalette.contrastRatio(t.primaryForeground, t.primary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          RawPalette.contrastRatio(t.primary, t.background),
          greaterThanOrEqualTo(3),
        );
        expect(
          _worst(t.primaryInk, [...grounds, t.primarySubtle]),
          greaterThanOrEqualTo(4.5),
        );
        expect(_worst(t.ring, grounds), greaterThanOrEqualTo(3));
        expect(
          RawPalette.contrastRatio(t.destructiveForeground, t.destructive),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  }
}

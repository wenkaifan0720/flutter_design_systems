// Brutal's six palettes: raw first, each designed by day and by night, each
// its own, each holding the look's words.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:brutal_ui/src/brutal/internal/focus_ink.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _six = ['raw', 'poster', 'zine', 'riso', 'blueprint', 'acid'];

double _ratio(Color a, Color b) => RawPalette.contrastRatio(a, b);

void main() {
  test('six palettes, raw the default', () {
    expect(BrutalThemeData.presets, _six);
  });

  test("raw is the look's own colours", () {
    expect(
      BrutalThemeData.preset('raw', Brightness.light).colors,
      const BrutalColors.light(),
    );
    expect(
      BrutalThemeData.preset('raw', Brightness.dark).colors,
      const BrutalColors.dark(),
    );
  });

  for (final brightness in Brightness.values) {
    final when = brightness == Brightness.dark ? 'night' : 'day';

    test(
      'by $when each palette is its own: no two share a signal or a lead',
      () {
        final colours = [
          for (final id in _six) BrutalThemeData.preset(id, brightness).colors,
        ];
        for (final c in colours) {
          expect(c.brightness, brightness);
        }
        expect(colours.map((c) => c.signal).toSet(), hasLength(6));
        expect(colours.map((c) => c.lime).toSet(), hasLength(6));
        expect(colours.map((c) => c.paper).toSet().length, greaterThan(2));
      },
    );

    for (final id in _six) {
      test("$id by $when holds the look's words", () {
        final c = BrutalThemeData.preset(id, brightness).colors;
        for (final (name, block) in [
          ('lime', c.lime),
          ('blue', c.blue),
          ('pink', c.pink),
          ('violet', c.violet),
        ]) {
          expect(
            _ratio(c.onBlock, block),
            greaterThanOrEqualTo(4.5),
            reason: '$name: black words on the block',
          );
        }
        expect(c.onBlock, const Color(0xFF000000));
        expect(c.onSignal, const Color(0xFF000000));
        expect(_ratio(c.onSignal, c.signal), greaterThanOrEqualTo(4.5));
        expect(_ratio(c.onDanger, c.danger), greaterThanOrEqualTo(4.5));
        for (final (name, ground) in [
          ('paper', c.paper),
          ('surface', c.surface),
        ]) {
          expect(
            _ratio(c.ink, ground),
            greaterThanOrEqualTo(7),
            reason: 'ink on $name',
          );
          expect(
            _ratio(c.inkMuted, ground),
            greaterThanOrEqualTo(4.5),
            reason: 'muted words on $name',
          );
          expect(
            _ratio(c.danger, ground),
            greaterThanOrEqualTo(4.5),
            reason: 'an error on $name',
          );
          expect(
            _ratio(c.disabled, ground),
            greaterThanOrEqualTo(4.5),
            reason: "a disabled field's words on $name",
          );
          expect(
            _ratio(brutalFocusInk(c, ground), ground),
            greaterThanOrEqualTo(3),
            reason: 'the focus ink on $name',
          );
        }
      });
    }
  }
}

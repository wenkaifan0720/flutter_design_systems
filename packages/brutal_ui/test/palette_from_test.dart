// BrutalThemeData.from on ui_core's palette maths: the signal stays the
// main action's fill with black or white words at 4.5:1 (the named rule),
// the lead block (lime) takes the signal's hue at the look's own lime tone
// under black words, the other blocks stay the look's own unless named, a
// named block wins; the focus ink is the nearest tone of the signal's hue
// that holds 3:1, not a mix toward black.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:brutal_ui/src/brutal/internal/focus_ink.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// The briefs a look's palette is checked in: navy, green, gold, purple and
// a pastel blush.
const _briefs = <String, Color>{
  'navy': Color(0xFF1F3A68),
  'green': Color(0xFF2E7D32),
  'gold': Color(0xFFC9A227),
  'purple': Color(0xFF6D28D9),
  'pastel': Color(0xFFF4A7B9),
};

double _hueApart(Color a, Color b) {
  final d = (RawHct.fromColor(a).hue - RawHct.fromColor(b).hue).abs() % 360;
  return d > 180 ? 360 - d : d;
}

void main() {
  for (final brightness in Brightness.values) {
    final own = brightness == Brightness.dark
        ? const BrutalColors.dark()
        : const BrutalColors.light();
    for (final MapEntry(key: name, value: signal) in _briefs.entries) {
      test('$name (${brightness.name}): the signal keeps its colour under '
          'words at 4.5:1', () {
        final c = BrutalThemeData.from(
          signal: signal,
          brightness: brightness,
        ).colors;
        expect(c.signal, signal);
        expect(
          RawPalette.contrastRatio(c.onSignal, c.signal),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('$name (${brightness.name}): the lead block takes the signal\'s '
          'hue at the look\'s lime tone, under black words', () {
        final c = BrutalThemeData.from(
          signal: signal,
          brightness: brightness,
        ).colors;
        expect(_hueApart(c.lime, signal), lessThan(6), reason: '${c.lime}');
        expect(
          RawHct.fromColor(c.lime).tone,
          moreOrLessEquals(RawHct.fromColor(own.lime).tone, epsilon: 1),
        );
        expect(
          RawPalette.contrastRatio(c.onBlock, c.lime),
          greaterThanOrEqualTo(4.5),
        );
        // The other blocks are a chart's series and the avatars' colours:
        // the look's own four hues.
        expect([c.blue, c.pink, c.violet], [own.blue, own.pink, own.violet]);
      });
    }

    test('a named block wins (${brightness.name})', () {
      const lime = Color(0xFFFFE066);
      const blue = Color(0xFF8AB4FF);
      final c = BrutalThemeData.from(
        signal: _briefs['navy']!,
        lime: lime,
        blue: blue,
        brightness: brightness,
      ).colors;
      expect(c.lime, lime);
      expect(c.blue, blue);
    });
  }

  test("the look's own orange keeps black words", () {
    final c = BrutalThemeData.from(signal: const Color(0xFFFF6A13)).colors;
    expect(c.signal, const Color(0xFFFF6A13));
    expect(c.onSignal, const Color(0xFF000000));
  });

  for (final (name, colors, ground) in [
    (
      'the orange on white',
      const BrutalColors.light(),
      const Color(0xFFFFFFFF),
    ),
    ('the orange on ink', const BrutalColors.dark(), const Color(0xFFF2F2F2)),
    (
      'a navy on night',
      BrutalThemeData.from(
        signal: _briefs['navy']!,
        brightness: Brightness.dark,
      ).colors,
      const Color(0xFF121212),
    ),
  ]) {
    test('focus ink, $name: the nearest tone of the signal\'s hue at 3:1', () {
      final ink = brutalFocusInk(colors, ground);
      final ratio = RawPalette.contrastRatio(ink, ground);
      expect(ratio, greaterThanOrEqualTo(3));
      if (RawPalette.contrastRatio(colors.signal, ground) < 3) {
        // Moved only as far as it must, in its own hue.
        expect(ratio, lessThan(3.1));
        expect(_hueApart(ink, colors.signal), lessThan(3));
      } else {
        expect(ink, colors.signal);
      }
    });
  }

  test('brutalContrast is RawPalette.contrastRatio', () {
    // ignore: deprecated_member_use_from_same_package
    expect(
      brutalContrast(const Color(0xFFFF6A13), const Color(0xFFFFFFFF)),
      RawPalette.contrastRatio(
        const Color(0xFFFF6A13),
        const Color(0xFFFFFFFF),
      ),
    );
  });
}

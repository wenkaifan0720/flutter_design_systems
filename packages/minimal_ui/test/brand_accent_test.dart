// MinimalThemeData.from walks every derived role in its own hue on ui_core's
// RawPalette until the presets' bars hold: words at 7:1, secondary words and
// the accent's ink at 4.5:1, a field's rim at 3:1, the primary's label at
// 4.5:1 on it. The named colour stays the fill wherever it stands 3:1 off
// the ground (it is the focus ring too) and Minimal's white or its ink reads
// on it, and moves its tone only, as little as it must, where not. A tinted grey
// stays a grey by night.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

const _briefs = {
  'navy': Color(0xFF1F3A68),
  'green': Color(0xFF2E7D32),
  'gold': Color(0xFFC9A227),
  'purple': Color(0xFF6D28D9),
  'pastel': Color(0xFFF4A7B9),
  'brick': Color(0xFFD9534F),
};

double _hueApart(Color a, Color b) {
  final d = (RawHct.fromColor(a).hue - RawHct.fromColor(b).hue).abs() % 360;
  return d > 180 ? 360 - d : d;
}

double _worst(Color ink, Iterable<Color> grounds) => grounds
    .map((g) => RawPalette.contrastRatio(ink, g))
    .reduce((a, b) => a < b ? a : b);

void main() {
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: accent) in _briefs.entries) {
      final t = MinimalThemeData.from(primary: accent, brightness: brightness);
      final grounds = [t.background, t.card, t.muted];
      final where = '${brightness.name}, $name';

      test(
        '$where: the words, the secondary words and a rim hold their bars',
        () {
          expect(_worst(t.foreground, grounds), greaterThanOrEqualTo(7));
          expect(
            _worst(t.mutedForeground, [...grounds, t.sunken]),
            greaterThanOrEqualTo(4.5),
          );
          expect(_worst(t.input, grounds), greaterThanOrEqualTo(3));
        },
      );

      test("$where: the primary's label reads on it, and the primary stands "
          '3:1 off the ground', () {
        expect(
          RawPalette.contrastRatio(t.primaryForeground, t.primary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          RawPalette.contrastRatio(t.primary, t.background),
          greaterThanOrEqualTo(3),
        );
        expect(_hueApart(t.primary, accent), lessThan(2.5));
      });

      test("$where: the accent's ink reads on every ground and its wash, in "
          'its own hue', () {
        expect(
          _worst(t.primaryInk, [...grounds, t.primarySubtle]),
          greaterThanOrEqualTo(4.5),
        );
        expect(_hueApart(t.primaryInk, accent), lessThan(2.5));
      });
    }
  }

  test('by day, a named colour that stands off the ground stays the fill', () {
    for (final name in ['navy', 'green', 'purple']) {
      final t = MinimalThemeData.from(primary: _briefs[name]!);
      expect(t.primary, _briefs[name], reason: name);
      expect(t.primaryForeground, const Color(0xFFFFFFFF), reason: name);
    }
  });

  test('by day, a gold moves its tone only, to stand 3:1 off the ground as '
      'the focus ring it also is, and keeps the dark ink', () {
    const gold = Color(0xFFE0B000);
    final t = MinimalThemeData.from(primary: gold);
    expect(t.primary, isNot(gold));
    expect(_hueApart(t.primary, gold), lessThan(2.5));
    expect(t.primaryForeground, t.foreground);
  });

  test('a cream neutral tints the night greys without turning them brown', () {
    final t = MinimalThemeData.from(
      primary: _briefs['navy']!,
      neutral: const Color(0xFFF3E9D2),
      brightness: Brightness.dark,
    );
    for (final grey in [t.background, t.card, t.muted]) {
      expect(RawHct.fromColor(grey).chroma, lessThanOrEqualTo(6.5));
    }
  });
  test('a vivid neutral tints the greys, its chroma held to a grey\'s', () {
    for (final brightness in Brightness.values) {
      final t = MinimalThemeData.from(
        primary: _briefs['navy']!,
        neutral: const Color(0xFF2E5BFF),
        brightness: brightness,
      );
      for (final grey in [t.background, t.card, t.muted, t.border]) {
        expect(
          RawHct.fromColor(grey).chroma,
          // Capped at 8; a grey's 8-bit channels round it up a little.
          lessThanOrEqualTo(9),
          reason: '${brightness.name}: $grey',
        );
      }
    }
  });
}

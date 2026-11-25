// ClayThemeData.from keeps a brand's accent as the one key's colour wherever
// Clay's dark ink or its light reads on it at 4.5:1 (a gold, a pastel or a
// navy keeps its colour), and moves only its tone, as little as it must,
// where neither does. The accent's text ink and the focus rim take the
// nearest tone of the accent's own hue that reads on every ground Clay paints
// them on: the ground, clay and a well.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _briefs = {
  'navy': Color(0xFF1F3A68),
  'green': Color(0xFF2E7D32),
  'gold': Color(0xFFC9A227),
  'purple': Color(0xFF6D28D9),
  'blush': Color(0xFFF4A7B9),
  'coral': Color(0xFFFF7A5C),
  // A brick neither Clay's ink nor its light reads on at 4.5:1.
  'brick': Color(0xFFD9534F),
};

double _hueApart(Color a, Color b) {
  final d = (RawHct.fromColor(a).hue - RawHct.fromColor(b).hue).abs() % 360;
  return d > 180 ? 360 - d : d;
}

void main() {
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: accent) in _briefs.entries) {
      final c = ClayThemeData.from(
        accent: accent,
        brightness: brightness,
      ).colors;
      final grounds = {
        'the ground': c.ground,
        'clay': c.clay,
        'a well': c.well,
      };

      test("${brightness.name}, $name: the key's words read on it", () {
        expect(clayContrast(c.onAccent, c.accent), greaterThanOrEqualTo(4.5));
      });

      test('${brightness.name}, $name: its text ink reads on every ground, '
          'in its own hue', () {
        for (final MapEntry(key: where, value: ground) in grounds.entries) {
          expect(
            clayContrast(c.accentInk, ground),
            greaterThanOrEqualTo(4.5),
            reason: 'on $where',
          );
        }
        expect(_hueApart(c.accentInk, accent), lessThan(2.5));
      });

      test('${brightness.name}, $name: the focus rim stands 3:1 from clay '
          'and a well', () {
        expect(clayContrast(c.focus, c.clay), greaterThanOrEqualTo(3));
        expect(clayContrast(c.focus, c.well), greaterThanOrEqualTo(3));
      });
    }
  }

  test('by day, a named accent either ink reads on stays the key', () {
    for (final name in ['navy', 'green', 'purple', 'gold', 'blush', 'coral']) {
      final accent = _briefs[name]!;
      final c = ClayThemeData.from(accent: accent).colors;
      expect(c.accent, accent, reason: name);
    }
  });

  test('a light named accent keeps dark words, as Clay\'s coral does', () {
    for (final name in ['gold', 'blush', 'coral']) {
      final c = ClayThemeData.from(accent: _briefs[name]!).colors;
      expect(c.onAccent, c.ink, reason: name);
    }
  });

  test('a brick neither ink reads on moves its tone only, its hue kept', () {
    final brick = _briefs['brick']!;
    final c = ClayThemeData.from(accent: brick).colors;
    expect(c.accent, isNot(brick));
    expect(_hueApart(c.accent, brick), lessThan(2.5));
    expect(clayContrast(c.onAccent, c.accent), greaterThanOrEqualTo(4.5));
  });

  test("by night, a chart's lines stand 3:1 from the clay, in Clay's "
      "colours and a brand's", () {
    final palettes = {
      'clay': const ClayColors.dark(),
      // An app's own night clay, paler than Clay's: the pastels lift off it.
      'a paler clay': const ClayColors.dark().copyWith(
        clay: const Color(0xFF77718F),
      ),
      for (final MapEntry(key: name, value: accent) in _briefs.entries)
        name: ClayThemeData.from(
          accent: accent,
          brightness: Brightness.dark,
        ).colors,
    };
    // Clay's own coral stands 3:1 already: it stays itself.
    const night = ClayColors.dark();
    expect(claySeriesColor(night, 0), night.accent);
    expect(claySliceColor(night, 0), night.accent);
    for (final MapEntry(key: name, value: c) in palettes.entries) {
      expect(
        clayContrast(claySliceColor(c, 0), c.clay),
        greaterThanOrEqualTo(3),
        reason: '$name, its first piece',
      );
      for (var i = 0; i <= 6; i++) {
        expect(
          clayContrast(claySeriesColor(c, i), c.clay),
          greaterThanOrEqualTo(3),
          reason: '$name, series $i',
        );
      }
    }
  });
}

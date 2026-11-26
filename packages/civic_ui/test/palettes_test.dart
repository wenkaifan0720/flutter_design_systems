// Civic's six palettes: each palette's action reads at 7:1 on the page and
// its ground by day and by night, carries its button's words at 4.5:1, and
// is none of the colours Civic keeps for a meaning (a success's green, an
// error's red, the focus's yellow); a picker's swatch is the action it
// gives, its label and id its own, and an app's stored id finds it again.
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

double _hueGap(Color a, Color b) {
  final d = (RawHct.fromColor(a).hue - RawHct.fromColor(b).hue).abs() % 360;
  return d > 180 ? 360 - d : d;
}

void main() {
  const ids = ['civic', 'harbour', 'indigo', 'heather', 'plum', 'slate'];

  test('there are six, civic the first, each named', () {
    final palettes = CivicThemeData.palettes;
    expect([for (final p in palettes) p.id], ids);
    expect({for (final p in palettes) p.label}, hasLength(6));
    for (final b in Brightness.values) {
      expect(
        CivicThemeData.preset('civic', b),
        CivicThemeData.from(brightness: b),
      );
      expect(
        CivicThemeData.light(),
        CivicThemeData.from(brightness: Brightness.light),
      );
      for (final p in palettes) {
        final t = b == Brightness.dark
            ? CivicThemeData.dark(palette: p)
            : CivicThemeData.light(palette: p);
        // The swatch a picker draws is the action the palette gives.
        expect(p.swatchesFor(b), [t.action], reason: '${p.id} ${b.name}');
        // An app stores the id and finds the palette by it again.
        expect(CivicThemeData.preset(p.id, b), t);
      }
    }
  });

  test("an app's own palette gives its first swatch as the action", () {
    const own = RawNamedPalette(
      id: 'moss',
      label: 'Moss',
      swatches: [Color(0xFF3B5D2A)],
      darkSwatches: [Color(0xFFB9D7A4)],
    );
    for (final b in Brightness.values) {
      final t = b == Brightness.dark
          ? CivicThemeData.dark(palette: own)
          : CivicThemeData.light(palette: own);
      expect(
        t,
        CivicThemeData.from(brightness: b, action: own.swatchesFor(b).first),
      );
    }
  });

  for (final b in Brightness.values) {
    for (final id in ids) {
      test('$id (${b.name}) reads and means nothing else', () {
        final t = CivicThemeData.preset(id, b);
        expect(
          RawPalette.contrastRatio(t.action, t.background),
          greaterThanOrEqualTo(7),
        );
        expect(
          RawPalette.contrastRatio(t.action, t.ground),
          greaterThanOrEqualTo(7),
        );
        expect(
          RawPalette.contrastRatio(t.onAction, t.action),
          greaterThanOrEqualTo(4.5),
        );
        expect(t.danger, CivicThemeData.from(brightness: b).danger);
        expect(t.success, CivicThemeData.from(brightness: b).success);
        expect(t.focus, CivicThemeData.from(brightness: b).focus);
        if (RawHct.fromColor(t.action).chroma > 16) {
          for (final kept in [t.success, t.danger, t.focus]) {
            expect(_hueGap(t.action, kept), greaterThan(30), reason: '$kept');
          }
        }
      });
    }
  }

  test('the tones stay apart and read in every palette, by day and by '
      'night', () {
    for (final b in Brightness.values) {
      for (final p in CivicThemeData.palettes) {
        final t = b == Brightness.dark
            ? CivicThemeData.dark(palette: p)
            : CivicThemeData.light(palette: p);
        final tones = [for (final tone in CivicTone.values) t.toneOf(tone)];
        final where = '${p.id} ${b.name}';
        for (final (fill, ink) in tones) {
          expect(
            RawPalette.contrastRatio(ink, fill),
            greaterThanOrEqualTo(7),
            reason: where,
          );
        }
        // Each meaning a hue of its own, apart from the action's too.
        final hues = [
          for (final tone in CivicTone.values)
            if (tone != CivicTone.neutral) t.toneOf(tone).$1,
        ];
        for (var i = 0; i < hues.length; i++) {
          for (var j = i + 1; j < hues.length; j++) {
            expect(_hueGap(hues[i], hues[j]), greaterThan(30), reason: where);
          }
        }
        // A tag never reads as the action's button: its fill is pale by
        // day, deep by night, the action's the other way.
        for (final (fill, _) in tones) {
          expect(
            RawPalette.contrastRatio(fill, t.action),
            greaterThanOrEqualTo(3),
            reason: where,
          );
        }
      }
    }
  });

  test('the chromatic palettes stand apart in hue', () {
    for (final b in Brightness.values) {
      final actions = [
        for (final id in ids)
          if (RawHct.fromColor(CivicThemeData.preset(id, b).action).chroma > 16)
            CivicThemeData.preset(id, b).action,
      ];
      for (var i = 0; i < actions.length; i++) {
        for (var j = i + 1; j < actions.length; j++) {
          expect(_hueGap(actions[i], actions[j]), greaterThan(15));
        }
      }
    }
  });

  test('each palette has its own action', () {
    for (final b in Brightness.values) {
      final actions = {
        for (final id in ids) CivicThemeData.preset(id, b).action,
      };
      expect(actions, hasLength(6));
    }
  });
}

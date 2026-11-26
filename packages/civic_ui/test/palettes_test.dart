// Civic's six palettes: each preset's action reads at 7:1 on the page and
// its ground by day and by night, carries its button's words at 4.5:1, and
// is none of the colours Civic keeps for a meaning (a success's green, an
// error's red, the focus's yellow).
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

double _hueGap(Color a, Color b) {
  final d = (RawHct.fromColor(a).hue - RawHct.fromColor(b).hue).abs() % 360;
  return d > 180 ? 360 - d : d;
}

void main() {
  test('there are six, civic the first', () {
    expect(CivicThemeData.presets, hasLength(6));
    expect(CivicThemeData.presets.toSet(), hasLength(6));
    expect(CivicThemeData.presets.first, 'civic');
    for (final b in Brightness.values) {
      expect(
        CivicThemeData.preset('civic', b),
        CivicThemeData.from(brightness: b),
      );
    }
  });

  for (final b in Brightness.values) {
    for (final id in CivicThemeData.presets) {
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

  test('the chromatic palettes stand apart in hue', () {
    for (final b in Brightness.values) {
      final actions = [
        for (final id in CivicThemeData.presets)
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
        for (final id in CivicThemeData.presets)
          CivicThemeData.preset(id, b).action,
      };
      expect(actions, hasLength(6));
    }
  });
}

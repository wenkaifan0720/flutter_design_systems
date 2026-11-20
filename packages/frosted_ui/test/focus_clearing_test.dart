// Keyboard focus clears a part's frost (FrostedClearPatch under it, its own
// glass thinner): the words on a cleared part must read as they do at rest,
// whatever stands behind the glass.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_parts.dart';
import 'package:material_ui/material_ui.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}

// What the patch's matrix and lift make of an opaque [ground].
Color _cleared(FrostedThemeData t, Color ground, double level) {
  final (m, lift) = FrostedClearPatch.of(t, level);
  double ch(int row) =>
      (m[row * 5] * ground.r +
              m[row * 5 + 1] * ground.g +
              m[row * 5 + 2] * ground.b)
          .clamp(0.0, 1.0) +
      lift;
  return Color.from(
    alpha: 1,
    red: ch(0).clamp(0.0, 1.0),
    green: ch(1).clamp(0.0, 1.0),
    blue: ch(2).clamp(0.0, 1.0),
  );
}

const _behind = <Color>[
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFF808080),
  Color(0xFFFF0000),
  Color(0xFF00FF00),
  Color(0xFF0000FF),
  Color(0xFFFFFF00),
  Color(0xFFFF00FF),
  Color(0xFF00FFFF),
  Color(0xFF3C3060),
];

void main() {
  for (final preset in FrostedThemeData.presets) {
    for (final mode in Brightness.values) {
      test('words on a cleared part read as at rest: $preset ${mode.name}', () {
        final t = FrostedThemeData.preset(preset, mode);
        final m = t.materials;
        final words = [t.colorScheme.textPrimary, t.colorScheme.textSecondary];
        for (final under in [m.sheer, m.pane, m.slab, m.bar]) {
          for (final behind in [..._behind, t.colorScheme.background]) {
            final ground = under.groundOver(behind.withValues(alpha: 1));
            // A row on the glass, and a part raised on it, its own milk
            // thinned by half as it clears.
            for (final raised in [
              null,
              m.sheer.raised,
              m.pane.raised,
              m.well.raised,
            ]) {
              for (final level in [FrostedClearing.hover, 1.0]) {
                final rest = raised == null
                    ? ground
                    : Color.alphaBlend(raised, ground);
                final clear = _cleared(t, ground, level);
                // Milk thins; a well's shade stays.
                final thinned =
                    raised == null || raised.computeLuminance() <= .5
                    ? raised
                    : raised.withValues(alpha: raised.a * (1 - .5 * level));
                final cleared = thinned == null
                    ? clear
                    : Color.alphaBlend(thinned, clear);
                for (final ink in words) {
                  final was = _contrast(ink.withValues(alpha: 1), rest);
                  final now = _contrast(ink.withValues(alpha: 1), cleared);
                  expect(
                    now,
                    greaterThanOrEqualTo(math.min(was, 4.5) - .02),
                    reason:
                        '$preset ${mode.name}: $ink over $behind, '
                        'raised $raised, level $level: $was at rest, $now cleared',
                  );
                }
              }
            }
          }
        }
      });
    }
  }

  test('a clearing at 0 leaves what is behind as it is', () {
    final t = FrostedThemeData.preset(
      FrostedThemeData.presets.first,
      Brightness.light,
    );
    final (matrix, lift) = FrostedClearPatch.of(t, 0);
    expect(lift, 0);
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 5; col++) {
        expect(matrix[row * 5 + col], closeTo(row == col ? 1 : 0, 1e-9));
      }
    }
  });
}

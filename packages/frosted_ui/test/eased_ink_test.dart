// Frosted's inks move the way ui_core's palette walks them (RawPalette.readableTone, the nearest tone of the ink's own
// hue that reads), their colour easing toward the ink they move to, so a night ink stays soft (a pale mint, not a neon
// green), and never past it: a quiet ink never outshines the ink it eases to, in any preset or seeded theme, by day or
// by night. Unbounded, Pearl's quiet ink by night walked brighter than the page's ink.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/src/frosted/internal/eased_ink.dart';

const _white = Color(0xFFFFFFFF);
const _black = Color(0xFF000000);
const _night = Color(0xFF14141A);

void main() {
  test('an ink that reads stays as it is', () {
    const ink = Color(0xFF333333);
    expect(frostedEasedInk(ink, _black, [_white]), ink);
  });

  test('an ink that does not read takes a tone of its hue that does, '
      'short of the ink it eases to', () {
    const ink = Color(0xFF9AB8F0);
    final read = frostedEasedInk(ink, _black, [_white]);
    expect(RawPalette.contrastRatio(read, _white), greaterThanOrEqualTo(4.5));
    final (own, at, to) = (
      RawHct.fromColor(ink),
      RawHct.fromColor(read),
      RawHct.fromColor(_black),
    );
    expect(at.tone, inExclusiveRange(to.tone, own.tone));
    expect((at.hue - own.hue).abs() % 360, lessThan(10));
  });

  test('by night a saturated ink lifts soft: its colour eases toward the '
      'light it walks to', () {
    const green = Color(0xFF0E7A2E);
    final plain = RawPalette.readableTone(green, on: [_night]);
    final eased = frostedEasedInk(green, _white, [_night]);
    expect(RawPalette.contrastRatio(eased, _night), greaterThanOrEqualTo(4.5));
    expect(
      RawHct.fromColor(eased).chroma,
      lessThan(RawHct.fromColor(plain).chroma),
    );
  });

  test('where only a tone past the ink it eases to would read, it is that '
      'ink', () {
    const toward = Color(0xFF8A8A8A);
    expect(frostedEasedInk(const Color(0xFFCCCCCC), toward, [_white]), toward);
  });

  for (final brightness in Brightness.values) {
    test('the quiet inks stay quieter than the ink (${brightness.name})', () {
      final themes = [
        for (final p in [for (final p in FrostedThemeData.palettes) p.id])
          FrostedThemeData.preset(p, brightness),
        for (final accent in const [
          Color(0xFF1F3A68),
          Color(0xFF2E7D32),
          Color(0xFFC9A227),
          Color(0xFF6D28D9),
          Color(0xFFF4A7B9),
        ])
          FrostedThemeData.from(accent: accent, brightness: brightness),
      ];
      // To a level's rounding (Opal's night tertiary and secondary walk to
      // the same tone, a level apart).
      for (final t in themes) {
        final page = t.colorScheme.background.withValues(alpha: 1);
        double on(Color ink) =>
            RawPalette.contrastRatio(Color.alphaBlend(ink, page), page);
        final ink = on(t.colorScheme.textPrimary);
        final secondary = on(t.colorScheme.textSecondary);
        final tertiary = on(t.colorScheme.textTertiary);
        expect(secondary, lessThanOrEqualTo(ink + .05), reason: t.id);
        expect(tertiary, lessThanOrEqualTo(secondary + .05), reason: t.id);
        // On the pearl card, a pale object by day and by night.
        final card = t.pearl.from.withValues(alpha: 1);
        double onCard(Color ink) =>
            RawPalette.contrastRatio(Color.alphaBlend(ink, card), card);
        expect(
          onCard(t.pearl.textSecondary),
          lessThanOrEqualTo(onCard(t.pearl.text) + .05),
          reason: '${t.id} pearl',
        );
      }
    });
  }
}

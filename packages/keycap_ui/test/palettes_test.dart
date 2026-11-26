// Keycap's six colourways (KeycapThemeData.presets): classic first, each the
// classic keyboard's plastics at their own tones in other hues with an accent
// key of its own. Every word and legend reads 4.5:1 on what it sits on, the
// accent's words too, and the focus stands 3:1, by day and by night.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';

typedef _Pick = Color Function(KeycapColors c);

void main() {
  test('six colourways, classic first', () {
    expect(KeycapThemeData.presets, [
      'classic',
      'retro',
      'sage',
      'rose',
      'lilac',
      'ocean',
    ]);
  });

  for (final b in Brightness.values) {
    final classic = b == Brightness.dark
        ? KeycapColors.dark
        : KeycapColors.light;

    test('${b.name}: classic is the look by day and by night', () {
      expect(KeycapColors.preset('classic', b), classic);
      expect(KeycapThemeData.preset('classic', b).colors, classic);
    });

    test('${b.name}: each colourway its own accent key', () {
      final keys = {
        for (final name in KeycapThemeData.presets)
          KeycapColors.preset(name, b).accent.top,
      };
      expect(keys, hasLength(KeycapThemeData.presets.length));
    });

    for (final name in KeycapThemeData.presets) {
      final c = KeycapThemeData.preset(name, b).colors;

      test('${b.name}, $name: its theme wears its colours', () {
        expect(c, KeycapColors.preset(name, b));
        expect(c.brightness, b);
      });

      test('${b.name}, $name: words read 4.5:1 on the case, wells, pages and '
          'panels', () {
        for (final (words, ink) in [
          ('ink', c.ink),
          ('muted ink', c.inkMuted),
          ('accent ink', c.accentInk),
        ]) {
          for (final (ground, fill) in [
            ('case', c.ground),
            ('well', c.well),
            ('page', c.page),
            ('chosen row', c.pageSelected),
            ('panel', c.panel),
          ]) {
            expect(
              keycapContrast(ink, fill),
              greaterThanOrEqualTo(4.5),
              reason: '$words on $ground',
            );
          }
        }
      });

      test('${b.name}, $name: every legend reads 4.5:1 on its key', () {
        for (final (key, caps) in [
          ('alpha', c.alpha),
          ('modifier', c.modifier),
          ('accent', c.accent),
          ('danger', c.danger),
        ]) {
          expect(
            keycapContrast(caps.legend, caps.top),
            greaterThanOrEqualTo(4.5),
            reason: key,
          );
        }
        expect(
          keycapContrast(c.latchedLegend, c.modifier.top),
          greaterThanOrEqualTo(4.5),
          reason: 'a latched legend',
        );
        expect(keycapContrast(c.onToast, c.toast), greaterThanOrEqualTo(4.5));
      });

      test('${b.name}, $name: the focus stands 3:1 on the case, wells and '
          'panels', () {
        for (final fill in [c.ground, c.well, c.panel]) {
          expect(keycapContrast(c.focus, fill), greaterThanOrEqualTo(3));
        }
      });

      test("${b.name}, $name: its plastics at classic's tones", () {
        for (final (pair, a, z) in <(String, _Pick, _Pick)>[
          ('ink on the case', (p) => p.ink, (p) => p.ground),
          ('muted ink on a well', (p) => p.inkMuted, (p) => p.well),
          ('disabled ink on a page', (p) => p.inkDisabled, (p) => p.page),
          ('a well in the case', (p) => p.well, (p) => p.ground),
          ('a page in the case', (p) => p.page, (p) => p.ground),
          ('an alpha on the case', (p) => p.alpha.top, (p) => p.ground),
          ('an alpha\'s front', (p) => p.alpha.front, (p) => p.alpha.top),
          ('a modifier on the case', (p) => p.modifier.top, (p) => p.ground),
          (
            'a modifier\'s legend',
            (p) => p.modifier.legend,
            (p) => p.modifier.top,
          ),
        ]) {
          final own = keycapContrast(a(classic), z(classic));
          expect(
            keycapContrast(a(c), z(c)),
            closeTo(own, own * 0.02),
            reason: pair,
          );
        }
      });
    }
  }
}

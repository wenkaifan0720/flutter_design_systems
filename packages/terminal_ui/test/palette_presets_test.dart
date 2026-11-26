// Terminal's six palettes and its colour API on ui_core's palette maths: the
// words, the accent and the words on it read on every ground they are drawn
// on, by day and by night, and a brand colour that reads short is stepped in
// its own hue rather than refused; a page drawn in each palette builds.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

double _worst(Color c, Iterable<Color> on) =>
    on.map((g) => RawPalette.contrastRatio(c, g)).reduce(math.min);

void _reads(TermThemeData t, String name) {
  final grounds = [t.background, t.surface];
  for (final (role, c) in [
    ('foreground', t.foreground),
    ('dim', t.dim),
    ('accent', t.accent),
    ('success', t.success),
    ('danger', t.danger),
    ('warning', t.warning),
    ('info', t.info),
  ]) {
    expect(
      _worst(c, grounds),
      greaterThanOrEqualTo(4.5),
      reason: '$name: $role on the background and the surface',
    );
  }
  expect(
    RawPalette.contrastRatio(t.onAccent, t.accent),
    greaterThanOrEqualTo(4.5),
    reason: '$name: the words on the accent',
  );
  expect(
    RawPalette.contrastRatio(t.rule, t.background),
    greaterThanOrEqualTo(3),
    reason: '$name: a frame on the background',
  );
}

double _hueGap(Color a, Color b) {
  final d = (RawHct.fromColor(a).hue - RawHct.fromColor(b).hue).abs() % 360;
  return math.min(d, 360 - d);
}

void main() {
  test('six palettes, the first Terminal\'s own', () {
    expect(TermThemeData.palettes, hasLength(6));
    expect({for (final p in TermThemeData.palettes) p.id}, hasLength(6));
    expect(TermThemeData.palettes.first.id, 'standard');
    for (final b in Brightness.values) {
      final own = b == Brightness.dark
          ? TermThemeData.dark()
          : TermThemeData.light();
      final standard = TermThemeData.preset('standard', b);
      expect(standard.background, own.background);
      expect(standard.foreground, own.foreground);
      expect(standard.accent, own.accent);
      final mono = TermThemeData.preset('mono', b);
      final monochrome = TermThemeData.monochrome(brightness: b);
      expect(mono.accent, monochrome.accent);
      expect(mono.danger, monochrome.danger);
    }
  });

  for (final id in TermThemeData.palettes.map((p) => p.id)) {
    for (final b in Brightness.values) {
      test('$id by ${b == Brightness.dark ? 'night' : 'day'} reads', () {
        final t = TermThemeData.preset(id, b);
        expect(t.brightness, b);
        _reads(t, '$id ${b.name}');
        if (const {'mono', 'phosphor', 'amber'}.contains(id)) {
          // One ink: a state reads by its shape alone.
          for (final c in [t.accent, t.success, t.danger, t.warning, t.info]) {
            expect(c, t.foreground);
          }
        }
      });
    }
  }

  test('the six look apart, by day and by night', () {
    for (final b in Brightness.values) {
      final seen = {
        for (final id in TermThemeData.palettes.map((p) => p.id))
          (
            TermThemeData.preset(id, b).background,
            TermThemeData.preset(id, b).accent,
          ),
      };
      expect(seen, hasLength(6));
    }
  });

  test('a name that is not a palette says which are', () {
    expect(
      () => TermThemeData.preset('solarized', Brightness.dark),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('standard'),
        ),
      ),
    );
  });

  test('a brand colour that reads short is stepped in its own hue', () {
    for (final (palette, b, brand) in [
      (TermPalette.night, Brightness.dark, const Color(0xFF0A7D4F)),
      (TermPalette.paper, Brightness.light, const Color(0xFF7DD3FC)),
    ]) {
      final t = TermThemeData.from(palette, brightness: b, accent: brand);
      expect(
        _worst(t.accent, [t.background, t.surface]),
        greaterThanOrEqualTo(4.5),
      );
      expect(_hueGap(t.accent, brand), lessThan(12));
      expect(
        RawPalette.contrastRatio(t.onAccent, t.accent),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('a colour that already reads is kept as given', () {
    const brand = Color(0xFF6CCFD8);
    expect(TermThemeData.from(TermPalette.night, accent: brand).accent, brand);
  });

  test("another palette's frames and accent read on its own surface", () {
    final palette = TermPalette.night.copyWith(
      background: const Color(0xFF20242A),
      cyan: const Color(0xFF2B8A94),
    );
    _reads(
      TermThemeData.from(palette).copyWith(
        // Only the accent and the frame are the theme's to step here.
        dim: const Color(0xFFFFFFFF),
        success: const Color(0xFFFFFFFF),
        danger: const Color(0xFFFFFFFF),
        warning: const Color(0xFFFFFFFF),
        info: const Color(0xFFFFFFFF),
      ),
      'a dark palette of its own',
    );
  });

  testWidgets('a page builds in each palette, by day and by night', (
    tester,
  ) async {
    for (final id in TermThemeData.palettes.map((p) => p.id)) {
      for (final b in Brightness.values) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: TermTheme(
              data: TermThemeData.preset(id, b),
              child: TermButton(label: 'deploy', onPressed: () {}),
            ),
          ),
        );
        expect(find.text('deploy'), findsOneWidget, reason: '$id ${b.name}');
      }
    }
  });
}

// The presets: one list, each a value, and each appearance reads. The bars are WCAG's, by Flutter's own luminance: words
// 4.5:1 on every ground they stand on; edges of controls and marks with no words 3:1. No preset is exempt, the concept's
// own included, and a pair under its bar moves a token rather than the bar.
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

const _words = 4.5, _edge = 3.0;

// A hue that is on purpose the same in every preset. The look has none.
const _oneLight = <String>{};

double _contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

void _reads(
  String what,
  Map<String, Color> colours,
  Map<String, Color> grounds,
  double bar,
) {
  for (final colour in colours.entries) {
    for (final ground in grounds.entries) {
      expect(
        _contrast(colour.value, ground.value),
        greaterThanOrEqualTo(bar),
        reason: '$what: ${colour.key} on ${ground.key}',
      );
    }
  }
}

void main() {
  test('five presets, the default first', () {
    expect(RetroDesktopThemeData.presets, [
      'classic',
      'lagoon',
      'berry',
      'marmalade',
      'slate',
    ]);
  });

  test('named preset factories match the preset registry in both modes', () {
    final factories = {
      'classic': RetroDesktopThemeData.classic,
      'lagoon': RetroDesktopThemeData.lagoon,
      'berry': RetroDesktopThemeData.berry,
      'marmalade': RetroDesktopThemeData.marmalade,
      'slate': RetroDesktopThemeData.slate,
    };
    for (final entry in factories.entries) {
      for (final brightness in Brightness.values) {
        expect(
          identical(
            entry.value(brightness),
            RetroDesktopThemeData.preset(entry.key, brightness),
          ),
          isTrue,
        );
      }
    }
  });

  test('an unknown preset is an error, not a silent default', () {
    expect(
      () => RetroDesktopThemeData.preset('nope', Brightness.light),
      throwsArgumentError,
    );
  });

  test('the luminance here is the true one', () {
    // WCAG's own corners, and a mid grey that a squared curve reads wrongly.
    expect(_contrast(Colors.black, Colors.white), closeTo(21, .01));
    expect(
      _contrast(const Color(0xFF767676), Colors.white),
      closeTo(4.54, .01),
    );
  });

  for (final id in RetroDesktopThemeData.presets) {
    for (final b in Brightness.values) {
      final name = '$id ${b.name}';
      final t = RetroDesktopThemeData.preset(id, b);
      final c = t.colors;
      // Every ground a word stands on: the window's greys, the wells and the tinted cells.
      final page = {
        'plat': c.platinum,
        'plat2': c.platinumLight,
        'plat3': c.platinumDark,
        'paper': c.paper,
        'paper2': c.paperDim,
      };

      test('$name builds its own appearance, the same value each time', () {
        expect(t.id, id);
        expect(t.dark, b == Brightness.dark);
        expect(identical(t, RetroDesktopThemeData.preset(id, b)), isTrue);
      });

      test('$name words read on every ground of the page', () {
        // ink3 is words: meta, hints, a chart's labels.
        _reads(
          'words',
          {'ink': c.text, 'ink2': c.textSecondary, 'ink3': c.textTertiary},
          page,
          _words,
        );
      });

      test('$name letters read on what they are made for', () {
        for (final (what, letters, ground) in [
          ('hlInk on hl', c.onHighlight, c.highlight),
          ('hlInk on the act face, top', c.onHighlight, c.highlightFaceTop),
          (
            'hlInk on the act face, middle',
            c.onHighlight,
            c.highlightFaceMiddle,
          ),
          ('hlInk on the act face, foot', c.onHighlight, c.highlightFaceBottom),
          ('paper on ink: the flag and the monogram', c.paper, c.text),
          ('ink on the tint', c.text, c.highlightContainer),
          ('a desk mark\'s name on its plate', c.text, c.markLabel),
        ]) {
          expect(
            _contrast(letters, ground),
            greaterThanOrEqualTo(_words),
            reason: what,
          );
        }
      });

      test('$name edges and marks read on the page', () {
        _reads('edges', {'ctl': c.control}, page, _edge);
        // By night a window's frame is ctl: its edge is the shadow around it.
        if (!c.dark) {
          expect(
            _contrast(c.outline, c.platinum),
            greaterThanOrEqualTo(_edge),
            reason: 'edge on plat',
          );
        }
        expect(
          _contrast(c.highlight, c.paper),
          greaterThanOrEqualTo(_edge),
          reason: 'hl on paper',
        );
        expect(
          _contrast(c.hatch, c.paper),
          greaterThanOrEqualTo(_edge),
          reason: 'hatch on paper',
        );
      });
    }
  }

  test(
    'the presets are designed apart: no two share a desk and a highlight',
    () {
      final seen = <String>{};
      for (final id in RetroDesktopThemeData.presets) {
        final c = RetroDesktopThemeData.preset(id, Brightness.light).colors;
        expect(
          seen.add('${c.desktop.toARGB32()}-${c.highlight.toARGB32()}'),
          isTrue,
          reason: id,
        );
      }
    },
  );

  test(
    'a colour with a hue lives in the theme, or a preset wears another\'s',
    () {
      final literal = RegExp(
        r'Color\(0x[0-9A-Fa-f]{2}([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})\)',
      );
      final found = <String>[];
      for (final dir in ['lib/src/retro_desktop', 'test/pages']) {
        for (final f in Directory(
          dir,
        ).listSync(recursive: true).whereType<File>()) {
          if (!f.path.endsWith('.dart') || f.path.endsWith('/theme.dart')) {
            continue;
          }
          for (final m in literal.allMatches(f.readAsStringSync())) {
            final rgb = '${m[1]}${m[2]}${m[3]}'.toUpperCase();
            if (m[1] != m[2] || m[2] != m[3]) {
              if (!_oneLight.contains(rgb)) found.add('${f.path}: ${m[0]}');
            }
          }
        }
      }
      expect(found, isEmpty);
    },
  );
}

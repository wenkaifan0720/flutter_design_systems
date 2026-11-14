// The presets: one list, each a value, and each appearance reads. The bars are WCAG's, by Flutter's own luminance: words
// 4.5:1 on every ground they stand on; edges of controls and marks with no words 3:1. No preset is exempt, the concept's
// own included, and a pair under its bar moves a token rather than the bar.
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/src/neumorphism/theme.dart';

const _words = 4.5, _edge = 3.0;

// A hue that is on purpose the same in every preset, and why. This look has none.
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
    expect(NeumorphicThemeData.presets, [
      'porcelain',
      'pompeii',
      'verona',
      'siena',
      'tyrian',
    ]);
  });

  test('an unknown preset is an error, not a silent default', () {
    expect(
      () => NeumorphicThemeData.preset('nope', Brightness.light),
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

  for (final id in NeumorphicThemeData.presets) {
    for (final b in Brightness.values) {
      final name = '$id ${b.name}';
      final t = NeumorphicThemeData.preset(id, b);
      final c = t.colors;
      // Every ground a word stands on: the wall, a raised face, a pressed well, each at both ends of its gradient.
      final page = {
        'ground': c.ground,
        'faceStart': c.faceStart,
        'faceEnd': c.faceEnd,
        'wellStart': c.wellStart,
        'wellEnd': c.wellEnd,
      };
      final washed = {
        'wash on faceStart': Color.alphaBlend(c.wash, c.faceStart),
        'wash on faceEnd': Color.alphaBlend(c.wash, c.faceEnd),
        'wash on wellEnd': Color.alphaBlend(c.wash, c.wellEnd),
      };

      test('$name builds its own appearance, the same value each time', () {
        expect(t.id, id);
        expect(t.dark, b == Brightness.dark);
        expect(identical(t, NeumorphicThemeData.preset(id, b)), isTrue);
      });

      test('$name words read on every ground of the page', () {
        _reads(
          'words',
          {
            'ink': c.ink,
            'inkSecondary': c.inkSecondary,
            'inkTertiary': c.inkTertiary,
            'pigmentInk': c.pigmentInk,
          },
          page,
          _words,
        );
      });

      test('$name letters read on what they are made for', () {
        _reads(
          'on a wash',
          {
            'ink': c.ink,
            'inkSecondary': c.inkSecondary,
            'pigmentInkLit': c.pigmentInkLit,
          },
          washed,
          _words,
        );
        for (final (what, letters, ground) in [
          ('onPigment on pigment', c.onPigment, c.pigment),
          ('onPigment on pigmentDk', c.onPigment, c.pigmentDk),
        ]) {
          expect(
            _contrast(letters, ground),
            greaterThanOrEqualTo(_words),
            reason: what,
          );
        }
      });

      test('$name edges and marks read on the page', () {
        // quiet is every printed edge a control keeps when its shadows wash out. The pigment is every state and mark that means live.
        _reads(
          'edge',
          {
            'quiet': c.quiet,
            'edge': c.edge,
            'pigment': c.pigment,
            'inkTertiary': c.inkTertiary,
            'barStart': c.barStart,
            'barEnd': c.barEnd,
          },
          page,
          _edge,
        );
      });

      test(
        "$name a resting control's edge has room: 4:1 on every face and well",
        () {
          _reads('resting edge', {'edge': c.edge}, page, 4.0);
        },
      );

      test(
        '$name is a designed mode, the pigment and the plaster together',
        () {
          final other = NeumorphicThemeData.preset(
            id,
            b == Brightness.dark ? Brightness.light : Brightness.dark,
          ).colors;
          expect(c.pigment, isNot(other.pigment));
          expect(c.ground, isNot(other.ground));
          // Mud: a well inside a dark slab is darker than the wall, and a catch-light carries the edge.
          expect(
            c.wellEnd.computeLuminance(),
            lessThan(c.faceStart.computeLuminance()),
          );
        },
      );
    }
  }

  test(
    'the presets are designed apart: plaster and pigment change together',
    () {
      final grounds = <int>{}, pigments = <int>{};
      for (final id in NeumorphicThemeData.presets) {
        for (final b in Brightness.values) {
          final c = NeumorphicThemeData.preset(id, b).colors;
          expect(
            grounds.add(c.ground.toARGB32()),
            isTrue,
            reason: '$id ${b.name}',
          );
          expect(
            pigments.add(c.pigment.toARGB32()),
            isTrue,
            reason: '$id ${b.name}',
          );
        }
      }
      final seen = <String>{};
      for (final id in NeumorphicThemeData.presets) {
        final c = NeumorphicThemeData.preset(id, Brightness.light).colors;
        expect(
          seen.add('${c.ground.toARGB32()}-${c.pigment.toARGB32()}'),
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
      for (final dir in ['lib/src/neumorphism', 'test/pages']) {
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

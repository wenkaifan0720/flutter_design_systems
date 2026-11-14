// The presets: one list, each a value, and each appearance reads. The bars are WCAG's, by Flutter's own luminance: words
// 4.5:1 on every ground they stand on; edges of controls and marks with no words 3:1. No preset is exempt, the concept's
// own included, and a pair under its bar moves a token rather than the bar.
import 'dart:io';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

const _words = 4.5, _edge = 3.0;

// A hue that is on purpose the same in every preset. Comic has none.
const _oneLight = <String>{};

double _contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

// How far apart two inks stand, as CIE76 in CIELAB (D65). Two inks of one chart stand at least this far apart, so a reader
// matches a key's swatch to its slice.
const _apart = 20.0;

double _distance(Color a, Color b) {
  List<double> lab(Color c) {
    double lin(double v) =>
        v <= .04045 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
    final r = lin(c.r), g = lin(c.g), b = lin(c.b);
    double f(double t) =>
        t > .008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
    final x = f((r * .4124 + g * .3576 + b * .1805) / .95047);
    final y = f(r * .2126 + g * .7152 + b * .0722);
    final z = f((r * .0193 + g * .1192 + b * .9505) / 1.08883);
    return [116 * y - 16, 500 * (x - y), 200 * (y - z)];
  }

  final p = lab(a), q = lab(b);
  return math.sqrt(
    math.pow(p[0] - q[0], 2) +
        math.pow(p[1] - q[1], 2) +
        math.pow(p[2] - q[2], 2),
  );
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

final _custom = <String, ComicThemeData Function(Brightness)>{
  'custom-plum': (b) => ComicThemeData.from(
    primary: const Color(0xff802651),
    caption: const Color(0xffeed36a),
    shade: const Color(0xff276c99),
    brightness: b,
  ),
  'custom-pale': (b) => ComicThemeData.from(
    primary: const Color(0xffeeeeee),
    caption: Colors.white,
    shade: const Color(0xffdddddd),
    background: Colors.white,
    brightness: b,
  ),
  'custom-dark': (b) => ComicThemeData.from(
    primary: const Color(0xff170e29),
    caption: const Color(0xff271933),
    shade: const Color(0xff121212),
    background: Colors.black,
    brightness: b,
  ),
  'custom-grey': (b) => ComicThemeData.from(
    primary: const Color(0xff777777),
    caption: const Color(0xff777777),
    shade: const Color(0xff777777),
    background: const Color(0xff777777),
    brightness: b,
  ),
};

void main() {
  test('five presets, the default first', () {
    expect(ComicThemeData.presets, [
      'offset',
      'reprint',
      'newsstand',
      'pulp',
      'sunday',
    ]);
  });

  test('an unknown preset is an error, not a silent default', () {
    expect(
      () => ComicTheme.preset('nope', Brightness.light),
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

  for (final id in [...ComicThemeData.presets, ..._custom.keys]) {
    for (final b in Brightness.values) {
      final name = '$id ${b.name}';
      final t = _custom[id]?.call(b) ?? ComicTheme.preset(id, b);
      final c = t.colors;
      // Every ground a word stands on: the newsprint, a panel, a well. Dots are measured below, as dots.
      final page = {'ground': c.background, 'card': c.card, 'well': c.inset};

      test('$name builds its own appearance, the same value each time', () {
        expect(t.id, _custom.containsKey(id) ? 'custom' : id);
        expect(t.brightness, b);
        if (_custom.containsKey(id)) {
          expect(t, _custom[id]!(b));
        } else {
          expect(identical(t, ComicTheme.preset(id, b)), isTrue);
        }
      });

      test('$name words read on every ground of the page', () {
        _reads(
          'words',
          {
            'ink': c.text,
            'textSecondary': c.textSecondary,
            'primaryText': c.primaryText,
            'shadeText': c.shadeText,
          },
          page,
          _words,
        );
      });

      test('$name letters read on what they are made for', () {
        for (final (what, letters, ground) in [
          ('onCaption on caption', c.onCaption, c.caption),
          ('onPrimary on act', c.onPrimary, c.primary),
          ('onShade on shade', c.onShade, c.shade),
          ('onPaper on paper', c.onPaper, c.paper),
          ('onPaperSecondary on paper', c.onPaperSecondary, c.paper),
          ('onPaper on control', c.onPaper, c.control),
          ('hint on control', c.hint, c.control),
          ('onCaption on the first head', c.onCaption, c.monogramSecondary),
          ('onCaption on the second head', c.onCaption, c.monogramTertiary),
          ('a step\'s number on an unlit block', c.onPaper, c.unlit),
        ]) {
          expect(
            _contrast(letters, ground),
            greaterThanOrEqualTo(_words),
            reason: what,
          );
        }
      });

      test('$name words on dots read against the dots themselves', () {
        // A dotted panel is the panel's fill under a screen of dots. A word lands on both, so it reads on both: the fill and
        // the dot's own ink, measured apart, not an average of them. Its words all go to full ink under ComicDotsScope.
        final dotted = t.dotted.colors;
        for (final (what, dot) in [
          ('the group\'s dots', c.dotTint),
          ('your dots', c.currentUserDot),
        ]) {
          for (final (who, ink) in [
            ('ink', dotted.text),
            ('textSecondary', dotted.textSecondary),
            ('primaryText', dotted.primaryText),
            ('shadeText', dotted.shadeText),
          ]) {
            expect(
              _contrast(ink, dot),
              greaterThanOrEqualTo(_words),
              reason: '$who on $what',
            );
          }
        }
        expect(_contrast(dotted.text, c.card), greaterThanOrEqualTo(_words));
        // Big lettering keeps its colour on dots, so its bar is the large one, on both the fill and the dot.
        expect(
          _contrast(c.primaryLargeText, c.currentUserDot),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contrast(c.primaryLargeText, c.currentUserTint),
          greaterThanOrEqualTo(3),
        );
        expect(
          _contrast(dotted.primaryLargeText, c.currentUserDot),
          greaterThanOrEqualTo(3),
        );
      });

      test('$name a bar says its amount', () {
        // A fill is told from the empty track by its end line or by itself: by day the line is the ink, at night it's lost in the
        // dark and the fill has to do it. On their own fill the dots are print, not a mark, but they stay dots: under about 1.8
        // they go to mud.
        for (final (what, fill) in [
          ('dots', c.shade),
          ('lead', c.caption),
          ('you', c.primary),
        ]) {
          final seen = [
            _contrast(fill, c.track),
            _contrast(c.outline, c.track),
          ].reduce((a, b) => a > b ? a : b);
          expect(
            seen,
            greaterThanOrEqualTo(_edge),
            reason: '$what on the track',
          );
        }
        expect(
          _contrast(c.shade, c.shadeTint),
          greaterThanOrEqualTo(1.8),
          reason: 'dots on the tint',
        );
        expect(
          _contrast(c.lampDot, c.caption),
          greaterThanOrEqualTo(1.8),
          reason: 'drama dots on the lamp',
        );
      });

      test('$name every ink of a chart reads on the page and apart', () {
        // Each mark by the ink that draws it: a flat fill by its fill; a dotted one by its dots, the tint under them being their
        // paper (the bar law above). It stands on the newsprint, a panel or a bar's track. By day a pale fill is carried by its
        // contour, which reads on the ground and against the fill; at night the contour is black, lost in the dark, and the fill
        // carries itself.
        final charts = <String, List<Color>>{
          'pie and its key': c.series,
          'flow': [c.shade, c.primary],
          'shares': [c.caption, c.shade, c.drama],
          'bars': [c.shade, c.caption, c.primary],
          'units': [c.shade, c.caption],
          'cells': [c.caption, c.shade, c.unlit],
          'steps': [c.caption, c.unlit],
        };
        final grounds = {
          'ground': c.background,
          'card': c.card,
          'track': c.track,
        };
        for (final chart in charts.entries) {
          final inks = chart.value;
          for (var i = 0; i < inks.length; i++) {
            for (final g in grounds.entries) {
              final own = _contrast(inks[i], g.value);
              final contour = math.min(
                _contrast(c.outline, g.value),
                _contrast(c.outline, inks[i]),
              );
              expect(
                math.max(own, contour),
                greaterThanOrEqualTo(_edge),
                reason: '${chart.key}, ink ${i + 1} on ${g.key}',
              );
            }
            for (var j = i + 1; j < inks.length; j++) {
              expect(
                _distance(inks[i], inks[j]),
                greaterThanOrEqualTo(_apart),
                reason: '${chart.key}, inks ${i + 1} and ${j + 1}',
              );
            }
          }
        }
        expect(c.series, hasLength(6));
      });

      test('$name edges and marks read on the page', () {
        // By day the contour is the line; at night the contour is the paper thing's own fill against the dark.
        if (t.brightness == Brightness.dark) {
          _reads('edge', {'control': c.control}, page, _edge);
        } else {
          _reads('edge', {'line': c.outline}, page, _edge);
        }
        _reads('marks', {'drama': c.drama}, {'card': c.card}, _edge);
      });
    }
  }

  test(
    'the presets are designed apart: no two share a light ground and a card',
    () {
      final seen = <String>{};
      for (final id in ComicThemeData.presets) {
        final c = ComicTheme.preset(id, Brightness.light).colors;
        expect(
          seen.add('${c.background.toARGB32()}-${c.primary.toARGB32()}'),
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
      for (final dir in ['lib/src/', 'test/pages']) {
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

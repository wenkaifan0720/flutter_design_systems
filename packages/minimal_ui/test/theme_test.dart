import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// CIE76 colour difference: the distance between two colours in CIELAB.
double _deltaE(Color a, Color b) {
  List<double> lab(Color c) {
    double lin(double v) =>
        v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) * 1.0;
    final r = lin(c.r), g = lin(c.g), bl = lin(c.b);
    final x = (r * 0.4124 + g * 0.3576 + bl * 0.1805) / 0.95047;
    final y = r * 0.2126 + g * 0.7152 + bl * 0.0722;
    final z = (r * 0.0193 + g * 0.1192 + bl * 0.9505) / 1.08883;
    double f(double v) =>
        v > 0.008856 ? math.pow(v, 1 / 3) * 1.0 : 7.787 * v + 16 / 116;
    return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
  }

  final p = lab(a), q = lab(b);
  return math.sqrt(
    math.pow(p[0] - q[0], 2) +
        math.pow(p[1] - q[1], 2) +
        math.pow(p[2] - q[2], 2),
  );
}

/// Themes from an app's own colours the bars must hold for as well, by
/// name: an accent and a neutral each, a hostile few among them (a pale
/// yellow no label reads on, a red beside the danger, an orange beside the
/// warning, one grey for everything).
const Map<String, (Color, Color?)> _fromColors = {
  'from plum': (Color(0xFF7A1F5C), Color(0xFF8B7355)),
  'from teal': (Color(0xFF0E9F9A), Color(0xFF5B7C99)),
  'from pale yellow': (Color(0xFFFFE066), null),
  'from red': (Color(0xFFE5484D), null),
  'from orange': (Color(0xFFFF8A00), Color(0xFFB08D57)),
  'from grey': (Color(0xFF808080), Color(0xFF808080)),
};

/// Every theme the bars are held for: the presets, then [_fromColors].
final List<String> _ids = [...MinimalThemeData.presets, ..._fromColors.keys];

MinimalThemeData _theme(String id, Brightness brightness) {
  final from = _fromColors[id];
  if (from == null) return MinimalThemeData.preset(id, brightness);
  final (accent, neutral) = from;
  return MinimalThemeData.from(
    primary: accent,
    neutral: neutral,
    brightness: brightness,
  );
}

void main() {
  group('MinimalThemeData.preset', () {
    test('builds every preset in both appearances', () {
      for (final id in _ids) {
        for (final brightness in Brightness.values) {
          final t = _theme(id, brightness);
          expect(
            t.isLightAppearance,
            brightness == Brightness.light,
            reason: '$id ${brightness.name} reads as the wrong appearance',
          );
          expect(t.giant.fontFamily, minimalFontFamily('GeistMono'));
          expect(t.figure.fontFamily, minimalFontFamily('GeistMono'));
          expect(t.figure.fontFeatures, t.mono.fontFeatures);
          expect(t.body.fontFamily, minimalFontFamily('Geist'));
          expect(t.rowHeight, 44);
          expect(t.hairline, 1);
          expect(t.iconStroke, 1.75);
        }
      }
    });

    test('every on-colour clears AA on its fill, in every preset', () {
      for (final id in _ids) {
        for (final brightness in Brightness.values) {
          final t = _theme(id, brightness);
          final pairs = <String, (Color, Color)>{
            'onAccent': (t.primaryForeground, t.primary),
            'onSuccess': (t.onSuccess, t.success),
            'onDanger': (t.destructiveForeground, t.destructive),
            'textPrimary': (t.foreground, t.background),
            'textSecondary': (t.mutedForeground, t.background),
          };
          for (final MapEntry(key: role, value: (ink, fill)) in pairs.entries) {
            expect(
              _contrast(ink, fill),
              greaterThanOrEqualTo(4.5),
              reason: '$id ${brightness.name}: $role fails AA',
            );
          }
        }
      }
    });

    test('every tone ink clears AA as text on the ground and on its subtle '
        'fill, in every preset', () {
      for (final id in _ids) {
        for (final brightness in Brightness.values) {
          final t = _theme(id, brightness);
          for (final tone in MinimalTone.values) {
            final colors = t.tone(tone);
            for (final (ground, name) in [
              (t.background, 'background'),
              (t.card, 'surface'),
              (colors.background, 'subtle'),
            ]) {
              expect(
                _contrast(colors.foreground, ground),
                greaterThanOrEqualTo(4.5),
                reason: '$id ${brightness.name}: ${tone.name} ink on $name',
              );
            }
          }
          // The accent's ink is what a link or a selection check prints;
          // info is the app-level word role, so it is held to the same bar.
          expect(
            _contrast(t.primaryInk, t.background),
            greaterThanOrEqualTo(4.5),
            reason: '$id ${brightness.name}: accentInk on the ground',
          );
          for (final (ground, name) in [
            (t.background, 'background'),
            (t.card, 'surface'),
          ]) {
            expect(
              _contrast(t.info, ground),
              greaterThanOrEqualTo(4.5),
              reason: '$id ${brightness.name}: info on $name',
            );
          }
          expect(
            _contrast(t.primaryInk, t.primarySubtle),
            greaterThanOrEqualTo(4.5),
            reason: '$id ${brightness.name}: accentInk on accentSubtle',
          );
        }
      }
    });

    test('a status fill stands 3:1 off the ground as a mark', () {
      for (final id in _ids) {
        for (final brightness in Brightness.values) {
          final t = _theme(id, brightness);
          for (final (fill, name) in [
            (t.success, 'success'),
            (t.warning, 'warning'),
            (t.destructive, 'danger'),
            (t.primary, 'accent'),
            (
              MinimalStatusIcon.colorOf(t, MinimalTaskStatus.active),
              'in progress',
            ),
          ]) {
            expect(
              _contrast(fill, t.background),
              greaterThanOrEqualTo(3),
              reason: '$id ${brightness.name}: $name mark on the ground',
            );
          }
        }
      }
    });

    test('an idle control edge stands 3:1 off every ground, and the off '
        "switch's thumb 3:1 off its track", () {
      for (final id in _ids) {
        for (final brightness in Brightness.values) {
          final t = _theme(id, brightness);
          for (final (ground, name) in [
            (t.background, 'background'),
            (t.card, 'surface'),
            (t.muted, 'surfaceAlt'),
          ]) {
            expect(
              _contrast(t.input, ground),
              greaterThanOrEqualTo(3),
              reason: '$id ${brightness.name}: controlBorder on $name',
            );
          }
          final thumb = t.isLightAppearance ? t.card : t.background;
          expect(
            _contrast(thumb, t.input),
            greaterThanOrEqualTo(3),
            reason: '$id ${brightness.name}: off thumb on its track',
          );
        }
      }
    });

    test('the accent and danger never read as one colour', () {
      for (final id in _ids) {
        for (final brightness in Brightness.values) {
          final t = _theme(id, brightness);
          expect(
            _deltaE(t.primary, t.destructive),
            greaterThanOrEqualTo(40),
            reason: '$id ${brightness.name}: accent and danger too close',
          );
        }
      }
    });

    test('the accent and warning never read as one colour', () {
      for (final id in _ids) {
        for (final brightness in Brightness.values) {
          final t = _theme(id, brightness);
          expect(
            _deltaE(t.primary, t.warning),
            greaterThanOrEqualTo(40),
            reason: '$id ${brightness.name}: accent and warning too close',
          );
        }
      }
    });

    test('an unknown preset throws', () {
      expect(
        () => MinimalThemeData.preset('neon', Brightness.light),
        throwsArgumentError,
      );
    });

    test('asking twice returns the same theme', () {
      expect(
        identical(
          MinimalThemeData.preset('ember', Brightness.dark),
          MinimalThemeData.preset('ember', Brightness.dark),
        ),
        isTrue,
      );
    });

    test('carries the specified roles', () {
      final light = MinimalThemeData.preset('standard', Brightness.light);
      final dark = MinimalThemeData.preset('standard', Brightness.dark);
      expect(light.primary, const Color(0xFF3E63DD));
      expect(light.border, const Color(0xFFE8E8EB));
      expect(dark.background, const Color(0xFF0E0E11));
      expect(dark.primary, const Color(0xFF7C9BFF));
      expect(dark.primaryForeground, const Color(0xFF0E0E11));
      // Graphite spends the ink as its accent; ember runs warm.
      expect(
        MinimalThemeData.preset('graphite', Brightness.light).primary,
        const Color(0xFF17171A),
      );
      expect(
        MinimalThemeData.preset('ember', Brightness.dark).primary,
        const Color(0xFFFF8A5C),
      );
      expect(light.info, light.primaryInk);
      expect(light.ring, light.primary);
    });
  });

  group('MinimalHost', () {
    Widget host({Brightness? brightness, required WidgetBuilder builder}) =>
        MaterialApp(
          home: MinimalHost(
            light: MinimalThemeData.preset('standard', Brightness.light),
            dark: MinimalThemeData.preset('standard', Brightness.dark),
            brightness: brightness,
            child: Builder(builder: builder),
          ),
        );

    testWidgets('publishes the pinned appearance through the accessor', (
      tester,
    ) async {
      late MinimalThemeData seen;
      await tester.pumpWidget(
        host(
          brightness: Brightness.dark,
          builder: (context) {
            seen = context.minimalTheme;
            return const SizedBox();
          },
        ),
      );
      expect(
        identical(seen, MinimalThemeData.preset('standard', Brightness.dark)),
        isTrue,
      );
      expect(MinimalTheme.of(tester.element(find.byType(SizedBox))), seen);
    });

    testWidgets('follows the platform when nothing is pinned', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      late MinimalThemeData seen;
      await tester.pumpWidget(
        host(
          builder: (context) {
            seen = context.minimalTheme;
            return const SizedBox();
          },
        ),
      );
      expect(seen.isLightAppearance, isFalse);
    });

    testWidgets('clamps text scaling to what a row was drawn to hold', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      late double scaled;
      await tester.pumpWidget(
        host(
          builder: (context) {
            scaled = MediaQuery.textScalerOf(context).scale(10);
            return const SizedBox();
          },
        ),
      );
      expect(scaled, closeTo(10 * MinimalChromeMetrics.maxTextScale, 0.001));
    });
  });

  group('MinimalFormat', () {
    final at = DateTime(2026, 8, 28, 7, 12);

    test('prints the mono stamps', () {
      expect(MinimalFormat.clock(DateTime(2026, 8, 28, 21, 30)), '21:30');
      expect(MinimalFormat.isoDate(DateTime(2026, 6, 2)), '2026-06-02');
      expect(MinimalFormat.stamp(DateTime(2026, 8, 3, 7, 5)), '03 Aug 07:05');
    });

    test('keeps the shared shapes', () {
      expect(MinimalFormat.money(128400, symbol: '€', cents: false), '€1,284');
      expect(MinimalFormat.money(-1250), r'-$12.50');
      expect(MinimalFormat.date(at), '28 Aug 2026');
      expect(MinimalFormat.weekday(at), 'Fri');
      expect(MinimalFormat.time(at), '07:12');
      expect(MinimalFormat.time12(at), '7:12 AM');
      expect(MinimalFormat.time12(DateTime(2026, 8, 28, 21, 30)), '9:30 PM');
      expect(
        MinimalFormat.relative(DateTime(2026, 8, 27), now: at),
        'Yesterday',
      );
    });

    test('relative counts calendar days, whatever the clock change', () {
      // The spring-forward night in Europe and the US: whatever zone the
      // test runs in, the next calendar day is tomorrow.
      for (final now in [DateTime(2026, 3, 28, 22), DateTime(2026, 3, 7, 22)]) {
        final next = DateTime(now.year, now.month, now.day + 1, 9);
        final after = DateTime(now.year, now.month, now.day + 2, 9);
        expect(MinimalFormat.relative(next, now: now), 'Tomorrow');
        expect(MinimalFormat.relative(after, now: now), 'In 2 days');
        expect(MinimalFormat.relative(now, now: next), 'Yesterday');
      }
    });
  });

  // A glyph on one of lucide's cuts, by its fields: lucide 3 names the cuts
  // (bell300), lucide 4 keeps the faces but not the names. Made at run time
  // only here, to compare against.
  IconData cut(IconData glyph, int weight) => IconData(
    // ignore: non_const_argument_for_const_parameter
    glyph.codePoint,
    // ignore: non_const_argument_for_const_parameter
    fontFamily: 'Lucide$weight',
    fontPackage: 'lucide_icons_flutter',
    matchTextDirection: glyph.matchTextDirection,
  );

  test('MinimalIcon re-cuts Lucide glyphs to the theme stroke only', () {
    expect(
      MinimalIcon.stroked(LucideIcons.bell, 1.75),
      cut(LucideIcons.bell, 300),
    );
    expect(MinimalIcon.stroked(Icons.add, 1.75), Icons.add);
    // A stroke nearer the face's own keeps the glyph as given.
    expect(MinimalIcon.stroked(LucideIcons.bell, 2.5), same(LucideIcons.bell));
  });

  // A release build tree-shakes icon fonts only when every IconData is
  // const, and refuses an app that makes one at run time (MinimalIcon once
  // did): the cut is lucide's own constant, mirrored glyphs too.
  test('the cut is a constant, never an IconData made at run time', () {
    final mirrored = MinimalIcon.stroked(LucideIcons.chevronLeftDir, 1.75);
    expect(mirrored, cut(LucideIcons.chevronLeftDir, 300));
    expect(mirrored.matchTextDirection, isTrue);
    // The same constant each time, from the generated table.
    expect(
      MinimalIcon.stroked(LucideIcons.chevronLeftDir, 1.75),
      same(mirrored),
    );
    expect(
      MinimalIcon.stroked(cut(LucideIcons.house, 600), 1.75),
      same(MinimalIcon.stroked(LucideIcons.house, 1.75)),
    );
  });
}

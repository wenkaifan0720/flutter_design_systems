import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/src/retro_desktop/theme.dart';
import 'package:retro_desktop_ui/src/retro_desktop/tokens.dart';
import 'package:retro_desktop_ui/src/retro_desktop/shapes.dart';

double _contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

List<double> _lab(Color color) {
  double linear(double value) => value <= .04045
      ? value / 12.92
      : math.pow((value + .055) / 1.055, 2.4).toDouble();
  final r = linear(color.r), g = linear(color.g), b = linear(color.b);
  double f(double value) => value > .008856
      ? math.pow(value, 1 / 3).toDouble()
      : 7.787 * value + 16 / 116;
  final x = f((.4124564 * r + .3575761 * g + .1804375 * b) / .95047);
  final y = f(.2126729 * r + .7151522 * g + .072175 * b);
  final z = f((.0193339 * r + .119192 * g + .9503041 * b) / 1.08883);
  return [116 * y - 16, 500 * (x - y), 200 * (y - z)];
}

void _chartReads(RetroDesktopColors colors) {
  final inks = colors.chartTones;
  expect(inks, hasLength(5));
  for (var i = 0; i < inks.length; i++) {
    for (final ground in [
      colors.paper,
      colors.paperDim,
      colors.platinum,
      colors.platinumLight,
      colors.platinumDark,
      colors.highlightContainer,
    ]) {
      expect(_contrast(inks[i], ground), greaterThanOrEqualTo(3));
    }
    final a = _lab(inks[i]);
    for (var j = i + 1; j < inks.length; j++) {
      final b = _lab(inks[j]);
      final distance = math.sqrt(
        List.generate(
          3,
          (k) => math.pow(a[k] - b[k], 2),
        ).reduce((a, b) => a + b),
      );
      expect(distance, greaterThanOrEqualTo(20), reason: 'Series $i and $j');
    }
  }
}

void main() {
  test('custom warm dark palette retains contrast after pixel rounding', () {
    final c = RetroDesktopThemeData.from(
      primary: const Color(0xff803b1c),
      surface: const Color(0xffe5dfcf),
      brightness: Brightness.dark,
    ).colors;
    for (final ink in [c.text, c.textSecondary, c.textTertiary]) {
      for (final ground in [
        c.platinum,
        c.platinumLight,
        c.platinumDark,
        c.paper,
        c.paperDim,
      ]) {
        expect(
          _contrast(Color(ink.toARGB32()), Color(ground.toARGB32())),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });

  test(
    'theme settings survive copy, interpolation, highlight and width changes',
    () {
      final base = RetroDesktopThemeData.classic();
      final custom = base.copyWith(
        appearance: RetroDesktopAppearance.chisel,
        density: RetroDesktopDensity.comfortable,
        typeface: const RetroDesktopTypeface(
          chromeFamily: 'Application Chrome',
          bodyFamily: 'Application Body',
          monoFamily: 'Application Mono',
        ),
      );
      expect(custom, custom.copyWith());
      expect(custom.hashCode, custom.copyWith().hashCode);
      expect(custom.atWidth(1440).typeface, custom.typeface);
      expect(custom.atWidth(1440).density, custom.density);
      expect(custom.onHighlight.shapes, custom.shapes);
      expect(custom.onHighlight.density, custom.density);
      expect(custom.lerp(base, 0), custom);
      expect(custom.lerp(base, 1), base);
      // The corners follow the appearance; no setting of their own.
      expect(
        custom.shapes,
        RetroDesktopShapes.of(RetroDesktopAppearance.chisel),
      );
      expect(
        base.shapes,
        RetroDesktopShapes.of(RetroDesktopAppearance.platinum),
      );
      expect(custom.focus.width, 1);
      expect(
        custom.copyWith(focus: custom.focus.copyWith(width: 3)).focus.width,
        3,
      );
      // The sizes are the look's; only the faces change.
      expect(custom.type.body.fontSize, base.type.body.fontSize);
      expect(custom.type.body.fontFamily, 'Application Body');
      expect(custom.type.pixel(20, 24).fontSize, 20);
      expect(custom.type.mono(10, 12).fontFamily, 'Application Mono');
      expect(custom.type.text(10, 12).fontSize, 10);
      expect(
        custom.density.apply(
          const EdgeInsetsDirectional.fromSTEB(10, 20, 30, 40),
          TextDirection.rtl,
        ),
        const EdgeInsets.fromLTRB(36, 24, 12, 48),
      );
      // Unless an app chooses, the platform's: compact under a pointer,
      // standard on touch.
      for (final (platform, step) in const [
        (TargetPlatform.macOS, RetroDesktopDensity.compact),
        (TargetPlatform.windows, RetroDesktopDensity.compact),
        (TargetPlatform.linux, RetroDesktopDensity.compact),
        (TargetPlatform.android, RetroDesktopDensity.standard),
        (TargetPlatform.iOS, RetroDesktopDensity.standard),
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(base.density, step, reason: platform.name);
      }
      debugDefaultTargetPlatformOverride = null;
    },
  );

  for (final preset in RetroDesktopThemeData.presets) {
    for (final brightness in Brightness.values) {
      test('chart data stays visible in $preset ${brightness.name}', () {
        final colors = RetroDesktopThemeData.preset(preset, brightness).colors;
        final inks = colors.chartTones;
        _chartReads(colors);
        for (final ink in inks) {
          for (final ground in [colors.paper, colors.highlightContainer]) {
            expect(_contrast(ink, ground), greaterThanOrEqualTo(3));
          }
        }
        expect(() => inks.add(colors.text), throwsUnsupportedError);
        expect(colors.copyWith(tones: []).chartTones, hasLength(5));
      });
    }
  }

  for (final brightness in Brightness.values) {
    for (final primary in [
      const Color(0xffffffff),
      const Color(0xff000000),
      const Color(0xffff0000),
      const Color(0xff00ff00),
      const Color(0xff0000ff),
      const Color(0x1055aa66),
    ]) {
      for (final surface in <Color?>[
        null,
        const Color(0xffffffff),
        const Color(0xff000000),
        const Color(0xff777777),
        const Color(0xffff0000),
        const Color(0x102255aa),
      ]) {
        test(
          'derived palette ${brightness.name} $primary $surface stays readable',
          () {
            final theme = RetroDesktopThemeData.from(
              primary: primary,
              brightness: brightness,
              surface: surface,
            );
            final c = theme.colors;
            _chartReads(c);
            expect(theme.dark, brightness == Brightness.dark);
            expect(theme.id, 'custom');
            final grounds = [
              c.platinum,
              c.platinumLight,
              c.platinumDark,
              c.paper,
              c.paperDim,
            ];
            for (final ink in [c.text, c.textSecondary, c.textTertiary]) {
              for (final ground in grounds) {
                expect(_contrast(ink, ground), greaterThanOrEqualTo(4.5));
                expect(
                  _contrast(Color(ink.toARGB32()), Color(ground.toARGB32())),
                  greaterThanOrEqualTo(4.5),
                );
              }
            }
            for (final ground in grounds) {
              expect(_contrast(c.control, ground), greaterThanOrEqualTo(3));
            }
            for (final face in [
              c.highlight,
              c.highlightFaceTop,
              c.highlightFaceMiddle,
              c.highlightFaceBottom,
            ]) {
              expect(_contrast(c.onHighlight, face), greaterThanOrEqualTo(4.5));
            }
            expect(
              _contrast(c.text, c.highlightContainer),
              greaterThanOrEqualTo(4.5),
            );
            expect(_contrast(c.text, c.markLabel), greaterThanOrEqualTo(4.5));
            expect(_contrast(c.highlight, c.paper), greaterThanOrEqualTo(3));
            expect(_contrast(c.hatch, c.paper), greaterThanOrEqualTo(3));
            for (final tone in c.tones) {
              expect(_contrast(tone, c.paper), greaterThanOrEqualTo(3));
            }
          },
        );
      }
    }
  }
}

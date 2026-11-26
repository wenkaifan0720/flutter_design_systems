// Studio's six presets and its colour API on ui_core's palette maths: every
// word, lit legend and ring reads on each ground it is painted on, in each
// preset and in an app's own colours, by day and by night.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:ui_core_test/ui_core_test.dart' show DesignPalette;

double _worst(Color c, Iterable<Color> on) =>
    on.map((g) => RawPalette.contrastRatio(c, g)).reduce(math.min);

void _reads(StudioColors c, String name) {
  final metals = [c.chassis, c.panel, c.panelLow, c.bar, c.barLow];
  final glass = [c.display, c.displayLow];
  final keys = [c.key, c.keyLow];
  final readout = [c.readout, c.readoutLow];
  for (final (what, colour, on, ratio) in [
    ('legend', c.legend, metals, 4.5),
    ('legendMuted', c.legendMuted, metals, 4.5),
    ('onDisplay', c.onDisplay, glass, 4.5),
    ('onDisplayMuted', c.onDisplayMuted, [...glass, ...metals], 4.5),
    ('litLegend', c.litLegend, [...metals, ...glass, ...keys], 4.5),
    ('dangerLegend', c.dangerLegend, [...metals, ...glass], 4.5),
    ('focusRing', c.focusRing, [...metals, ...keys], 3.0),
    ('onIndicator', c.onIndicator, [c.indicator], 4.5),
    ('onKey', c.onKey, keys, 4.5),
    ('onReadout', c.onReadout, readout, 4.5),
    ('onReadoutMuted', c.onReadoutMuted, readout, 4.5),
    ('readoutLit', c.readoutLit, readout, 4.5),
    ('onLitKey', c.onLitKey, [c.litKey], 4.5),
  ]) {
    expect(
      _worst(colour, on),
      greaterThanOrEqualTo(ratio),
      reason: '$name: $what reads under $ratio:1 on a ground it is painted on',
    );
  }
}

void main() {
  test('Studio has six presets, its own first', () {
    expect(StudioThemeData.presets, hasLength(6));
    expect(StudioThemeData.presets.first, 'anodised');
    expect(StudioThemeData.presets.toSet(), hasLength(6));
    final lights = {
      for (final id in StudioThemeData.presets)
        StudioThemeData.preset(id, Brightness.light).colors.indicator,
    };
    expect(lights, hasLength(6), reason: 'each preset has its own light');
    for (final b in Brightness.values) {
      expect(
        StudioThemeData.preset('anodised', b).colors,
        StudioThemeData.anodised(b).colors,
      );
    }
  });

  for (final b in Brightness.values) {
    for (final id in StudioThemeData.presets) {
      test('every word reads in $id by ${b.name}', () {
        _reads(StudioThemeData.preset(id, b).colors, '$id ${b.name}');
      });
    }
    for (final p in DesignPalette.briefs) {
      test('every word reads in ${p.name} by ${b.name}', () {
        _reads(
          StudioThemeData.from(
            indicator: p.accent,
            finish: p.neutral,
            brightness: b,
          ).colors,
          '${p.name} ${b.name}',
        );
      });
    }
  }

  test('by day the readout glass keeps its brightness for a dark light', () {
    final own = const StudioColors.light();
    for (final p in DesignPalette.briefs) {
      final c = StudioThemeData.from(indicator: p.accent).colors;
      expect(c.litReadout, isTrue, reason: p.name);
      expect(
        RawHct.fromColor(c.readout).tone,
        closeTo(RawHct.fromColor(own.readout).tone, 1),
        reason: p.name,
      );
      expect(
        RawHct.fromColor(c.readoutLow).tone,
        closeTo(RawHct.fromColor(own.readoutLow).tone, 1),
        reason: p.name,
      );
    }
  });

  test('a cream finish anodises the night metal to a charcoal, not brown', () {
    final c = StudioThemeData.from(
      indicator: DesignPalette.pastel.accent,
      finish: DesignPalette.pastel.neutral,
      brightness: Brightness.dark,
    ).colors;
    for (final metal in [c.chassis, c.panel, c.panelLow, c.bar, c.key]) {
      expect(RawHct.fromColor(metal).chroma, lessThanOrEqualTo(6.5));
    }
    final day = StudioThemeData.from(
      indicator: DesignPalette.pastel.accent,
      finish: DesignPalette.pastel.neutral,
    ).colors;
    expect(
      RawHct.fromColor(day.panel).chroma,
      greaterThan(2),
      reason: 'by day the metal keeps the finish',
    );
  });

  test("the glass takes the finish's hue, at a breath", () {
    // On plum or brass metal a mint-grey pane would read as dirt: the
    // display glass leans to the finish too, far fainter than the metal.
    for (final finish in [const Color(0xFF5B4570), const Color(0xFFC2A46E)]) {
      final hue = RawHct.fromColor(finish).hue;
      for (final b in Brightness.values) {
        final c = StudioThemeData.from(
          indicator: const Color(0xFFFFAE3A),
          finish: finish,
          brightness: b,
        ).colors;
        for (final pane in [c.display, c.displayLow]) {
          final h = RawHct.fromColor(pane);
          expect(h.chroma, lessThanOrEqualTo(4.5), reason: '${b.name} $pane');
          if (b == Brightness.light) {
            final off = (h.hue - hue).abs() % 360;
            expect(
              off > 180 ? 360 - off : off,
              lessThan(20),
              reason: 'the day glass under $finish',
            );
          }
        }
      }
    }
  });

  test('a vivid finish tints the metal, never paints it', () {
    // A brand's full orange and blue as finishes: the metal takes their hue
    // at a tint (chroma 7 at most), as anodising does.
    for (final finish in [const Color(0xFFFF5A00), const Color(0xFF0050FF)]) {
      for (final b in Brightness.values) {
        final c = StudioThemeData.from(
          indicator: const Color(0xFFFFAE3A),
          finish: finish,
          brightness: b,
        ).colors;
        for (final metal in [c.chassis, c.panel, c.bar, c.key]) {
          expect(
            RawHct.fromColor(metal).chroma,
            lessThanOrEqualTo(7.5),
            reason: '${b.name} metal under $finish',
          );
        }
      }
    }
  });

  test('a light neither dark nor light words read on still gets words', () {
    // A mid grey: white reads 4.2:1 on it, the look's dark words 4.4:1.
    const grey = Color(0xFF7A7A7A);
    for (final b in Brightness.values) {
      final c = StudioThemeData.from(indicator: grey, brightness: b).colors;
      expect(
        RawPalette.contrastRatio(c.onIndicator, c.indicator),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  test('a named light keeps its colour where its words read on it', () {
    for (final light in [
      const Color(0xFFFFAE3A),
      const Color(0xFF1F3A68),
      const Color(0xFFC9A227),
    ]) {
      for (final b in Brightness.values) {
        expect(
          StudioThemeData.from(
            indicator: light,
            brightness: b,
          ).colors.indicator,
          light,
        );
      }
    }
  });

  // The hue distance between two colours, 0 to 180 degrees.
  double hueGap(Color a, Color b) {
    final d = (RawHct.fromColor(a).hue - RawHct.fromColor(b).hue).abs() % 360;
    return d > 180 ? 360 - d : d;
  }

  test('the words on a preset\'s lit glass take the glass\'s hue', () {
    for (final id in StudioThemeData.presets.skip(1)) {
      final c = StudioThemeData.preset(id, Brightness.light).colors;
      for (final ink in [c.onReadout, c.onReadoutMuted]) {
        expect(
          hueGap(ink, c.readout),
          lessThan(20),
          reason: '$id: $ink on ${c.readout}',
        );
        expect(
          RawPalette.contrastRatio(ink, c.readoutLow),
          greaterThanOrEqualTo(4.5),
          reason: id,
        );
      }
    }
    final own = StudioThemeData.light().colors;
    expect(own.onReadout, const Color(0xFF2A2116));
  });

  test('graphite is the one hue-free set: neutral steel, ice glass, a cool '
      'white light', () {
    for (final b in Brightness.values) {
      final c = StudioThemeData.preset('graphite', b).colors;
      final metals = [c.chassis, c.panel, c.panelLow, c.bar, c.key, c.keyLow];
      for (final metal in [...metals, c.display, c.displayLow]) {
        expect(
          RawHct.fromColor(metal).chroma,
          lessThan(2),
          reason: '${b.name} $metal',
        );
      }
      final light = RawHct.fromColor(c.lightInDark);
      expect(light.chroma, lessThan(8), reason: 'a cool white, not a tint');
      expect(light.tone, greaterThan(80), reason: '${b.name}: a white light');
      if (b == Brightness.light) {
        // By day the white can't read on the silver: what is on shows in
        // ink (lamps, a tab's bar, a latched key), the white only in a
        // dark slot or on the graphite main key.
        expect(RawHct.fromColor(c.indicator).tone, lessThan(30));
        expect(hueGap(c.indicator, c.lightInDark), lessThan(30));
        expect(
          RawPalette.contrastRatio(c.indicator, c.key),
          greaterThanOrEqualTo(3),
          reason: 'a lit lamp reads on a key',
        );
        expect(
          RawPalette.contrastRatio(c.onLitKey, c.litKey),
          greaterThanOrEqualTo(7),
          reason: 'the main key\'s legend in the white light',
        );
      } else {
        expect(c.indicator, c.lightInDark);
      }
      final words = [
        c.readoutLit,
        c.onReadout,
        c.onReadoutMuted,
        c.litLegend,
        c.lampOff,
      ];
      for (final w in words) {
        expect(
          RawHct.fromColor(w).chroma,
          lessThan(8),
          reason: '${b.name}: $w keeps no hue of its own',
        );
      }
      expect(
        RawHct.fromColor(c.onIndicator).chroma,
        lessThan(3),
        reason: 'a lit key\'s words are a neutral black or white',
      );
      if (b == Brightness.light) {
        final glass = RawHct.fromColor(c.readout);
        expect(glass.tone, greaterThan(85), reason: 'ice-white glass');
        expect(glass.chroma, lessThan(8));
        expect(
          hueGap(c.readout, c.indicator),
          lessThan(30),
          reason: 'the glass lit as the light is, not cream',
        );
        for (final w in [c.readoutLit, c.onReadout]) {
          expect(
            RawHct.fromColor(w).tone,
            lessThan(20),
            reason: 'near-black $w',
          );
        }
      } else {
        for (final w in [c.readoutLit, c.onReadout, c.lightInDark]) {
          expect(RawHct.fromColor(w).tone, greaterThan(80), reason: 'white $w');
          expect(
            hueGap(w, c.indicator),
            lessThan(30),
            reason: 'cool, not warm: $w',
          );
        }
      }
    }
  });

  test('a preset\'s unlit lamps are its own lamp, dark', () {
    for (final b in Brightness.values) {
      for (final id in StudioThemeData.presets.skip(1)) {
        final c = StudioThemeData.preset(id, b).colors;
        expect(
          hueGap(c.lampOff, c.indicator),
          lessThan(20),
          reason: '$id ${b.name}',
        );
        expect(
          RawPalette.contrastRatio(c.lampEdge, c.key),
          greaterThanOrEqualTo(3.3),
          reason: id,
        );
      }
    }
    expect(StudioThemeData.dark().colors.lampOff, const Color(0xFF5A4E3C));
  });
}

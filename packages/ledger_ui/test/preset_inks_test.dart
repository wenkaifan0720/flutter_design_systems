import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/src/ledger/internal/themes/frost.g.dart';
import 'package:ledger_ui/src/ledger/internal/themes/paper.g.dart';
import 'package:ledger_ui/src/ledger/internal/themes/signal.g.dart';

// CIE76 between two colours.
double _apart(Color a, Color b) {
  List<double> lab(Color c) {
    double linear(double v) =>
        v <= .04045 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
    final r = linear(c.r), g = linear(c.g), b = linear(c.b);
    double f(double t) =>
        t > .008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
    final x = f((r * .4124 + g * .3576 + b * .1805) / .95047);
    final y = f(r * .2126 + g * .7152 + b * .0722);
    final z = f((r * .0193 + g * .1192 + b * .9505) / 1.08883);
    return [116 * y - 16, 500 * (x - y), 200 * (y - z)];
  }

  final p = lab(a), q = lab(b);
  return math.sqrt(
    List.generate(3, (i) => math.pow(p[i] - q[i], 2)).reduce((s, v) => s + v),
  );
}

double _hueGap(Color a, Color b) {
  final d = (RawHct.fromColor(a).hue - RawHct.fromColor(b).hue).abs() % 360;
  return math.min(d, 360 - d);
}

// The presets built on a token record, with the record.
const _records = <String, LedgerTokens>{
  'terracotta': paperTokens,
  'indigo': signalTokens,
  'verdigris': frostTokens,
};

void main() {
  test("by day a preset's words are in its accent's hue, as prussian's", () {
    for (final id in [..._records.keys, 'prussian']) {
      final t = LedgerThemeData.preset(id, Brightness.light);
      for (final (name, ink, chroma) in [
        ('ink', t.textPrimary, 12.0),
        ('second ink', t.textSecondary, 12.0),
        if (id != 'prussian') ('third ink', t.textTertiary, 6.0),
      ]) {
        expect(
          _hueGap(ink, t.accent),
          lessThanOrEqualTo(12),
          reason: '$id $name',
        );
        expect(
          RawHct.fromColor(ink).chroma,
          greaterThanOrEqualTo(chroma),
          reason: '$id $name',
        );
      }
    }
  });

  test('by day no two presets share an ink', () {
    final ids = [for (final p in LedgerThemeData.palettes) p.id];
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        expect(
          _apart(
            LedgerThemeData.preset(ids[i], Brightness.light).textPrimary,
            LedgerThemeData.preset(ids[j], Brightness.light).textPrimary,
          ),
          greaterThanOrEqualTo(5.5),
          reason: '${ids[i]} and ${ids[j]}',
        );
      }
    }
  });

  test(
    "by day a token preset's second ink carries its accent's hue plainly",
    () {
      // A dark ink holds little colour (a teal at the ink's tone, 20 at most);
      // the second ink, under every row, is where the hue shows.
      for (final id in _records.keys) {
        expect(
          RawHct.fromColor(
            LedgerThemeData.preset(id, Brightness.light).textSecondary,
          ).chroma,
          greaterThanOrEqualTo(22),
          reason: id,
        );
      }
    },
  );

  test("the token presets' inks keep their record's tones and read", () {
    for (final MapEntry(key: id, value: record) in _records.entries) {
      final t = LedgerThemeData.preset(id, Brightness.light);
      final grounds = [t.background, t.surface, t.surfaceAlt];
      for (final (name, ink, wanted, ratio) in [
        ('ink', t.textPrimary, record.light.textPrimary, 7.0),
        ('second ink', t.textSecondary, record.light.textSecondary, 4.5),
      ]) {
        expect(
          RawHct.fromColor(ink).tone,
          closeTo(RawHct.fromColor(wanted).tone, 1.5),
          reason: '$id $name',
        );
        for (final g in grounds) {
          expect(
            RawPalette.contrastRatio(ink, g),
            greaterThanOrEqualTo(ratio),
            reason: '$id $name on $g',
          );
        }
      }
      for (final g in grounds) {
        expect(
          RawPalette.contrastRatio(t.textTertiary, g),
          greaterThanOrEqualTo(4.5),
          reason: '$id third ink on $g',
        );
      }
    }
  });

  test("by lamplight the token presets keep their record's inks", () {
    for (final MapEntry(key: id, value: record) in _records.entries) {
      final t = LedgerThemeData.preset(id, Brightness.dark);
      expect(t.textPrimary, record.dark.textPrimary, reason: id);
      expect(t.textSecondary, record.dark.textSecondary, reason: id);
    }
  });
}

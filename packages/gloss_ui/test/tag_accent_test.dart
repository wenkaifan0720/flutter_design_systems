// An accent tag stands on its palette's gel, pale by day and deep by night,
// with the gel's ink reading on it at 4.5:1; its glyph grows with its words.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

double _contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

double _hues(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}

/// The tone that follows the palette (named `jade` before 0.6.0).
final _accent = GlossTagTone.values.firstWhere(
  (v) => v.name == 'accent' || v.name == 'jade',
);

Future<GlossFace> _plate(WidgetTester t, GlossThemeData data) async {
  await t.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GlossTheme(
        data: data,
        child: Center(child: GlossTag('Reading', tone: _accent)),
      ),
    ),
  );
  return t
      .widget<GlossSurface>(
        find.descendant(
          of: find.byType(GlossTag),
          matching: find.byType(GlossSurface),
        ),
      )
      .face;
}

void main() {
  for (final b in Brightness.values) {
    testWidgets("an accent tag's plate takes its palette's gel (${b.name})", (
      t,
    ) async {
      for (final id in const [
        'jade',
        'sapphire',
        'amethyst',
        'amber',
        'rose',
        'teal',
      ]) {
        final data = GlossThemeData.preset(id, b);
        final c = data.colors;
        final face = await _plate(t, data);
        final plate = RawHct.fromColor(face.middle);
        final gel = RawHct.fromColor(c.jade);
        expect(
          _hues(plate.hue, gel.hue),
          lessThan(20),
          reason: '$id: the plate in the gel\'s hue',
        );
        expect(
          _contrast(face.foreground, face.middle),
          greaterThanOrEqualTo(4.5),
          reason: '$id: the words on the plate',
        );
      }
    });
  }

  testWidgets("a tag's glyph grows with its words", (t) async {
    Future<double> glyph(double scale) async {
      await t.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: GlossTheme(
              data: GlossThemeData.preset('sapphire', Brightness.light),
              child: Center(
                child: GlossTag(
                  'Reading',
                  tone: _accent,
                  icon: LucideIcons.bookOpen,
                ),
              ),
            ),
          ),
        ),
      );
      return t.getSize(find.byType(Icon)).height;
    }

    final base = await glyph(1);
    expect(await glyph(1.4), moreOrLessEquals(base * 1.4, epsilon: .5));
  });
}

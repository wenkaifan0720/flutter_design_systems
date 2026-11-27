// A keycap's letters read at 4.5:1 or more on its pearl, by day and by
// night, at the pearl's lit top as at its middle.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets("a keycap's letters read on its pearl by ${brightness.name}", (
      tester,
    ) async {
      final theme = brightness == Brightness.dark
          ? GlossThemeData.dark()
          : GlossThemeData.light();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => GlossHost(
            theme: GlossThemeData.light(),
            darkTheme: GlossThemeData.dark(),
            brightness: brightness,
            child: app!,
          ),
          home: const Center(child: GlossKbd('Ctrl K')),
        ),
      );
      await tester.pumpAndSettle();
      final ink = tester.widget<Text>(find.text('Ctrl K')).style!.color!;
      final pearl = GlossFace.pearl(theme.colors);
      for (final ground in [pearl.top, pearl.middle]) {
        expect(_contrast(ink, ground), greaterThanOrEqualTo(4.5));
      }
    });
  }
}

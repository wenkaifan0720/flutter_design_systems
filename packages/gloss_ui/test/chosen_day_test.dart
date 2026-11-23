// What is on glows jade inside its well (Gloss's rule, as a switch's groove
// and a slider's lit run): the chosen day, and a range's two ends, stand in
// a well lit jade, their figures white on it. They stood as raised gel
// beads, the key Gloss keeps for the one thing a screen acts on.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

double _ratio(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

GlossFace _faceOf(WidgetTester tester, String day) => tester
    .widget<AnimatedGlossSurface>(
      find
          .ancestor(
            of: find.text(day),
            matching: find.byType(AnimatedGlossSurface),
          )
          .first,
    )
    .face;

void main() {
  for (final brightness in Brightness.values) {
    for (final range in [false, true]) {
      testWidgets(
        '${range ? "a range's ends glow" : 'the chosen day glows'} jade in '
        'a well (${brightness.name})',
        (tester) async {
          final data = brightness == Brightness.light
              ? GlossThemeData.light()
              : GlossThemeData.dark();
          await tester.pumpWidget(
            MaterialApp(
              home: GlossTheme(
                data: data,
                child: Center(
                  child: SizedBox(
                    width: 360,
                    child: range
                        ? GlossCalendar.range(
                            firstDate: DateTime(2026),
                            lastDate: DateTime(2027, 12, 31),
                            currentDate: DateTime(2026, 11, 2),
                            selectedRange: GlossDateRange(
                              start: DateTime(2026, 11, 20),
                              end: DateTime(2026, 11, 24),
                            ),
                            onRangeChanged: (_) {},
                          )
                        : GlossCalendar(
                            firstDate: DateTime(2026),
                            lastDate: DateTime(2027, 12, 31),
                            currentDate: DateTime(2026, 11, 2),
                            selectedDate: DateTime(2026, 11, 20),
                            onDateChanged: (_) {},
                          ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final c = data.colors;
          for (final day in [
            if (range) ...['20', '24'] else '20',
          ]) {
            final face = _faceOf(tester, day);
            expect(face.lift, lessThan(0), reason: '$day stands raised');
            expect(face.middle, c.jade, reason: '$day is not lit jade');
            final words = tester.widget<Text>(find.text(day)).style!.color!;
            expect(_ratio(words, face.middle), greaterThanOrEqualTo(4.5));
          }
          // A day between a range's ends stays on the glaze, not in a well.
          if (range) expect(_faceOf(tester, '22').lift, 0);
        },
      );
    }
  }
}

// A slider and a range slider stacked in one column run their beads
// between the same two ends: a slider's bead at its least stands where
// the range's lower bead does, at its most where the upper one does (the
// slider's travel stood 6 px wider at each end).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  for (final direction in TextDirection.values) {
    for (final at in [0.0, 1.0]) {
      testWidgets('a slider at $at ends where the range does, $direction', (
        tester,
      ) async {
        tester.view
          ..physicalSize = const Size(400, 300)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, app) => GlossHost(
              theme: GlossThemeData.light(),
              darkTheme: GlossThemeData.dark(),
              brightness: Brightness.light,
              child: Directionality(textDirection: direction, child: app!),
            ),
            home: Align(
              alignment: AlignmentDirectional.topStart,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      GlossSlider(value: at, onChanged: (_) {}),
                      GlossRangeSlider(
                        values: const GlossRangeValues(0, 1),
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Finder beads(Type type) => find.descendant(
          of: find.byType(type),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == 28 && w.height == 28,
          ),
        );
        final bead = tester.getRect(beads(GlossSlider).first).center.dx;
        final range = beads(GlossRangeSlider);
        expect(range, findsNWidgets(2));
        final ends = [
          tester.getRect(range.at(0)).center.dx,
          tester.getRect(range.at(1)).center.dx,
        ]..sort();
        final low = direction == TextDirection.ltr ? ends.first : ends.last;
        final high = direction == TextDirection.ltr ? ends.last : ends.first;
        expect(bead, moreOrLessEquals(at == 0 ? low : high, epsilon: 0.5));
      });
    }
  }
}

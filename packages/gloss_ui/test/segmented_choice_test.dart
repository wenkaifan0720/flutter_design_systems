// A segmented control's choice is a state, not the screen's act: its thumb
// is raised pearl with the chosen words lit jade, as a latched chip's, and
// never the jade gel of the one action. The jade words read at 4.5:1 on the
// pearl by day and by night, up to its crown, the glaze's lightest stop,
// with no engraving: that was the gel's, a dark line above words cut into it.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

import '../example/lib/kit_gallery/kit.dart';

void main() {
  setUpAll(glossLoadFonts);

  for (final brightness in Brightness.values) {
    testWidgets(
      'the chosen segment is pearl, its words jade (${brightness.name})',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          kitApp(
            brightness: brightness,
            home: Center(
              child: GlossSegmentedButton<String>(
                segments: const [
                  GlossSegment(value: 'low', label: 'Low'),
                  GlossSegment(value: 'normal', label: 'Normal'),
                  GlossSegment(value: 'high', label: 'High'),
                ],
                selected: 'high',
                onChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final control = find.byType(GlossSegmentedButton<String>);
        final colors = GlossTheme.of(tester.element(control)).colors;
        final faces = tester
            .widgetList<GlossSurface>(
              find.descendant(of: control, matching: find.byType(GlossSurface)),
            )
            .map((s) => s.face);
        expect(faces.where((f) => f.middle == colors.jade), isEmpty);
        expect(
          faces.where((f) => f == GlossFace.pearl(colors).copyWith(lift: 0.7)),
          hasLength(1),
        );
        final chosen = tester.widget<Text>(find.text('High')).style!;
        expect(
          chosen.shadows ?? const <Shadow>[],
          isEmpty,
          reason: 'a dark line above the words, left from the jade gel',
        );
        final words = chosen.color!;
        // Jade: the jade ink's hue, lifted or deepened only.
        expect(
          HSLColor.fromColor(words).hue,
          closeTo(HSLColor.fromColor(colors.jadeInk).hue, 4),
        );
        final ground = GlossFace.pearl(colors).top;
        final (a, b) = (words.computeLuminance(), ground.computeLuminance());
        expect(
          (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05),
          greaterThanOrEqualTo(4.5),
          reason: "the chosen words on the pearl's crown",
        );
      },
    );
  }
}

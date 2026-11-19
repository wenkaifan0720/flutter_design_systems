// A stepper's keys stand as tall as its readout: one row, one height (the
// user, more than once; ui_core_test 0.1.2's DesignFieldPartsCheck holds it
// within 1 px). At 1x, 2x and 3x text, both directions, on and off; the
// readout grows with its figures and the keys with it, and the figures stay
// whole in the window.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

void main() {
  setUpAll(studioLoadFonts);

  for (final scale in [1.0, 2.0, 3.0]) {
    for (final direction in TextDirection.values) {
      for (final enabled in [true, false]) {
        testWidgets('a${enabled ? 'n' : ' disabled'} stepper\'s keys are as '
            'tall as its readout at ${scale}x, ${direction.name}', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 2;
          tester.view.physicalSize = const Size(390 * 2, 600 * 2);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, app) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: Directionality(
                  textDirection: direction,
                  child: StudioHost(brightness: Brightness.light, child: app!),
                ),
              ),
              home: Align(
                alignment: Alignment.topCenter,
                child: StudioStepper(
                  value: 12,
                  min: 1,
                  max: 99,
                  semanticLabel: 'Takes',
                  onChanged: enabled ? (_) {} : null,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          Rect face(Finder of) => tester.getRect(
            find
                .descendant(
                  of: of,
                  matching: find.byType(AnimatedStudioSurface),
                )
                .first,
          );
          final keys = find.descendant(
            of: find.byType(StudioStepper),
            matching: find.byType(StudioIconButton),
          );
          expect(keys, findsNWidgets(2));
          final figures = find.text('12');
          final readout = tester.getRect(
            find
                .ancestor(
                  of: figures,
                  matching: find.byType(AnimatedStudioSurface),
                )
                .first,
          );
          expect(
            readout.height,
            greaterThanOrEqualTo(
              StudioTheme.of(tester.element(find.byType(StudioStepper)))
                  .controlHeight,
            ),
          );
          for (final key in [face(keys.first), face(keys.last)]) {
            expect(
              key.height,
              moreOrLessEquals(readout.height, epsilon: 0.5),
              reason: 'a key $key beside a readout $readout',
            );
            expect(key.center.dy, moreOrLessEquals(readout.center.dy));
          }
          final paragraph = tester.renderObject<RenderParagraph>(figures);
          expect(paragraph.didExceedMaxLines, isFalse);
          final box = tester.getRect(figures);
          expect(
            readout.inflate(0.5).contains(box.topLeft) &&
                readout.inflate(0.5).contains(box.bottomRight),
            isTrue,
            reason: 'the figures $box leave the readout $readout',
          );
        });
      }
    }
  }
}

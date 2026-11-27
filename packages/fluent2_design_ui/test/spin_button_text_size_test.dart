// A spin button grows with its words as a text field does: at 100% and
// 200% text, left to right and right to left, on a phone and a desktop
// width, under a pointer and a finger, its value stands whole inside its
// frame, the frame is as tall as a text field's beside it, and its steppers
// take the field's height.
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gallery_support.dart' show loadFluent2TestFonts;

Widget _app(double scale, TextDirection direction) => WidgetsApp(
  color: const Color(0xFF000000),
  localizationsDelegates: const [
    RawWidgetsLocalizations.delegate,
    Fluent2Localizations.delegate,
  ],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: Directionality(
      textDirection: direction,
      child: Fluent2Host(child: child!),
    ),
  ),
  onGenerateRoute: (settings) => PageRouteBuilder<void>(
    settings: settings,
    pageBuilder: (context, _, _) => Align(
      alignment: AlignmentDirectional.topStart,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 300,
              child: Fluent2TextField(
                key: const ValueKey('text'),
                value: 'Nov 20, 2026',
                semanticLabel: 'Due date',
                onChanged: (_) {},
              ),
            ),
            const SizedBox(height: 16),
            Fluent2SpinButton(
              key: const ValueKey('spin'),
              semanticLabel: 'Estimate (minutes)',
              value: 45,
              min: 0,
              max: 600,
              step: 15,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(loadFluent2TestFonts);

  const platforms = TargetPlatformVariant({
    TargetPlatform.macOS,
    TargetPlatform.android,
  });

  for (final width in [390.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'at ${width.round()}, ${direction.name}, ${(scale * 100).round()}% text, '
          'the value stands whole and the steppers take the field\'s height',
          variant: platforms,
          (tester) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(_app(scale, direction));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            final spin = find.byKey(const ValueKey('spin'));
            final frame = tester.getRect(spin);
            final editor = find.descendant(
              of: spin,
              matching: find.byType(EditableText),
            );
            final line = tester.state<EditableTextState>(editor).renderEditable;
            final box = MatrixUtils.transformRect(
              line.getTransformTo(null),
              Offset.zero & line.size,
            );
            // The value's whole line, its descent included, inside the frame.
            final words = line.preferredLineHeight;
            expect(box.height, greaterThanOrEqualTo(words - 0.5));
            expect(box.top, greaterThanOrEqualTo(frame.top - 0.5));
            expect(box.bottom, lessThanOrEqualTo(frame.bottom + 0.5));

            // As tall as a text field's frame in the same size.
            final text = tester.getRect(find.byKey(const ValueKey('text')));
            expect(frame.height, moreOrLessEquals(text.height, epsilon: 0.5));

            // The steppers stand the field's line tall: under a pointer the
            // pair splits it, under a finger each takes all of it.
            final steppers = find
                .descendant(
                  of: spin,
                  matching: find.byWidgetPredicate(
                    (w) => w.runtimeType.toString() == '_Stepper',
                  ),
                )
                .evaluate()
                .map((e) => tester.getRect(find.byWidget(e.widget)))
                .toList();
            expect(steppers, hasLength(2));
            final touch =
                debugDefaultTargetPlatformOverride == TargetPlatform.android;
            final inner = frame.height - (touch ? 0 : 2);
            if (touch) {
              for (final s in steppers) {
                expect(s.height, moreOrLessEquals(inner, epsilon: 1));
              }
            } else {
              final total = steppers.fold<double>(0, (a, s) => a + s.height);
              expect(total, moreOrLessEquals(inner, epsilon: 1));
            }
          },
        );
      }
    }
  }
}

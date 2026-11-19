// Choices keep their parts in place as the text grows, where Material's do:
// a selector's lamp, stacked over its words in a narrow space, stands a
// small gap above their capitals and clear of the trough's edge at 1x and
// 2x (at 3x Material's segmented button breaks its words too), and a chip's
// face holds its words whole, descenders and all, at 1x, 2x and 3x.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(WidgetTester tester, Widget child, double scale) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 1200 * 2);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: ApplianceHost(brightness: Brightness.light, child: app!),
      ),
      home: Align(
        alignment: Alignment.topLeft,
        child: Padding(padding: const EdgeInsets.all(32), child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(applianceLoadFonts);

  for (final scale in [1.0, 2.0, 3.0]) {
    if (scale < 3) {
      testWidgets('a selector\'s lamps sit just over their words and clear of '
          'its edge at ${scale}x', (tester) async {
        await _show(
          tester,
          ApplianceSegmentedButton<int>(
            segments: const [
              ApplianceSegment(value: 0, label: 'Low'),
              ApplianceSegment(value: 1, label: 'Normal'),
              ApplianceSegment(value: 2, label: 'High'),
            ],
            value: 2,
            onChanged: (_) {},
          ),
          scale,
        );
        final trough = tester.getRect(
          find.byType(ApplianceSegmentedButton<int>),
        );
        final lamps = find.byType(ApplianceLamp);
        expect(lamps, findsNWidgets(3));
        for (final (i, label) in ['Low', 'Normal', 'High'].indexed) {
          final lamp = tester.getRect(lamps.at(i));
          final words = find.text(label);
          final box = tester.getRect(words);
          final paragraph = tester.renderObject<RenderParagraph>(words);
          expect(paragraph.didExceedMaxLines, isFalse);
          final baseline = paragraph.computeDistanceToActualBaseline(
            TextBaseline.alphabetic,
          );
          final style = tester.widget<Text>(words).style!;
          final cap =
              TextScaler.linear(scale).scale(style.fontSize!) *
              ApplianceTheme.of(tester.element(words)).capHeightFactor;
          // In the screen's pixels, through any scaling of the words.
          final capTop = paragraph.localToGlobal(Offset(0, baseline - cap)).dy;
          final capBottom = paragraph.localToGlobal(Offset(0, baseline)).dy;
          expect(
            lamp.top - trough.top,
            greaterThanOrEqualTo(ApplianceMetrics.troughInset + 2),
            reason: '$label\'s lamp is on the edge',
          );
          expect(
            trough.bottom - capBottom,
            greaterThanOrEqualTo(ApplianceMetrics.troughInset + 2),
          );
          if (lamp.bottom <= capTop + 0.5) {
            // Stacked: a small gap over the capitals.
            expect(
              capTop - lamp.bottom,
              inInclusiveRange(2, ApplianceSpacing.tight + 3),
              reason: '$label\'s lamp floats over it',
            );
            // Centred as one: as much room over the lamp as under the words.
            expect(
              (lamp.top - trough.top) - (trough.bottom - capBottom),
              inInclusiveRange(-6, 6),
            );
          } else {
            // In a row: the lamp before the words, on their capitals' middle.
            expect(lamp.right, lessThanOrEqualTo(box.left + 0.5));
            expect(
              lamp.center.dy,
              moreOrLessEquals((capTop + capBottom) / 2, epsilon: 1.5),
            );
          }
        }
      });
    }

    testWidgets('a chip holds its words whole at ${scale}x', (tester) async {
      await _show(
        tester,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ApplianceChip('Planning', selected: true, onSelected: (_) {}),
            ApplianceChip('Fieldwork', onDeleted: () {}),
          ],
        ),
        scale,
      );
      for (final label in ['Planning', 'Fieldwork']) {
        final words = find.text(label);
        final paragraph = tester.renderObject<RenderParagraph>(words);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          paragraph.size.width,
          greaterThanOrEqualTo(
            paragraph.getMaxIntrinsicWidth(double.infinity) - 0.5,
          ),
        );
        final box = tester.getRect(words);
        final face = tester.getRect(
          find
              .descendant(
                of: find.ancestor(
                  of: words,
                  matching: find.byType(ApplianceChip),
                ),
                matching: find.byType(AnimatedApplianceSurface),
              )
              .first,
        );
        expect(
          face.inflate(0.5).contains(box.topLeft) &&
              face.inflate(0.5).contains(box.bottomRight),
          isTrue,
          reason: '$label ($box) leaves its face ($face)',
        );
      }
    });
  }
}

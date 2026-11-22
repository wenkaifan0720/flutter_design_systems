// A donut's legend starts each line with its swatch, on the reading side,
// whichever way the label is written: right to left, an English label on
// an Arabic page still has its swatch at the line's right, a gap before the
// label, not jammed against the label's far end. The swatch sits on the
// first line of words.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  setUpAll(keycapLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets("each legend line starts with its swatch, ${direction.name}", (
      tester,
    ) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(780, 1400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) =>
              KeycapHost(brightness: Brightness.light, child: app!),
          home: Directionality(
            textDirection: direction,
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: KeycapDonutChart(
                semanticLabel: 'Notes',
                slices: [('Work', 14), ('Home', 9), ('Ideas', 21)],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final swatches = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 10 && w.height == 10,
      );
      expect(swatches, findsNWidgets(3));
      // The three swatches are one const widget: read each by its element.
      for (final swatch in swatches.evaluate()) {
        final square = swatch.renderObject! as RenderBox;
        final box = square.localToGlobal(Offset.zero) & square.size;
        final row = swatch.findAncestorRenderObjectOfType<RenderFlex>()!;
        final line = row.localToGlobal(Offset.zero) & row.size;
        if (direction == TextDirection.ltr) {
          expect(box.left - line.left, lessThan(2));
        } else {
          expect(line.right - box.right, lessThan(2));
        }
        // The legend words on the swatch's line.
        final words = tester
            .renderObjectList<RenderParagraph>(
              find.descendant(
                of: find.byType(KeycapDonutChart),
                matching: find.byType(RichText),
              ),
            )
            .firstWhere((p) {
              final r = p.localToGlobal(Offset.zero) & p.size;
              return r.top <= box.center.dy &&
                  box.center.dy <= r.bottom &&
                  p.text.toPlainText().contains(RegExp('Work|Home|Ideas'));
            });
        final first = words.localToGlobal(Offset.zero).dy;
        final firstLine = words.getFullHeightForCaret(
          const TextPosition(offset: 0),
        );
        expect(
          box.center.dy,
          moreOrLessEquals(first + firstLine / 2, epsilon: 2),
        );
      }
    });
  }
}

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/text_scale_host.dart';

void main() {
  testWidgets('today\'s bar keeps its gap under the digits at text scale 1.3', (
    tester,
  ) async {
    final day = DateTime(2026, 3, 12);
    // The space between today's figure's baseline and the top of its bar.
    Future<double> gap(double scale) async {
      await tester.pumpWidget(
        textScaleHost(
          MinimalCalendar(
            firstDate: DateTime(2026),
            lastDate: DateTime(2026, 12, 31),
            value: DateTime(2026, 3, 20),
            currentDate: day,
            onChanged: (_) {},
          ),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();
      final bar = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints ==
                const BoxConstraints.tightFor(width: 10, height: 2),
      );
      expect(bar, findsOneWidget);
      final figure = find.descendant(
        of: find.ancestor(of: bar, matching: find.byType(Stack)).first,
        matching: find.text('${day.day}'),
      );
      // The figure's baseline: its paragraph's top plus the baseline of
      // the same words laid out alone (a box's baseline is read only by its
      // parent while it lays out).
      final p = tester.renderObject<RenderParagraph>(figure);
      final painter = TextPainter(
        text: p.text,
        textDirection: TextDirection.ltr,
        textScaler: p.textScaler,
      )..layout();
      final baseline =
          tester.getTopLeft(figure).dy +
          painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
      painter.dispose();
      return tester.getRect(bar).top - baseline;
    }

    final atOne = await gap(1);
    expect(atOne, greaterThan(2));
    expect(await gap(1.3), moreOrLessEquals(atOne, epsilon: 0.5));
  });
}

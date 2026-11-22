// A wheel's rows keep clear of each other at twice the text size: the drum's
// rows grow with its figures, so "15 min" no longer touches "20 min". At the
// usual size a row stays 40 high.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _show(
  WidgetTester tester, {
  required double scale,
  required TextDirection direction,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => ClayTheme(
        data: ClayThemeData.clay(Brightness.light),
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale,
          child: app!,
        ),
      ),
      home: Directionality(
        textDirection: direction,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ClayWheelPicker<int>(
              items: const [5, 10, 15, 20, 30],
              value: 15,
              labelOf: (n) => '$n min',
              onChanged: (_) {},
              semanticLabel: 'Duration',
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(clayLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets('rows keep clear of each other at 2x, ${direction.name}', (
      tester,
    ) async {
      await _show(tester, scale: 2, direction: direction);
      final chosen = tester.getRect(find.text('15 min'));
      final next = tester.getRect(find.text('20 min'));
      final before = tester.getRect(find.text('10 min'));
      expect(
        next.top - chosen.bottom,
        greaterThanOrEqualTo(6),
        reason: '15 min ends at ${chosen.bottom}, 20 min starts at ${next.top}',
      );
      expect(
        chosen.top - before.bottom,
        greaterThanOrEqualTo(6),
        reason: '10 min ends at ${before.bottom}, 15 min at ${chosen.top}',
      );
    });
  }

  testWidgets('rows are 40 apart at the usual text size', (tester) async {
    await _show(tester, scale: 1, direction: TextDirection.ltr);
    final chosen = tester.getRect(find.text('15 min'));
    final next = tester.getRect(find.text('20 min'));
    expect(next.center.dy - chosen.center.dy, moreOrLessEquals(40, epsilon: 4));
  });
}

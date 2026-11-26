// A date picker's year grid stays clear of the action row: at 200% text on
// a 390 by 844 phone its last visible row stood under Cancel and OK. On
// opening, the grid ends at the foot of the dialog's scroll, above the
// actions, while the headline keeps its place; the last year, 2100, is
// reached and chosen there.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_ui/material_ui.dart' show GridView, MaterialApp;

Finder _pressable(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(ExpressivePressable))
    .first;

void main() {
  for (final (size, scale) in [
    (const Size(390, 844), 1.0),
    (const Size(390, 844), 2.0),
    (const Size(1440, 900), 1.0),
  ]) {
    testWidgets('${size.width.round()} by ${size.height.round()} at '
        '${(scale * 100).round()}% text: the year grid stands above the '
        'actions, and 2100 is reached and chosen', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: ExpressiveHost(
              theme: ExpressiveThemeData.baseline(),
              brightness: Brightness.light,
              child: app!,
            ),
          ),
          home: Builder(
            builder: (context) => Center(
              child: ExpressiveFilledButton(
                'Open',
                onPressed: () => showExpressiveDatePicker(
                  context: context,
                  initialDate: DateTime(2026, 9, 5),
                  currentDate: DateTime(2026, 9, 5),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(_pressable('Open'));
      await tester.pumpAndSettle();
      final headline = tester.getRect(find.text('Select date'));
      await tester.tap(_pressable('September 2026'));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Select date')), headline);
      final grid = find.byType(GridView);
      final foot = tester.getRect(grid).bottom;
      // The grid's foot stands above the actions' words.
      for (final action in ['Cancel', 'OK']) {
        expect(
          foot,
          lessThanOrEqualTo(tester.getRect(find.text(action)).top),
          reason: action,
        );
      }
      while (find.text('2100').evaluate().isEmpty) {
        await tester.drag(grid, const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle();
      final last = tester.getRect(_pressable('2100'));
      expect(last.bottom, lessThanOrEqualTo(foot));
      await tester.tap(_pressable('2100'));
      await tester.pumpAndSettle();
      expect(find.text('September 2100'), findsOneWidget);
    });
  }
}

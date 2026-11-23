// A combobox's list and its field meet on one rule, as a select's list and
// its button do: the list's edge lies over the field's, below it or above
// it. They stacked two rules (4 px of ink).
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  double width = 390,
  double height = 844,
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) => Directionality(
        textDirection: direction,
        child: BrutalTheme(
          data: brightness == Brightness.light
              ? BrutalThemeData.light()
              : BrutalThemeData.dark(),
          child: BrutalToaster(child: navigator!),
        ),
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final low in [false, true]) {
    for (final direction in TextDirection.values) {
      testWidgets('a combobox ${low ? 'low' : 'high'}, ${direction.name}: '
          'its list meets the field on one rule', (tester) async {
        await _pump(
          tester,
          Align(
            alignment: low
                ? AlignmentDirectional.bottomStart
                : AlignmentDirectional.topStart,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 358,
                child: BrutalCombobox<String>(
                  labelText: 'Venue',
                  options: const ['Hall 1', 'Hall 2', 'Kino Arsenal'],
                  displayStringForOption: (s) => s,
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
          direction: direction,
        );
        await tester.tap(find.byType(EditableText));
        await tester.enterText(find.byType(EditableText), 'a');
        await tester.pumpAndSettle();
        final w = BrutalThemeData.light().borderWidth;
        final field = tester.getRect(find.byType(BrutalTextField));
        final list = tester.getRect(
          find
              .ancestor(
                of: find.text('Hall 1'),
                matching: find.byType(BrutalSurface),
              )
              .last,
        );
        if (list.center.dy > field.center.dy) {
          expect(list.top, moreOrLessEquals(field.bottom - w, epsilon: .5));
        } else {
          expect(list.bottom, moreOrLessEquals(field.top + w, epsilon: .5));
        }
        expect(list.left, moreOrLessEquals(field.left, epsilon: .5));
        expect(list.right, moreOrLessEquals(field.right, epsilon: .5));
      });
    }
  }
}

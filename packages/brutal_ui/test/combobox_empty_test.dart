// A combobox whose typing matches nothing says so in a panel the field's width,
// as its list stands: not a scrap the size of its words.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("a combobox's 'Nothing matches' stands the field's width", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: BrutalTheme(
          data: BrutalThemeData.light(),
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: 600,
                child: BrutalCombobox<String>(
                  label: 'Venue',
                  options: const ['Gallery Nine', 'Library Hall', 'Kino 2'],
                  labelOf: (v) => v,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'Zzz');
    await tester.pumpAndSettle();
    final field = tester.getRect(find.byType(EditableText));
    final words = find.text('Nothing matches');
    expect(words, findsOneWidget);
    final panel = tester.getRect(
      find.ancestor(of: words, matching: find.byType(BrutalSurface)).first,
    );
    expect(panel.width, greaterThan(field.width));
    expect(panel.width, closeTo(600, 4));
  });
}

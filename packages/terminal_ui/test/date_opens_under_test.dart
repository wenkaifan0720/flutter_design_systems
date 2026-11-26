// A date field low on a phone's form brings itself up the page so its
// calendar opens under it, never over the form's title above.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  testWidgets('the calendar opens under a field low on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    DateTime? day;
    await tester.pumpWidget(
      MaterialApp(
        home: TermTheme(
          data: TermThemeData.dark(),
          child: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Column(
                children: [
                  const TermPane(
                    title: 'new book',
                    child: SizedBox(height: 480),
                  ),
                  TermDatePicker(
                    labelText: 'started',
                    value: day,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2030),
                    currentDate: DateTime(2026, 11, 14),
                    onChanged: (d) => setState(() => day = d),
                  ),
                  const SizedBox(height: 600),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('started').first);
    await tester.pumpAndSettle();
    final calendar = tester.getRect(find.byType(TermCalendar));
    final field = tester.getRect(find.byType(TermDatePicker));
    expect(calendar.top, greaterThanOrEqualTo(field.bottom - 1));
    expect(calendar.bottom, lessThanOrEqualTo(700));
  });
}

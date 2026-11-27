// A date field shows its day in the medium form with its year ("2 Oct
// 2026"), one format for every date the app shows, and says the whole date
// to a screen reader. It showed the whole date, weekday and all.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  testWidgets('a date field shows the medium date and says the full one', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final day = DateTime(2026, 10, 2);
    late RawWidgetsLocalizations words;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            ClayTheme(data: ClayThemeData.clay(Brightness.light), child: app!),
        home: Builder(
          builder: (context) {
            words = RawWidgetsLocalizations.of(context);
            return ClayScreen(
              body: ClayDatePicker(
                labelText: 'Date started',
                value: day,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                onChanged: (_) {},
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(words.formatMediumDate(day)), findsOneWidget);
    expect(find.text(words.formatFullDate(day)), findsNothing);
    final node = tester.getSemantics(
      find.descendant(
        of: find.byType(ClayDatePicker),
        matching: find.byType(RawButton),
      ),
    );
    expect(node.getSemanticsData().value, words.formatFullDate(day));
    handle.dispose();
  });
}

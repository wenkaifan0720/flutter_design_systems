// A calendar's days stay apart at twice the text size on a phone: each
// day's figures keep inside its ball, as far from the next day's as
// Material's calendar keeps them.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  setUpAll(clayLoadFonts);

  testWidgets('days stay apart at 2x text on a phone', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => ClayTheme(
          data: ClayThemeData.clay(Brightness.light),
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: app!,
          ),
        ),
        home: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: ClayCalendar(
              firstDate: DateTime(2026),
              lastDate: DateTime(2027, 12, 31),
              selectedDate: DateTime(2026, 11, 21),
              currentDate: DateTime(2026, 11, 21),
              onDateChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // A row's days, as drawn: 8 to 14 November 2026 is Sunday to Saturday.
    final days = [
      for (var d = 8; d <= 14; d++) tester.getRect(find.text('$d')),
    ];
    for (var i = 0; i + 1 < days.length; i++) {
      final gap = days[i + 1].left - days[i].right;
      expect(
        gap,
        greaterThanOrEqualTo(14),
        reason: 'the ${i + 8}th and ${i + 9}th run together ($gap apart)',
      );
    }
  });
}

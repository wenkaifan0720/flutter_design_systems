// A calendar's days stay apart at twice the text size on a phone: each
// day's figures shrink to keep inside their cell (its touch target
// overhangs a narrow month's seventh), so "14" and "13" never run together
// into one number (the gallery's card printed "14131211109").
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  setUpAll(keycapLoadFonts);

  testWidgets('days stay apart at 2x text on a phone', (tester) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    addTearDown(tester.view.reset);
    final controller = RawCalendarController(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      initialMonth: DateTime(2026, 11),
      selectedDate: DateTime(2026, 11, 20),
      currentDate: DateTime(2026, 11, 16),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 2,
          maxScaleFactor: 2,
          child: KeycapHost(brightness: Brightness.light, child: app!),
        ),
        // A calendar in a card on a phone: about 280 wide.
        home: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 280,
            child: SingleChildScrollView(
              child: KeycapCalendar(controller: controller),
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
        greaterThanOrEqualTo(7),
        reason: 'the ${i + 8}th and ${i + 9}th run together ($gap apart)',
      );
    }
  });
}

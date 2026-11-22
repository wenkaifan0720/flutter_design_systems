// A date field low on a phone opens its calendar where the whole month fits:
// the calendar wants its full height before it picks a side, so it stands
// above the field rather than below in a sliver or off the screen's foot.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  final pickers = <String, Widget>{
    'date': KeycapDatePicker(
      label: 'Remind me on',
      value: DateTime(2026, 11, 20),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
    'date range': KeycapDateRangePicker(
      label: 'Show notes from',
      value: RawDateRange(DateTime(2026, 11, 20), DateTime(2026, 11, 24)),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
  };
  for (final MapEntry(key: kind, value: picker) in pickers.entries) {
    for (final above in [300.0, 350.0, 400.0, 450.0, 500.0, 550.0, 600.0]) {
      testWidgets(
        "a $kind field ${above.round()} down: its calendar stays on a phone's "
        'screen',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, app) =>
                  KeycapHost(brightness: Brightness.light, child: app!),
              home: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: above),
                    picker,
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          // The field: the foot of the picker, under its label.
          final field = tester.getRect(find.byWidget(picker));
          await tester.tapAt(field.bottomCenter - const Offset(0, 16));
          await tester.pumpAndSettle();
          final calendar = tester.getRect(find.byType(KeycapCalendar));
          expect(calendar.top, greaterThanOrEqualTo(0));
          expect(
            calendar.bottom,
            lessThanOrEqualTo(844),
            reason: 'the calendar ran off the foot: $calendar',
          );
          // Its whole month shows: a panel that scrolls is no shorter than it.
          final scroll = find.ancestor(
            of: find.byType(KeycapCalendar),
            matching: find.byType(SingleChildScrollView),
          );
          if (scroll.evaluate().isNotEmpty) {
            expect(
              tester.getRect(scroll.first).height,
              greaterThanOrEqualTo(calendar.height - 0.5),
              reason: 'the month was cut short',
            );
          }
        },
      );
    }
  }
}

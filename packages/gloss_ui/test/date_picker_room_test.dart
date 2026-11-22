// A date field low on a phone opens its calendar where the whole month fits:
// the picker asks its popover for the month's full height before it picks a
// side, so the calendar stands above the field rather than running off the
// screen's foot, and shrinks and scrolls only where neither side holds it.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

void main() {
  final pickers = <String, Widget>{
    'date': GlossDatePicker(
      label: 'Cook on',
      value: DateTime(2026, 11, 20),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
    'date range': GlossDateRangePicker(
      label: 'Cook on',
      value: GlossDateRange(
        start: DateTime(2026, 11, 20),
        end: DateTime(2026, 11, 24),
      ),
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
              home: GlossTheme(
                data: GlossThemeData.light(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(height: above),
                      picker,
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          // The field: the foot of the picker, under its label.
          final field = tester.getRect(find.byWidget(picker));
          await tester.tapAt(field.bottomCenter - const Offset(0, 16));
          await tester.pumpAndSettle();
          final calendar = tester.getRect(find.byType(GlossCalendar));
          expect(calendar.top, greaterThanOrEqualTo(0));
          expect(
            calendar.bottom,
            lessThanOrEqualTo(844),
            reason: 'the calendar ran off the foot: $calendar',
          );
        },
      );
    }
  }
}

// A date chosen low on a phone opens a calendar that stays whole on the screen, its full month showing. Retro opens
// no calendar from a field: its date picker and its range picker are calendars on the page, and a date is chosen in a
// window, the date dialog, which stands in the middle of the screen under the menu bar wherever the button that opened
// it stands. So here the button stands 300 to 600 down a 390 by 844 phone, opens the date dialog, or a dialog with the
// range picker in it, and the calendar must lie within the screen and be as tall as when the button stands at the top.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

typedef _Opener = void Function(BuildContext context);

final _openers = <String, (_Opener, Type)>{
  'date': (
    (context) => showRetroDesktopDatePicker(
      context,
      value: DateTime(2026, 11, 20),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
    ),
    RetroDesktopDatePicker,
  ),
  'date range': (
    (context) => showRetroDesktopDialog<void>(
      context,
      builder: (context) => RetroDesktopDialog(
        title: 'Stay',
        content: [
          RetroDesktopDateRangePicker(
            firstDate: DateTime(2026),
            lastDate: DateTime(2027, 12, 31),
            value: RawDateRange(DateTime(2026, 11, 20), DateTime(2026, 11, 24)),
            onChanged: (_) {},
          ),
        ],
        actions: const [
          RetroDesktopDialogAction<void>('Done', isDefaultAction: true),
        ],
      ),
    ),
    RetroDesktopCalendar,
  ),
};

// The calendar's rect once the button [above] down a phone opens it.
Future<Rect> _opened(WidgetTester tester, String kind, double above) async {
  final (open, calendar) = _openers[kind]!;
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // A fresh app each time: the last one's window closes with it.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    retroDesktopApp(
      Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: above),
            RetroDesktopButton('Due', onPressed: () => open(context)),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Due'));
  await tester.pumpAndSettle();
  return tester.getRect(find.byType(calendar));
}

void main() {
  setUpAll(loadRetroDesktopFonts);
  for (final kind in _openers.keys) {
    for (final above in [300.0, 350.0, 400.0, 450.0, 500.0, 550.0, 600.0]) {
      testWidgets(
        "a $kind button ${above.round()} down: its calendar stays whole on a "
        "phone's screen",
        (tester) async {
          final atTop = await _opened(tester, kind, 0);
          final calendar = await _opened(tester, kind, above);
          expect(calendar.top, greaterThanOrEqualTo(0), reason: '$calendar');
          expect(
            calendar.bottom,
            lessThanOrEqualTo(844),
            reason: 'the calendar ran off the foot: $calendar',
          );
          expect(
            calendar.height,
            closeTo(atTop.height, .5),
            reason: 'the full month shows: $calendar, $atTop at the top',
          );
        },
      );
    }
  }
}

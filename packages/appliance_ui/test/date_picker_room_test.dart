// A date field low on a phone opens its calendar where the whole month fits:
// the calendar stands above the field rather than running off the screen's
// foot, and shows every week, as tall as it opens at the top of the screen,
// with nothing scrolled out of its plate.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _phone = Size(390, 844);

/// Opens [picker] [above] points down a 390 by 844 phone and gives the open
/// calendar's rect and its plate's.
Future<(Rect calendar, Rect plate)> _open(
  WidgetTester tester,
  Widget picker,
  double above,
) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
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
  // The key: the foot of the picker, under its label.
  final field = tester.getRect(find.byWidget(picker));
  await tester.tapAt(field.bottomCenter - const Offset(0, 16));
  await tester.pumpAndSettle();
  return (
    tester.getRect(find.byType(ApplianceCalendar)),
    tester.getRect(find.byType(ApplianceMenuPlate)),
  );
}

void main() {
  setUpAll(applianceLoadFonts);

  final pickers = <String, Widget>{
    'date': ApplianceDatePicker(
      label: 'Due',
      value: DateTime(2026, 11, 20),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
    'date range': ApplianceDateRangePicker(
      label: 'Away',
      value: RawDateRange(DateTime(2026, 11, 20), DateTime(2026, 11, 24)),
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
  };
  for (final MapEntry(key: kind, value: picker) in pickers.entries) {
    for (final above in [300.0, 350.0, 400.0, 450.0, 500.0, 550.0, 600.0]) {
      testWidgets("a $kind field ${above.round()} down: its calendar stays "
          "whole on a phone's screen", (tester) async {
        tester.view.physicalSize = _phone;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final (top, _) = await _open(tester, picker, 0);
        final (calendar, plate) = await _open(tester, picker, above);
        expect(calendar.top, greaterThanOrEqualTo(0));
        expect(
          calendar.bottom,
          lessThanOrEqualTo(_phone.height),
          reason: 'the calendar ran off the foot: $calendar',
        );
        expect(
          calendar.height,
          top.height,
          reason: 'the calendar opened shorter than its month: $calendar',
        );
        expect(
          plate.top <= calendar.top && calendar.bottom <= plate.bottom,
          isTrue,
          reason: 'the plate $plate clips the calendar $calendar',
        );
      });
    }
  }
}

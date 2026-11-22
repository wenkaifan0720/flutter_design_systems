// A date picker called up from low on a phone shows its whole month on the screen. Neumorphism raises its calendars in
// a sheet from the phone's foot (showNeumorphicDatePicker) and in a dialog (showNeumorphicDateRangePicker), not beside
// the field, so where the field sits must not matter: the month lies within the screen, at the height it has when
// called up from the top. August 2026 runs over six weeks however the week starts, the tallest a month stands.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

const _screen = Size(390, 844);

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadNeumorphicGlyphs();
  });

  final pickers = <String, (Type, void Function(BuildContext))>{
    'date': (
      NeumorphicDatePicker,
      (context) => showNeumorphicDatePicker(
        context,
        value: DateTime(2026, 8, 20),
        first: DateTime(2026),
        last: DateTime(2027, 12, 31),
        today: DateTime(2026, 8, 20),
      ),
    ),
    'date range': (
      NeumorphicDateRangePicker,
      (context) => showNeumorphicDateRangePicker(
        context,
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        initialDateRange: RawDateRange(
          DateTime(2026, 8, 20),
          DateTime(2026, 8, 24),
        ),
      ),
    ),
  };

  /// Calls the picker up from a field [above] pt down a phone's page, reads the calendar's rect, and closes it.
  Future<Rect> openFrom(
    WidgetTester tester,
    double above,
    Type calendar,
    void Function(BuildContext) open,
  ) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // A fresh app each time: an app kept between pumps keeps its first page.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      neumorphicApp(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: above),
              Builder(
                builder: (context) =>
                    NeumorphicButton('Due', onPressed: () => open(context)),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(NeumorphicButton)).dy,
      greaterThanOrEqualTo(above),
    );
    await tester.tap(find.text('Due'));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(calendar));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(calendar), findsNothing);
    return rect;
  }

  for (final MapEntry(key: kind, value: (calendar, open)) in pickers.entries) {
    for (final above in [300.0, 350.0, 400.0, 450.0, 500.0, 550.0, 600.0]) {
      testWidgets(
        "a $kind picker called up ${above.round()} down shows its whole month on a phone's screen",
        (tester) async {
          final atTop = await openFrom(tester, 0, calendar, open);
          final rect = await openFrom(tester, above, calendar, open);
          expect(rect.top, greaterThanOrEqualTo(0), reason: '$rect');
          expect(
            rect.bottom,
            lessThanOrEqualTo(_screen.height),
            reason: 'the calendar ran off the foot: $rect',
          );
          expect(
            rect.height,
            moreOrLessEquals(atTop.height),
            reason: 'the month was cut short: $rect, at the top $atTop',
          );
        },
      );
    }
  }
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

// A day's number is written in the app's digits, as Material's day picker
// writes it (formatDecimal); the month's header in the app's words and
// digits (formatMonthYear).

final Map<DateTime, String> _days = {};
String? _header;

Widget _calendar(RawCalendarController c, Locale locale) => harness(
  Localizations(
    locale: locale,
    delegates: const [
      RawWidgetsLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    child: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 340,
        child: RawCalendarDatePicker(
          controller: c,
          headerBuilder: (context, header) {
            _header = header.label;
            return Text(header.label);
          },
          dayBuilder: (context, day, states) {
            _days[day.date] = day.label;
            return Text(day.label);
          },
        ),
      ),
    ),
  ),
  textDirection: locale.languageCode == 'ar'
      ? TextDirection.rtl
      : TextDirection.ltr,
);

RawCalendarController _controller() => RawCalendarController(
  firstDate: DateTime(2025),
  lastDate: DateTime(2027, 12, 31),
  initialMonth: DateTime(2026, 11),
  currentDate: DateTime(2026, 11, 2),
);

void main() {
  setUp(() {
    _days.clear();
    _header = null;
  });

  testWidgets('in Arabic a day reads in Arabic-Indic digits, as its month '
      'and year do', (tester) async {
    final c = _controller();
    addTearDown(c.dispose);
    await tester.pumpWidget(_calendar(c, const Locale('ar')));
    await tester.pumpAndSettle();
    expect(_days[DateTime(2026, 11, 20)], '٢٠');
    expect(find.text('٢٠'), findsOneWidget);
    expect(find.text('20'), findsNothing);
    expect(_header, contains('٢٠٢٦'));
    expect(_header, isNot(contains('2026')));
  });

  testWidgets('in English a day reads 20', (tester) async {
    final c = _controller();
    addTearDown(c.dispose);
    await tester.pumpWidget(_calendar(c, const Locale('en')));
    await tester.pumpAndSettle();
    expect(_days[DateTime(2026, 11, 20)], '20');
    expect(_days[DateTime(2026, 11, 9)], '9');
    expect(_header, 'November 2026');
  });

  test('a day made without a label reads its number in ASCII digits', () {
    final day = RawCalendarDayDetails(
      date: DateTime(2026, 11, 20),
      inMonth: true,
      isToday: false,
      selected: false,
      isRangeStart: false,
      isRangeEnd: false,
      inRange: false,
      inPreview: false,
      isPreviewEnd: false,
      enabled: true,
      focused: false,
    );
    expect(day.label, '20');
  });
}

// A date field low on a phone opens its calendar where the whole month fits:
// the calendar stands below the field when it fits there whole, else above
// it, never running off the screen's foot or cut to part of a month.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

Widget _host(double above, Widget picker) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: MinimalScaffold(
    padding: EdgeInsets.zero,
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: above),
          picker,
        ],
      ),
    ),
  ),
);

final _pickers = <String, (Widget, Finder Function())>{
  'date': (
    MinimalDatePicker(
      labelText: 'Due',
      value: DateTime(2026, 11, 20),
      mode: MinimalDatePickerMode.date,
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
    // The open calendar: the inline picker inside the popover.
    () => find.byType(MinimalDatePicker).last,
  ),
  'date range': (
    MinimalDateRangePicker(
      labelText: 'Stay',
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (_) {},
    ),
    // The open calendar: the panel round the range's months.
    () => find
        .byWidgetPredicate((w) => w.runtimeType.toString() == 'MinimalKitPanel')
        .last,
  ),
};

/// Opens the picker with its field [above] points down a 390 x 844 phone and
/// returns where its calendar stands.
Future<Rect> _open(WidgetTester tester, String kind, double above) async {
  final (picker, calendar) = _pickers[kind]!;
  // A fresh page, with nothing open over it.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(_host(above, picker));
  await tester.pumpAndSettle();
  await tester.tap(
    find
        .descendant(
          of: find.byWidget(picker),
          matching: find.byType(MinimalPressable),
        )
        .first,
  );
  await tester.pumpAndSettle();
  return tester.getRect(calendar());
}

void main() {
  for (final kind in _pickers.keys) {
    for (final above in [300.0, 350.0, 400.0, 450.0, 500.0, 550.0, 600.0]) {
      testWidgets("a $kind field ${above.round()} down: its whole calendar "
          "stays on a phone's screen", (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final whole = await _open(tester, kind, 40);
        final low = await _open(tester, kind, above);
        expect(low.top, greaterThanOrEqualTo(0));
        expect(
          low.bottom,
          lessThanOrEqualTo(844),
          reason: 'the calendar ran off the foot: $low',
        );
        expect(
          low.height,
          closeTo(whole.height, 0.5),
          reason: 'the calendar was cut short: $low against $whole',
        );
      });
    }
  }
}

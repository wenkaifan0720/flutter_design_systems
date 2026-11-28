// An open date field's month is named for what it is, "Select date" from the
// app's localizations, not with the field's label: a screen reader heard the
// label twice while the month was open ("Date started" on the field, and
// again on the month that stood over it).
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

final _day = DateTime(2026, 11, 20);

final _fields = <String, (String, Widget Function())>{
  'a date field': (
    'Date started',
    () => ClayDatePicker(
      labelText: 'Date started',
      value: _day,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      onChanged: (_) {},
    ),
  ),
  'a date-range field': (
    'Break',
    () => ClayDateRangePicker(
      labelText: 'Break',
      value: ClayDateRange(start: _day, end: _day.add(const Duration(days: 4))),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      onChanged: (_) {},
    ),
  ),
};

void main() {
  setUpAll(clayLoadFonts);

  for (final MapEntry(key: name, value: (label, build)) in _fields.entries) {
    testWidgets('$name names its open month "Select date", not its label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final field = build();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ClayHost(child: child!),
          home: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: SizedBox(width: 358, child: field),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final named = find.bySemanticsLabel(
        RegExp('(^|\n)${RegExp.escape(label)}(\n|\$)'),
      );
      final before = named.evaluate().length;
      final rect = tester.getRect(find.byWidget(field));
      await tester.tapAt(rect.bottomCenter - const Offset(0, 16));
      await tester.pumpAndSettle();
      expect(
        named.evaluate().length,
        before,
        reason: 'the open month said the field\'s label again',
      );
      expect(
        find.bySemanticsLabel('Select date'),
        findsOneWidget,
        reason: 'the open month is named for what it is',
      );
      handle.dispose();
    });
  }
}

// A field's control says its label once, and its value once: the field
// names it (ClayFieldDecorator), so the control adds no name of its own, and
// a chosen day is said in full as its value, not again in short in its name.
// A select, a date field and a date-range field said their label twice
// ("Date started Date started"), and a date field said its day twice.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

final _day = DateTime(2026, 11, 20);

final _fields = <String, (String, Widget Function())>{
  'a select': (
    'Repeat',
    () => ClaySelect<String>(
      labelText: 'Repeat',
      helperText: 'Optional',
      value: 'daily',
      items: const [ClaySelectItem(value: 'daily', label: 'Every day')],
      onChanged: (_) {},
    ),
  ),
  'an empty date field': (
    'Date started',
    () => ClayDatePicker(
      labelText: 'Date started',
      helperText: 'Optional',
      value: null,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      onChanged: (_) {},
    ),
  ),
  'a date field with a day': (
    'Date started',
    () => ClayDatePicker(
      labelText: 'Date started',
      value: _day,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      onChanged: (_) {},
    ),
  ),
  'an empty date-range field': (
    'Break',
    () => ClayDateRangePicker(
      labelText: 'Break',
      helperText: 'Optional',
      value: null,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      onChanged: (_) {},
    ),
  ),
  'a date-range field with a span': (
    'Break',
    () => ClayDateRangePicker(
      labelText: 'Break',
      value: ClayDateRange(start: _day, end: _day.add(const Duration(days: 4))),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      onChanged: (_) {},
    ),
  ),
  'a time field': (
    'Wake at',
    () => ClayTimeField(labelText: 'Wake at', value: null, onChanged: (_) {}),
  ),
  'an input': ('Name', () => const ClayInput(labelText: 'Name')),
  'a text field': ('Title', () => const ClayTextField(labelText: 'Title')),
};

void main() {
  setUpAll(clayLoadFonts);

  for (final MapEntry(key: name, value: (label, field)) in _fields.entries) {
    testWidgets('$name says its label once, and its value once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => ClayHost(child: child!),
          home: Center(child: SizedBox(width: 358, child: field())),
        ),
      );
      await tester.pumpAndSettle();
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}')).first,
      );
      final data = node.getSemanticsData();
      final words = data.label.split('\n');
      expect(
        words.where((w) => w == label),
        hasLength(1),
        reason: 'said as "${data.label}"',
      );
      if (data.value.isNotEmpty) {
        // The value is said once: none of its words is said again in the
        // name, in another form.
        expect(
          words,
          hasLength(1),
          reason: 'said as "${data.label}" "${data.value}"',
        );
      }
      handle.dispose();
    });
  }
}

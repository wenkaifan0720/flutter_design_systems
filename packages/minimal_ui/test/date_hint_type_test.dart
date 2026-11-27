// A date pill prints a date in the mono face, as every Minimal figure; unset,
// it says so in the sans at the same size, words not being figures.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<TextStyle> _styleOf(WidgetTester tester, DateTime? value) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          MinimalHost(brightness: Brightness.light, child: app!),
      home: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 360,
          child: MinimalDatePicker(
            labelText: 'Started',
            value: value,
            hintText: 'Not yet',
            mode: MinimalDatePickerMode.date,
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final shown = value == null
      ? find.text('Not yet')
      : find.descendant(
          of: find.byType(MinimalDatePicker),
          matching: find.textContaining('2026'),
        );
  return tester.widget<Text>(shown.first).style!;
}

void main() {
  testWidgets('an unset date pill speaks in the sans, a date in mono', (
    tester,
  ) async {
    final hint = await _styleOf(tester, null);
    final t = tester.element(find.byType(MinimalDatePicker)).minimalTheme;
    expect(hint.fontFamily, t.body.fontFamily);
    expect(hint.color, t.mutedForeground);
    final date = await _styleOf(tester, DateTime(2026, 11, 18));
    expect(date.fontFamily, t.mono.fontFamily);
    expect(hint.fontSize, date.fontSize);
  });
}

// A date picker opened from the keys holds the focus on its chosen day, in its
// popover and in its sheet: the arrow keys step from that day.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

Widget _app(Widget child) => MaterialApp(
  builder: (context, app) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: app!,
  ),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(24), child: child),
  ),
);

// Tabs to the date and opens it with Enter.
Future<void> _openFromKeys(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(minimalLoadFonts);

  testWidgets('a date picker opened from the keys walks on from its chosen '
      'day', (tester) async {
    final picked = <DateTime>[];
    await tester.pumpWidget(
      _app(
        MinimalDatePicker(
          labelText: 'Due',
          value: DateTime(2026, 3, 12, 9),
          mode: MinimalDatePickerMode.date,
          currentDate: DateTime(2026, 3, 2),
          onChanged: picked.add,
        ),
      ),
    );
    await _openFromKeys(tester);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Calendar days');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(picked, [DateTime(2026, 3, 13, 9)]);
  });

  testWidgets('a date picker in a sheet opens with its calendar focused', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MinimalDatePicker(
          labelText: 'Due',
          value: DateTime(2026, 3, 12, 9),
          mode: MinimalDatePickerMode.date,
          confirmSelection: true,
          onChanged: (_) {},
        ),
      ),
    );
    await _openFromKeys(tester);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Calendar days');
  });
}

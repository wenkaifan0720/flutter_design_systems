// A field's first words take Flutter's name, `initialValue`, on the text field, the text area and the stub input;
// `initial`, the name before 0.8.1, still gives them (dart fix moves it, test_fixes/renamed_0_8_1.dart).
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

Future<String> _shown(WidgetTester tester, Widget field) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          RetroDesktopTheme(data: RetroDesktopThemeData.classic(), child: app!),
      home: Center(child: SizedBox(width: 320, child: field)),
    ),
  );
  await tester.pumpAndSettle();
  return tester.widget<EditableText>(find.byType(EditableText)).controller.text;
}

void main() {
  final fields = <String, Widget Function({String? now, String? before})>{
    'text field': ({now, before}) =>
        RetroDesktopTextField(initialValue: now, initial: before),
    'text area': ({now, before}) =>
        RetroDesktopTextArea(initialValue: now, initial: before),
    'input': ({now, before}) =>
        RetroDesktopInput(initialValue: now, initial: before),
  };
  for (final MapEntry(key: name, value: build) in fields.entries) {
    testWidgets('a $name shows its initialValue', (tester) async {
      expect(await _shown(tester, build(now: 'Pepper')), 'Pepper');
    });
    testWidgets("a $name shows the words given by the old name", (
      tester,
    ) async {
      expect(await _shown(tester, build(before: 'Salt')), 'Salt');
    });
  }

  test('the old name and initialValue hold the same words', () {
    expect(const RetroDesktopTextField(initial: 'Salt').initialValue, 'Salt');
    expect(const RetroDesktopTextArea(initial: 'Salt').initialValue, 'Salt');
    expect(const RetroDesktopInput(initial: 'Salt').initialValue, 'Salt');
    expect(
      const RetroDesktopTextField(initialValue: 'Pepper').initial,
      'Pepper',
    );
  });
}

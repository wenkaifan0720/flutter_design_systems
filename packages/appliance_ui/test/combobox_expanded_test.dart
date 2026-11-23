// A combobox and a tag input say on their text input whether their list is
// open: closed at rest, open while it shows, closed again after Escape, and a
// tag input holding tags says it as one with none does.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(WidgetTester tester, Widget field) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
      home: Scaffold(
        body: Center(child: SizedBox(width: 320, child: field)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectExpanded(WidgetTester tester, bool open) => expect(
  tester.getSemantics(find.byType(EditableText)),
  isSemantics(isTextField: true, hasExpandedState: true, isExpanded: open),
);

Future<void> _openAndClose(
  WidgetTester tester,
  String typed,
  String shown,
) async {
  _expectExpanded(tester, false);
  await tester.tap(find.byType(EditableText));
  await tester.enterText(find.byType(EditableText), typed);
  await tester.pumpAndSettle();
  expect(find.text(shown), findsOneWidget);
  _expectExpanded(tester, true);
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
  expect(find.text(shown), findsNothing);
  _expectExpanded(tester, false);
}

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets('a combobox says on its text input whether its list is open', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _show(
      tester,
      ApplianceCombobox<String>(
        labelText: 'Town',
        options: const ['Bristol', 'Leeds'],
        onSelected: (_) {},
      ),
    );
    await _openAndClose(tester, 'Le', 'Leeds');
    semantics.dispose();
  });

  for (final values in const [
    <String>[],
    ['Hall'],
  ]) {
    testWidgets(
      'a tag input ${values.isEmpty ? 'with no tags' : 'holding a tag'} says '
      'on its text input whether its list is open',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _show(
          tester,
          ApplianceTagInput<String>(
            labelText: 'Rooms',
            values: values,
            options: const ['Hall', 'Kitchen'],
            onChanged: (_) {},
          ),
        );
        await _openAndClose(tester, 'Ki', 'Kitchen');
        semantics.dispose();
      },
    );
  }
}

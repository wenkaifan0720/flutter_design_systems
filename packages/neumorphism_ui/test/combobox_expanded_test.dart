// A combobox's and a multi-select's text input say whether their list is open: expanded while it shows, collapsed
// once Escape closes it, with tags in the field or none.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

Widget _host(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) =>
      NeumorphicHost(brightness: Brightness.light, child: app!),
  home: Scaffold(body: home),
);

void _expectExpanded(WidgetTester tester, bool open) => expect(
  tester.getSemantics(find.byType(EditableText)),
  isSemantics(isTextField: true, hasExpandedState: true, isExpanded: open),
);

void main() {
  setUpAll(loadNeumorphicFonts);

  testWidgets('a combobox says on its text input whether its list is open', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Center(
          child: SizedBox(
            width: 300,
            child: NeumorphicCombobox<String>(
              labelText: 'Room',
              options: const ['Kitchen', 'Study'],
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    _expectExpanded(tester, false);
    await tester.tap(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'S');
    await tester.pumpAndSettle();
    expect(find.text('Study'), findsOneWidget);
    _expectExpanded(tester, true);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Study'), findsNothing);
    _expectExpanded(tester, false);
    semantics.dispose();
  });

  for (final values in const [
    <String>[],
    ['Kitchen'],
  ]) {
    testWidgets(
      'a multi-select ${values.isEmpty ? 'with no tags' : 'with a tag'} says on its text input whether its list is open',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(
            Center(
              child: SizedBox(
                width: 320,
                child: NeumorphicMultiSelect<String>(
                  labelText: 'Rooms',
                  options: const ['Kitchen', 'Study'],
                  values: values,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        );
        _expectExpanded(tester, false);
        await tester.tap(find.byType(EditableText));
        await tester.enterText(find.byType(EditableText), 'S');
        await tester.pumpAndSettle();
        expect(find.text('Study'), findsOneWidget);
        _expectExpanded(tester, true);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Study'), findsNothing);
        _expectExpanded(tester, false);
        semantics.dispose();
      },
    );
  }
}

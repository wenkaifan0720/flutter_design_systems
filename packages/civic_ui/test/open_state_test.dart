// What a list's field says while the list is open: a combobox's and a
// multi-select's text input reads expanded while its options show and
// collapsed once Escape closes them, and the combobox's chevron points up as
// the select's does. A select opened from the keys puts them on its chosen
// answer.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/kit.dart';
import 'screens_matrix.dart';

Future<void> _pump(WidgetTester tester, Widget field) => showScreen(
  tester,
  kitApp(
    brightness: Brightness.light,
    home: Align(
      alignment: Alignment.topCenter,
      child: Padding(padding: const EdgeInsets.all(16), child: field),
    ),
  ),
  width: 390,
  height: 844,
);

// The words of the widget the keys are on.
Finder _focused(String text) => find.descendant(
  of: find.byElementPredicate(
    (e) => e == FocusManager.instance.primaryFocus?.context,
  ),
  matching: find.text(text),
);

void main() {
  final fields = <String, Widget>{
    'combobox': const CivicCombobox<String>(
      labelText: 'Street',
      options: ['Mill Lane', 'Mill Road', 'Dock Lane'],
    ),
    'multi-select': CivicMultiSelect<String>(
      labelText: 'Streets',
      values: const [],
      options: const ['Mill Lane', 'Mill Road', 'Dock Lane'],
      onChanged: (_) {},
    ),
  };
  for (final MapEntry(key: kind, value: field) in fields.entries) {
    testWidgets("a $kind's text input reads expanded while its list is open", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, field);
      final input = find.byType(EditableText);
      expect(
        tester.getSemantics(input),
        isSemantics(
          isTextField: true,
          hasExpandedState: true,
          isExpanded: false,
        ),
      );
      await tester.showKeyboard(input);
      await tester.enterText(input, 'Mill');
      await tester.pumpAndSettle();
      expect(find.text('Mill Road'), findsOneWidget);
      expect(
        tester.getSemantics(input),
        isSemantics(
          isTextField: true,
          hasExpandedState: true,
          isExpanded: true,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Mill Road'), findsNothing);
      expect(
        tester.getSemantics(input),
        isSemantics(
          isTextField: true,
          hasExpandedState: true,
          isExpanded: false,
        ),
      );
      semantics.dispose();
    });
  }

  testWidgets("a combobox's chevron points up while its list is open", (
    tester,
  ) async {
    await _pump(tester, fields['combobox']!);
    expect(find.byIcon(LucideIcons.chevronDown), findsOneWidget);
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'Mill');
    await tester.pumpAndSettle();
    expect(find.byIcon(LucideIcons.chevronUp), findsOneWidget);
    expect(find.byIcon(LucideIcons.chevronDown), findsNothing);
  });

  testWidgets('a select opened from the keys puts them on its chosen answer', (
    tester,
  ) async {
    await _pump(
      tester,
      CivicSelect<int>(
        labelText: 'Zone',
        value: 3,
        items: [
          for (var i = 1; i <= 6; i++)
            CivicSelectItem(value: i, label: 'Zone $i'),
        ],
        onChanged: (_) {},
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Zone 6'), findsOneWidget);
    expect(
      _focused('Zone 3'),
      findsOneWidget,
      reason: 'the keys are on ${FocusManager.instance.primaryFocus}',
    );
    // On the answer itself, not on the list round it.
    expect(_focused('Zone 4'), findsNothing);
  });
}

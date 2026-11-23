// What a list's field says while the list is open: a combobox's and a tag
// input's text input reads expanded while its options show and collapsed
// once Escape closes them, and the combobox's mark turns over as the
// select's does. A select opened from the keys puts them on its chosen
// option, and a date picker on its chosen day.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:brutal_ui/src/brutal/internal/drop_mark.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// The words of the widget the keys are on.
Finder _focused(String text) => find.descendant(
  of: find.byElementPredicate(
    (e) => e == FocusManager.instance.primaryFocus?.context,
  ),
  matching: find.text(text),
);

Future<void> _pump(WidgetTester tester, Widget field) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: BrutalTheme(
        data: BrutalThemeData.light(),
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(padding: const EdgeInsets.all(24), child: field),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final fields = <String, Widget>{
    'combobox': BrutalCombobox<String>(
      labelText: 'Venue',
      options: const ['Hall 1', 'Hall 2', 'Kino'],
      displayStringForOption: (v) => v,
    ),
    'tag input': BrutalTagInput<String>(
      labelText: 'Kinds',
      values: const [],
      options: const ['Hall 1', 'Hall 2', 'Kino'],
      displayStringForOption: (v) => v,
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
      await tester.enterText(input, 'Hall');
      await tester.pumpAndSettle();
      expect(find.text('Hall 2'), findsOneWidget);
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
      expect(find.text('Hall 2'), findsNothing);
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

  testWidgets("a combobox's mark turns over while its list is open", (
    tester,
  ) async {
    await _pump(tester, fields['combobox']!);
    bool open() =>
        tester.widget<BrutalDropMark>(find.byType(BrutalDropMark)).open;
    expect(open(), isFalse);
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'Hall');
    await tester.pumpAndSettle();
    expect(open(), isTrue);
  });

  testWidgets('a select opened from the keys puts them on its chosen option', (
    tester,
  ) async {
    await _pump(
      tester,
      BrutalSelect<int>(
        labelText: 'Row',
        value: 3,
        items: [
          for (var i = 1; i <= 6; i++)
            BrutalSelectItem(value: i, label: 'Row $i'),
        ],
        onChanged: (_) {},
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Row 6'), findsOneWidget);
    expect(
      _focused('Row 3'),
      findsOneWidget,
      reason: 'the keys are on ${FocusManager.instance.primaryFocus}',
    );
    // On the option itself, not on the list round it.
    expect(_focused('Row 4'), findsNothing);
  });

  testWidgets('a date picker opened from the keys puts them on its chosen '
      'day', (tester) async {
    DateTime? picked;
    await _pump(
      tester,
      BrutalDatePicker(
        labelText: 'Due',
        value: DateTime(2026, 11, 20),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (day) => picked = day,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(BrutalCalendar), findsOneWidget);
    // ui_core's calendar holds the keys on its grid and walks a day among
    // its days: one step on and Enter take the day after the chosen one.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      picked,
      DateTime(2026, 11, 21),
      reason: 'the keys are on ${FocusManager.instance.primaryFocus}',
    );
  });
}

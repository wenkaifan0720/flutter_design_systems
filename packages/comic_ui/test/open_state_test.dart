// What a list's field says while the list is open: a combobox's and a
// multi-select's text input reads expanded while its options show and
// collapsed once Escape closes them, and the combobox's chevron turns up as
// its list opens. A select opened from the keys puts them on its chosen
// option, and the date picker on its chosen day.
import 'package:comic_ui/comic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

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
    comicApp(
      Align(
        alignment: Alignment.topCenter,
        child: Padding(padding: const EdgeInsets.all(24), child: field),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadComicFonts);

  final fields = <String, Widget>{
    'combobox': ComicCombobox<String>(
      labelText: 'Venue',
      options: const ['Hall 1', 'Hall 2', 'Kino'],
      displayStringForOption: (v) => v,
    ),
    'multi-select': ComicMultiSelect<String>(
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

  testWidgets("a combobox's chevron turns up while its list is open", (
    tester,
  ) async {
    await _pump(tester, fields['combobox']!);
    expect(find.byIcon(ComicGlyphs.chevronDown), findsOneWidget);
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'Hall');
    await tester.pumpAndSettle();
    expect(find.byIcon(ComicGlyphs.chevronUp), findsOneWidget);
    expect(find.byIcon(ComicGlyphs.chevronDown), findsNothing);
  });

  testWidgets('a select opened from the keys puts them on its chosen option', (
    tester,
  ) async {
    await _pump(
      tester,
      ComicSelect<int>(
        labelText: 'Row',
        value: 3,
        options: [for (var i = 1; i <= 6; i++) ComicSelectOption(i, 'Row $i')],
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

  testWidgets('the date picker puts the keys on its chosen day', (
    tester,
  ) async {
    await _pump(
      tester,
      Builder(
        builder: (context) => ComicButton(
          'Due',
          onPressed: () => showComicDatePicker(
            context,
            value: DateTime(2026, 11, 20),
            firstDate: DateTime(2026),
            lastDate: DateTime(2027, 12, 31),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ComicButton));
    await tester.pumpAndSettle();
    expect(find.byType(ComicDatePicker), findsOneWidget);
    expect(
      _focused('20'),
      findsOneWidget,
      reason: 'the keys are on ${FocusManager.instance.primaryFocus}',
    );
    // On the day itself, not on the calendar round it.
    expect(_focused('21'), findsNothing);
  });
}

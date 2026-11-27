// The example app, Shelf, as a reader uses it: a book opened from the list
// and back again on a phone and beside the rail on a desktop; a book added
// (its missing title said first), one deleted after the dialog's answer, a
// date chosen, and the appearance and palette changed.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui_example/main.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _open(WidgetTester tester, {double width = 390}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ShelfApp(shelf: Shelf.sample()));
  await tester.pumpAndSettle();
}

/// Scrolls [target] into view and taps it.
Future<void> _press(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Lets a snackbar's time run out, so no timer is left when the test ends.
Future<void> _wait(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 30));
  await tester.pumpAndSettle();
}

/// A book only the list shows.
final _list = find.text('Things Fall Apart');

final _back = find.byIcon(ExpressiveSymbols.arrowBack);

/// The Settings place's press target, where it can be pressed.
final _settingsPlace = find
    .byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          (widget.properties.label?.startsWith('Settings') ?? false),
    )
    .hitTestable();

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('a book opens on a page of its own and back returns to the '
        'list (${width.toInt()})', (tester) async {
      await _open(tester, width: width);
      expect(_list, findsOneWidget);
      await tester.tap(find.text('Middlemarch'));
      await tester.pumpAndSettle();
      expect(find.text('George Eliot'), findsOneWidget);
      // A phone's bar steps aside for the pushed page; a desktop's rail
      // stays beside it.
      expect(_settingsPlace, width < 600 ? findsNothing : findsOneWidget);
      await tester.tap(_back);
      await tester.pumpAndSettle();
      expect(_list, findsOneWidget);
      expect(_settingsPlace, findsOneWidget);
    });
  }

  testWidgets('a book without a title is not saved: the problem is said at '
      'the field', (tester) async {
    await _open(tester);
    await tester.tap(find.byIcon(ExpressiveSymbols.add));
    await tester.pumpAndSettle();
    await _press(tester, find.text('Save book'));
    expect(find.text('Enter the book’s title'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(ExpressiveTextField).first,
        matching: find.byType(EditableText),
      ),
      'Small Things Like These',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('Enter the book’s title'), findsNothing);
    await _press(tester, find.text('Save book'));
    expect(_list, findsOneWidget);
    expect(find.text('Small Things Like These'), findsOneWidget);
    expect(find.text('Added “Small Things Like These”'), findsOneWidget);
    await _wait(tester);
  });

  testWidgets('an optional date is chosen in the form, printed with its year', (
    tester,
  ) async {
    await _open(tester);
    await tester.tap(find.byIcon(ExpressiveSymbols.add));
    await tester.pumpAndSettle();
    final field = find.byType(ExpressiveDockedDatePicker);
    final medium = RegExp(r'^\d{1,2} [A-Z][a-z]{2} \d{4}$');
    expect(
      find.descendant(of: field, matching: find.textContaining(medium)),
      findsNothing,
    );
    await _press(tester, field);
    await tester.tap(find.text('15').last);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: field, matching: find.textContaining(medium)),
      findsOneWidget,
    );
  });

  testWidgets("a book is deleted only on the dialog's answer", (tester) async {
    await _open(tester);
    await _press(tester, find.text('Beloved'));
    await _press(tester, find.text('Delete book'));
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(find.text('Toni Morrison'), findsOneWidget);
    await _press(tester, find.text('Delete book'));
    await tester.tap(find.text('Delete book').last);
    await tester.pumpAndSettle();
    expect(_list, findsOneWidget);
    expect(find.text('Toni Morrison'), findsNothing);
    expect(find.text('Deleted “Beloved”'), findsOneWidget);
    await _wait(tester);
  });

  testWidgets('the settings change the appearance and the palette', (
    tester,
  ) async {
    await _open(tester);
    await tester.tap(find.byIcon(ExpressiveSymbols.settings));
    await tester.pumpAndSettle();
    final ember = ExpressiveThemeData.palettes.firstWhere(
      (p) => p.id == 'ember',
    );
    ExpressiveThemeData theme() =>
        tester.element(find.text(ember.label)).expressiveTheme;
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(theme().brightness, Brightness.dark);
    await _press(tester, find.text(ember.label));
    expect(theme().colors.primary, ember.swatchesFor(Brightness.dark).first);
    await _press(tester, find.text('Light'));
    expect(theme().brightness, Brightness.light);
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets('each palette shows its colour beside its name, by day and by '
        'night (${width.toInt()})', (tester) async {
      await _open(tester, width: width);
      await tester.tap(find.byIcon(ExpressiveSymbols.settings).first);
      await tester.pumpAndSettle();
      // A round of [colour] between the radio's ring and [name], on its line.
      void swatchBefore(String name, Color colour) {
        final swatch = find.descendant(
          of: find.byType(ExpressiveRadioGroup<String>),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
                (widget.decoration as BoxDecoration).color == colour,
          ),
        );
        expect(swatch, findsOneWidget, reason: '$name shows $colour');
        final words = tester.getRect(find.text(name));
        final round = tester.getRect(swatch);
        // The label's capitals centre on the row, as the round does; its
        // box sits lower by the descent.
        expect(round.center.dy, moreOrLessEquals(words.center.dy, epsilon: 2));
        final gap = words.left - round.right;
        expect(gap, inInclusiveRange(8, 24), reason: '$name beside its colour');
      }

      for (final palette in ExpressiveThemeData.palettes) {
        swatchBefore(
          palette.label,
          palette.swatchesFor(Brightness.light).first,
        );
      }
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      for (final palette in ExpressiveThemeData.palettes) {
        swatchBefore(palette.label, palette.swatchesFor(Brightness.dark).first);
      }
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel(RegExp('^Ember')), findsOneWidget);
      handle.dispose();
    });
  }
}

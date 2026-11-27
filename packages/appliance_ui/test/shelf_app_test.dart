// The example, Shelf, as an adopter would use it, at a phone's width and a
// desktop's: a book opens over the list while the three places stay in reach
// of a screen reader, the form checks its fields before it saves, deleting
// asks first, and settings change the appearance and the palette, each
// palette's colours beside its name.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

// The example app is the adopter's copy, tested where it stands.
// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';

const _look = 'Appliance';

Future<void> _app(WidgetTester tester, double width) async {
  tester.view
    ..physicalSize = Size(width, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ShelfApp());
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Finder _button(String label) => find.byWidgetPredicate(
  (w) => w is ApplianceIconButton && w.semanticLabel == label,
);

// Lets a toast run out, so no timer outlives the test.
Future<void> _toastsDone(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(applianceLoadFonts);

  for (final width in const [390.0, 800.0, 1440.0]) {
    final at = '(${width.toInt()})';

    testWidgets('a book opens over the list; the places stay in reach $at', (
      tester,
    ) async {
      await _app(tester, width);
      expect(find.text('Middlemarch'), findsOneWidget);
      const DesignControlNodesCheck(look: _look)
          .check(tester.element(find.byType(BooksPage)))
          .verify();
      await _tap(tester, find.text('Middlemarch'));
      expect(find.text('George Eliot'), findsOneWidget);
      if (width < 600) {
        // On a phone the key strip steps away for a pushed page, and back
        // brings it again.
        expect(find.text('Settings').hitTestable(), findsNothing);
        await Navigator.of(tester.element(find.byType(BookPage))).maybePop();
        await tester.pumpAndSettle();
        expect(find.text('Settings').hitTestable(), findsOneWidget);
      } else {
        // On the desktop the rail or the side panel stays, in reach of a
        // screen reader.
        const DesignNavigationCheck(look: _look)
            .check(
              tester.element(find.byType(ShelfApp)),
              destinations: ['Books', 'Reading', 'Settings'],
            )
            .verify();
        await Navigator.of(tester.element(find.byType(BookPage))).maybePop();
        await tester.pumpAndSettle();
      }
      expect(find.byType(BookPage), findsNothing);
      expect(find.text('Middlemarch'), findsOneWidget);
    });

    testWidgets('the form checks its fields, then saves $at', (tester) async {
      await _app(tester, width);
      await _tap(tester, _button('Add a book').first);
      await _tap(tester, find.text('Save'));
      expect(find.text('Enter the title'), findsOneWidget);
      final form = tester.element(find.byType(BookForm));
      const DesignFieldSemanticsCheck(look: _look).check(form).verify();
      const DesignControlNodesCheck(look: _look).check(form).verify();
      await tester.enterText(find.byType(EditableText).at(0), 'Piranesi');
      await tester.enterText(find.byType(EditableText).at(1), 'Susanna Clarke');
      await _tap(tester, find.text('Save'));
      expect(find.byType(BookForm), findsNothing);
      expect(find.text('Piranesi'), findsOneWidget);
      expect(find.text('Saved "Piranesi"'), findsOneWidget);
      await _toastsDone(tester);
    });

    testWidgets('deleting a book asks first $at', (tester) async {
      await _app(tester, width);
      await _tap(tester, find.text('Stoner'));
      await _tap(tester, find.text('Delete'));
      expect(find.text('Delete "Stoner"?'), findsOneWidget);
      await _tap(tester, find.text('Keep'));
      expect(find.text('John Williams'), findsOneWidget);
      await _tap(tester, find.text('Delete'));
      await _tap(tester, find.text('Delete').last);
      expect(find.byType(BookPage), findsNothing);
      expect(find.text('Stoner'), findsNothing);
      expect(find.text('Deleted "Stoner"'), findsOneWidget);
      await _toastsDone(tester);
    });

    testWidgets('settings change the appearance and the palette $at', (
      tester,
    ) async {
      await _app(tester, width);
      // The rail shows the places' glyphs; each is named.
      await _tap(tester, find.bySemanticsLabel(RegExp('^Settings')).first);
      ApplianceThemeData theme() =>
          ApplianceTheme.of(tester.element(find.byType(SettingsPage)));
      final second = ApplianceThemeData.palettes[1];
      await _tap(tester, find.text('Dark'));
      expect(theme().brightness, Brightness.dark);
      await _tap(tester, find.text(second.label));
      expect(
        theme().colors.signal,
        ApplianceThemeData.preset(second.id, Brightness.dark).colors.signal,
      );
      expect(theme().brightness, Brightness.dark);
      await _tap(tester, find.text('Light'));
      expect(theme().brightness, Brightness.light);
    });

    testWidgets('each palette shows its colours beside its name $at', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _app(tester, width);
      await _tap(tester, find.bySemanticsLabel(RegExp('^Settings')).first);
      for (final dark in [false, true]) {
        if (dark) await _tap(tester, find.text('Dark'));
        final brightness = dark ? Brightness.dark : Brightness.light;
        for (final palette in ApplianceThemeData.palettes) {
          final swatches = find.byWidgetPredicate(
            (w) => w is PaletteSwatches && w.palette == palette,
          );
          expect(swatches, findsOneWidget, reason: palette.label);
          final dots = find.descendant(
            of: swatches,
            matching: find.byType(Container),
          );
          expect(
            [
              for (final dot in tester.widgetList<Container>(dots))
                (dot.decoration! as BoxDecoration).color,
            ],
            // The ground's tile, then the colours on it.
            [
              palette.swatchesFor(brightness).last,
              ...palette
                  .swatchesFor(brightness)
                  .take(palette.swatchesFor(brightness).length - 1),
            ],
            reason: '${palette.label} ${brightness.name}',
          );
          // Beside its name, on its line, after it.
          final name = tester.getRect(find.text(palette.label));
          final shown = tester.getRect(swatches);
          expect((shown.center.dy - name.center.dy).abs(), lessThan(2));
          expect(shown.left, greaterThan(name.right));
          expect(shown.left - name.right, lessThan(16));
          // A screen reader hears the name alone.
          expect(
            find.bySemanticsLabel(palette.label),
            findsOneWidget,
            reason: palette.label,
          );
        }
      }
      semantics.dispose();
    });
  }
}

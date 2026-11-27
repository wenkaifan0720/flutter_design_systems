// The example, Takes, as an adopter would use it, at a phone's width, a
// rail's and a desktop's: an episode opens over the list while the three
// places stay in reach of a screen reader, the form checks its fields before
// it saves, deleting asks first, and settings change the appearance and the
// palette, each palette's colours beside its name.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

// The example app; a test reads it from the example.
// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';

const _look = 'Studio';

Future<void> _app(WidgetTester tester, double width) async {
  tester.view
    ..physicalSize = Size(width, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(TakesApp());
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Finder _button(String tooltip) => find.byWidgetPredicate(
  (w) => w is StudioIconButton && w.tooltip == tooltip,
);

/// A place by what a screen reader hears.
Finder _place(String label) =>
    find.bySemanticsLabel(RegExp('^$label(\n.*)?Tab \\d of 3', dotAll: true));

// Lets a toast run out, so no timer outlives the test.
Future<void> _toastsDone(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(studioLoadFonts);

  for (final width in const [390.0, 800.0, 1440.0]) {
    final at = '(${width.toInt()})';

    testWidgets(
      'an episode opens over the list; the places stay in reach $at',
      (tester) async {
        await _app(tester, width);
        expect(find.text('The quiet booth'), findsOneWidget);
        const DesignControlNodesCheck(look: _look)
            .check(tester.element(find.byType(EpisodesPage).first))
            .verify();
        await _tap(tester, find.text('The quiet booth'));
        expect(find.byType(EpisodePage), findsOneWidget);
        expect(find.text('Roomtone'), findsWidgets);
        if (width < 600) {
          // On a phone the key bank steps away for a pushed page, and back
          // brings it again.
          expect(_place('Settings').hitTestable(), findsNothing);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(_place('Settings').hitTestable(), findsOneWidget);
        } else {
          // From a rail's width the places stay, in reach of a screen reader.
          const DesignNavigationCheck(look: _look)
              .check(
                tester.element(find.byType(TakesApp)),
                destinations: ['Episodes', 'Editing', 'Settings'],
              )
              .verify();
        }
      },
    );

    testWidgets('the form checks its fields, then saves $at', (tester) async {
      await _app(tester, width);
      await _tap(tester, _button('New episode').first);
      await _tap(tester, find.text('Save'));
      expect(find.text('Enter the title'), findsOneWidget);
      final form = tester.element(find.byType(EpisodeForm));
      const DesignFieldSemanticsCheck(look: _look).check(form).verify();
      const DesignControlNodesCheck(look: _look).check(form).verify();
      await tester.enterText(find.byType(EditableText).at(0), 'Room 4');
      await tester.enterText(find.byType(EditableText).at(1), 'Roomtone');
      await _tap(tester, find.text('Save'));
      expect(find.byType(EpisodeForm), findsNothing);
      expect(find.text('Room 4'), findsOneWidget);
      expect(find.text('Saved "Room 4"'), findsOneWidget);
      await _toastsDone(tester);
    });

    testWidgets('deleting an episode asks first $at', (tester) async {
      await _app(tester, width);
      await _tap(tester, find.text('Tape, again'));
      await _tap(tester, find.text('Delete'));
      expect(find.text('Delete "Tape, again"?'), findsOneWidget);
      await _tap(tester, find.text('Keep'));
      expect(find.byType(EpisodePage), findsOneWidget);
      await _tap(tester, find.text('Delete'));
      await _tap(tester, find.text('Delete').last);
      expect(find.byType(EpisodePage), findsNothing);
      expect(find.text('Tape, again'), findsNothing);
      expect(find.text('Deleted "Tape, again"'), findsOneWidget);
      await _toastsDone(tester);
    });

    testWidgets('settings change the appearance and the palette $at', (
      tester,
    ) async {
      await _app(tester, width);
      await _tap(tester, _place('Settings').first);
      StudioColors colors() =>
          tester.element(find.byType(SettingsPage)).studioTheme.colors;
      await _tap(tester, find.text('Dark'));
      expect(colors().brightness, Brightness.dark);
      await _tap(tester, find.text('Cobalt'));
      expect(
        colors().indicator,
        StudioThemeData.preset('cobalt', Brightness.dark).colors.indicator,
      );
      expect(colors().brightness, Brightness.dark);
      await _tap(tester, find.text('Light'));
      expect(colors().brightness, Brightness.light);
    });

    testWidgets('each palette shows its colours beside its name $at', (
      tester,
    ) async {
      await _app(tester, width);
      await _tap(tester, _place('Settings').first);
      for (final dark in [false, true]) {
        if (dark) await _tap(tester, find.text('Dark'));
        final brightness = dark ? Brightness.dark : Brightness.light;
        for (final palette in StudioThemeData.palettes) {
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
          // Right after its name, on its line.
          final name = tester.getRect(find.text(palette.label));
          final shown = tester.getRect(swatches);
          expect((shown.center.dy - name.center.dy).abs(), lessThan(2));
          expect(shown.left, greaterThan(name.right));
          expect(shown.left - name.right, lessThan(16));
          // A screen reader hears the name alone.
          expect(find.bySemanticsLabel(palette.label), findsOneWidget);
        }
      }
    });
  }
}

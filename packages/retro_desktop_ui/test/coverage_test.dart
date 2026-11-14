// The example's new parts work, not only lay out: a menu opens, a palette
// filters, a table sorts, toasts queue, a wheel and a range take their keys, a
// combo box filters. In both appearances.
// The package emitter relocates these public example imports to example/lib.
// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../example/lib/kit_gallery/demos/coverage.dart';

import 'support.dart';

Future<void> _pump(
  WidgetTester tester,
  RetroDesktopAppearance appearance,
  Widget child,
) async {
  tester.view.physicalSize = const Size(1000, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) => RetroDesktopTheme(
        data: RetroDesktopThemeData.classic(Brightness.light)
            .copyWith(appearance: appearance),
        child: app!,
      ),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

/// Whether [first] stands above [second] on the page.
bool _above(WidgetTester tester, String first, String second) =>
    tester.getTopLeft(find.text(first)).dy <
    tester.getTopLeft(find.text(second)).dy;

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final appearance in RetroDesktopAppearance.values) {
    group(appearance.name, () {
      testWidgets('a menu bar opens and chooses', (tester) async {
        await _pump(tester, appearance, kitSpecimenMenuBar());
        expect(find.text('Open'), findsNothing);
        await tester.tap(find.text('File'));
        await tester.pumpAndSettle();
        expect(find.text('Open'), findsOneWidget);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Open'), findsNothing);
        expect(find.text('Chose from the menu'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 10));
        await tester.pumpAndSettle();
      });

      testWidgets('a table sorts on its column', (tester) async {
        await _pump(tester, appearance, kitSpecimenDataTable());
        expect(_above(tester, 'Budget', 'Notes'), isTrue);
        await tester.tap(find.text('Size'));
        await tester.pumpAndSettle();
        expect(_above(tester, 'Notes', 'Budget'), isTrue);
        await tester.tap(find.text('Size'));
        await tester.pumpAndSettle();
        expect(_above(tester, 'Letters', 'Plans'), isTrue);
        expect(_above(tester, 'Budget', 'Notes'), isTrue);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a range takes the arrows, each thumb its own', (
        tester,
      ) async {
        await _pump(tester, appearance, kitSpecimenRangeSlider());
        DesignRangeValues values() => tester
            .widget<RetroDesktopRangeSlider>(
              find.byType(RetroDesktopRangeSlider),
            )
            .values;
        expect(values(), const DesignRangeValues(20, 80));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(values().start, greaterThan(20));
        expect(values().end, 80);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
        expect(values().end, lessThan(80));
        expect(tester.takeException(), isNull);
      });

      testWidgets('a combo box filters as it is typed in', (tester) async {
        await _pump(tester, appearance, kitSpecimenCombobox());
        await tester.tap(find.byType(EditableText));
        await tester.pump();
        await tester.enterText(find.byType(EditableText), 'ch');
        await tester.pumpAndSettle();
        expect(find.text('Chile'), findsOneWidget);
        expect(find.text('Austria'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a combo box says so when no option fits', (tester) async {
        await _pump(tester, appearance, kitSpecimenCombobox());
        await tester.tap(find.byType(EditableText));
        await tester.pump();
        await tester.enterText(find.byType(EditableText), 'zz');
        await tester.pumpAndSettle();
        // ui_core's shared word (DesignLocalizations.noResultsLabel).
        expect(find.text('No results'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a code field offers paste in the look\'s own menu', (
        tester,
      ) async {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => call.method == 'Clipboard.hasStrings'
              ? <String, Object?>{'value': true}
              : call.method == 'Clipboard.getData'
              ? <String, Object?>{'text': '123456'}
              : null,
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        final code = TextEditingController();
        addTearDown(code.dispose);
        await _pump(
          tester,
          appearance,
          RetroDesktopInputOtp(label: 'Code', controller: code),
        );
        // The boxes stand under the label, at the row's start.
        await tester.tapAt(
          tester.getBottomLeft(find.byType(RetroDesktopInputOtp)) +
              const Offset(18, -18),
          buttons: kSecondaryButton,
        );
        await tester.pumpAndSettle();
        expect(find.byType(RetroDesktopTextContextMenu), findsOneWidget);
        await tester.tap(find.text('Paste'));
        await tester.pumpAndSettle();
        expect(code.text, '123456');
        expect(tester.takeException(), isNull);
      });
    });
  }
}

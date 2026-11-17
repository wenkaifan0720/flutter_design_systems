// slipway's screens at a phone's, a tablet's and a desk's width, at night
// and on paper, right to left and at 200% text: each lays out with nothing
// overflowing and nothing thrown, and names itself to a screen reader. Every
// run takes each screen at one width and theme, in turn (the screens meet
// all six), one screen right to left and one at 200%; the sweep runs the
// rest (tiers.dart).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

// The example's screens are the ones under test.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/everyday_screens.dart';
import 'faces.dart';
import 'tiers.dart';

Future<void> _pump(WidgetTester tester, Widget app, double width) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(loadFaces);

  final screens = everydayScreens.length;
  for (final (turn, screen) in everydayScreens.indexed) {
    var cell = 0;
    for (final width in const [390.0, 768.0, 1440.0]) {
      for (final brightness in Brightness.values) {
        testWidgets('${screen.id} at ${width.toInt()} ${brightness.name}', (
          tester,
        ) async {
          final semantics = tester.ensureSemantics();
          await _pump(tester, screen.app(brightness, TextDirection.ltr), width);
          expect(tester.takeException(), isNull);
          // A screen with a modal over it names the modal; the app behind
          // is out of a screen reader's reach.
          final name = switch (screen.id) {
            'palette' => 'commands',
            'confirm' => 'delete project',
            _ => 'slipway',
          };
          expect(find.bySemanticsLabel(name), findsWidgets);
          semantics.dispose();
        }, tags: sweepUnlessTurn(turn, cell++, 6));
      }
    }
    testWidgets('${screen.id} right to left', (tester) async {
      await _pump(tester, screen.app(Brightness.dark, TextDirection.rtl), 390);
      expect(tester.takeException(), isNull);
      expect(
        Directionality.of(tester.element(find.byType(TermTopBar))),
        TextDirection.rtl,
      );
    }, tags: sweepUnlessTurn(turn, 0, screens));
  }

  testWidgets('the grid holds at 200% text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      everydayScreens.first.app(Brightness.dark, TextDirection.ltr),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    final grid = TermGrid.of(
      tester.element(find.byType(TermTopBar)),
      const TermGrid(),
    );
    expect(grid.cellWidth, closeTo(18, 0.01));
    expect(grid.lineHeight, 48);
  });

  for (final (turn, screen) in everydayScreens.indexed) {
    testWidgets('${screen.id} at 200% text on a phone', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(tester, screen.app(Brightness.light, TextDirection.ltr), 390);
      expect(tester.takeException(), isNull);
    }, tags: sweepUnlessTurn(turn, 1, screens));
  }
}

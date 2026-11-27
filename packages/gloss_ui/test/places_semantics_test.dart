// Every place stays in reach of a screen reader beside a page that keeps its own navigator (Simmer's list-and-detail
// pane on a tablet and a desk): the pane's pages never hide the rail or the sidebar.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/everyday_screens.dart';

void main() {
  final home = everydayScreens.firstWhere((s) => s.id == 'home');
  for (final width in const [390.0, 768.0, 1440.0]) {
    testWidgets('every place is heard at ${width.toInt()}', (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(home.app(Brightness.light, TextDirection.ltr));
      await tester.pumpAndSettle();
      for (final place in const [
        'Gloss',
        'Today',
        'Recipes',
        'List',
        'Settings',
      ]) {
        // From the rail up ui_core's shell names a place and its place
        // among them ("Today\nTab 2 of 5").
        expect(
          find.bySemanticsLabel(RegExp('^${RegExp.escape(place)}(\n|\$)')),
          findsWidgets,
          reason: place,
        );
      }
      semantics.dispose();
    });
  }

  testWidgets('a switch between places plays on a phone', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(home.app(Brightness.light, TextDirection.ltr));
    await tester.pumpAndSettle();
    // The phone's bar is ui_core's tab bar too: "Recipes\nTab 3 of 5".
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Recipes(\n|$)')).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    // Mid-switch: Today is still going as Recipes comes.
    expect(find.text('Start cooking'), findsOneWidget);
    expect(find.text('Under 25 min'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Start cooking'), findsNothing);
    semantics.dispose();
  });
}

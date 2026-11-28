// A sheet stands on a phone's window list and status line, as the family's
// sheets on ui_core's bottom sheet route do: the bar shows under the dimmed
// screen, a tap on it closes the sheet, and the y/N question at the foot is
// still an alert to a screen reader.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

Widget _app() => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) =>
      TermHost(brightness: Brightness.dark, child: child!),
  home: TermScaffold(
    title: 'shelf',
    destinations: const [
      TermNavigationDestination(label: 'books'),
      TermNavigationDestination(label: 'add'),
      TermNavigationDestination(label: 'settings'),
    ],
    selectedIndex: 0,
    onDestinationSelected: (_) {},
    body: Builder(
      builder: (context) => Column(
        children: [
          TermButton(
            label: 'share',
            onPressed: () => showTermSheet<void>(
              context: context,
              builder: (context) => TermSheet(
                title: 'share middlemarch',
                actions: [TermButton.filled(label: 'copy', onPressed: () {})],
                child: const Text('a link to the book'),
              ),
            ),
          ),
          TermButton(
            label: 'delete',
            onPressed: () => showTermConfirmDialog(
              context: context,
              title: 'delete book',
              message: 'it leaves your shelf',
              confirmLabel: 'delete',
              sheet: true,
            ),
          ),
        ],
      ),
    ),
  ),
);

void _phone(WidgetTester tester, {double inset = 0}) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(bottom: inset);
  tester.view.viewPadding = FakeViewPadding(bottom: inset);
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(loadFaces);

  for (final inset in [0.0, 34.0]) {
    testWidgets('a sheet at 390 stands on the window list (bottom inset '
        '${inset.round()})', (tester) async {
      _phone(tester, inset: inset);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byType(TermNavigationBar));
      await tester.tap(find.text('share'));
      await tester.pumpAndSettle();
      final sheet = tester.getRect(find.byType(TermSheet));
      // The sheet's ground ends where the bars over the foot begin (the
      // status line over the window list), never over the window list.
      final ground = tester.getRect(
        find
            .ancestor(
              of: find.byType(TermSheet),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(
        ground.bottom,
        lessThanOrEqualTo(bar.top + 0.01),
        reason: '$ground over $bar',
      );
      expect(sheet.bottom, lessThanOrEqualTo(bar.top + 0.01));
      // The window list is still painted, under the dimmed screen.
      expect(find.byType(TermNavigationBar).hitTestable(), findsNothing);
      expect(find.text('1:books*'), findsOneWidget);
      // A tap on the bar closes the sheet, as a tap anywhere outside it.
      await tester.tapAt(bar.center);
      await tester.pumpAndSettle();
      expect(find.byType(TermSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the y/N question at the foot is an alert, on the window list', (
    tester,
  ) async {
    _phone(tester);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final bar = tester.getRect(find.byType(TermNavigationBar));
    await tester.tap(find.text('delete'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.role == SemanticsRole.alertDialog,
      ),
      findsOneWidget,
    );
    final question = tester.getRect(find.byType(TermConfirmDialog));
    expect(question.bottom, lessThanOrEqualTo(bar.top + 0.01));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(TermConfirmDialog), findsNothing);
    semantics.dispose();
  });
}

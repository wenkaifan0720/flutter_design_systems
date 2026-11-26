// ui_core_test 0.6.1's semantics checks over the example app, Shelf, as a
// screen reader meets it: every control keeps a node of its own (a row's
// delete, a status word), a field's label is read once, and with a book open
// the rail and the side pane are still there to take a tap. A phone's window
// list steps away under a pushed screen, so its places are read on the list.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

import '../example/lib/main.dart';

const _places = ['books', 'add', 'settings'];

Future<void> _open(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ShelfApp(shelf: Shelf.sample()));
  await tester.pumpAndSettle();
}

void _check(WidgetTester tester) {
  final app = tester.element(find.byType(ShelfShell));
  const DesignControlNodesCheck(look: 'Terminal').check(app).verify();
  const DesignFieldSemanticsCheck(look: 'Terminal').check(app).verify();
}

/// A place, as a screen reader hears it (the rail draws its number alone).
Finder _place(String label) =>
    find.bySemanticsLabel(RegExp('^$label')).hitTestable();

void main() {
  for (final width in [390.0, 800.0, 1440.0]) {
    testWidgets('each control keeps a node of its own, in every place '
        '(${width.toInt()})', (tester) async {
      final semantics = tester.ensureSemantics();
      await _open(tester, width);
      _check(tester);
      const DesignNavigationCheck(look: 'Terminal')
          .check(tester.element(find.byType(ShelfShell)), destinations: _places)
          .verify();
      await tester.tap(find.text('Middlemarch'));
      await tester.pumpAndSettle();
      _check(tester);
      if (width >= 600) {
        const DesignNavigationCheck(look: 'Terminal')
            .check(
              tester.element(find.byType(ShelfShell)),
              destinations: _places,
            )
            .verify();
      }
      await tester.tap(find.bySemanticsLabel('back'));
      await tester.pumpAndSettle();
      for (final place in ['add', 'settings']) {
        await tester.tap(_place(place).first);
        await tester.pumpAndSettle();
        _check(tester);
      }
      semantics.dispose();
    });
  }
}

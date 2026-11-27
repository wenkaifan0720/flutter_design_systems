// ui_core_test 0.6.0's semantics checks over the example app, Shelf, as a
// screen reader meets it: every control keeps a node of its own (a row's tag,
// a swipe row's acts), a field's label is read once, and with a book open
// the rail and the side bar are still there to take a tap. A phone's
// bar steps away under a pushed page, so its places are read on the list.
// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart' show LedgerBack;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

import '../example/lib/main.dart';

const _places = ['Books', 'Add', 'Settings'];

Future<void> _open(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ShelfApp(shelf: Shelf.sample()));
  await tester.pumpAndSettle();
}

void _check(WidgetTester tester) {
  final app = tester.element(find.byType(ShelfShell));
  const DesignControlNodesCheck(look: 'Ledger').check(app).verify();
  const DesignFieldSemanticsCheck(look: 'Ledger').check(app).verify();
}

void main() {
  for (final width in [390.0, 800.0, 1440.0]) {
    testWidgets('each control keeps a node of its own, in every place '
        '(${width.toInt()})', (tester) async {
      final semantics = tester.ensureSemantics();
      await _open(tester, width);
      _check(tester);
      const DesignNavigationCheck(look: 'Ledger')
          .check(tester.element(find.byType(ShelfShell)), destinations: _places)
          .verify();
      await tester.tap(find.textContaining(RegExp('^Middlemarch')));
      await tester.pumpAndSettle();
      _check(tester);
      if (width >= 600) {
        const DesignNavigationCheck(look: 'Ledger')
            .check(
              tester.element(find.byType(ShelfShell)),
              destinations: _places,
            )
            .verify();
      }
      await tester.tap(find.byType(LedgerBack));
      await tester.pumpAndSettle();
      for (final mark in [LucideIcons.plus, LucideIcons.settings]) {
        // By its mark: a tablet's rail shows the places' marks alone.
        await tester.tap(find.byIcon(mark).first);
        await tester.pumpAndSettle();
        _check(tester);
      }
      semantics.dispose();
    });
  }
}

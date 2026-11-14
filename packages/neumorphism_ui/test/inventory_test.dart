// The inventory: Neumorphism answers every one of the shared rows, once, with a live specimen that is the row's own
// class (`Neumorphic<Stem>`); and the gallery that lists them lays every specimen out, at a phone's width and a
// desktop's, by day and by night.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);

  test('every row is answered once, and none is left out', () {
    expect(neumorphicInventory.problems, isEmpty);
    expect(neumorphicInventory.entries.length, DesignInventoryRow.all.length);
    // Left out of 0.1.0 by the look's laws, each with its reason (README, "How Neumorphism is built"): a key floating
    // over the content is a bump over bumps, and a pull's dome stood over the first row.
    expect(
      {
        for (final e in neumorphicInventory.entries)
          if (!e.isPresent && e.absentReason != null) e.row,
      },
      {'FloatingActionButton', 'RefreshIndicator'},
    );
  });

  test('the inventory verifies', neumorphicInventory.verify);

  for (final width in const [390.0, 1440.0]) {
    for (final dark in const [false, true]) {
      testWidgets(
        'the gallery lays out every row at $width ${dark ? 'dark' : 'light'}',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            neumorphicApp(
              const NeumorphicScaffold(
                scroll: false,
                topBar: NeumorphicAppBar(title: 'Components'),
                body: NeumorphicInventoryGallery(),
              ),
              dark: dark,
              width: width,
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          final list = find
              .descendant(
                of: find.byType(NeumorphicInventoryGallery),
                matching: find.byType(Scrollable),
              )
              .first;
          for (final row in DesignInventoryRow.all) {
            await tester.scrollUntilVisible(
              find.byKey(ValueKey<String>('inventory-${row.id}')),
              240,
              scrollable: list,
            );
            await tester.pump();
            expect(tester.takeException(), isNull, reason: row.id);
          }
        },
      );
    }
  }
}

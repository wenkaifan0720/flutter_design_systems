// The inventory (looks/INVENTORY.md): Retro Desktop answers every one of the shared rows, once, with a specimen that
// is one of its own parts or a reason it leaves the row out; and the gallery that lists them lays every specimen out,
// in both appearances, at a phone's width and a desktop's, by day and by night.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

import 'support.dart';

void main() {
  setUpAll(loadRetroDesktopFonts);

  test('every row is answered once, and every gap has a reason', () {
    expect(retroDesktopInventory.problems, isEmpty);
    expect(retroDesktopInventory.entries.length, DesignInventoryRow.all.length);
    // Rows the period had no honest form for (the look's laws, DECISIONS.md):
    // each says why and what to use instead.
    const absent = [
      'FloatingActionButton',
      'WheelPicker',
      'Command',
      'MultiSelect',
      'CarouselView',
      'SwipeActions',
      'RefreshIndicator',
      'HoverCard',
    ];
    expect(retroDesktopInventory.absentCount, absent.length);
    for (final row in absent) {
      expect(retroDesktopInventory.entryFor(row)?.isPresent, isFalse);
    }
    retroDesktopInventory.verify();
  });

  testWidgets('every specimen is one of Retro Desktop\'s own parts', (
    tester,
  ) async {
    late BuildContext host;
    await tester.pumpWidget(
      retroDesktopApp(
        Builder(
          builder: (context) {
            host = context;
            return const SizedBox();
          },
        ),
      ),
    );
    // A row's id is a label, not a class name; the specimen is still the look's own part, never a stand-in.
    for (final entry in retroDesktopInventory.entries) {
      final builder = entry.builder;
      if (builder == null) continue;
      final specimen = builder(host);
      // A row may show its part's kinds side by side (the Button row: default, plain, text and destructive), each of
      // them the look's own part.
      final parts = specimen is Wrap ? specimen.children : [specimen];
      // A part set apart by a Padding (the quiet button's room for its held face) is still the part inside it.
      for (final placed in parts) {
        final part = placed is Padding ? placed.child! : placed;
        final name = '${part.runtimeType}'.split('<').first;
        // The scroll area's specimen holds its own controller in a private
        // holder (_OwnScroll) around the part.
        expect(
          name,
          anyOf(startsWith('RetroDesktop'), '_OwnScroll'),
          reason: entry.row,
        );
      }
    }
  });

  for (final appearance in RetroDesktopAppearance.values) {
    for (final width in const [390.0, 1440.0]) {
      for (final dark in const [false, true]) {
        testWidgets(
          'the gallery lays out every row, ${appearance.name} at $width '
          '${dark ? 'dark' : 'light'}',
          (tester) async {
            tester.view.physicalSize = Size(width, 1000);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              retroDesktopApp(
                Builder(
                  builder: (context) => RetroDesktopTheme(
                    data: RetroDesktopTheme.of(context)
                        .copyWith(appearance: appearance),
                    child: const RetroDesktopScaffold(
                      scroll: false,
                      topBar: RetroDesktopAppBar(title: 'Components'),
                      body: RetroDesktopInventoryGallery(),
                    ),
                  ),
                ),
                dark: dark,
                width: width,
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
            final list = find
                .descendant(
                  of: find.byType(RetroDesktopInventoryGallery),
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
}

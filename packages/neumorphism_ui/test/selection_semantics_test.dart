// What a screen reader hears of a chosen thing: a toggle button reads as a button that is selected, and the gallery's
// selectable rooms, rows of a data table, read as checkable rows rather than buttons.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

// ignore_for_file: avoid_relative_lib_imports — the gallery under test is the example app, not a package dependency.
import '../example/lib/gallery.dart';
import 'gallery_support.dart' show loadBundledFonts, settle;
import 'support.dart';

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });

  testWidgets('a selected icon button reads as a button that is selected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        neumorphicApp(
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphicIconButton(
                  NeumorphicGlyphs.plus,
                  semanticLabel: 'Pin',
                  selected: true,
                  onPressed: () {},
                ),
                NeumorphicIconButton(
                  NeumorphicGlyphs.plus,
                  semanticLabel: 'Mute',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Pin')),
        isSemantics(
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasToggledState: false,
          hasCheckedState: false,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Mute')),
        isSemantics(isButton: true, isSelected: false, hasToggledState: false),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('the selectable rooms read as checkable rows, not buttons', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 6000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GalleryApp(initialPage: 'collections'));
      await settle(tester);
      // The table's first page; the tree of rooms below it names some of the same rooms.
      final table = find.byWidgetPredicate((w) => w is NeumorphicDataTable);
      for (final room in ['Attic', 'Bedroom', 'Cellar', 'Hall', 'Kitchen']) {
        final row = find.descendant(
          of: table,
          matching: find.bySemanticsLabel(RegExp('^$room\n')),
        );
        expect(row, findsOneWidget, reason: room);
        expect(
          tester.getSemantics(row),
          isSemantics(
            hasCheckedState: true,
            isButton: false,
            hasTapAction: true,
          ),
          reason: room,
        );
      }
    } finally {
      semantics.dispose();
    }
  });
}

// The inventory answers every row of ui_core's list, and every part it
// carries builds at a phone's width and at a desk's, night and paper, with
// nothing thrown and nothing overflowing (the gallery frames each one the
// same way: in a scrolling page).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  test('the inventory answers every row', termInventory.verify);

  test('it leaves out only what would break the look', () {
    final absent = [
      for (final e in termInventory.entries)
        if (e.absentReason != null) e.row,
    ];
    expect(
      absent,
      unorderedEquals(const [
        'FloatingActionButton',
        'WheelPicker',
        'CarouselView',
        'SwipeActions',
        'PieChart',
      ]),
    );
  });

  for (final brightness in Brightness.values) {
    for (final width in const [390.0, 1280.0]) {
      testWidgets('every part builds, ${brightness.name}, ${width.round()} '
          'wide', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.reset);
        for (final entry in termInventory.entries) {
          final build = entry.builder;
          if (build == null) continue;
          await tester.pumpWidget(
            MaterialApp(
              home: TermTheme(
                data: TermThemeData.of(brightness),
                child: TermToaster(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(9),
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: Builder(key: ValueKey(entry.row), builder: build),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull, reason: entry.row);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('a part is as tall as its lines, not as the room it is given', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(720, 2400);
    addTearDown(tester.view.reset);
    final tall = <String>[];
    for (final entry in termInventory.entries) {
      final build = entry.builder;
      if (build == null) continue;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: TermTheme(
            data: TermThemeData.dark(),
            child: TermToaster(
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: KeyedSubtree(
                  key: key,
                  child: Builder(key: ValueKey(entry.row), builder: build),
                ),
              ),
            ),
          ),
        ),
      );
      final height = tester.getSize(find.byKey(key)).height;
      if (height > 1600 && !_fills.contains(entry.row)) tall.add(entry.row);
    }
    expect(tall, isEmpty, reason: 'these grew to the room they were given');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

/// Parts that are a screen or a region, and fill what they are given: a
/// whole view's state stands in the middle of its room.
const _fills = {'StatusView'};

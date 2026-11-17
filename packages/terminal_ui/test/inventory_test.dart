// The inventory answers every row of ui_core's list, and every part it
// carries builds at a phone's width and at a desk's, night and paper, with
// nothing thrown and nothing overflowing (the gallery frames each one the
// same way: in a scrolling page). Every run builds each part once, at one
// width and theme in turn; the sweep builds each at all four (tiers.dart).
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

  final cells = [
    for (final brightness in Brightness.values)
      for (final width in [390.0, 1280.0]) (brightness, width),
  ];
  final parts = [
    for (final entry in termInventory.entries)
      if (entry.builder case final build?) (row: entry.row, build: build),
  ];

  testWidgets('every part builds, at a width and a theme in turn', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    for (final (turn, part) in parts.indexed) {
      final (brightness, width) = cells[turn % cells.length];
      await _build(tester, part, brightness, width);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final (brightness, width) in cells) {
    testWidgets('every part builds, ${brightness.name}, ${width.round()} '
        'wide', (tester) async {
      addTearDown(tester.view.reset);
      for (final part in parts) {
        await _build(tester, part, brightness, width);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }, tags: const ['sweep']);
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

/// Builds [part] in a scrolling page [width] wide, in [brightness],
/// with nothing thrown. The test resets the view.
Future<void> _build(
  WidgetTester tester,
  ({String row, WidgetBuilder build}) part,
  Brightness brightness,
  double width,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  await tester.pumpWidget(
    MaterialApp(
      home: TermTheme(
        data: TermThemeData.of(brightness),
        child: TermToaster(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(9),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: Builder(key: ValueKey(part.row), builder: part.build),
            ),
          ),
        ),
      ),
    ),
  );
  expect(
    tester.takeException(),
    isNull,
    reason: '${part.row}, ${brightness.name}, ${width.round()} wide',
  );
}

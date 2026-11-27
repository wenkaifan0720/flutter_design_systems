// A row's menu button stands at the row's end on the row's fill: the
// chosen row's selected fill, and the row's hover, run under it to the
// row's end, with no notch before it. It stays its own target and its own
// node: a press on it is not the row's, and a screen reader reaches it
// apart from the row's words.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

const _stage = ValueKey('stage');
const _row = ValueKey('row');

Future<void> _pump(
  WidgetTester t, {
  Brightness brightness = Brightness.light,
  bool selected = true,
  VoidCallback? onOpen,
  VoidCallback? onMenu,
}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(600, 300);
  addTearDown(t.view.reset);
  final theme = Fluent2ThemeData.lapis(brightness);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, route) => Fluent2Theme(data: theme, child: route!),
      home: ColoredBox(
        color: theme.background,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: _stage,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 480,
                child: Fluent2ListGroup(
                  children: [
                    Fluent2ListItem(
                      key: _row,
                      title: 'Proof the studio map',
                      subtitle: 'Open studio',
                      selected: selected,
                      onTap: onOpen ?? () {},
                      action: Fluent2IconButton(
                        Fluent2Icons.moreHorizontal,
                        semanticLabel: 'Task actions',
                        onPressed: onMenu ?? () {},
                      ),
                    ),
                    Fluent2ListItem(title: 'Ship the brief', onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

// The stage's pixels, read at points in the screen's coordinates.
Future<int Function(double x, double y)> _pixels(WidgetTester t) async {
  final origin = t.getTopLeft(find.byKey(_stage));
  final (data, width) = (await t.runAsync<(ByteData, int)>(() async {
    final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(_stage));
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    image.dispose();
    return (data!, width);
  }))!;
  return (double x, double y) => data.getUint32(
    (((y - origin.dy).round()) * width + (x - origin.dx).round()) * 4,
  );
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('the chosen row\'s fill runs under its menu button to its '
        'end, ${brightness.name}', (t) async {
      await _pump(t, brightness: brightness);
      final row = t.getRect(find.byKey(_row));
      final button = t.getRect(find.byType(Fluent2IconButton));
      final at = await _pixels(t);
      final y = row.top + 4;
      final fill = at(row.left + 2, y);
      // The card's own ground, on the row under it.
      final card = at(row.left + 2, row.bottom + 4);
      expect(fill, isNot(card), reason: 'the row is chosen');
      expect(at(button.left - 1, y), fill, reason: 'no notch before it');
      expect(at(row.right - 2, y), fill, reason: 'the fill runs to the end');
    });
  }

  testWidgets("the row's hover runs under its menu button", (t) async {
    await _pump(t, selected: false);
    final row = t.getRect(find.byKey(_row));
    final rest = (await _pixels(t))(row.right - 2, row.top + 4);
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(t.getCenter(find.text('Proof the studio map')));
    await t.pumpAndSettle();
    final at = await _pixels(t);
    final hover = at(row.left + 2, row.top + 4);
    expect(hover, isNot(rest), reason: 'the row is hovered');
    expect(at(row.right - 2, row.top + 4), hover);
  });

  testWidgets("a press on the menu button is the button's, not the row's", (
    t,
  ) async {
    var opened = 0, menus = 0;
    await _pump(t, onOpen: () => opened++, onMenu: () => menus++);
    await t.tap(find.byType(Fluent2IconButton));
    await t.pumpAndSettle();
    expect((opened, menus), (0, 1));
    await t.tap(find.text('Proof the studio map'));
    await t.pumpAndSettle();
    expect((opened, menus), (1, 1));
  });

  testWidgets("a screen reader reaches the menu button apart from the row's "
      'words', (t) async {
    final semantics = t.ensureSemantics();
    await _pump(t);
    final button = t.getSemantics(find.bySemanticsLabel('Task actions'));
    final row = t.getSemantics(find.bySemanticsLabel(RegExp('^Proof')));
    expect(button.id, isNot(row.id));
    expect(row.label, isNot(contains('Task actions')));
    expect(row, isSemantics(isSelected: true));
    semantics.dispose();
  });
}

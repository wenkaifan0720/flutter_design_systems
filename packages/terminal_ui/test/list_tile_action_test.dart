// A row's menu key stands at the row's end on the chosen bar: the bar runs
// under it to the row's end, with no notch before it, and on the inverse bar
// the key is drawn in inverse video with the row. It stays its own target
// and its own node: a press on it is not the row's, and a screen reader
// reaches it apart from the row's words.
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  Future<void> pump(
    WidgetTester tester, {
    required Brightness brightness,
    required bool active,
    GlobalKey? stage,
    VoidCallback? onOpen,
    VoidCallback? onMenu,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 200);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: TermTheme(
          data: brightness == Brightness.dark
              ? TermThemeData.dark()
              : TermThemeData.light(),
          child: Builder(
            builder: (context) => ColoredBox(
              color: TermTheme.of(context).background,
              child: Align(
                alignment: Alignment.topLeft,
                child: RepaintBoundary(
                  key: stage,
                  child: SizedBox(
                    width: 540,
                    child: TermPaneScope(
                      active: active,
                      child: TermListTile(
                        key: const ValueKey('row'),
                        title: const Text('proof the studio map'),
                        selected: true,
                        onTap: onOpen ?? () {},
                        action: TermIconButton(
                          glyph: '⋯',
                          semanticLabel: 'task actions',
                          onPressed: onMenu ?? () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    for (final active in [true, false]) {
      final where =
          '${active ? 'in the active pane' : 'in another pane'}, '
          '${brightness.name}';
      testWidgets(
        'the chosen bar runs under the row\'s key to its end, $where',
        (tester) async {
          final stage = GlobalKey();
          await pump(
            tester,
            brightness: brightness,
            active: active,
            stage: stage,
          );
          final row = tester.getRect(find.byKey(const ValueKey('row')));
          final key = tester.getRect(find.byType(TermIconButton));
          final image = (await tester.runAsync(() async {
            final boundary =
                stage.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final data = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            final width = image.width;
            image.dispose();
            return (data!, width);
          }))!;
          final (data, width) = image;
          int at(double x, double y) =>
              data.getUint32((y.round() * width + x.round()) * 4);
          final y = row.center.dy;
          // The bar at the row's start, just before the key, and past it at
          // the row's end: one colour, the bar's, not the page's.
          final bar = at(row.left + 2, y);
          final page = TermTheme.of(
            tester.element(find.byKey(const ValueKey('row'))),
          ).background;
          int rgba(Color c) =>
              (c.r * 255).round() << 24 |
              (c.g * 255).round() << 16 |
              (c.b * 255).round() << 8 |
              (c.a * 255).round();
          expect(bar, isNot(rgba(page)), reason: 'the row is chosen');
          expect(at(key.left - 1, y), bar, reason: 'no notch before the key');
          expect(at(row.right - 2, y), bar, reason: 'the bar runs to the end');
        },
      );
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets('on the inverse bar the key is drawn in inverse video, '
        '${brightness.name}', (tester) async {
      await pump(tester, brightness: brightness, active: true);
      final row = TermTheme.of(
        tester.element(find.byKey(const ValueKey('row'))),
      );
      final words = tester.widget<Text>(
        find.descendant(
          of: find.byType(TermIconButton),
          matching: find.text('⋯'),
        ),
      );
      final ink =
          words.style?.color ??
          DefaultTextStyle.of(
            tester.element(
              find.descendant(
                of: find.byType(TermIconButton),
                matching: find.text('⋯'),
              ),
            ),
          ).style.color!;
      // On the bar (the words' ink), the key's words take the page's.
      expect(termContrast(ink, row.foreground), greaterThanOrEqualTo(4.5));
    });
  }

  testWidgets('a press on the key is the key\'s, not the row\'s', (
    tester,
  ) async {
    var opened = 0, menus = 0;
    await pump(
      tester,
      brightness: Brightness.light,
      active: true,
      onOpen: () => opened++,
      onMenu: () => menus++,
    );
    await tester.tap(find.byType(TermIconButton));
    await tester.pumpAndSettle();
    expect((opened, menus), (0, 1));
    await tester.tap(find.text('proof the studio map'));
    await tester.pumpAndSettle();
    expect((opened, menus), (1, 1));
  });

  testWidgets('a screen reader reaches the key apart from the row\'s words', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, brightness: Brightness.dark, active: true);
    final key = tester.getSemantics(find.bySemanticsLabel('task actions'));
    final row = tester.getSemantics(find.text('proof the studio map'));
    expect(key.id, isNot(row.id));
    expect(row.label, isNot(contains('task actions')));
    expect(row, isSemantics(isSelected: true));
    semantics.dispose();
  });
}

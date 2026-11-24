// A raised pane (a palette, a menu, a dialog) stands on its own ground out
// to its frame's outer line and no further, so the page's lines and words
// beside it stay whole; the words cut into its border blank what is under
// them, their cells past the line in the page's ground. A framed select's
// field, while its list is up, keeps its frame drawn on that ground, its
// sides in the accent. A one-line select's field, while its list is up,
// stands on the list's ground with its brackets still drawn on it.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

final _shot = GlobalKey();

Widget _host(TermThemeData theme, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: TermTheme(
    data: theme,
    child: ColoredBox(
      color: theme.background,
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: RepaintBoundary(
            key: _shot,
            child: ColoredBox(
              color: theme.background,
              child: SizedBox(width: 360, child: child),
            ),
          ),
        ),
      ),
    ),
  ),
);

/// The picture under [_shot], one pixel a point, and its width.
Future<(ByteData, int, int)> _picture(WidgetTester tester) async {
  final boundary =
      _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final size = (image.width, image.height);
    image.dispose();
    return (data!, size.$1, size.$2);
  }))!;
}

/// How far [rgba]'s pixel at [x], [y] is from [colour], summed over the
/// channels, 0 to 765.
int _distance(ByteData rgba, int width, int x, int y, Color colour) {
  final i = (y * width + x) * 4;
  return (rgba.getUint8(i) - (colour.r * 255).round()).abs() +
      (rgba.getUint8(i + 1) - (colour.g * 255).round()).abs() +
      (rgba.getUint8(i + 2) - (colour.b * 255).round()).abs();
}

void main() {
  setUpAll(loadFaces);

  const themes = {'paper': TermThemeData.light, 'night': TermThemeData.dark};
  for (final MapEntry(key: name, value: theme) in themes.entries) {
    testWidgets('on $name a raised pane has no ground past its frame', (
      tester,
    ) async {
      final t = theme();
      await tester.pumpWidget(
        _host(
          t,
          const TermPane(
            raised: true,
            title: 'start a timer',
            child: SizedBox(height: 96),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final (rgba, w, h) = await _picture(tester);
      final grid = tester.element(find.byType(TermPane)).termGrid;
      final midX = w ~/ 2, midY = h ~/ 2;
      // Past the line on all four sides, the page.
      for (final (x, y) in [
        (1, midY),
        (w - 2, midY),
        (midX, 1),
        (midX, h - 2),
      ]) {
        expect(
          _distance(rgba, w, x, y, t.background),
          lessThan(6),
          reason: 'at $x, $y: the page, not the pane\'s ground',
        );
      }
      // Inside it, the ground.
      expect(
        _distance(rgba, w, (grid.cellWidth * 2).round(), midY, t.surface),
        lessThan(6),
      );
    });

    testWidgets("on $name a raised pane's border words blank what is under "
        "them past the line, in the page's ground, not a tab of the pane's", (
      tester,
    ) async {
      final t = theme();
      // What the pane stands over: a colour neither theme uses.
      const under = Color(0xFFFF00FF);
      await tester.pumpWidget(
        _host(
          t,
          const Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: under)),
              SizedBox(
                width: 360,
                child: TermPane(
                  raised: true,
                  title: 'start a timer',
                  child: SizedBox(height: 96),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final (rgba, w, h) = await _picture(tester);
      final grid = tester.element(find.byType(TermPane)).termGrid;
      final start =
          tester.getTopLeft(find.textContaining('start a timer')).dx -
          tester.getTopLeft(find.byKey(_shot)).dx;
      final end = start + grid.widthOf('start a timer');
      // The title's cells above the line: its ink or the page's ground,
      // never what is under them and never the pane's own ground.
      var shows = 0, tab = 0, all = 0;
      for (var y = 1; y < grid.lineHeight / 2 - 4; y++) {
        for (var x = start.ceil(); x < end.floor(); x++) {
          all++;
          if (_distance(rgba, w, x, y, under) < 60) shows++;
          if (_distance(rgba, w, x, y, t.surface) < 6) tab++;
        }
      }
      expect(shows, 0, reason: '$shows of $all show what is under');
      expect(tab, lessThan(all ~/ 20), reason: '$tab of $all are a tab');
    });

    testWidgets("on $name an open framed select keeps its frame's sides on "
        'its ground', (tester) async {
      final t = theme();
      await tester.pumpWidget(
        _host(
          t,
          Builder(
            builder: (context) => RawTapTargetScope(
              targets: RawTapTargets.of(context)
                  .copyWith(input: RawInput.pointer),
              child: TermSelect<String>(
                labelText: 'assignee',
                value: 'maya',
                items: const [
                  TermSelectItem(value: 'maya', label: 'maya'),
                  TermSelectItem(value: 'sam', label: 'sam'),
                  TermSelectItem(value: 'noor', label: 'noor'),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TermSelect<String>));
      await tester.pumpAndSettle();
      expect(find.text('noor'), findsOneWidget, reason: 'the list is up');
      final (rgba, w, h) = await _picture(tester);
      final grid = tester.element(find.byType(TermSelect<String>)).termGrid;
      final field = tester.getSize(find.byType(TermFieldFrame));
      final y = (field.height / 2).round();
      // Each side's line, in the accent, about half a cell in from its edge.
      bool lit(int from, int to) =>
          [for (var x = from; x < to; x++) _distance(rgba, w, x, y, t.accent)]
              .any((d) => d < 90);
      final cell = grid.cellWidth.round();
      expect(lit(0, cell), isTrue, reason: 'the start side');
      expect(
        lit(field.width.round() - cell, field.width.round()),
        isTrue,
        reason: 'the end side',
      );
    });

    testWidgets('on $name an open select keeps its brackets on its ground', (
      tester,
    ) async {
      final t = theme();
      await tester.pumpWidget(
        _host(
          t,
          Builder(
            builder: (context) => RawTapTargetScope(
              targets: RawTapTargets.of(context)
                  .copyWith(input: RawInput.pointer),
              child: TermSelect<String>.inline(
                labelText: 'theme',
                value: 'day',
                items: const [
                  TermSelectItem(value: 'system', label: 'system'),
                  TermSelectItem(value: 'day', label: 'day'),
                  TermSelectItem(value: 'night', label: 'night'),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final grid = tester.element(find.byType(TermSelect<String>)).termGrid;
      final indent = TermFieldLine.indentOf(grid, 360, 'theme', null);
      await tester.tapAt(
        tester.getTopLeft(find.byType(TermSelect<String>)) +
            Offset(indent + grid.cellWidth * 4, grid.lineHeight / 2 + 2),
      );
      await tester.pumpAndSettle();
      expect(find.text('night'), findsOneWidget, reason: 'the list is up');
      final (rgba, w, h) = await _picture(tester);
      final field = tester.getSize(find.byType(TermFieldLine));
      // The opening bracket's cell, on the field's line: its strokes in the
      // accent, heavy while the list is up.
      var ink = 0;
      for (var y = 0; y < field.height.floor() && y < h; y++) {
        for (
          var x = indent.floor();
          x < (indent + grid.cellWidth).ceil();
          x++
        ) {
          if (_distance(rgba, w, x, y, t.accent) < 90) ink++;
        }
      }
      expect(ink, greaterThan(grid.fontSize.round()), reason: 'bracket ink');
    });
  }
}

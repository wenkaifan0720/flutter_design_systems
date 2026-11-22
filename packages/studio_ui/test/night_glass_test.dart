// Glass set into the metal reads as a recess by night as it does by day,
// though a shadow can't darken dark glass: the glass reflects the room in a
// strip under the shadow of its top lip, clear of a first row, and the wall
// inside its lower lip catches the light. A pane set into another pane is
// told apart from it the same way, and so is a field's window.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

const _width = 320.0, _height = 160.0;

// The brightness (0 to 255, the mean of the channels) of each row of the
// middle column of the glass [glass] finds, [subject] standing on a night
// panel.
Future<List<double>> _column(
  WidgetTester tester,
  Widget subject,
  Finder glass,
) async {
  final stage = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, page) =>
          StudioTheme(data: StudioThemeData.dark(), child: page!),
      home: Builder(
        builder: (context) => ColoredBox(
          color: StudioTheme.of(context).colors.chassis,
          child: Center(
            child: RepaintBoundary(
              key: stage,
              child: StudioSurface(
                face: StudioTheme.of(context).colors.panelFace,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: subject,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final window = tester
      .getRect(glass)
      .shift(-tester.getTopLeft(find.byKey(stage)));
  final width = tester.getSize(find.byKey(stage)).width.round();
  final pixels = (await tester.runAsync(() async {
    final boundary =
        stage.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
  final x = window.center.dx.round();
  return [
    for (var y = window.top.round(); y < window.bottom.round(); y++)
      () {
        final i = (y * width + x) * 4;
        return (pixels[i] + pixels[i + 1] + pixels[i + 2]) / 3;
      }(),
  ];
}

// A night pane's column, the pane set into other glass or into a panel.
Future<List<double>> _pane(WidgetTester tester, {required bool nested}) {
  const pane = SizedBox(
    key: ValueKey('pane'),
    width: _width,
    height: _height,
    child: StudioDisplay(child: SizedBox.expand()),
  );
  return _column(
    tester,
    nested
        ? const StudioDisplay(padding: EdgeInsets.all(24), child: pane)
        : pane,
    find.byKey(const ValueKey('pane')),
  );
}

// An empty night text field's window.
Future<List<double>> _field(WidgetTester tester) => _column(
  tester,
  const SizedBox(width: _width, child: StudioTextField()),
  find
      .descendant(
        of: find.byType(StudioTextField),
        matching: find.byType(AnimatedStudioSurface),
      )
      .first,
);

void main() {
  for (final nested in [false, true]) {
    final where = nested ? 'in another pane' : 'in a panel';
    testWidgets('by night a pane $where reflects the room under its top lip', (
      tester,
    ) async {
      final rows = await _pane(tester, nested: nested);
      // Below the lip's shadow, in the strip under it, the glass is brighter
      // than at its middle.
      final strip = rows.sublist(0, 24).reduce(math.max);
      final low = rows[(_height * 0.75).round()];
      expect(strip - low, greaterThan(4), reason: '$rows');
      // And the lip's shadow is darker than the reflection under it.
      expect(rows[0], lessThan(strip));
    });
    testWidgets('by night a pane $where reflects the room only under its '
        'lip, clear of its first row', (tester) async {
      final rows = await _pane(tester, nested: nested);
      // A pane's first row starts a gap below its lip: the glass there is no
      // lighter than low down, so the row doesn't read as hovered.
      final low = rows[(_height * 0.75).round()];
      expect(rows[28] - low, lessThan(1), reason: '$rows');
    });
    testWidgets('by night a pane $where shows the lit wall inside its lower '
        'lip', (tester) async {
      final rows = await _pane(tester, nested: nested);
      final wall = rows[_height.round() - 1];
      final glass = rows[_height.round() - 8];
      expect(wall - glass, greaterThan(6));
    });
  }

  testWidgets("by night a field's window reflects the room under its top "
      'lip', (tester) async {
    final rows = await _field(tester);
    final h = rows.length;
    expect(h, greaterThanOrEqualTo(28));
    // Below the lip's shadow the glass is brighter than low down in it.
    expect(rows[h ~/ 4] - rows[h * 3 ~/ 4], greaterThan(2), reason: '$rows');
  });

  testWidgets("by night a field's window shows the lit wall inside its "
      'lower lip', (tester) async {
    final rows = await _field(tester);
    final h = rows.length;
    expect(rows[h - 1] - rows[h - 6], greaterThan(6), reason: '$rows');
  });
}

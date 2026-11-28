// A swipe row in a group: what it shows when open stays on the slab and
// shows whole there. The slab clips its rows at its own round outline, the
// row cuts only where it slides (its start and end), so an action's shadow
// falls soft on the slab, and an action's slab keeps concentric with the
// group's corner. The row's own box cut its action's shadow square (a
// tinted rectangle round the Delete slab, over the groove), and the words
// and the shadow of a top or bottom row stood past the group's round corner.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:ui_core_test/ui_core_test.dart';

const _rows = [
  ('Pride and Prejudice', 'Jane Austen'),
  ('Beloved', 'Toni Morrison'),
  ('Wolf Hall', 'Hilary Mantel'),
];

final _shot = GlobalKey();

Widget _app(Brightness brightness, TextDirection direction, {Widget? only}) =>
    MaterialApp(
      builder: (context, child) => Directionality(
        textDirection: direction,
        child: ClayHost(brightness: brightness, child: child!),
      ),
      home: RepaintBoundary(
        key: _shot,
        child: Builder(
          builder: (context) => ColoredBox(
            color: ClayTheme.of(context).colors.ground,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 358,
                  child:
                      only ??
                      ClayGroup(
                        children: [
                          for (final (title, author) in _rows)
                            ClaySwipeRow(
                              startActions: [
                                ClaySwipeAction(
                                  label: 'Done',
                                  onPressed: () {},
                                ),
                              ],
                              endActions: [
                                ClaySwipeAction(
                                  label: 'Delete',
                                  isDestructiveAction: true,
                                  onPressed: () {},
                                ),
                              ],
                              child: ClayListTile(
                                title: title,
                                subtitle: author,
                                onTap: () {},
                              ),
                            ),
                        ],
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

// Opens [title]'s row on the side [end] names.
Future<void> _open(
  WidgetTester tester,
  String title,
  TextDirection direction, {
  bool end = true,
}) async {
  final toEnd = direction == TextDirection.ltr ? -1.0 : 1.0;
  await tester.dragFrom(
    tester.getCenter(find.text(title)),
    Offset((end ? toEnd : -toEnd) * 70, 0),
  );
  await _settle(tester);
}

Future<(ByteData, int)> _pixels(WidgetTester tester) async {
  final box =
      _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(() => box.toImage()))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final width = image.width;
  image.dispose();
  return (bytes, width);
}

void main() {
  setUpAll(clayLoadFonts);

  for (final brightness in Brightness.values) {
    for (final direction in TextDirection.values) {
      final named = '${brightness.name}, ${direction.name}';

      testWidgets('an open row paints nothing past the slab, $named', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(brightness, direction));
        await _settle(tester);
        final (closed, width) = await _pixels(tester);
        final slab = tester.getRect(
          find
              .descendant(
                of: find.byType(ClayGroup),
                matching: find.byType(ClaySurface),
              )
              .first,
        );
        final theme = ClayTheme.of(tester.element(find.byType(ClayGroup)));
        final outline = RRect.fromRectAndRadius(
          slab,
          Radius.circular(theme.shapeScheme.corners.large),
        ).inflate(1);
        // The top row toward its end, the bottom row toward its start: each
        // round corner of the slab has an open row's action or words at it.
        await _open(tester, _rows.first.$1, direction);
        await _open(tester, _rows.last.$1, direction, end: false);
        final (open, _) = await _pixels(tester);
        final past = <String>[];
        for (var y = slab.top.floor() - 12; y < slab.bottom + 12; y++) {
          for (var x = slab.left.floor() - 12; x < slab.right + 12; x++) {
            if (outline.contains(Offset(x + .5, y + .5))) continue;
            final i = (y * width + x) * 4;
            var most = 0;
            for (var k = 0; k < 4; k++) {
              final d = (open.getUint8(i + k) - closed.getUint8(i + k)).abs();
              if (d > most) most = d;
            }
            if (most > 2) past.add('($x, $y) by $most');
          }
        }
        expect(past, isEmpty, reason: '${past.length} pixels past the slab');
      });

      testWidgets("an open row's action shadow falls whole on the slab, "
          '$named', (tester) async {
        tester.view.physicalSize = const Size(390, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(brightness, direction));
        await _settle(tester);
        await _open(tester, _rows[1].$1, direction);
        final report = await const DesignShadowClipCheck(look: 'Clay').check(
          tester.element(find.byType(ClayGroup)),
          runAsync: tester.runAsync,
        );
        report.verify();
      });
    }
  }

  testWidgets("an action's slab keeps concentric with the group's corner", (
    tester,
  ) async {
    await tester.pumpWidget(_app(Brightness.light, TextDirection.ltr));
    await _settle(tester);
    await _open(tester, _rows.first.$1, TextDirection.ltr);
    final theme = ClayTheme.of(tester.element(find.byType(ClayGroup)));
    final face = tester
        .widget<AnimatedClaySurface>(
          find
              .ancestor(
                of: find.text('Delete'),
                matching: find.byType(AnimatedClaySurface),
              )
              .first,
        )
        .face;
    expect(face.radius, theme.shapeScheme.corners.large - ClaySpacing.tight);
  });

  testWidgets("a row on its own keeps its action's own corner", (tester) async {
    await tester.pumpWidget(
      _app(
        Brightness.light,
        TextDirection.ltr,
        only: ClaySwipeRow(
          endActions: [
            ClaySwipeAction(
              label: 'Delete',
              isDestructiveAction: true,
              onPressed: () {},
            ),
          ],
          child: const ClayListTile(title: 'Pride and Prejudice'),
        ),
      ),
    );
    await _settle(tester);
    await _open(tester, 'Pride and Prejudice', TextDirection.ltr);
    final theme = ClayTheme.of(tester.element(find.byType(ClaySwipeRow)));
    final face = tester
        .widget<AnimatedClaySurface>(
          find
              .ancestor(
                of: find.text('Delete'),
                matching: find.byType(AnimatedClaySurface),
              )
              .first,
        )
        .face;
    expect(face.radius, theme.shapeScheme.corners.medium);
  });
  testWidgets(
    "an app's own row with a fill keeps to the slab's round corners",
    (tester) async {
      tester.view.physicalSize = const Size(390, 200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Future<(ByteData, int)> shot(Color fill) async {
        await tester.pumpWidget(
          _app(
            Brightness.light,
            TextDirection.ltr,
            only: ClayGroup(
              children: [
                ColoredBox(color: fill, child: const SizedBox(height: 56)),
                ColoredBox(color: fill, child: const SizedBox(height: 56)),
              ],
            ),
          ),
        );
        await _settle(tester);
        return _pixels(tester);
      }

      final (bare, width) = await shot(const Color(0x00000000));
      final (filled, _) = await shot(const Color(0xFF2E7D32));
      final slab = tester.getRect(
        find
            .descendant(
              of: find.byType(ClayGroup),
              matching: find.byType(ClaySurface),
            )
            .first,
      );
      final theme = ClayTheme.of(tester.element(find.byType(ClayGroup)));
      final outline = RRect.fromRectAndRadius(
        slab,
        Radius.circular(theme.shapeScheme.corners.large),
      ).inflate(1);
      var past = 0;
      for (var y = slab.top.floor(); y < slab.bottom; y++) {
        for (var x = slab.left.floor(); x < slab.right; x++) {
          if (outline.contains(Offset(x + .5, y + .5))) continue;
          final i = (y * width + x) * 4;
          for (var k = 0; k < 4; k++) {
            if ((filled.getUint8(i + k) - bare.getUint8(i + k)).abs() > 2) {
              past++;
              break;
            }
          }
        }
      }
      expect(
        past,
        0,
        reason: '$past pixels of the rows past the round corners',
      );
    },
  );
}

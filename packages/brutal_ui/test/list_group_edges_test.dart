// A list group clips to its own square, and its rows run to its sides under
// the frame's rule, drawn over them: a pressed row's ink meets the rule on no
// pixel they share (on a fraction a light seam showed between), the act a
// swipe uncovers runs to the frame's edge with its words centred inside the
// rule, nothing a row moves shows past the frame, and a row's words stand
// where they stood, inside the rule.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _shot = ValueKey('shot');
const _red = Color(0xFFFF0000);

Future<void> _pump(WidgetTester tester, double ratio, List<Widget> rows) async {
  tester.view.physicalSize = const Size(390, 600) * ratio;
  tester.view.devicePixelRatio = ratio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: BrutalTheme(
        data: BrutalThemeData.light(),
        child: RepaintBoundary(
          key: _shot,
          child: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: BrutalListGroup(children: rows),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<(ByteData, int)> _grab(WidgetTester tester, double ratio) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shot),
  );
  final image = (await tester.runAsync(
    () => boundary.toImage(pixelRatio: ratio),
  ))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final w = image.width;
  image.dispose();
  return (bytes, w);
}

Rect _tile(WidgetTester tester, String title) => tester.getRect(
  find.ancestor(of: find.text(title), matching: find.byType(BrutalListTile)),
);

void main() {
  final bw = BrutalThemeData.light().borderWidth;

  testWidgets("a group's rows run to its sides, their words where they stood", (
    tester,
  ) async {
    await _pump(tester, 1, [
      BrutalListTile(title: 'Pachinko', onTap: () {}),
      BrutalSwipeRow(
        endActions: [
          BrutalSwipeAction(
            label: 'Delete',
            isDestructiveAction: true,
            onPressed: () {},
          ),
        ],
        child: BrutalListTile(title: 'Stoner', onTap: () {}),
      ),
    ]);
    final frame = tester.getRect(find.byType(BrutalListGroup));
    for (final title in ['Pachinko', 'Stoner']) {
      final row = _tile(tester, title);
      expect(row.left, frame.left, reason: title);
      expect(row.right, frame.right, reason: title);
      expect(
        tester.getRect(find.text(title)).left,
        frame.left + bw + BrutalSpacing.regular,
        reason: '$title: its words inside the rule, as before',
      );
    }
  });

  for (final end in [true, false]) {
    testWidgets(
      "a swipe uncovers its act to the frame's edge, its words inside the rule "
      '(${end ? 'end' : 'start'})',
      (tester) async {
        final act = [
          BrutalSwipeAction(
            label: 'Delete',
            isDestructiveAction: true,
            onPressed: () {},
          ),
        ];
        await _pump(tester, 1, [
          BrutalSwipeRow(
            startActions: end ? const <BrutalSwipeAction>[] : act,
            endActions: end ? act : const <BrutalSwipeAction>[],
            child: BrutalListTile(title: 'Stoner', onTap: () {}),
          ),
        ]);
        final frame = tester.getRect(find.byType(BrutalListGroup));
        await tester.drag(find.text('Stoner'), Offset(end ? -160 : 160, 0));
        await tester.pumpAndSettle();
        final box = tester.getRect(
          find
              .ancestor(
                of: find.text('DELETE'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final words = tester.getRect(find.text('DELETE'));
        // The part of the act inside the rule, where its words centre.
        final (inner, outer) = end
            ? (box.left, frame.right - bw)
            : (box.right, frame.left + bw);
        expect(end ? box.right : box.left, end ? frame.right : frame.left);
        expect(
          end ? words.right <= outer : words.left >= outer,
          isTrue,
          reason: 'its words inside the rule',
        );
        expect(
          words.center.dx,
          moreOrLessEquals((inner + outer) / 2, epsilon: .5),
          reason: 'its words centred on the part inside the rule',
        );
      },
    );
  }

  testWidgets('nothing a row moves shows past the frame', (tester) async {
    await _pump(tester, 1, [
      BrutalListTile(title: 'Pachinko', onTap: () {}),
      Transform.translate(
        offset: const Offset(-24, 0),
        child: const SizedBox(height: 56, child: ColoredBox(color: _red)),
      ),
    ]);
    final frame = tester.getRect(find.byType(BrutalListGroup));
    final band = tester.getRect(find.byType(Transform).last);
    final (bytes, w) = await _grab(tester, 1);
    var spilled = 0;
    final y = band.center.dy.floor();
    for (var x = 0; x < frame.left.floor(); x++) {
      final i = (y * w + x) * 4;
      if (bytes.getUint8(i) > 200 &&
          bytes.getUint8(i + 1) < 60 &&
          bytes.getUint8(i + 2) < 60) {
        spilled++;
      }
    }
    expect(spilled, 0);
  });

  testWidgets("a pressed row's ink meets the frame's rule with no seam", (
    tester,
  ) async {
    const ratio = 2.625;
    await _pump(tester, ratio, [
      BrutalListTile(title: 'Pachinko', onTap: () {}),
      BrutalListTile(title: 'Stoner', onTap: () {}),
    ]);
    final row = _tile(tester, 'Pachinko');
    final press = await tester.startGesture(row.center);
    await tester.pumpAndSettle();
    final (bytes, w) = await _grab(tester, ratio);
    await press.up();
    final ink = BrutalThemeData.light().colors.ink;
    final tone = (ink.r + ink.g + ink.b) / 3;
    double light(int x, int y) {
      final i = (y * w + x) * 4;
      return (bytes.getUint8(i) +
              bytes.getUint8(i + 1) +
              bytes.getUint8(i + 2)) /
          765;
    }

    bool solid(int x, int y) => (light(x, y) - tone).abs() < .04;
    final seams = <String>[];
    // Along rows through the pressed row, beside each of its sides.
    for (
      var y = (row.top * ratio).ceil() + 4;
      y < (row.bottom * ratio).floor() - 4;
      y++
    ) {
      for (final edge in [row.left, row.right]) {
        final at = (edge * ratio).round();
        for (var x = math.max(2, at - 12); x < at + 12; x++) {
          if (solid(x - 2, y) &&
              solid(x - 1, y) &&
              solid(x + 1, y) &&
              solid(x + 2, y) &&
              light(x, y) > tone + .1) {
            seams.add('($x, $y)');
          }
        }
      }
    }
    expect(seams, isEmpty);
  });
}

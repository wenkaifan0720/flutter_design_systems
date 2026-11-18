// A plate seated in a rounded container stands in it by one inset on every
// side it meets, and its corners are the container's less that inset: the
// segmented and tab thumbs at either end of their troughs, a toggle in its
// trough. A tag in the tag field is a capsule, as every key and bead Gloss
// moulds is wherever it sits, and stands in the well by one inset all round.
// At a phone's width and a desk's.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

typedef _Seat = ({Rect rect, double radius});

double _area(Rect r) => r.width * r.height;

/// Every surface [part] paints, the container (the largest) first.
List<_Seat> _seats(WidgetTester tester, Finder part) {
  final seats = [
    for (final e
        in find
            .descendant(of: part, matching: find.byType(GlossSurface))
            .evaluate())
      () {
        final rect = tester.getRect(
          find.byElementPredicate((x) => identical(x, e)),
        );
        final face = (e.widget as GlossSurface).face;
        return (
          rect: rect,
          radius: math.min(
            face.radius ?? rect.shortestSide / 2,
            rect.shortestSide / 2,
          ),
        );
      }(),
  ];
  seats.sort((a, b) => _area(b.rect).compareTo(_area(a.rect)));
  return seats;
}

Future<void> _show(WidgetTester tester, double width, Widget part) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF0E7652),
      builder: (context, _) => GlossTheme(
        data: GlossThemeData.jade(Brightness.light),
        child: Padding(
          padding: const EdgeInsets.all(GlossSpacing.regular),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [part],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// [plate] stands in [well] by [inset] on [sides], its corners the well's
/// less the inset.
void _seated(_Seat well, _Seat plate, double inset, Set<String> sides) {
  final w = well.rect, p = plate.rect;
  final gaps = {
    'left': p.left - w.left,
    'top': p.top - w.top,
    'right': w.right - p.right,
    'bottom': w.bottom - p.bottom,
  };
  for (final side in sides) {
    expect(gaps[side], moreOrLessEquals(inset, epsilon: 0.01), reason: side);
  }
  expect(
    plate.radius,
    moreOrLessEquals(well.radius - inset, epsilon: 0.01),
    reason: 'corner',
  );
}

void main() {
  for (final width in const [390.0, 1440.0]) {
    testWidgets(
      'at ${width.toInt()}: the painted range meets each bead at both endpoints',
      (tester) async {
        const boundaryKey = ValueKey('range');
        for (final direction in TextDirection.values) {
          await _show(
            tester,
            width,
            RepaintBoundary(
              key: boundaryKey,
              child: Directionality(
                textDirection: direction,
                child: GlossRangeSlider(
                  values: const GlossRangeValues(0, 1),
                  onChanged: (_) {},
                ),
              ),
            ),
          );
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(boundaryKey),
          );
          final samples = await tester.runAsync(() async {
            const dpr = 2.0;
            final image = await boundary.toImage(pixelRatio: dpr);
            try {
              final data = (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!;
              final y = image.height ~/ 2;
              // The bead is centered in a 44 px target. Check the groove just beyond
              // its 14 px radius at each end, away from its antialiased edge.
              const inset = 22 + 14 + 3;
              bool jade(double x) {
                final offset = (y * image.width + x.floor()) * 4;
                final red = data.getUint8(offset);
                final green = data.getUint8(offset + 1);
                final blue = data.getUint8(offset + 2);
                return green > red + 24 && green > blue + 11;
              }

              return [jade(inset * dpr), jade(image.width - inset * dpr)];
            } finally {
              image.dispose();
            }
          });
          expect(samples, [
            true,
            true,
          ], reason: 'The jade interval reaches both handles in $direction');
        }
      },
    );
    for (final end in const [false, true]) {
      final ends = end ? {'right', 'top', 'bottom'} : {'left', 'top', 'bottom'};
      testWidgets('at ${width.toInt()}: the segmented thumb at its '
          '${end ? 'end' : 'start'} is concentric in the trough', (
        tester,
      ) async {
        await _show(
          tester,
          width,
          GlossSegmentedButton<String>(
            segments: const [
              GlossSegment(value: 'day', label: 'Day'),
              GlossSegment(value: 'week', label: 'Week'),
              GlossSegment(value: 'month', label: 'Month'),
            ],
            expanded: false,
            selected: end ? 'month' : 'day',
            onChanged: (_) {},
          ),
        );
        final seats = _seats(tester, find.byType(GlossSegmentedButton<String>));
        _seated(seats[0], seats[1], 3, ends);
      });

      testWidgets('at ${width.toInt()}: the tab thumb at its '
          '${end ? 'end' : 'start'} is concentric in the trough', (
        tester,
      ) async {
        await _show(
          tester,
          width,
          GlossTabBar(
            tabs: const ['Method', 'Ingredients', 'Notes'],
            selectedIndex: end ? 2 : 0,
            onSelected: (_) {},
          ),
        );
        final seats = _seats(tester, find.byType(GlossTabBar));
        _seated(seats[0], seats[1], 3, ends);
      });
    }

    testWidgets('at ${width.toInt()}: the first toggle is concentric in the '
        'trough', (tester) async {
      await _show(
        tester,
        width,
        GlossToggleGroup<String>(
          semanticLabel: 'Diet',
          toggles: const [
            GlossToggle(value: 'veg', label: 'Vegan'),
            GlossToggle(value: 'gf', label: 'Gluten-free'),
          ],
          selected: const {'veg'},
          onSelectionChanged: (_) {},
        ),
      );
      final seats = _seats(tester, find.byType(GlossToggleGroup<String>));
      final first = seats
          .skip(1)
          .reduce((a, b) => a.rect.left <= b.rect.left ? a : b);
      _seated(seats[0], first, 2, {'left', 'top', 'bottom'});
    });

    testWidgets('at ${width.toInt()}: a tag stands in the tag field by one '
        'inset all round', (tester) async {
      await _show(
        tester,
        width,
        GlossTagInput<String>(
          // One tag, so the tag and the line share one row.
          values: const ['Quick'],
          options: const ['Quick', 'Batch', 'Freezer'],
          onChanged: (_) {},
        ),
      );
      final seats = _seats(tester, find.byType(GlossTagInput<String>));
      final well = seats[0].rect;
      final seat = seats
          .skip(1)
          .reduce((a, b) => a.rect.left <= b.rect.left ? a : b);
      final tag = seat.rect;
      final top = tag.top - well.top;
      expect(top, greaterThan(0));
      expect(well.bottom - tag.bottom, moreOrLessEquals(top, epsilon: 0.01));
      expect(tag.left - well.left, moreOrLessEquals(top, epsilon: 0.01));
      // A capsule, as Gloss's keys and beads are.
      expect(seat.radius, tag.height / 2);
    });
  }

  testWidgets('alone in the tag field, the typing line stands where a text '
      "field's words do", (tester) async {
    await _show(
      tester,
      390,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlossTagInput<String>(
            values: const [],
            hint: 'Add a tag',
            onChanged: (_) {},
          ),
          const GlossTextField(hint: 'A name'),
        ],
      ),
    );
    expect(
      tester.getTopLeft(find.text('Add a tag')).dx,
      tester.getTopLeft(find.text('A name')).dx,
    );
  });
}

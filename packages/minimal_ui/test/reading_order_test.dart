// Reading order and marks, part by part (review 11-12): a figure, a chord
// and a line of code keep their order right to left; a colour strip keeps
// its colours under its thumb; a face stack, a sparkline and a heatmap run
// from the start edge as the page's charts do, and a stat's arrow leans the
// way its sparkline runs; a carousel's dots stand on
// its middle beside a pause button; a badge's count is centred on its
// host's corner; a stack's faces are cut apart by the ground alone; and
// today wears one ink rim, inside its square, on any day of a heatmap.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

final MinimalThemeData _light = MinimalThemeData.preset(
  'standard',
  Brightness.light,
);

Widget _app(TextDirection direction, Widget part) => MaterialApp(
  builder: (context, navigator) => Directionality(
    textDirection: direction,
    child: MinimalHost(
      light: _light,
      dark: MinimalThemeData.preset('standard', Brightness.dark),
      brightness: Brightness.light,
      child: navigator!,
    ),
  ),
  home: Scaffold(
    body: Center(child: SizedBox(width: 360, child: part)),
  ),
);

void main() {
  testWidgets('a counter prints 12d as 12d right to left', (tester) async {
    await tester.pumpWidget(
      _app(TextDirection.rtl, MinimalCounter(12, format: (v) => '${v}d')),
    );
    double x(String c) => tester.getCenter(find.text(c)).dx;
    expect(x('1'), lessThan(x('2')));
    expect(x('2'), lessThan(x('d')));
  });

  testWidgets('a chord reads left to right in every language', (tester) async {
    await tester.pumpWidget(
      _app(TextDirection.rtl, Center(child: MinimalKbd.chord('G T'))),
    );
    expect(
      tester.getCenter(find.text('G')).dx,
      lessThan(tester.getCenter(find.text('T')).dx),
    );
  });

  testWidgets('a short line of code starts at the left right to left', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(TextDirection.rtl, const MinimalCodeBlock('HAB-4', copyable: false)),
    );
    final well = tester.getRect(find.byType(MinimalCodeBlock));
    expect(tester.getTopLeft(find.text('HAB-4')).dx, lessThan(well.center.dx));
  });

  testWidgets('a colour strip keeps its thumb on its colour right to left', (
    tester,
  ) async {
    // The picker stands on its start, held to the control measure from a
    // tablet up: the hue's thumb is read from the picker's own left edge.
    Rect box() => tester.getRect(
      find
          .descendant(
            of: find.byType(MinimalColorPicker),
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    // The first handle is the hue's.
    double hueAt() =>
        tester.getCenter(find.byType(DesignValueHandle).first).dx - box().left;
    final picker = MinimalColorPicker(
      value: const Color(0xFF2563EB),
      onChanged: (_) {},
    );
    await tester.pumpWidget(_app(TextDirection.ltr, picker));
    final ltr = hueAt();
    await tester.pumpWidget(_app(TextDirection.rtl, picker));
    final rtl = hueAt();
    // Blue is 221 degrees round: right of the strip's middle either way.
    expect(rtl, closeTo(ltr, 0.5));
    expect(rtl, greaterThan(box().width / 2));
  });

  testWidgets('a face stack starts at the start edge right to left', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        TextDirection.rtl,
        const Center(child: MinimalAvatarGroup(['Hanna Berg', 'Oskar Lind'])),
      ),
    );
    expect(
      tester.getCenter(find.text('HB')).dx,
      greaterThan(tester.getCenter(find.text('OL')).dx),
    );
  });

  testWidgets("a stack's faces are cut apart by the ground alone", (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        TextDirection.ltr,
        const Center(
          child: MinimalAvatarGroup([
            'Hanna Berg',
            'Oskar Lind',
            'Ines Duarte',
          ], max: 2),
        ),
      ),
    );
    final rims = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(MinimalAvatarGroup),
            matching: find.byType(Container),
          ),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.border)
        .whereType<Border>()
        .map((b) => b.top.color)
        .toList();
    // Two faces, each rim in the page's ground; the +1 disc is not a face,
    // and wears the border's hairline (as a neutral count does).
    expect(rims, [_light.background, _light.background, _light.border]);
  });

  testWidgets('a sparkline stands now at the start edge right to left', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(TextDirection.rtl, const MinimalSparkline([1, 2, 3], height: 20)),
    );
    final line = find
        .descendant(
          of: find.byType(MinimalSparkline),
          matching: find.byType(CustomPaint),
        )
        .first;
    final width = tester.getSize(line).width;
    expect(
      line,
      paints..something((method, args) {
        if (method != #drawCircle) return false;
        return (args[0] as Offset).dx < width / 2;
      }),
    );
  });

  testWidgets("a stat's arrow leans the way its sparkline runs", (
    tester,
  ) async {
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(
        _app(
          direction,
          const MinimalStat(
            label: 'Kept',
            value: '82%',
            delta: '6%',
            spark: [1, 2, 3],
          ),
        ),
      );
      // Right to left the up-right arrow is drawn mirrored: up-left, toward
      // the end edge, where the line stands now.
      expect(
        find.descendant(
          of: find.byType(Icon),
          matching: find.byType(Transform),
        ),
        direction == TextDirection.rtl ? findsOneWidget : findsNothing,
        reason: '$direction',
      );
    }
  });

  testWidgets('a heatmap puts its oldest week at the start right to left', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        TextDirection.rtl,
        MinimalHeatmap(levels: [2, for (var i = 0; i < 7; i++) 0], weeks: 2),
      ),
    );
    final grid = find
        .descendant(
          of: find.byType(MinimalHeatmap),
          matching: find.byType(CustomPaint),
        )
        .first;
    final width = tester.getSize(grid).width;
    expect(
      grid,
      paints..something((method, args) {
        if (method != #drawRRect) return false;
        final square = args[0] as RRect;
        // A paint keeps 8-bit channels; the theme's colours are floats.
        return (args[1] as Paint).color.toARGB32() ==
                _light.success.toARGB32() &&
            square.left > width / 2;
      }),
    );
  });

  testWidgets('today wears the same ink rim on a kept and an empty day', (
    tester,
  ) async {
    for (final today in [0, 1]) {
      await tester.pumpWidget(
        _app(
          TextDirection.ltr,
          MinimalHeatmap(levels: const [2, 0], weeks: 1, today: today),
        ),
      );
      final grid = find
          .descendant(
            of: find.byType(MinimalHeatmap),
            matching: find.byType(CustomPaint),
          )
          .first;
      expect(
        grid,
        paints..something((method, args) {
          if (method != #drawRRect) return false;
          final paint = args[1] as Paint;
          return paint.style == PaintingStyle.stroke &&
              paint.color.toARGB32() == _light.foreground.toARGB32();
        }),
        reason: 'today on day $today',
      );
      expect(grid, isNot(paints..circle()), reason: 'today on day $today');
      // The rim stands inside the square's edge: today is its neighbours'
      // size and stays inside the grid.
      const pitch = MinimalHeatmap.cell + MinimalHeatmap.gap;
      final square = Rect.fromLTWH(
        0,
        today * pitch,
        MinimalHeatmap.cell,
        MinimalHeatmap.cell,
      );
      expect(
        grid,
        paints..something((method, args) {
          if (method != #drawRRect) return false;
          final paint = args[1] as Paint;
          if (paint.style != PaintingStyle.stroke) return false;
          final outer = (args[0] as RRect).outerRect.inflate(
            paint.strokeWidth / 2,
          );
          return (outer.left - square.left).abs() < 0.01 &&
              (outer.top - square.top).abs() < 0.01 &&
              (outer.right - square.right).abs() < 0.01 &&
              (outer.bottom - square.bottom).abs() < 0.01;
        }),
        reason: 'today on day $today',
      );
      expect(
        tester.getSize(grid),
        const Size(MinimalHeatmap.cell, 7 * pitch - MinimalHeatmap.gap),
        reason: 'no margin round the grid for the rim',
      );
    }
  });

  testWidgets("a playing carousel's dots stand on its middle", (tester) async {
    await tester.pumpWidget(
      _app(
        TextDirection.ltr,
        const MinimalCarouselView(
          height: 120,
          autoplay: Duration(seconds: 3),
          children: [
            SizedBox.expand(),
            SizedBox.expand(),
            SizedBox.expand(),
            SizedBox.expand(),
          ],
        ),
      ),
    );
    // The arrows and the pause button.
    expect(find.byType(MinimalIconButton), findsNWidgets(3));
    expect(
      tester.getCenter(find.byType(MinimalPageDots)).dx,
      closeTo(tester.getCenter(find.byType(MinimalCarouselView)).dx, 0.5),
    );
    // Gone, the carousel stops its timer.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("a badge's count is centred on its host's corner", (
    tester,
  ) async {
    const host = Key('host');
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(
        _app(
          direction,
          const Center(
            child: MinimalBadge(
              count: 3,
              child: SizedBox.square(key: host, dimension: 16),
            ),
          ),
        ),
      );
      final glyph = tester.getRect(find.byKey(host));
      final mark = tester.getRect(
        find
            .ancestor(of: find.text('3'), matching: find.byType(Container))
            .first,
      );
      final cap = mark.height / 2;
      // The count's first round end: its centre on the top-end corner.
      final end = direction == TextDirection.ltr
          ? mark.left + cap - glyph.right
          : mark.right - cap - glyph.left;
      expect(end, closeTo(0, 0.01), reason: direction.name);
      expect(mark.center.dy, closeTo(glyph.top, 0.01), reason: direction.name);
    }
  });
}

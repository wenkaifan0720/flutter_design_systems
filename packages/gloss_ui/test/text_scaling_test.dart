import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

class _AxisCanvas extends TestRecordingCanvas {
  final labels = <Rect>[];

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    labels.add(offset & Size(paragraph.longestLine, paragraph.height));
  }
}

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  double width = 390,
  double height = 620,
  double scale = 2,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF0E7652),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: GlossTheme(
            data: GlossThemeData.jade(Brightness.light),
            child: page!,
          ),
        ),
      ),
      home: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // From 600 wide the calendar opens in its panel; below, in a sheet. Each
  // scrolls to the last week on a short screen.
  for (final (width, height, holder) in const [
    (640.0, 620.0, 'panel'),
    (390.0, 480.0, 'sheet'),
  ]) {
    for (final range in [false, true]) {
      testWidgets(
        'the ${range ? 'range' : 'single-date'} picker\'s $holder scrolls to the last week on a short screen',
        (tester) async {
          final first = DateTime(2026);
          final last = DateTime(2026, 12, 31);
          final today = DateTime(2026, 11, 4);
          DateTime? chosen;
          await _show(
            tester,
            range
                ? GlossDateRangePicker(
                    labelText: 'Plan',
                    value: null,
                    firstDate: first,
                    lastDate: last,
                    currentDate: today,
                    onChanged: (days) => chosen = days.end,
                  )
                : GlossDatePicker(
                    labelText: 'Plan',
                    value: null,
                    firstDate: first,
                    lastDate: last,
                    currentDate: today,
                    onChanged: (day) => chosen = day,
                  ),
            width: width,
            height: height,
          );
          await tester.tap(
            find.byType(range ? GlossDateRangePicker : GlossDatePicker),
          );
          await tester.pumpAndSettle();
          final grid = find.byType(GlossCalendar);
          final day = find.descendant(of: grid, matching: find.text('30')).last;
          final viewport = find
              .ancestor(of: grid, matching: find.byType(Scrollable))
              .first;
          expect(day.hitTestable(), findsNothing);
          await tester.drag(viewport, const Offset(0, -420));
          await tester.pumpAndSettle();
          expect(day.hitTestable(), findsOneWidget);
          if (range) {
            await tester.tap(
              find.descendant(of: grid, matching: find.text('29')).last,
            );
            await tester.pumpAndSettle();
          }
          await tester.tap(day);
          await tester.pumpAndSettle();
          expect(chosen, DateTime(2026, 11, 30));
          expect(grid, findsNothing);
        },
      );
    }
  }

  const series = [
    GlossSeries('Balance', [40, 80, 60, 100]),
  ];
  const labels = ['Jan', 'Feb', 'Mar', 'Apr'];
  for (final chart in const <Widget>[
    GlossLineChart(labels: labels, series: series, semanticLabel: 'Budget'),
    GlossAreaChart(labels: labels, series: series, semanticLabel: 'Budget'),
    GlossBarChart(labels: labels, series: series, semanticLabel: 'Budget'),
  ]) {
    testWidgets(
      '${chart.runtimeType} scales painted axis labels in both reading directions',
      (tester) async {
        for (final dir in TextDirection.values) {
          double? ordinary;
          for (final scale in [1.0, 2.0]) {
            await _show(tester, chart, scale: scale, direction: dir);
            final findPlot = find.descendant(
              of: find.byWidget(chart),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is CustomPaint &&
                    w.painter != null &&
                    w.size == Size.infinite,
              ),
            );
            final plot = tester.renderObject<RenderCustomPaint>(findPlot);
            final canvas = _AxisCanvas();
            plot.painter!.paint(canvas, plot.size);
            expect(canvas.labels.length, greaterThanOrEqualTo(4));
            final tickHeight = canvas.labels.first.height;
            if (ordinary == null) {
              ordinary = tickHeight;
            } else {
              expect(tickHeight, greaterThan(ordinary * 1.8));
              expect(canvas.labels.last.height, greaterThan(ordinary * 1.8));
              for (final rect in canvas.labels) {
                expect(rect.left, greaterThanOrEqualTo(-.01));
                expect(rect.right, lessThanOrEqualTo(plot.size.width + .01));
                expect(rect.top, greaterThanOrEqualTo(-14.01));
                expect(rect.bottom, lessThanOrEqualTo(plot.size.height + 8.01));
              }
              for (final (index, rect) in canvas.labels.indexed) {
                for (final other in canvas.labels.skip(index + 1)) {
                  expect(
                    rect.overlaps(other),
                    isFalse,
                    reason: '$rect overlaps $other',
                  );
                }
              }
            }
          }
        }
      },
    );
  }

  testWidgets('the pie legend reflows and shows each amount in full', (
    tester,
  ) async {
    const chart = GlossPieChart(
      slices: [
        GlossSlice('Supplies', 50),
        GlossSlice('Equipment and tools', 25),
      ],
      semanticLabel: 'Plan A',
    );
    for (final width in [390.0, 900.0]) {
      await _show(tester, chart, width: width);
      final leg = find.text('Supplies 50');
      final other = find.text('Equipment and tools 25');
      final total = find.text('75');
      expect(
        tester.renderObject<RenderParagraph>(leg).didExceedMaxLines,
        isFalse,
      );
      expect(
        tester.renderObject<RenderParagraph>(other).didExceedMaxLines,
        isFalse,
      );
      if (width == 390) {
        expect(
          tester.getTopLeft(leg).dy,
          greaterThan(tester.getBottomLeft(total).dy),
        );
      } else {
        expect(
          tester.getTopLeft(leg).dx,
          greaterThan(tester.getTopRight(total).dx),
        );
      }
    }
  });
}

// A chart reads in the page's direction, as the layout does: right to left
// a line chart's points run from the right, its scale stands at the right,
// and a sparkline's last value (in the accent) is its leftmost cell. Left
// to right both read as before.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

final _stage = GlobalKey();

Future<void> _pump(WidgetTester tester, Locale locale, Widget chart) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(700, 400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: TermTheme(
        data: TermThemeData.dark(),
        child: Builder(
          builder: (context) => ColoredBox(
            color: TermTheme.of(context).background,
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: RepaintBoundary(
                key: _stage,
                child: SizedBox(width: 600, child: chart),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// The stage's pixels, and its width.
Future<(ByteData, int)> _pixels(WidgetTester tester) async =>
    (await tester.runAsync<(ByteData, int)>(() async {
      final boundary =
          _stage.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final width = image.width;
      image.dispose();
      return (data!, width);
    }))!;

int _rgba(Color c) =>
    (c.r * 255).round() << 24 |
    (c.g * 255).round() << 16 |
    (c.b * 255).round() << 8 |
    (c.a * 255).round();

// The painted box of the first CustomPaint whose painter is a [painter],
// within the stage.
Rect _painted(WidgetTester tester, String painter) {
  final paint = find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter.runtimeType.toString() == painter,
  );
  return tester
      .getRect(paint.first)
      .shift(-tester.getTopLeft(find.byKey(_stage)));
}

// The left and right ends of the inked pixels in [band]: neither [ground]
// nor left clear.
(double, double)? _inked(ByteData data, int width, Rect band, Color ground) {
  final page = _rgba(ground);
  double? left, right;
  for (var y = band.top.ceil(); y < band.bottom.floor(); y++) {
    for (var x = band.left.ceil(); x < band.right.floor(); x++) {
      final pixel = data.getUint32((y * width + x) * 4);
      if (pixel == page || pixel & 0xFF == 0) continue;
      left = left == null || x < left ? x.toDouble() : left;
      right = right == null || x > right ? x.toDouble() : right;
    }
  }
  return left == null ? null : (left, right!);
}

void main() {
  setUpAll(loadFaces);

  for (final (locale, rtl) in [
    (const Locale('en'), false),
    (const Locale('ar'), true),
  ]) {
    final way = rtl ? 'right to left' : 'left to right';

    testWidgets("$way a line chart's first point and scale stand at the "
        "line's start", (tester) async {
      await _pump(
        tester,
        locale,
        const TermLineChart(
          series: [
            TermSeries(label: 'hours', values: [9, 0, 0, 0, 0, 0, 0, 0]),
          ],
          semanticLabel: 'hours',
        ),
      );
      final plot = _painted(tester, '_PlotPainter');
      final scale = tester
          .getRect(find.text(rtl ? '٩' : '9'))
          .shift(-tester.getTopLeft(find.byKey(_stage)));
      expect(
        rtl ? scale.left >= plot.right : scale.right <= plot.left,
        isTrue,
        reason: 'the scale at the start: $scale, plot $plot',
      );
      final (data, width) = await _pixels(tester);
      final ground = TermTheme.of(tester.element(find.byType(TermLineChart)))
          .background;
      // The first value is the top: the top line of dots is inked only at
      // the start's end of the plot.
      final top = Rect.fromLTRB(
        plot.left,
        plot.top,
        plot.right,
        plot.top + plot.height / 8,
      );
      final (left, right) = _inked(data, width, top, ground)!;
      if (rtl) {
        expect(left, greaterThan(plot.center.dx), reason: '$left..$right');
      } else {
        expect(right, lessThan(plot.center.dx), reason: '$left..$right');
      }
    });

    testWidgets("$way a sparkline's last value is its cell at the line's end", (
      tester,
    ) async {
      await _pump(
        tester,
        locale,
        const Align(
          alignment: AlignmentDirectional.topStart,
          child: TermSparkline(values: [1, 1, 1, 1, 8]),
        ),
      );
      final spark = _painted(tester, '_SparkPainter');
      final (data, width) = await _pixels(tester);
      final theme = TermTheme.of(tester.element(find.byType(TermSparkline)));
      final accent = _rgba(theme.accent);
      double? at;
      for (
        var y = spark.top.ceil();
        y < spark.bottom.floor() && at == null;
        y++
      ) {
        for (var x = spark.left.ceil(); x < spark.right.floor(); x++) {
          if (data.getUint32((y * width + x) * 4) == accent) {
            at = x.toDouble();
            break;
          }
        }
      }
      expect(at, isNotNull, reason: 'the last cell is in the accent');
      if (rtl) {
        expect(at, lessThan(spark.center.dx));
      } else {
        expect(at, greaterThan(spark.center.dx));
      }
    });
  }
}

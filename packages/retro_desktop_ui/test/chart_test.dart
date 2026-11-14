import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

Widget _host(Widget chart, RetroDesktopThemeData theme) => MaterialApp(
  home: RetroDesktopTheme(
    data: theme,
    child: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: Center(child: SizedBox(width: 240, child: chart)),
    ),
  ),
);

void main() {
  for (final (name, values, point, atTop) in [
    ('one huge value', [1e100], const Offset(50, 50), false),
    // Sample inside the endpoint mark: the second of two values stands in the middle of its band (x 74.5 of the
    // 1..99 plot), on the scale's top line, which stands half a value's line inside the plate (its inset is added).
    ('opposite finite extremes', [-1e308, 1e308], const Offset(74, 2), true),
  ]) {
    testWidgets('$name keeps the data mark in the plot', (tester) async {
      final theme = RetroDesktopThemeData.classic();
      await tester.pumpWidget(
        _host(
          RetroDesktopChart(
            label: 'Observations',
            series: [RetroDesktopChartSeries('Reading', values)],
            format: (value) => value.toStringAsExponential(2),
          ),
          theme,
        ),
      );
      expect(tester.takeException(), isNull);
      final painter = tester
          .widget<CustomPaint>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is CustomPaint &&
                  widget.painter.runtimeType.toString() == '_ChartPainter',
            ),
          )
          .painter!;
      // The scale's inset in the 98 px tall plate: half a value's line, at
      // most a quarter of the plate.
      final pad = (painter as dynamic).pad as double;
      final at = atTop
          ? point.translate(0, pad < 98 / 4 ? pad : 98 / 4)
          : point;
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), const Size(100, 100));
      final picture = recorder.endRecording();
      final pixel = await tester.runAsync(() async {
        final image = await picture.toImage(100, 100);
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final index = (at.dy.toInt() * 100 + at.dx.toInt()) * 4;
        final channels = bytes!.buffer.asUint8List();
        final color = Color.fromARGB(
          channels[index + 3],
          channels[index],
          channels[index + 1],
          channels[index + 2],
        );
        image.dispose();
        return color;
      });
      picture.dispose();
      expect(pixel!.toARGB32(), theme.colors.chartTones.first.toARGB32());
    }, tags: const ['goldens']);
  }

  for (final kind in RetroDesktopChartType.values) {
    testWidgets(
      '${kind.name} tolerates missing data and long axis formatting at 2x',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          const formatted = 'A deliberately long reading in application units';
          await tester.pumpWidget(
            _host(
              RetroDesktopChart(
                label: 'Observations',
                kind: kind,
                series: [
                  RetroDesktopChartSeries('Reading', [
                    null,
                    double.nan,
                    double.infinity,
                    20,
                  ]),
                ],
                format: (_) => formatted,
              ),
              RetroDesktopThemeData.classic(),
            ),
          );
          expect(tester.takeException(), isNull);
          expect(
            tester
                .getSemantics(find.bySemanticsLabel('Observations'))
                .getSemanticsData()
                .value,
            contains(formatted),
          );
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}

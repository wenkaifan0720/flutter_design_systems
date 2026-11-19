import 'dart:io';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

  // On the web an Arabic reader's digits and words come from a fallback face that arrives after the first frame. The
  // chart measured its axes once, against the face it had then, so the wider face cut its values to "…٤" and clipped
  // the day letters. Here the axes' family stands in a narrow face for the first frame, and the reader's wider face
  // joins it after (a face added to a family later takes its glyphs over).
  testWidgets('an Arabic chart names every value and day whole once its face '
      'arrives', (tester) async {
    Future<void> load(String file) async {
      final bytes = File('assets/fonts/$file.ttf').readAsBytesSync();
      await tester.runAsync(
        () => (FontLoader(
          'ChartArrivingFace',
        )..addFont(Future.value(ByteData.sublistView(bytes)))).load(),
      );
    }

    await load('Jersey15-OneFace');
    const digits = '٠١٢٣٤٥٦٧٨٩';
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Localizations(
          locale: const Locale('ar'),
          delegates: const [DefaultWidgetsLocalizations.delegate],
          child: MediaQuery(
            data: const MediaQueryData(),
            child: RetroDesktopTheme(
              data: RetroDesktopThemeData.classic(),
              child: Center(
                child: SizedBox(
                  width: 358,
                  child: RetroDesktopChart(
                    label: 'الساعات',
                    series: [
                      RetroDesktopChartSeries('الساعات', [
                        0,
                        3,
                        4,
                        3.5,
                        3,
                        2.5,
                        0,
                      ]),
                    ],
                    labels: const ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'],
                    format: (v) => '${digits[v.round()]} س',
                    style: const RetroDesktopStyle(
                      textStyle: WidgetStatePropertyAll(
                        TextStyle(fontFamily: 'ChartArrivingFace'),
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
    void expectWhole(String when) {
      final names = tester.renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.byType(RetroDesktopChart),
          matching: find.byType(RichText),
        ),
      );
      final axis = [
        for (final name in names)
          if (name.text.toPlainText().length <= 3) name,
      ];
      expect(axis, hasLength(greaterThanOrEqualTo(7 + 3)), reason: when);
      for (final name in axis) {
        final words = name.text.toPlainText();
        // Measured afresh: a paragraph keeps its intrinsic widths from before a face arrives.
        final whole = TextPainter(
          text: name.text,
          textDirection: name.textDirection,
          textScaler: name.textScaler,
          locale: name.locale,
        )..layout();
        expect(name.didExceedMaxLines, isFalse, reason: '$words $when');
        expect(
          name.size.width,
          greaterThanOrEqualTo(whole.width - 0.5),
          reason: '$words $when',
        );
        whole.dispose();
      }
    }

    expectWhole('in the first face');
    await load('AtkinsonMono-400');
    await tester.pumpAndSettle();
    expectWhole('once the wider face arrived');
  });
}

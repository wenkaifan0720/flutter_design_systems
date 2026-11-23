// A chart's figures are the reader's: Arabic-Indic digits on an Arabic
// page, on the axis and in what a screen reader hears. An app names its
// values (a unit) with valueFormat. A chart whose values are all 0 counts its
// axis 0 and 1, not in tenths.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

import '../example/lib/kit_gallery/kit.dart';

const _days = ['Mon', 'Tue', 'Wed'];

// A recording canvas that takes each paragraph's width as it is drawn (the
// painter disposes its words once painted).
class _Canvas extends TestRecordingCanvas {
  final words = <Rect>[];

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    words.add(offset & Size(paragraph.longestLine, paragraph.height));
    super.drawParagraph(paragraph, offset);
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget chart, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    kitApp(
      brightness: Brightness.light,
      home: Builder(
        builder: (context) => Localizations.override(
          context: context,
          locale: locale,
          child: Directionality(
            textDirection: locale.languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: 400, child: chart),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// The figures up the value axis: the words standing beside the plot, not
// under it.
List<Rect> _figures(WidgetTester tester) {
  final paint = tester
      .renderObjectList<RenderCustomPaint>(
        find.descendant(
          of: find.byType(GlossBarChart),
          matching: find.byType(CustomPaint),
        ),
      )
      .firstWhere((r) => '${r.painter.runtimeType}' == '_BarPainter');
  final canvas = _Canvas();
  paint.painter!.paint(canvas, paint.size);
  final foot = canvas.words.map((w) => w.top).reduce((a, b) => a > b ? a : b);
  return [
    for (final w in canvas.words)
      if (w.top < foot) w,
  ];
}

double _width(WidgetTester tester, String words) {
  final theme = GlossTheme.of(tester.element(find.byType(GlossBarChart)));
  final painter = TextPainter(
    text: TextSpan(text: words, style: theme.textTheme.caption),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

void main() {
  setUpAll(glossLoadFonts);

  testWidgets('an all-zero bar chart counts its axis 0 and 1', (tester) async {
    await _pump(
      tester,
      const GlossBarChart(
        labels: _days,
        series: [
          GlossSeries('Hours', [0, 0, 0]),
        ],
        semanticLabel: 'Hours a day',
      ),
    );
    expect(_figures(tester), hasLength(2));
  });

  testWidgets('an Arabic page reads the figures in Arabic-Indic digits', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      const GlossBarChart(
        labels: ['الاثنين', 'الثلاثاء', 'الأربعاء'],
        series: [
          GlossSeries('الساعات', [2, 6, 3]),
        ],
        semanticLabel: 'ساعات اليوم',
      ),
      locale: const Locale('ar'),
    );
    final readOut = tester
        .getSemantics(find.bySemanticsLabel('ساعات اليوم'))
        .value;
    expect(readOut, contains('٦'));
    expect(readOut, isNot(contains('6')));
    final widest = _figures(tester)
        .map((w) => w.width)
        .reduce((a, b) => a > b ? a : b);
    expect(widest, closeTo(_width(tester, '٦'), 0.5));
    semantics.dispose();
  });

  testWidgets("a chart's valueFormat writes the axis and the read-out", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      const GlossBarChart(
        labels: _days,
        series: [
          GlossSeries('Hours', [2, 6, 3]),
        ],
        semanticLabel: 'Hours a day',
        valueFormat: DesignChartValueFormat(suffix: ' h'),
      ),
    );
    final widest = _figures(tester)
        .map((w) => w.width)
        .reduce((a, b) => a > b ? a : b);
    // Wider than any figure of two digits: the unit is on the axis.
    expect(widest, greaterThan(_width(tester, '66')));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Hours a day')).value,
      contains('Tue 6 h'),
    );
    semantics.dispose();
  });
}

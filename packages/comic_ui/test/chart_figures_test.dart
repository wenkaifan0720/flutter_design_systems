// A chart's figures are the reader's: Arabic-Indic digits on an Arabic page in what a screen reader hears (the axis
// takes the same words); a sparkline says its range in the page's words.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

Future<void> _arabic(WidgetTester tester, Widget chart) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    comicApp(
      Builder(
        builder: (context) => Localizations.override(
          context: context,
          locale: const Locale('ar'),
          delegates: const [RawWidgetsLocalizations.delegate],
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 400, child: chart),
          ),
        ),
      ),
      direction: TextDirection.rtl,
      width: 800,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadComicFonts);

  testWidgets('an Arabic page reads the figures in Arabic-Indic digits', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _arabic(
      tester,
      const ComicChart(
        semanticLabel: 'ساعات اليوم',
        type: ComicChartType.bar,
        labels: ['الاثنين', 'الثلاثاء', 'الأربعاء'],
        series: [
          ComicChartSeries('الساعات', [2, 6, 3]),
        ],
      ),
    );
    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp('ساعات اليوم')),
    );
    final heard = '${node.label} ${node.value}';
    expect(heard, contains('٦'));
    expect(heard, isNot(contains('6')));
    semantics.dispose();
  });

  testWidgets('an Arabic sparkline says its range in Arabic', (tester) async {
    final semantics = tester.ensureSemantics();
    await _arabic(
      tester,
      const ComicSparkline(semanticLabel: 'الأسبوع', values: [2, 6, 3]),
    );
    final node = tester.getSemantics(find.bySemanticsLabel('الأسبوع'));
    expect(node.value, contains('٢'));
    expect(node.value, isNot(contains('to')));
    semantics.dispose();
  });
}

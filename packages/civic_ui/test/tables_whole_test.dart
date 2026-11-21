// The charts in English and in Arabic, on a phone and at 1440, at the
// reader's text and at twice it: no chart's words overlap (a bar's value
// never runs into its neighbour's), and with its table folded out no cell
// is cut (tables_whole.dart). A missing value is said, in its table cell
// and in its bar's place. Every gallery page is held to the same at 390
// and twice the text (words_whole_test).
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';
import 'screens_matrix.dart';
import 'tables_whole.dart';

/// The charts, in English or in Arabic.
Widget _charts({required bool arabic}) {
  String w(String en, String ar) => arabic ? ar : en;
  return ListView(
    padding: const EdgeInsets.all(CivicSpacing.s16),
    children: [
      CivicLineChart(
        title: w('Permits issued each month', 'التصاريح الصادرة كل شهر'),
        labelHeader: w('Month', 'الشهر'),
        labels: arabic
            ? const ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو']
            : const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
        series: [
          CivicChartSeries(w('Resident', 'المقيم'), const [
            120,
            135,
            128,
            142,
            138,
            150,
          ]),
          CivicChartSeries(w('Visitor', 'الزائر'), const [
            80,
            92,
            110,
            104,
            121,
            133,
          ]),
        ],
      ),
      const SizedBox(height: CivicSpacing.s32),
      CivicBarChart(
        title: w('Fines paid by quarter', 'الغرامات المدفوعة كل ربع سنة'),
        labelHeader: w('Quarter', 'الربع'),
        missingLabel: w('No data yet', 'لا توجد بيانات بعد'),
        labels: arabic
            ? const ['الربع ١', 'الربع ٢', 'الربع ٣', 'الربع ٤']
            : const ['Q1', 'Q2', 'Q3', 'Q4'],
        series: const [
          CivicChartSeries('2025', [310, 280, 355, 290]),
          CivicChartSeries('2026', [295, 330, 340, null]),
        ],
      ),
      const SizedBox(height: CivicSpacing.s32),
      CivicPieChart(
        title: w('Permits by kind', 'التصاريح حسب النوع'),
        labelHeader: w('Kind', 'النوع'),
        valueHeader: w('Permits', 'التصاريح'),
        shareHeader: w('Share', 'النسبة'),
        slices: [
          CivicPieSlice(w('Resident', 'المقيم'), 1240),
          CivicPieSlice(w('Visitor', 'الزائر'), 610),
          CivicPieSlice(w('Business', 'الأعمال'), 150),
        ],
      ),
    ],
  );
}

void main() {
  setUpAll(loadScreenFonts);
  for (final arabic in [false, true]) {
    final direction = arabic ? TextDirection.rtl : TextDirection.ltr;
    for (final (width, text) in [(390.0, 1.0), (390.0, 2.0), (1440.0, 1.0)]) {
      final name =
          '${arabic ? 'Arabic' : 'English'} at ${width.round()}, '
          'text ×${text.round()}';
      testWidgets('charts in $name: words apart, cells whole', (tester) async {
        await showScreen(
          tester,
          kitApp(
            brightness: Brightness.light,
            direction: direction,
            home: Directionality(
              textDirection: direction,
              child: ColoredBox(
                color: kitTheme(Brightness.light).ground,
                child: _charts(arabic: arabic),
              ),
            ),
          ),
          width: width,
          height: 2400,
          text: text,
        );
        expect(tester.takeException(), isNull);
        expectChartWordsApart(tester, where: name);
        final l = RawWidgetsLocalizations.of(
          tester.element(find.byType(CivicBarChart)),
        );
        await openChartTables(tester, l.chartShowTableLabel);
        expect(tester.takeException(), isNull);
        expectCellsWhole(tester, where: name);
        // Q4 2026 is missing: its cell says so.
        expect(
          find.text(arabic ? 'لا توجد بيانات بعد' : 'No data yet'),
          findsWidgets,
        );
      });
    }
  }
}

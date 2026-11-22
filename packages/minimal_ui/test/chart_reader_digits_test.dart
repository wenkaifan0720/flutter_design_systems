// A chart's figures are the reader's digits (Arabic's ٤٢ for 42), as its
// dates and times are, and a bar chart takes a format for a value with its
// unit, as the line, area and pie charts do.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

Widget _app(Locale locale, Widget child) => WidgetsApp(
  color: const Color(0xFF000000),
  locale: locale,
  supportedLocales: const [Locale('en'), Locale('ar')],
  localizationsDelegates: const [RawWidgetsLocalizations.delegate],
  builder: (context, _) => MinimalTheme(
    data: MinimalThemeData.standard(),
    child: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: 342, child: child),
    ),
  ),
);

String _heard(WidgetTester tester, Finder of) =>
    tester.getSemantics(of).getSemanticsData().label;

String _all(WidgetTester tester) {
  final labels = <String>[];
  void walk(SemanticsNode node) {
    final data = node.getSemanticsData();
    labels
      ..add(data.label)
      ..add(data.value);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return labels.join(' | ');
}

void main() {
  setUpAll(minimalLoadFonts);

  for (final (locale, fortyTwo) in const [
    (Locale('en'), '42'),
    (Locale('ar'), '٤٢'),
  ]) {
    testWidgets('a bar chart and a pie chart say their figures in '
        '${locale.languageCode} digits', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          locale,
          const Column(
            children: [
              MinimalBarChart([42, 7], labels: ['M', 'T']),
              MinimalPieChart(
                slices: [
                  MinimalChartSlice('Design', 42),
                  MinimalChartSlice('Build', 31),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final heard = _all(tester);
      expect(heard, contains('M: $fortyTwo'));
      expect(heard, contains('Design $fortyTwo'));
      if (locale.languageCode == 'ar') expect(heard, isNot(contains('42')));
      semantics.dispose();
    });
  }

  testWidgets('a bar chart says a value with its unit', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const Locale('en'),
        MinimalBarChart(
          const [2.5, 0],
          labels: const ['Mon', 'Tue'],
          format: (v) => '${v.floor()}h ${((v % 1) * 60).round()}m',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      _heard(tester, find.bySemanticsLabel(RegExp('^Mon'))),
      'Mon: 2h 30m',
    );
    semantics.dispose();
  });
}

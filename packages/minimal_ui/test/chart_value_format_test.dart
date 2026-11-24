// A line chart writes its figures as ui_core's RawChartValueFormat does:
// in the reader's separators (German's 1,5), in thousands from a thousand up.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

Widget _app(Locale locale, Widget child) => WidgetsApp(
  color: const Color(0xFF000000),
  locale: locale,
  supportedLocales: const [Locale('en'), Locale('de')],
  localizationsDelegates: const [RawWidgetsLocalizations.delegate],
  builder: (context, _) => MinimalTheme(
    data: MinimalThemeData.standard(),
    child: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(width: 342, child: child),
    ),
  ),
);

String _all(WidgetTester tester) {
  final words = <String>[];
  void walk(SemanticsNode node) {
    final data = node.getSemanticsData();
    words
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
  return words.join(' | ');
}

void main() {
  setUpAll(minimalLoadFonts);

  testWidgets('a line chart says its values in the reader\'s separators', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const Locale('de'),
        const MinimalLineChart(
          series: [
            MinimalChartSeries('Stunden', [2.5, 4, 1.5]),
          ],
          labels: ['Mo', 'Di', 'Mi'],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final heard = _all(tester);
    expect(heard, contains('Minimum 1,5'));
    expect(heard, isNot(contains('1.5')));
    semantics.dispose();
  });

  testWidgets('a line chart writes thousands as 1.2k', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const Locale('en'),
        const MinimalLineChart(
          series: [
            MinimalChartSeries('Revenue', [1240, 12400]),
          ],
          labels: ['Jan', 'Feb'],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final heard = _all(tester);
    expect(heard, contains('1.2k'));
    expect(heard, contains('12k'));
    semantics.dispose();
  });
}

// Counts read as plurals: one thing and two things, one point and two, one
// slice and two; Larder's Orders never read "1 things". The words come
// through localizations that take the number whole, so another language
// words its own forms: Larder's through its own, a chart's through ui_core's
// (here Russian's one, few and many).
// ignore_for_file: avoid_relative_lib_imports
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/everyday_screens.dart';
import '../example/lib/kit_gallery/larder/words.dart';

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) =>
      ApplianceHost(brightness: Brightness.light, child: app!),
  home: ApplianceScreen(
    body: Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(width: 358, child: child),
    ),
  ),
);

ApplianceDonutChart _donut(int slices) => ApplianceDonutChart(
  semanticLabel: 'Spending by room',
  slices: [for (var i = 0; i < slices; i++) ('Room $i', 10.0 + i)],
);

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  test('Larder counts one thing and two things', () {
    const words = DefaultLarderWords();
    expect(words.things(1), '1 thing');
    expect(words.things(2), '2 things');
    expect(words.searchFound(1, 'tea'), '1 thing for “tea”');
    expect(words.searchFound(2, 'tea'), '2 things for “tea”');
  });

  test('a chart counts one point and two, one slice and two', () {
    const words = DefaultDesignLocalizations();
    expect(words.chartPointCountLabel(1), '1 point');
    expect(words.chartPointCountLabel(2), '2 points');
    expect(words.chartSliceCountLabel(1), '1 slice');
    expect(words.chartSliceCountLabel(2), '2 slices');
  });

  testWidgets('Larder\'s Orders read an order of one as 1 thing', (
    tester,
  ) async {
    _phone(tester);
    final screen = everydayScreens.firstWhere((s) => s.id == 'orders');
    await tester.pumpWidget(screen.app(Brightness.dark, TextDirection.ltr));
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp(r'\b1 things\b')), findsNothing);
    expect(find.textContaining(RegExp(r' · 1 thing$')), findsOneWidget);
  });

  testWidgets('a line chart over one point says point', (tester) async {
    _phone(tester);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const ApplianceLineChart(
          semanticLabel: 'Power',
          labels: ['Mon'],
          series: [
            ApplianceChartSeries('Kettle', [3]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The name, then ui_core's summary as its value.
    expect(
      tester.getSemantics(find.bySemanticsLabel('Power')).value,
      matches(RegExp(r'\b1 point\b')),
    );
    semantics.dispose();
  });

  for (final (count, english) in const [(1, '1 slice'), (2, '2 slices')]) {
    testWidgets('a donut of $count says $english', (tester) async {
      _phone(tester);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_app(_donut(count)));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Spending by room')).value,
        matches(RegExp('\\b$english\\b')),
      );
      semantics.dispose();
    });
  }

  testWidgets('a donut of 1, 2 and 5 in Russian says each form', (
    tester,
  ) async {
    _phone(tester);
    final ru = await DesignLocalizations.delegate.load(const Locale('ru'));
    final forms = {
      for (final n in const [1, 2, 5])
        ru.chartSliceCountLabel(n).replaceAll(RegExp(r'[0-9]'), '').trim(),
    };
    expect(forms, hasLength(3), reason: "Russian's one, few and many");
    final semantics = tester.ensureSemantics();
    for (final count in const [1, 2, 5]) {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Localizations.override(
              context: context,
              locale: const Locale('ru'),
              delegates: const [DesignLocalizations.delegate],
              child: _donut(count),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Spending by room')).value,
        contains(ru.chartSliceCountLabel(count)),
      );
    }
    semantics.dispose();
  });
}

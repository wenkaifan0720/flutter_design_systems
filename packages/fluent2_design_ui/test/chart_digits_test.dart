// A chart the app gives no words for writes its figures in the reader's
// digits: in Arabic a bar's value, a line chart's value axis and what a
// screen reader hears of each chart, in Arabic-Indic digits.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

final _latin = RegExp('[0-9]');
final _arabic = RegExp('[٠-٩]');

Future<void> _pump(WidgetTester t, Widget chart) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(600, 500);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: const Locale('ar'),
      supportedLocales: RawWidgetsLocalizations.supportedLocales,
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        Fluent2Localizations.delegate,
      ],
      builder: (context, child) => Fluent2Host(child: child!),
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (context, _, _) =>
            Center(child: SizedBox(width: 480, child: chart)),
      ),
    ),
  );
  await t.pumpAndSettle();
}

// Every word a screen reader can reach on the page.
List<String> _heard(WidgetTester t) {
  final out = <String>[];
  void walk(SemanticsNode n) {
    out.addAll([n.label, n.value].where((s) => s.isNotEmpty));
    n.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  walk(t.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!);
  return out;
}

// Every word drawn as text on the page.
List<String> _shown(WidgetTester t) => [
  for (final e in find.byType(RichText).evaluate())
    (e.widget as RichText).text.toPlainText(),
];

void main() {
  testWidgets('a bar chart in Arabic writes and says its values in '
      'Arabic-Indic digits', (t) async {
    final semantics = t.ensureSemantics();
    await _pump(
      t,
      const Fluent2BarChart(bars: [Fluent2Bar('ن', 12), Fluent2Bar('ث', 3.5)]),
    );
    final words = [..._shown(t), ..._heard(t)];
    expect(words.where(_latin.hasMatch), isEmpty, reason: '$words');
    expect(words.where(_arabic.hasMatch), isNotEmpty, reason: '$words');
    semantics.dispose();
  });

  testWidgets('a line chart in Arabic says its values in Arabic-Indic '
      'digits', (t) async {
    final semantics = t.ensureSemantics();
    await _pump(
      t,
      const Fluent2LineChart(
        series: [
          Fluent2ChartSeries('الساعات', [1, 4, 2.5]),
        ],
        labels: ['ن', 'ث', 'ر'],
      ),
    );
    final words = _heard(t);
    expect(words.where(_latin.hasMatch), isEmpty, reason: '$words');
    expect(words.where(_arabic.hasMatch), isNotEmpty, reason: '$words');
    semantics.dispose();
  });

  testWidgets('a pie chart in Arabic writes its values in Arabic-Indic '
      'digits', (t) async {
    final semantics = t.ensureSemantics();
    await _pump(
      t,
      const Fluent2PieChart(
        slices: [Fluent2PieSlice('الاستوديو', 8), Fluent2PieSlice('الدليل', 7)],
      ),
    );
    final words = [..._shown(t), ..._heard(t)];
    expect(words.where(_latin.hasMatch), isEmpty, reason: '$words');
    expect(words.where(_arabic.hasMatch), isNotEmpty, reason: '$words');
    semantics.dispose();
  });
}

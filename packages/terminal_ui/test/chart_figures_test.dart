// A chart writes its figures in the reader's digits and separators, as the
// number field writes its value: a bar's value, a line chart's scale and
// the points a screen reader hears, in Arabic-Indic digits with Arabic's
// point and thousands mark, in German with a comma for the point, and in
// English as before, grouped past 999 as the number field groups.
import 'package:flutter/rendering.dart' show RenderParagraph, SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

const _locales = [Locale('en'), Locale('ar'), Locale('de')];

Widget _host(Widget child, Locale locale) => MaterialApp(
  locale: locale,
  supportedLocales: _locales,
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
          child: SizedBox(width: 600, child: child),
        ),
      ),
    ),
  ),
);

List<String> _heard(WidgetTester tester) {
  final said = <String>[];
  bool visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.label.isNotEmpty) said.add(data.label);
    if (data.value.isNotEmpty) said.add(data.value);
    node.visitChildren(visit);
    return true;
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return said;
}

List<String> _painted(WidgetTester tester) => [
  for (final text in tester.widgetList<RichText>(find.byType(RichText)))
    text.text.toPlainText(),
];

const _bars = {
  'en': ['42 min', '2.5 min', '1,482 min'],
  'ar': ['٤٢ min', '٢٫٥ min', '١٬٤٨٢ min'],
  'de': ['42 min', '2,5 min', '1.482 min'],
};

void main() {
  setUpAll(loadFaces);

  test("a grid counts no cell for a direction mark, Arabic's among them", () {
    final grid = TermThemeData.dark().grid;
    // Arabic's minus is its letter mark and a hyphen.
    expect(grid.widthOf('\u061C-٣'), grid.cols(2));
    expect(grid.widthOf('\u200F\u2068a\u2069'), grid.cols(1));
  });

  for (final locale in _locales) {
    final lang = locale.languageCode;
    testWidgets("$lang: bars write their figures in the reader's digits and "
        'separators, and say them so', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const TermBarChart(
            unit: 'min',
            bars: [('api', 42), ('web', 2.5), ('db', 1482)],
          ),
          locale,
        ),
      );
      await tester.pumpAndSettle();
      final painted = _painted(tester);
      final heard = _heard(tester);
      for (final (i, name) in ['api', 'web', 'db'].indexed) {
        final figure = _bars[lang]![i];
        expect(painted, contains(figure));
        expect(heard, contains('$name, $figure'));
        // The value's column holds it on one line. (Arabic's digits are in
        // neither bundled face: the test font draws them a cell and a
        // half wide, where a device's Arabic face draws them about a cell.)
        if (lang != 'ar') {
          final line = tester.renderObject<RenderParagraph>(find.text(figure));
          final boxes = line.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: figure.length),
          );
          expect(boxes.map((b) => b.top).toSet(), hasLength(1), reason: figure);
        }
      }
      semantics.dispose();
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets("$lang: a line chart's scale and points are in the reader's "
        'digits', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const TermLineChart(
            lines: 6,
            series: [
              TermSeries(label: 'latency', values: [120, 135, 128, 160]),
            ],
          ),
          locale,
        ),
      );
      await tester.pumpAndSettle();
      final arabic = lang == 'ar';
      final figures = [
        ..._painted(tester),
        ..._heard(tester),
      ].where((t) => t.contains(RegExp('[0-9٠-٩]'))).toList();
      expect(figures, isNotEmpty);
      for (final text in figures) {
        expect(text.contains(RegExp('[0-9]')), !arabic, reason: text);
        expect(text.contains(RegExp('[٠-٩]')), arabic, reason: text);
      }
      // The scale's top, and a point as a screen reader hears it.
      expect(figures.join(' '), contains(arabic ? '١٦٠' : '160'));
      semantics.dispose();
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  }
}

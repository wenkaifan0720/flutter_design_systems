// Tags, chips, segments, chart legends and monograms: the glyph or swatch that leads words grows with the words
// under the platform's text scaling, as the words do.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

Widget _at(double scale, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: RetroDesktopTheme(
      data: RetroDesktopThemeData.classic().atWidth(1024),
      child: page!,
    ),
  ),
  home: ColoredBox(
    color: const Color(0xffdddddd),
    child: Center(
      child: SizedBox(width: 900, height: 600, child: Center(child: child)),
    ),
  ),
);

void main() {
  Future<double> measure(
    WidgetTester tester,
    double scale,
    Widget part,
    Finder Function() of,
  ) async {
    tester.view.physicalSize = const Size(1024, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_at(scale, part));
    await tester.pumpAndSettle();
    return tester.getSize(of()).height;
  }

  Finder glyph() => find.byIcon(RetroDesktopGlyphs.tag);
  Finder swatch() => find
      .byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_LegendPainter',
      )
      .first;

  final parts = <String, (Widget, Finder Function(), double)>{
    'a tag\'s glyph': (
      const RetroDesktopTag('Draft', icon: RetroDesktopGlyphs.tag),
      glyph,
      12,
    ),
    'a chip\'s glyph': (
      RetroDesktopChip(
        'walnut',
        icon: RetroDesktopGlyphs.tag,
        onPressed: () {},
      ),
      glyph,
      14,
    ),
    'a segment\'s glyph': (
      RetroDesktopSegmentedButton<String>(
        label: 'View',
        value: 'list',
        segments: const [
          RetroDesktopButtonSegment(
            'list',
            'List',
            icon: RetroDesktopGlyphs.tag,
          ),
          RetroDesktopButtonSegment('grid', 'Grid'),
        ],
        onChanged: (_) {},
      ),
      glyph,
      18,
    ),
    'a chart legend\'s swatch': (
      const RetroDesktopChart(
        semanticLabel: 'Hours',
        series: [
          RetroDesktopChartSeries('Hours', [1, 2, 3]),
          RetroDesktopChartSeries('Breaks', [2, 1, 2]),
        ],
        labels: ['M', 'T', 'W'],
      ),
      swatch,
      14,
    ),
    'a monogram': (
      const RetroDesktopMonogram('AC'),
      () => find.byType(RetroDesktopMonogram),
      19,
    ),
  };

  for (final MapEntry(key: name, value: (part, of, own)) in parts.entries) {
    testWidgets('$name grows with the text', (tester) async {
      expect(await measure(tester, 1, part, of), own);
      expect(await measure(tester, 2, part, of), own * 2);
    });
  }
}

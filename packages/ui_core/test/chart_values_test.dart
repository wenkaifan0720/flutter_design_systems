import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

// A week of hours, Monday first.
const _week = [
  RawChartSeries(
    label: 'Hours',
    points: [
      RawChartPoint(0, 2.5),
      RawChartPoint(1, 4),
      RawChartPoint(2, 0),
      RawChartPoint(3, 6),
      RawChartPoint(4, 3),
      RawChartPoint(5, 0),
      RawChartPoint(6, 1),
    ],
  ),
];
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

RawChartDetails? _last;

// A chart in [locale], read in [direction], 400 by 200.
Widget _host({
  Locale locale = const Locale('en'),
  TextDirection direction = TextDirection.ltr,
  RawChartValueFormat? valueFormat,
  RawChartFormat? formatY,
  double Function(List<RawScaleTick> yTicks)? yLabelGutter,
  EdgeInsetsGeometry padding = const EdgeInsets.all(8),
}) => Localizations(
  locale: locale,
  delegates: const [
    RawWidgetsLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ],
  child: Directionality(
    textDirection: direction,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 400,
        height: 200,
        child: RawChart(
          semanticLabel: 'Hours this week',
          series: _week,
          xAxis: RawChartXAxis.band,
          categories: _days,
          padding: padding,
          valueFormat: valueFormat,
          formatY: formatY,
          yLabelGutter: yLabelGutter,
          builder: (context, d) {
            _last = d;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  ),
);

void main() {
  group('RawChartValueFormat', () {
    final en = RawWidgetsLocalizations.forLocale(const Locale('en'));
    final ar = RawWidgetsLocalizations.forLocale(const Locale('ar'));

    test('writes a value in the reader\'s digits with its unit', () {
      const hours = RawChartValueFormat(suffix: ' h');
      expect(hours.format(4, en), '4 h');
      expect(hours.format(2.5, en), '2.5 h');
      expect(hours.format(4, ar), '٤ h');
      expect(
        const RawChartValueFormat(prefix: r'$').format(1240, en),
        r'$1,240',
      );
    });

    test('takes the decimals it is given, else its own, else the '
        'value\'s', () {
      const plain = RawChartValueFormat();
      expect(plain.format(2, en, fractionDigits: 1), '2.0');
      expect(
        const RawChartValueFormat(fractionDigits: 2).format(2, en),
        '2.00',
      );
      expect(plain.format(0.25, en), '0.25');
    });

    test('a builder gets the figure in the reader\'s digits', () {
      // Gloss's compact figures: 1.2k past a thousand.
      final compact = RawChartValueFormat.custom(
        (value, figure, words) => value.abs() >= 1000
            ? '${words.formatDecimal(value / 1000, fractionDigits: 1)}k'
            : figure,
      );
      expect(compact.format(1200, en), '1.2k');
      expect(compact.format(1200, ar), '١٫٢k');
      expect(compact.format(40, ar), '٤٠');
    });

    test('labels a scale\'s ticks at the scale\'s decimals', () {
      final scale = RawLinearScale.nice(min: 0, max: 1, start: 0, end: 100);
      final ticks = scale.ticks(en);
      expect(ticks.map((t) => t.fractionDigits).toSet(), {1});
      const hours = RawChartValueFormat(suffix: ' h');
      expect(hours.labelTicks(ticks, en).map((t) => t.label), [
        '0.0 h',
        '0.2 h',
        '0.4 h',
        '0.6 h',
        '0.8 h',
        '1.0 h',
      ]);
    });
  });

  testWidgets('a chart writes its values with the unit, in the reader\'s '
      'digits, on its axis and in what a screen reader hears', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        locale: const Locale('ar'),
        direction: TextDirection.rtl,
        valueFormat: const RawChartValueFormat(suffix: ' س'),
      ),
    );
    await tester.pump();
    final labels = _last!.yTicks.map((t) => t.label).toList();
    expect(labels.first, '٠ س');
    expect(labels, contains('٦ س'));
    final node = tester.getSemantics(find.byType(RawChart));
    expect(node.value, contains('٦ س'));
    expect(node.value, isNot(contains('6')));
    semantics.dispose();
  });

  testWidgets('formatY still wins over valueFormat', (tester) async {
    await tester.pumpWidget(
      _host(
        valueFormat: const RawChartValueFormat(suffix: ' h'),
        formatY: (v) => 'y$v',
      ),
    );
    expect(_last!.yTicks.first.label, 'y0.0');
  });

  testWidgets('right to left, a week runs from the right: Monday at the '
      'right, and the gutter for the value labels stands at the right', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(direction: TextDirection.rtl, yLabelGutter: (ticks) => 30),
    );
    final d = _last!;
    expect(d.textDirection, TextDirection.rtl);
    final monday = d.x.map(0);
    final sunday = d.x.map(6);
    expect(monday, greaterThan(sunday));
    expect(d.plotArea.right, 400 - 8 - 30);
    expect(d.plotArea.left, 8);
    expect(d.xTicks.first.label, 'Mon');
    expect(d.xTicks.first.position, greaterThan(d.xTicks.last.position));
  });

  testWidgets('left to right, the gutter stands at the left, as wide as '
      'the widest value label measures', (tester) async {
    late List<RawScaleTick> given;
    await tester.pumpWidget(
      _host(
        valueFormat: const RawChartValueFormat(suffix: ' h'),
        yLabelGutter: (ticks) {
          given = ticks;
          return RawScaleTick.widestLabel(
            ticks,
            style: const TextStyle(fontSize: 10),
          );
        },
      ),
    );
    final d = _last!;
    expect(d.textDirection, TextDirection.ltr);
    expect(given.map((t) => t.label), contains('6 h'));
    final widest = RawScaleTick.widestLabel(
      given,
      style: const TextStyle(fontSize: 10),
    );
    expect(widest, greaterThan(0));
    expect(d.plotArea.left, 8 + widest);
    expect(d.plotArea.right, 400 - 8);
  });

  test('widestLabel follows the text scale', () {
    const ticks = [
      RawScaleTick(value: 0, position: 0, label: '0 h'),
      RawScaleTick(value: 10, position: 1, label: '10 h'),
    ];
    const style = TextStyle(fontSize: 10);
    final one = RawScaleTick.widestLabel(ticks, style: style);
    final two = RawScaleTick.widestLabel(
      ticks,
      style: style,
      textScaler: const TextScaler.linear(2),
    );
    expect(two, moreOrLessEquals(one * 2, epsilon: 1));
  });

  testWidgets('a pie chart writes its values with the unit', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('ar'),
        delegates: const [
          RawWidgetsLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            width: 200,
            height: 200,
            child: RawPieChart(
              semanticLabel: 'Time',
              slices: const [
                RawPieSlice(label: 'Design', value: 6),
                RawPieSlice(label: 'Review', value: 2),
              ],
              valueFormat: const RawChartValueFormat(suffix: ' س'),
              builder: (context, d) => const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    final node = tester.getSemantics(find.byType(RawPieChart));
    expect(node.value, contains('٦ س'));
    semantics.dispose();
  });

  test('a scale tick says its decimals; a band\'s and a time\'s say none', () {
    final en = RawWidgetsLocalizations.forLocale(const Locale('en'));
    expect(
      RawLinearScale.nice(
        min: 0,
        max: 100,
        start: 0,
        end: 1,
      ).ticks(en).first.fractionDigits,
      0,
    );
    expect(
      const RawBandScale(
        count: 2,
        start: 0,
        end: 1,
      ).ticks(en).first.fractionDigits,
      isNull,
    );
    // A tick with no decimals of its own takes the value's.
    expect(
      const RawChartValueFormat(suffix: '%')
          .labelTicks(const [
            RawScaleTick(value: 5, position: 0, label: 'x'),
          ], en)
          .single
          .label,
      '5%',
    );
  });
}

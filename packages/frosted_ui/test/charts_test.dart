// Frosted's charts, one test each: every chart is a painter fed by its data,
// sized by its constraints on the phone and the desktop, read aloud as its
// label, with its words drawn as text in the theme's small label.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

const Size _phone = Size(390, 844);
const Size _desktop = Size(1440, 900);

Widget _host(
  Widget child, {
  Brightness brightness = Brightness.light,
  String style = 'opal',
  double textScale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (BuildContext context, Widget? page) => FrostedHost(
    light: FrostedThemeData.preset(style, Brightness.light),
    dark: FrostedThemeData.preset(style, Brightness.dark),
    brightness: brightness,
    child: MediaQuery.withClampedTextScaling(
      minScaleFactor: textScale,
      maxScaleFactor: textScale,
      child: page!,
    ),
  ),
  home: child,
);

/// Pumps [child] in a window of [size], 20 in from each side; nothing may
/// throw or overflow.
Future<void> _pump(
  WidgetTester t,
  Widget child, {
  Size size = _phone,
  Brightness brightness = Brightness.light,
  String style = 'opal',
  double textScale = 1,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    _host(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [child],
        ),
      ),
      brightness: brightness,
      style: style,
      textScale: textScale,
    ),
  );
  expect(t.takeException(), isNull);
}

/// Pumps [chart] on the phone and then the desktop, checking each time that
/// it is read as [label] and stands within its column.
Future<void> _bothWidths(WidgetTester t, Widget chart, String label) async {
  for (final size in [_phone, _desktop]) {
    await _pump(t, chart, size: size);
    expect(
      find.bySemanticsLabel(label),
      findsOneWidget,
      reason: '$label at $size',
    );
    final box = t.getSize(find.byWidget(chart));
    expect(box.width, size.width - 40, reason: '$label at $size');
    expect(box.height, greaterThan(0), reason: '$label at $size');
  }
}

// --- Keel's figures (keel.json) ---------------------------------------------

const List<num> _netWorth = [
  61400, 62900, 64100, 63200, 65600, 67000, //
  68300, 69900, 71600, 73400, 75278.38, 78182.56,
];

const List<String> _months = [
  'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', //
  'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct',
];

/// Everyday's closing balance each day of October so far.
const List<num> _everyday = [
  673.12, 667.32, 667.32, 667.32, 661.52, 655.72, 649.92, 644.12, //
  4050.82, 4050.82, 4050.82, 2864.80, 2861.90, 2859.00, 2856.10, 2853.20,
  2853.20, 2853.20, 2850.30, 2847.40, 2844.50, 2841.60, 6251.20, 6251.20,
  6251.20, 6251.20, 6251.20, 6248.30,
];

/// Investing's value at each day's close in October so far.
const List<num> _investing = [
  50612.40, 50388.15, 50388.15, 50388.15, 50701.92, 50455.30, 50120.84, //
  49876.25, 50034.61, 50034.61, 50034.61, 49702.18, 49388.47, 49165.02,
  49420.66, 49610.35, 49610.35, 49610.35, 49283.90, 48902.14, 48655.37,
  48874.05, 48712.68, 48712.68, 48712.68, 48601.20, 48529.33, 48920.70,
];

/// What October had spent by the end of each day so far.
const List<num> _spentByDay = [
  1172.40, 1210.55, 1274.75, 1371.55, 1390.15, 1402.55, 1447.65, //
  1470.40, 1541.70, 1596.60, 1717.05, 1732.25, 1742.05, 1800.65,
  1833.90, 1852.80, 1945.20, 2021.35, 2035.65, 2063.25, 2105.10,
  2124.80, 2188.20, 2209.35, 2354.90, 2401.30, 2476.47, 2486.12,
];

/// Dining out on each day of October so far.
const List<num> _dining = [
  15.70, 32.35, 29.20, 38.50, 5.25, 0, 4.75, 6.25, 20.05, 0, 13.45, 9.40, //
  0, 23.95, 0, 16.00, 0, 0, 8.41, 7.50, 26.35, 5.75, 6.50, 10.29, 0, 0, 0,
  6.75,
];

/// Interest paid into Savings by month, November to October.
const List<num> _interest = [
  58.12, 60.40, 61.95, 57.30, 64.18, 64.90, //
  67.42, 66.85, 69.77, 71.04, 70.92, 73.42,
];

/// The Lisbon fund at each month's end, and where $150 a month leads it.
const List<num> _lisbonSaved = [
  790,
  940,
  1090,
  1240,
  1390,
  1540,
  1690,
  1840,
  1990,
  2540,
  2690,
  2840,
];
const List<num> _lisbonAhead = [2990, 3140, 3290, 3440, 3590, 3740, 3890];

/// What went into each goal each month: the Emergency fund, Lisbon, the
/// bike.
const List<num> _emergencyByMonth = [
  458.12, 460.40, 461.95, 457.30, 464.18, 464.90, //
  467.42, 466.85, 469.77, 471.04, 470.92, 473.42,
];
const List<num> _lisbonByMonth = [
  150,
  150,
  150,
  150,
  150,
  150,
  150,
  150,
  150,
  550,
  150,
  150,
];
const List<num> _bikeByMonth = [0, 0, 0, 0, 0, 0, 140, 100, 100, 100, 100, 100];

const List<FrostedStep> _bills = [
  FrostedStep(1, 1150, 'Rent'),
  FrostedStep(3, 35, 'Kite Mobile'),
  FrostedStep(12, 1326.44, 'Keel Card'),
  FrostedStep(15, 15.98, 'Newsline'),
  FrostedStep(19, 2.99, 'Cloudbox'),
  FrostedStep(27, 10.99, 'Streamline Music'),
];

const List<FrostedAxisMark> _octoberAxis = [
  FrostedAxisMark.first('Oct 1'),
  FrostedAxisMark(7, '8'),
  FrostedAxisMark(14, '15'),
  FrostedAxisMark(21, '22'),
  FrostedAxisMark(27, 'Today', current: true),
];

const List<FrostedAxisMark> _novemberAxis = [
  FrostedAxisMark.first('Nov 1'),
  FrostedAxisMark(7, '8'),
  FrostedAxisMark(14, '15'),
  FrostedAxisMark(21, '22'),
  FrostedAxisMark.last('30'),
];

const List<FrostedAxisMark> _goalAxis = [
  FrostedAxisMark.first('Nov 2025'),
  FrostedAxisMark(11, 'Today', current: true),
  FrostedAxisMark.last('May 2027'),
];

const List<FrostedChartNote> _everydayNotes = [
  FrostedChartNote(1, 'Rent and goals'),
  FrostedChartNote(9, 'Paycheck'),
  FrostedChartNote(12, 'Card autopay'),
  FrostedChartNote(23, 'Paycheck'),
];

Widget _goal({List<num> projection = _lisbonAhead}) => Builder(
  builder: (context) => FrostedGoalChart(
    saved: _lisbonSaved,
    projection: projection,
    target: 4000,
    endDate: DateTime(2027, 5),
    hue: context.frostedTheme.hues.sunset,
    marks: _goalAxis,
    label: 'Lisbon in May: saved, and where it is headed',
  ),
);

Widget _fan({List<VoidCallback?> taps = const [null, null, null, null]}) =>
    Builder(
      builder: (context) {
        final hues = context.frostedTheme.hues;
        return FrostedFan(
          flows: [
            FrostedFanEnd(
              amount: 400,
              hue: hues.azure,
              title: 'Emergency fund',
              subtitle: 'Auto-save · Sun, Nov 1',
              onPressed: taps[0],
            ),
            FrostedFanEnd(
              amount: 150,
              hue: hues.sunset,
              title: 'Lisbon in May',
              subtitle: 'Auto-save · Sun, Nov 1',
              onPressed: taps[1],
            ),
            FrostedFanEnd(
              amount: 100,
              hue: hues.lime,
              title: 'New bike',
              subtitle: 'Auto-save · Sun, Nov 1',
              onPressed: taps[2],
            ),
            FrostedFanEnd(
              amount: 1326.44,
              hue: hues.slate,
              title: 'Keel Card autopay',
              subtitle: 'Autopay · Thu, Nov 12',
              onPressed: taps[3],
            ),
          ],
          source: hues.cyan,
          label: 'What leaves Everyday on its own in November',
        );
      },
    );

/// Every chart at once, for the presets and the narrow phone.
List<Widget> _all() => [
  const FrostedTrailChart(
    values: _netWorth,
    months: _months,
    label: 'Net worth over the last 12 months',
  ),
  const FrostedTrailChart.steps(
    values: _everyday,
    start: 2479.82,
    daysInMonth: 31,
    notes: _everydayNotes,
    marks: _octoberAxis,
    label: 'Everyday balance through October',
  ),
  const FrostedTrailChart.days(
    values: _investing,
    daysInMonth: 31,
    marks: _octoberAxis,
    label: 'Investing value through October',
  ),
  const FrostedSpendChart(
    spent: _spentByDay,
    budget: 2700,
    daysInMonth: 31,
    firstNote: 'Rent',
    marks: _octoberAxis,
    label: 'October spending against the budget pace',
  ),
  _goal(),
  Builder(
    builder: (context) => FrostedDayBars(
      values: _dining,
      daysInMonth: 31,
      hue: context.frostedTheme.hues.coral,
      marks: _octoberAxis,
      label: 'Dining out, each day in October',
    ),
  ),
  Builder(
    builder: (context) => FrostedDayBars.months(
      values: _interest,
      months: _months,
      hue: context.frostedTheme.hues.seafoam,
      label: 'Interest earned each month',
    ),
  ),
  Builder(
    builder: (context) {
      final hues = context.frostedTheme.hues;
      return FrostedDayBars.stacked(
        series: [
          FrostedBarSeries(hues.azure, _emergencyByMonth),
          FrostedBarSeries(hues.sunset, _lisbonByMonth),
          FrostedBarSeries(hues.lime, _bikeByMonth),
        ],
        months: _months,
        lines: 4,
        label: 'Put away each month',
      );
    },
  ),
  const FrostedStepsChart(
    steps: _bills,
    daysInMonth: 30,
    marks: _novemberAxis,
    label: 'November bills, added up through the month',
  ),
  _fan(),
  Builder(
    builder: (context) => FrostedChartKey(
      keys: [
        const FrostedKey(FrostedKeySwatch.line, 'Spent', figure: '\$2,486.12'),
        const FrostedKey(FrostedKeySwatch.pace, 'Budget pace'),
        FrostedKey(
          FrostedKeySwatch.projection,
          'Projected',
          hue: context.frostedTheme.hues.sunset,
        ),
      ],
    ),
  ),
];

void main() {
  setUp(
    () =>
        TestWidgetsFlutterBinding
            .instance
            .platformDispatcher
            .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        ),
  );
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  testWidgets('FrostedTrailChart draws the year by month, a month by day and a '
      'balance by its steps', (t) async {
    const year = FrostedTrailChart(
      values: _netWorth,
      months: _months,
      label: 'Net worth over the last 12 months',
    );
    await _pump(t, year);
    // The grid every $10k, named at the end; the months' initials under
    // the columns, October in the page ink; 140 tall, the months 8 under
    // on their 12 line.
    for (final value in ['\$80k', '\$70k', '\$60k']) {
      expect(find.text(value), findsOneWidget, reason: value);
    }
    expect(find.text('O'), findsOneWidget);
    expect(find.text('Oct'), findsNothing);
    expect(t.getSize(find.byWidget(year)).height, 140 + 8 + 12);
    final october = t.widget<Text>(find.text('O'));
    expect(october.style!.color, context(t).colorScheme.textPrimary);
    expect(october.style!.fontWeight, FontWeight.w600);
    await _bothWidths(t, year, 'Net worth over the last 12 months');
    expect(find.text('Oct'), findsOneWidget);
    expect(t.getSize(find.byWidget(year)).height, 210 + 8 + 12);

    const days = FrostedTrailChart.days(
      values: _investing,
      daysInMonth: 31,
      marks: _octoberAxis,
      label: 'Investing value through October',
    );
    await _bothWidths(t, days, 'Investing value through October');
    for (final word in ['Oct 1', '8', '15', '22', 'Today', '\$50k']) {
      expect(find.text(word), findsOneWidget, reason: word);
    }
    expect(t.getSize(find.byWidget(days)).height, 210 + 8 + 16);

    const steps = FrostedTrailChart.steps(
      values: _everyday,
      start: 2479.82,
      daysInMonth: 31,
      notes: _everydayNotes,
      marks: _octoberAxis,
      label: 'Everyday balance through October',
    );
    await _bothWidths(t, steps, 'Everyday balance through October');
    expect(find.text('Paycheck'), findsNWidgets(2));
    expect(find.text('Card autopay'), findsOneWidget);
    expect(find.text('Rent and goals'), findsOneWidget);
    for (final value in ['\$7.5k', '\$5k', '\$2.5k', '\$0']) {
      expect(find.text(value), findsOneWidget, reason: value);
    }
    // A rise's note stands over its cliff, a fall's under it.
    final paycheck = t.getRect(find.text('Paycheck').first);
    final autopay = t.getRect(find.text('Card autopay'));
    expect(paycheck.bottom, lessThan(autopay.top));
    await _pump(t, steps);
    expect(t.getSize(find.byWidget(steps)).height, 150 + 8 + 16);

    // A bare trail is the line alone: no grid values, no months, 140 tall.
    const bare = FrostedTrailChart(
      values: _netWorth,
      bare: true,
      label: 'Net worth over the last 12 months',
    );
    await _bothWidths(t, bare, 'Net worth over the last 12 months');
    expect(find.text('\$80k'), findsNothing);
    expect(find.text('Oct'), findsNothing);
    await _pump(t, bare);
    expect(t.getSize(find.byWidget(bare)).height, 140);
  });

  testWidgets('FrostedSpendChart lays the month against its budget pace', (
    t,
  ) async {
    const chart = FrostedSpendChart(
      spent: _spentByDay,
      budget: 2700,
      daysInMonth: 31,
      firstNote: 'Rent',
      marks: _octoberAxis,
      label: 'October spending against the budget pace',
    );
    await _bothWidths(t, chart, 'October spending against the budget pace');
    for (final word in ['Budget \$2,700', '\$2k', '\$1k', 'Rent', 'Oct 1']) {
      expect(find.text(word), findsOneWidget, reason: word);
    }
    expect(find.text('\$3k'), findsNothing);
    await _pump(t, chart);
    expect(t.getSize(find.byWidget(chart)).height, 176 + 8 + 16);
    // Today stands at its day's point, 28 of 31 across the plot (the
    // plot is the width less the 36 gutter), and the budget's name over
    // its rule at the start.
    final box = t.getRect(find.byWidget(chart));
    final today = t.getRect(find.text('Today'));
    expect(today.center.dx, moreOrLessEquals(box.left + 28 / 31 * 314));
    expect(t.getRect(find.text('Budget \$2,700')).left, box.left);
    expect(
      find.bySemanticsLabel('October spending against the budget pace'),
      findsOneWidget,
    );
  });

  testWidgets('FrostedGoalChart runs what was saved on to the target', (
    t,
  ) async {
    await _bothWidths(
      t,
      _goal(),
      'Lisbon in May: saved, and where it is headed',
    );
    for (final word in [
      'Target \$4,000',
      '\$3,890 by May 2027',
      'Nov 2025',
      'Today',
      'May 2027',
    ]) {
      expect(find.text(word), findsOneWidget, reason: word);
    }
    await _pump(t, _goal());
    expect(t.getSize(find.byType(FrostedGoalChart)).height, 170 + 8 + 16);
    // The projection's end, under the target, names itself under its
    // point with its right edge there; today 12 of 19 columns across.
    final box = t.getRect(find.byType(FrostedGoalChart));
    final end = t.getRect(find.text('\$3,890 by May 2027'));
    expect(
      end.right,
      moreOrLessEquals(box.left + 18.5 / 19 * 310, epsilon: 0.01),
    );
    expect(end.top, greaterThan(t.getRect(find.text('Target \$4,000')).bottom));
    expect(
      t.getRect(find.text('Today')).center.dx,
      moreOrLessEquals(box.left + 11.5 / 19 * 310, epsilon: 0.01),
    );
    // Without a projection there is no end to name.
    await _pump(t, _goal(projection: const []));
    expect(find.textContaining(' by '), findsNothing);
    expect(find.text('Target \$4,000'), findsOneWidget);
  });

  testWidgets('FrostedKey draws its swatch as the CSS does: the spectrum, dots '
      '4 on and 3 off, a projection 2 on and 4 off', (t) async {
    await _pump(
      t,
      const Center(child: FrostedKey(FrostedKeySwatch.pace, 'Budget pace')),
    );
    Finder swatch() => find
        .descendant(
          of: find.byType(FrostedKey),
          matching: find.byType(CustomPaint),
        )
        .first;
    expect(t.getSize(swatch()), const Size(16, 2));
    expect(find.text('Budget pace'), findsOneWidget);
    expect(
      t.renderObject(swatch()),
      paints
        ..clipRRect(
          rrect: RRect.fromLTRBR(0, 0, 16, 2, const Radius.circular(1)),
        )
        ..path(
          includes: const [Offset(2, 1), Offset(9, 1), Offset(15, 1)],
          excludes: const [Offset(5.5, 1), Offset(12.5, 1)],
        ),
    );
    await _pump(
      t,
      Center(
        child: Builder(
          builder: (context) => FrostedKey(
            FrostedKeySwatch.projection,
            'Projected',
            hue: context.frostedTheme.hues.sunset,
          ),
        ),
      ),
    );
    expect(t.getSize(swatch()), const Size(16, 2.5));
    expect(
      t.renderObject(swatch()),
      paints
        ..clipRRect()
        ..path(
          includes: const [Offset(1, 1.25), Offset(7, 1.25), Offset(13, 1.25)],
          excludes: const [Offset(4, 1.25), Offset(10, 1.25)],
        ),
    );
    await _pump(
      t,
      const Center(
        child: FrostedKey(FrostedKeySwatch.line, 'Spent', figure: '\$2,486.12'),
      ),
    );
    expect(t.getSize(swatch()), const Size(16, 2));
    expect(
      t.renderObject(swatch()),
      paints
        ..clipRRect()
        ..rect(rect: const Rect.fromLTWH(0, 0, 16, 2)),
    );
    // The word stands 8 past the swatch, the figure 8 past the word's dot
    // (`.key`'s gap between its items: the words' last space collapses).
    final words = t.getRect(find.text('Spent ·'));
    expect(words.left - t.getRect(swatch()).right, 8);
    expect(t.getRect(find.text('\$2,486.12')).left - words.right, 8);
    expect(find.bySemanticsLabel('Spent · \$2,486.12'), findsOneWidget);
  });

  testWidgets('FrostedChartKey lines its keys up 16 apart, 12 in a head', (
    t,
  ) async {
    const keys = [
      FrostedKey(FrostedKeySwatch.line, 'Spent'),
      FrostedKey(FrostedKeySwatch.pace, 'Budget pace'),
    ];
    await _pump(t, const FrostedChartKey(keys: keys));
    expect(find.byType(FrostedKey), findsNWidgets(2));
    final a = t.getRect(find.byType(FrostedKey).first);
    final b = t.getRect(find.byType(FrostedKey).last);
    expect(b.left - a.right, 16);
    await _pump(t, const FrostedChartKey(keys: keys, inHead: true));
    expect(
      t.getRect(find.byType(FrostedKey).last).left -
          t.getRect(find.byType(FrostedKey).first).right,
      12,
    );
  });

  testWidgets('FrostedDayBars draws a month day by day, a year by month, and '
      'the months stacked', (t) async {
    final days = Builder(
      builder: (context) => FrostedDayBars(
        values: _dining,
        daysInMonth: 31,
        hue: context.frostedTheme.hues.coral,
        marks: _octoberAxis,
        label: 'Dining out, each day in October',
      ),
    );
    await _bothWidths(t, days, 'Dining out, each day in October');
    for (final word in ['Oct 1', 'Today', '\$40', '\$10']) {
      expect(find.text(word), findsOneWidget, reason: word);
    }
    expect(t.getSize(find.byType(FrostedDayBars)).height, 150 + 8 + 16);
    await _pump(t, days);
    expect(t.getSize(find.byType(FrostedDayBars)).height, 120 + 8 + 16);

    final months = Builder(
      builder: (context) => FrostedDayBars.months(
        values: _interest,
        months: _months,
        hue: context.frostedTheme.hues.seafoam,
        label: 'Interest earned each month',
      ),
    );
    await _bothWidths(t, months, 'Interest earned each month');
    for (final word in ['+\$73.42', '\$75', '\$50', '\$25', 'Oct']) {
      expect(find.text(word), findsOneWidget, reason: word);
    }
    await _pump(t, months);
    expect(find.text('O'), findsOneWidget);
    expect(t.getSize(find.byType(FrostedDayBars)).height, 140 + 8 + 12);
    // The value stands over the latest bar's top right corner in the
    // hue's ink, semibold, in the display face.
    final value = t.widget<Text>(find.text('+\$73.42'));
    expect(value.style!.color, context(t).hues.seafoam.ink);
    expect(value.style!.fontWeight, FontWeight.w600);
    final box = t.getRect(find.byType(FrostedDayBars));
    final slot = (350 - 36) / 12;
    expect(
      t.getRect(find.text('+\$73.42')).right,
      moreOrLessEquals(box.left + 11.5 * slot + slot * 0.5 / 2, epsilon: 0.01),
    );

    final stacked = Builder(
      builder: (context) {
        final hues = context.frostedTheme.hues;
        return FrostedDayBars.stacked(
          series: [
            FrostedBarSeries(hues.azure, _emergencyByMonth),
            FrostedBarSeries(hues.sunset, _lisbonByMonth),
            FrostedBarSeries(hues.lime, _bikeByMonth),
          ],
          months: _months,
          lines: 4,
          label: 'Put away each month',
        );
      },
    );
    await _bothWidths(t, stacked, 'Put away each month');
    for (final word in ['+\$723', '\$1.25k', '\$250']) {
      expect(find.text(word), findsOneWidget, reason: word);
    }
    expect(
      t.widget<Text>(find.text('+\$723')).style!.color,
      context(t).colorScheme.textPrimary,
    );
    await _pump(t, stacked);
    expect(t.getSize(find.byType(FrostedDayBars)).height, 150 + 8 + 12);
  });

  testWidgets('FrostedStepsChart adds the bills up, the largest two named', (
    t,
  ) async {
    const chart = FrostedStepsChart(
      steps: _bills,
      daysInMonth: 30,
      marks: _novemberAxis,
      label: 'November bills, added up through the month',
    );
    await _bothWidths(t, chart, 'November bills, added up through the month');
    for (final word in ['Nov 1', '8', '15', '22', '30', '\$3k', '\$1k']) {
      expect(find.text(word), findsOneWidget, reason: word);
    }
    expect(find.text('Rent \$1,150', findRichText: true), findsOneWidget);
    expect(find.text('Keel Card \$1,326', findRichText: true), findsOneWidget);
    expect(find.textContaining('Kite Mobile'), findsNothing);
    await _pump(t, chart);
    expect(t.getSize(find.byWidget(chart)).height, 150 + 8 + 16);
    // The card's name stands 8 past its step at the centre of the 12th
    // day, centred on the riser.
    final box = t.getRect(find.byWidget(chart));
    final card = t.getRect(find.text('Keel Card \$1,326', findRichText: true));
    expect(card.left, moreOrLessEquals(box.left + 11.5 / 30 * 314 + 8));
    expect(
      card.top,
      lessThan(t.getRect(find.text('Rent \$1,150', findRichText: true)).top),
    );
  });

  testWidgets("FrostedAxisMark.startingAt starts its word at its slot's "
      'centre; a plain mark centres under it', (t) async {
    await _pump(
      t,
      Builder(
        builder: (context) => FrostedDayBars(
          values: _dining,
          daysInMonth: 31,
          hue: context.frostedTheme.hues.coral,
          marks: const [
            FrostedAxisMark.startingAt(0, 'Oct 1'),
            FrostedAxisMark(7, '8'),
          ],
          label: 'Dining out, each day in October',
        ),
      ),
    );
    final box = t.getRect(find.byType(FrostedDayBars));
    // The words' row ends the bars' gutter (36 on a phone) short.
    final row = box.width - 36;
    expect(
      t.getRect(find.text('Oct 1')).left,
      moreOrLessEquals(box.left + 0.5 / 31 * row, epsilon: 0.5),
    );
    expect(
      t.getRect(find.text('8')).center.dx,
      moreOrLessEquals(box.left + 7.5 / 31 * row, epsilon: 0.5),
    );
  });

  testWidgets('FrostedRecordChart stands its head 10 over the plot and the '
      'axis words 18 under it, the column gap over their own 8', (t) async {
    final days = Builder(
      builder: (context) => FrostedRecordChart(
        head: Text(
          'Each day in October',
          style: context.frostedTheme.textTheme.labelMedium,
        ),
        chart: FrostedDayBars(
          values: _dining,
          daysInMonth: 31,
          hue: context.frostedTheme.hues.coral,
          marks: _octoberAxis,
          label: 'Dining out, each day in October',
        ),
      ),
    );
    await _pump(t, days);
    final head = t.getRect(find.text('Each day in October'));
    final bars = t.getRect(find.byType(FrostedDayBars));
    expect(bars.top - head.bottom, 10);
    // The plot is 120 on a phone; the day words 8 + 10 under it, 16 tall.
    expect(bars.height, 120 + 8 + 10 + 16);

    final months = Builder(
      builder: (context) => FrostedRecordChart(
        chart: FrostedDayBars.months(
          values: _interest,
          months: _months,
          hue: context.frostedTheme.hues.seafoam,
          label: 'Interest earned each month',
        ),
      ),
    );
    await _pump(t, months);
    expect(t.getSize(find.byType(FrostedDayBars)).height, 140 + 8 + 10 + 12);
    // A chart alone keeps its words 8 under the plot.
    await _pump(
      t,
      FrostedStepsChart(
        steps: _bills,
        daysInMonth: 30,
        marks: _novemberAxis,
        label: 'November bills, added up through the month',
      ),
    );
    expect(t.getSize(find.byType(FrostedStepsChart)).height, 150 + 8 + 16);
  });

  testWidgets('FrostedFan fans the flows out, each row a link beside where it '
      'lands', (t) async {
    final opened = <String>[];
    final fan = _fan(
      taps: [
        () => opened.add('emergency'),
        null,
        null,
        () => opened.add('card'),
      ],
    );
    await _bothWidths(t, fan, 'What leaves Everyday on its own in November');
    for (final word in [
      'Emergency fund',
      'Lisbon in May',
      'New bike',
      'Keel Card autopay',
      'Autopay · Thu, Nov 12',
    ]) {
      expect(find.text(word), findsOneWidget, reason: word);
    }
    expect(find.text('\$1,326.44', findRichText: true), findsOneWidget);
    expect(find.text('\$400.00', findRichText: true), findsOneWidget);
    expect(t.getSize(find.byType(FrostedFan)).height, 280);
    await _pump(t, fan);
    expect(t.getSize(find.byType(FrostedFan)).height, 228);
    // The rows start 114 in (the bars at 96, 6 wide, then 12), at least
    // 44 apart, each centred on its destination.
    final box = t.getRect(find.byType(FrostedFan));
    final first = t.getRect(find.text('Emergency fund'));
    expect(first.left, box.left + 96 + 6 + 12);
    final rows = [
      for (final w in [
        'Emergency fund',
        'Lisbon in May',
        'New bike',
        'Keel Card autopay',
      ])
        t.getRect(find.text(w)).center.dy,
    ];
    for (var i = 1; i < rows.length; i++) {
      expect(rows[i] - rows[i - 1], greaterThanOrEqualTo(44));
    }
    // A row with somewhere to go is a link read as its words.
    expect(
      find.bySemanticsLabel('Emergency fund, Auto-save · Sun, Nov 1, \$400.00'),
      findsOneWidget,
    );
    await t.tap(find.text('Emergency fund'));
    await t.tap(find.text('Keel Card autopay'));
    expect(opened, ['emergency', 'card']);
    expect(find.bySemanticsLabel(RegExp(r'^Lisbon in May,')), findsNothing);
  });

  testWidgets('The charts stand in both presets, light and dark', (t) async {
    for (final style in ['opal', 'quartz']) {
      for (final brightness in Brightness.values) {
        await _pump(
          t,
          Expanded(
            child: SingleChildScrollView(child: Column(children: _all())),
          ),
          brightness: brightness,
          style: style,
        );
        expect(
          find.bySemanticsLabel('Put away each month'),
          findsOneWidget,
          reason: '$style $brightness',
        );
      }
    }
  });

  testWidgets('The charts fit a 320 phone at text scale 1.3', (t) async {
    await _pump(
      t,
      Expanded(
        child: SingleChildScrollView(child: Column(children: _all())),
      ),
      size: const Size(320, 640),
      textScale: 1.3,
    );
    expect(
      find.bySemanticsLabel('Net worth over the last 12 months'),
      findsOneWidget,
    );
    for (final chart in _all()) {
      await _pump(t, chart, size: const Size(320, 640), textScale: 1.3);
    }
  });
}

/// The theme the pumped page shows.
FrostedThemeData context(WidgetTester t) =>
    t.element(find.byType(Padding).first).frostedTheme;

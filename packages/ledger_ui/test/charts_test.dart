// The Stage C charts: every engraving fed the Keel pilot's figures (copied
// from the gallery's generated keel.dart), sized by the column it is given
// on a phone and at desktop width, light and dark, and read as one node:
// its label and, where it has one, its value.
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:ledger_ui/src/ledger/internal/plot.dart';

// --- The frame ---------------------------------------------------------------

const Size _phone = Size(390, 844);
const Size _desktop = Size(1440, 900);

/// The column a chart is given: the window less the gutter at each side.
double _column(bool wide) =>
    wide ? _desktop.width - 2 * 56 : _phone.width - 2 * 24;

Widget _host(Widget child, Brightness brightness) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => LedgerHost(brightness: brightness, child: page!),
  home: Builder(
    builder: (context) => SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: LedgerLayout.gutter(context),
        vertical: 24,
      ),
      child: child,
    ),
  ),
);

Future<void> _pump(
  WidgetTester t,
  Widget child, {
  Size size = _phone,
  Brightness brightness = Brightness.light,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(_host(child, brightness));
}

/// Pumps [child] on a phone and at desktop width, light and dark. Each lays
/// out clean (nothing overflows or throws, no words cut short), then
/// [check] runs.
Future<void> _everywhere(
  WidgetTester t,
  Widget child, [
  void Function(bool wide)? check,
]) async {
  for (final size in const [_phone, _desktop]) {
    for (final brightness in Brightness.values) {
      await _pump(t, child, size: size, brightness: brightness);
      final where = '${size.width.round()} wide, ${brightness.name}';
      expect(t.takeException(), isNull, reason: where);
      _expectWordsFit(t, where);
      check?.call(size == _desktop);
    }
  }
}

/// Every line of words stands whole: none clipped at its end or its foot.
void _expectWordsFit(WidgetTester t, String where) {
  for (final p in t.allRenderObjects.whereType<RenderParagraph>()) {
    if (!p.hasSize) continue;
    final words = p.text.toPlainText();
    final oneLine = !p.softWrap || p.maxLines == 1;
    if (oneLine) {
      expect(
        p.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(p.size.width + .5),
        reason: '"$words" is cut short ($where)',
      );
    } else {
      expect(p.didExceedMaxLines, isFalse, reason: '"$words" ($where)');
    }
    expect(
      p.getMinIntrinsicHeight(p.size.width),
      lessThanOrEqualTo(p.size.height + .5),
      reason: '"$words" is cut at its foot ($where)',
    );
  }
}

/// Every label and value the semantics tree speaks, in its order.
List<String> _spoken(WidgetTester t) {
  final words = <String>[];
  void walk(SemanticsNode node) {
    if (node.isMergedIntoParent) return;
    final data = node.getSemanticsData();
    if (data.label.isNotEmpty) words.add(data.label);
    if (data.value.isNotEmpty) words.add(data.value);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  for (final view in t.binding.renderViews) {
    final root = view.owner?.semanticsOwner?.rootSemanticsNode;
    if (root != null) walk(root);
  }
  return words;
}

/// The plot's size: as wide as its column, as tall as [phone] (the source's
/// phone plot is the column's 342) or the desktop plot's aspect.
Size _plot(bool wide, {required double phone, required Size desk}) {
  final w = _column(wide);
  return Size(w, wide ? w * desk.height / desk.width : phone);
}

/// The plot's drawn size.
Size _plotSize(WidgetTester t) => t.getSize(find.byType(LedgerPlot));

/// [size] to within a hundredth (the plot multiplies its aspect out).
Matcher _about(Size size) => isA<Size>()
    .having((s) => s.width, 'width', closeTo(size.width, .01))
    .having((s) => s.height, 'height', closeTo(size.height, .01));

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    // The look names its faces as the package that bundles them registers
    // them (ledgerFontFamily); a family a package already names keeps it.
    final loader = FontLoader(
      family.startsWith('packages/') ? family : ledgerFontFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

List<LedgerGridLine> _grid(List<(double, String)> lines) => [
  for (final (value, label) in lines) LedgerGridLine(value, label),
];

// --- The pilot's figures (copied from the gallery's keel.dart) ---------------

const List<double> _netWorthK = [
  61.4,
  62.9,
  64.1,
  63.2,
  65.6,
  67,
  68.3,
  69.9,
  71.6,
  73.4,
  75.2784,
  78.1826,
];
const List<(double, String)> _netWorthGrid = [
  (80, '80k'),
  (70, '70k'),
  (60, '60k'),
];
const List<String> _months = [
  'N',
  'D',
  'J',
  'F',
  'M',
  'A',
  'M',
  'J',
  'J',
  'A',
  'S',
  'O',
];

const List<double> _cumulative = [
  1172.4,
  1210.55,
  1274.75,
  1371.55,
  1390.15,
  1402.55,
  1447.65,
  1470.4,
  1541.7,
  1596.6,
  1717.05,
  1732.25,
  1742.05,
  1800.65,
  1833.9,
  1852.8,
  1945.2,
  2021.35,
  2035.65,
  2063.25,
  2105.1,
  2124.8,
  2188.2,
  2209.35,
  2354.9,
  2401.3,
  2476.47,
  2486.12,
];
const List<(double, String)> _cumulativeGrid = [(2000, '\$2k'), (1000, '\$1k')];

const List<double> _daily = [
  1172.4,
  38.15,
  64.2,
  96.8,
  18.6,
  12.4,
  45.1,
  22.75,
  71.3,
  54.9,
  120.45,
  15.2,
  9.8,
  58.6,
  33.25,
  18.9,
  92.4,
  76.15,
  14.3,
  27.6,
  41.85,
  19.7,
  63.4,
  21.15,
  145.55,
  46.4,
  75.17,
  9.65,
];
const List<(double, String)> _dailyGrid = [
  (150, '\$150'),
  (100, '\$100'),
  (50, '\$50'),
];
const List<(int, String)> _paydays = [
  (23, 'Pay +\$3,412.50'),
  (9, 'Pay +\$3,412.50'),
];

const List<double> _diningDays = [
  15.7,
  32.35,
  29.2,
  38.5,
  5.25,
  0,
  4.75,
  6.25,
  20.05,
  0,
  13.45,
  9.4,
  0,
  23.95,
  0,
  16,
  0,
  0,
  8.41,
  7.5,
  26.35,
  5.75,
  6.5,
  10.29,
  0,
  0,
  0,
  6.75,
];
const List<(double, String)> _diningGrid = [(40, '\$40'), (20, '\$20')];

const List<(int, double)> _visits = [
  (28, 6.75),
  (23, 6.5),
  (22, 5.75),
  (21, 7.5),
  (20, 7.5),
  (16, 5.5),
  (14, 7.25),
  (9, 7),
  (8, 6.25),
  (7, 4.75),
  (5, 5.25),
  (2, 8.25),
  (1, 6),
];

const List<double> _everyday = [
  673.12,
  667.32,
  667.32,
  667.32,
  661.52,
  655.72,
  649.92,
  644.12,
  4050.82,
  4050.82,
  4050.82,
  2864.8,
  2861.9,
  2859,
  2856.1,
  2853.2,
  2853.2,
  2853.2,
  2850.3,
  2847.4,
  2844.5,
  2841.6,
  6251.2,
  6251.2,
  6251.2,
  6251.2,
  6251.2,
  6248.3,
];
const List<(double, String)> _everydayGrid = [
  (6000, '\$6k'),
  (4000, '\$4k'),
  (2000, '\$2k'),
];
const List<(int, String, bool)> _everydayMarks = [
  (23, 'Pay +\$3,412.50', true),
  (9, 'Pay +\$3,412.50', true),
  (12, 'Card −\$1,180.22', false),
];

const List<double> _investing = [
  50612.4,
  50388.15,
  50388.15,
  50388.15,
  50701.92,
  50455.3,
  50120.84,
  49876.25,
  50034.61,
  50034.61,
  50034.61,
  49702.18,
  49388.47,
  49165.02,
  49420.66,
  49610.35,
  49610.35,
  49610.35,
  49283.9,
  48902.14,
  48655.37,
  48874.05,
  48712.68,
  48712.68,
  48712.68,
  48601.2,
  48529.33,
  48920.7,
];
const List<(double, String)> _investingGrid = [
  (51000, '\$51k'),
  (50000, '\$50k'),
  (49000, '\$49k'),
  (48000, '\$48k'),
];

const List<double> _interest = [
  58.12,
  60.4,
  61.95,
  57.3,
  64.18,
  64.9,
  67.42,
  66.85,
  69.77,
  71.04,
  70.92,
  73.42,
];

const List<(int, double)> _billSteps = [
  (1, 1150),
  (3, 35),
  (12, 1326.44),
  (15, 15.98),
  (19, 2.99),
  (27, 10.99),
];
const List<(double, String)> _billsGrid = [(2000, '\$2k'), (1000, '\$1k')];
const List<(int, String, String, double, double)> _billNotes = [
  (0, 'Rent', '\$1,150.00 · Nov 1', 40, 46),
  (2, 'Keel Card payment', '\$1,326.44 · Nov 12', 74, 76),
];

const List<double> _savedByMonth = [
  16521.85,
  17132.25,
  17744.2,
  18351.5,
  18965.68,
  19580.58,
  20338,
  21054.85,
  21774.62,
  22895.66,
  23616.58,
  24340,
];
const List<(double, String)> _goalsGrid = [(25000, '\$25k'), (20000, '\$20k')];

const List<(int, double)> _lisbonHist = [
  (0, 790),
  (1, 940),
  (2, 1090),
  (3, 1240),
  (4, 1390),
  (5, 1540),
  (6, 1690),
  (7, 1840),
  (8, 1990),
  (9, 2540),
  (10, 2690),
  (11, 2840),
];
const List<(int, double)> _lisbonProj = [
  (12, 2990),
  (13, 3140),
  (14, 3290),
  (15, 3440),
  (16, 3590),
  (17, 3740),
  (18, 3890),
];
const List<(double, String)> _lisbonGrid = [
  (3000, '\$3,000'),
  (2000, '\$2,000'),
  (1000, '\$1,000'),
];
const List<String> _lisbonKeys = [
  'N',
  'D',
  'J',
  'F',
  'M',
  'A',
  'M',
  'J',
  'J',
  'A',
  'S',
  'O',
  'N',
  'D',
  'J',
  'F',
  'M',
  'A',
  'M',
];

void main() {
  setUpAll(_loadFonts);
  setUpAll(_stillMotion);
  tearDownAll(_movingMotion);

  group('the plot data', () {
    test("a note hangs on the desktop as on a phone unless told", () {
      const note = LedgerChartNote(0, '**Rent**\n\$1,150.00 · Nov 1', lift: 40);
      expect(note.deskLift, 40);
      expect(note.deskText, note.text);
      const told = LedgerChartNote(
        0,
        '**Rent**\n\$1,150.00 · Nov 1',
        lift: 40,
        deskLift: 46,
        deskText: '**Rent** \$1,150.00 · Nov 1',
      );
      expect(told.deskLift, 46);
      expect(told.deskText, '**Rent** \$1,150.00 · Nov 1');
    });

    test('a mark stands above its point unless below', () {
      expect(const LedgerChartMark(23, 'Pay +\$3,412.50').below, isFalse);
      expect(
        const LedgerChartMark(12, 'Card −\$1,180.22', below: true).below,
        isTrue,
      );
      const bracket = LedgerChartBracket(2, 11, '2026 to date **\$667.75**');
      expect((bracket.first, bracket.last), (2, 11));
      const line = LedgerGridLine(2000, '\$2k');
      expect((line.value, line.label), (2000, '\$2k'));
    });
  });

  testWidgets('LedgerNetWorthChart reads its label and its end', (t) async {
    await _everywhere(
      t,
      LedgerNetWorthChart(
        values: _netWorthK,
        low: 56,
        high: 82,
        grid: _grid(_netWorthGrid),
        endLabel: 'Oct 78.18k',
        months: _months,
      ),
      (wide) {
        expect(_spoken(t), ['Net worth by month', 'Oct 78.18k']);
        expect(
          _plotSize(t),
          _about(_plot(wide, phone: 168, desk: const Size(712, 330))),
        );
        for (final (_, label) in _netWorthGrid) {
          expect(find.text(label), findsOneWidget);
        }
        expect(find.text('Oct 78.18k'), findsOneWidget);
        // A key under each month, the last green.
        expect(find.text('O'), findsOneWidget);
        expect(
          t.widget<Text>(find.text('O')).style?.color,
          t.element(find.text('O')).ledgerTheme.pace,
        );
      },
    );
  });

  testWidgets(
    'LedgerCumulativeChart reads its budget; the day ruler under it',
    (t) async {
      await _everywhere(
        t,
        LedgerCumulativeChart(
          cumulative: _cumulative,
          budget: 2700,
          days: 31,
          high: 3000,
          grid: _grid(_cumulativeGrid),
          budgetLabel: 'Budget \$2,700',
          note: const LedgerChartNote(
            0,
            '**Rent** \$1,150.00 · Oct 1',
            lift: 74,
            deskLift: 62,
          ),
        ),
        (wide) {
          expect(_spoken(t), [
            'Spent through the month against the budget',
            'Budget \$2,700',
          ]);
          expect(
            _plotSize(t),
            _about(_plot(wide, phone: 248, desk: const Size(712, 392))),
          );
          expect(find.text('Budget \$2,700'), findsOneWidget);
          expect(find.text('Rent \$1,150.00 · Oct 1'), findsOneWidget);
          // The 1st, the 8th, the 15th, the 22nd, today and the last day.
          for (final day in ['Oct 1', '8', '15', '22', '31']) {
            expect(find.text(day), findsOneWidget, reason: day);
          }
          expect(find.text('Today'), wide ? findsOneWidget : findsNothing);
          expect(find.text('28'), wide ? findsNothing : findsOneWidget);
        },
      );
    },
  );

  group('LedgerDayBars', () {
    testWidgets('the month by day, the rent day broken off, paydays ringed', (
      t,
    ) async {
      await _everywhere(
        t,
        LedgerDayBars(
          values: _daily,
          days: 31,
          cap: 190,
          capLabels: const {1: '**\$1,172.40** Oct 1, rent day'},
          marks: [
            for (final (day, text) in _paydays) LedgerChartMark(day, text),
          ],
          grid: _grid(_dailyGrid),
        ),
        (wide) {
          expect(_spoken(t), ['Spent per day']);
          expect(
            _plotSize(t),
            _about(_plot(wide, phone: 132, desk: const Size(712, 236))),
          );
          expect(find.text('Pay +\$3,412.50'), findsNWidgets(2));
          expect(find.text('\$1,172.40 Oct 1, rent day'), findsOneWidget);
          // A phone keeps the grid's top line alone.
          expect(find.text('\$150'), findsOneWidget);
          expect(find.text('\$100'), wide ? findsOneWidget : findsNothing);
          expect(find.text('\$50'), wide ? findsOneWidget : findsNothing);
        },
      );
    });

    testWidgets("a category's days at its own heights", (t) async {
      await _everywhere(
        t,
        LedgerDayBars(
          values: _diningDays,
          days: 31,
          grid: _grid(_diningGrid),
          high: 43.2,
          height: 120,
          deskHeight: 268,
        ),
        (wide) {
          expect(_spoken(t), ['Spent per day']);
          expect(_plotSize(t), _about(Size(_column(wide), wide ? 268 : 120)));
        },
      );
    });
  });

  testWidgets('LedgerVisitRuler reads its count, its two ends labelled', (
    t,
  ) async {
    await _everywhere(
      t,
      const LedgerVisitRuler(
        visits: _visits,
        days: 31,
        today: 28,
        current: 28,
        startLabel: 'Oct 1',
        endLabel: 'Oct 31',
      ),
      (wide) {
        expect(_spoken(t), ['13 payments this month']);
        expect(_plotSize(t), _about(Size(_column(wide), 34)));
        final ruler = t.getRect(find.byType(LedgerVisitRuler));
        expect(t.getRect(find.text('Oct 1')).left, ruler.left);
        expect(t.getRect(find.text('Oct 31')).right, closeTo(ruler.right, .5));
      },
    );
  });

  group('LedgerMonthLine', () {
    testWidgets("Everyday's balance: paydays above, the card's payment below", (
      t,
    ) async {
      await _everywhere(
        t,
        LedgerMonthLine(
          values: _everyday,
          start: 2479.82,
          days: 31,
          low: 0,
          high: 7400,
          grid: _grid(_everydayGrid),
          marks: [
            for (final (day, text, above) in _everydayMarks)
              LedgerChartMark(day, text, below: !above),
          ],
        ),
        (wide) {
          expect(_spoken(t), ['Balance through the month']);
          expect(
            _plotSize(t),
            _about(_plot(wide, phone: 196, desk: const Size(712, 300))),
          );
          expect(find.text('Pay +\$3,412.50'), findsNWidgets(2));
          // Day 9's pay (the second mark) stands over its point and day
          // 12's card payment hangs under its own, lower one.
          final pay = t.getRect(find.text('Pay +\$3,412.50').last);
          final card = t.getRect(find.text('Card −\$1,180.22'));
          expect(card.top, greaterThan(pay.bottom));
        },
      );
    });

    testWidgets('a value through the month reads its end', (t) async {
      await _everywhere(
        t,
        LedgerMonthLine(
          values: _investing,
          start: 50428.82,
          days: 31,
          low: 47400,
          high: 51300,
          grid: _grid(_investingGrid),
          endLabel: 'Today 48.92k',
          endAbove: true,
          height: 176,
        ),
        (wide) {
          expect(_spoken(t), ['Balance through the month', 'Today 48.92k']);
          expect(
            _plotSize(t),
            _about(_plot(wide, phone: 176, desk: const Size(712, 300))),
          );
          expect(find.text('Today 48.92k'), findsOneWidget);
        },
      );
    });
  });

  testWidgets('LedgerMonthBars brackets the year to date', (t) async {
    await _everywhere(
      t,
      LedgerMonthBars(
        values: _interest,
        bracket: LedgerChartBracket(
          2,
          _interest.length - 1,
          '2026 to date **\$667.75**',
        ),
        marks: [LedgerChartMark(_interest.length - 1, '+\$73.42')],
        months: _months,
      ),
      (wide) {
        expect(_spoken(t), ['By month']);
        expect(
          _plotSize(t),
          _about(_plot(wide, phone: 164, desk: const Size(712, 240))),
        );
        expect(find.text('2026 to date \$667.75'), findsOneWidget);
        expect(find.text('+\$73.42'), findsOneWidget);
        expect(find.text('O'), findsOneWidget);
      },
    );
  });

  testWidgets('LedgerStepTotal names its large bills, broken on a phone', (
    t,
  ) async {
    await _everywhere(
      t,
      LedgerStepTotal(
        steps: _billSteps,
        days: 30,
        high: 3000,
        grid: _grid(_billsGrid),
        notes: [
          for (final (index, name, rest, lift, deskLift) in _billNotes)
            LedgerChartNote(
              index,
              '**$name**\n$rest',
              lift: lift,
              deskLift: deskLift,
              deskText: '**$name** $rest',
            ),
        ],
      ),
      (wide) {
        expect(_spoken(t), ['Bills summed as they fall due']);
        expect(
          _plotSize(t),
          _about(_plot(wide, phone: 220, desk: const Size(712, 320))),
        );
        final rent = wide
            ? 'Rent \$1,150.00 · Nov 1'
            : 'Rent\n\$1,150.00 · Nov 1';
        expect(find.text(rent), findsOneWidget);
        for (final day in ['Nov 1', '8', '15', '22', '30']) {
          expect(find.text(day), findsOneWidget, reason: day);
        }
      },
    );
  });

  group('LedgerGoalChart', () {
    testWidgets('the goals saved against their target, the gap to go', (
      t,
    ) async {
      await _everywhere(
        t,
        LedgerGoalChart(
          history: [
            for (var i = 0; i < _savedByMonth.length; i++)
              (i, _savedByMonth[i]),
          ],
          months: _savedByMonth.length,
          target: 29800,
          low: 15000,
          high: 31886,
          grid: _grid(_goalsGrid),
          targetLabel: 'Target \$29,800',
          gapLabel: 'To go **\$5,460**',
          keys: _months,
          now: _savedByMonth.length - 1,
          height: 280,
          deskHeight: 268,
        ),
        (wide) {
          expect(_spoken(t), [
            'Saved over time against the target',
            'Target \$29,800',
          ]);
          expect(_plotSize(t), _about(Size(_column(wide), wide ? 268 : 280)));
          expect(find.text('Target \$29,800'), findsOneWidget);
          expect(find.text('To go \$5,460'), findsOneWidget);
        },
      );
    });

    testWidgets('a goal and its projection to its date', (t) async {
      await _everywhere(
        t,
        const LedgerGoalChart(
          history: _lisbonHist,
          projection: _lisbonProj,
          months: 19,
          target: 4000,
          low: 0,
          high: 4400,
          grid: [
            LedgerGridLine(3000, '\$3,000'),
            LedgerGridLine(2000, '\$2,000'),
            LedgerGridLine(1000, '\$1,000'),
          ],
          targetLabel: 'Target \$4,000',
          endLabel: '\$3,890\nby May 2027',
          keys: _lisbonKeys,
          now: 11,
        ),
        (wide) {
          expect(_spoken(t), [
            'Saved over time against the target',
            'Target \$4,000',
          ]);
          expect(
            _plotSize(t),
            _about(_plot(wide, phone: 196, desk: const Size(712, 300))),
          );
          expect(find.textContaining('\$3,890'), findsOneWidget);
          for (final (_, label) in _lisbonGrid) {
            expect(find.text(label), findsOneWidget);
          }
        },
      );
    });
  });
}

/// Reduced motion on, as a reader who asked for it has it: every Ledger
/// change lands at once, so a test reads the settled frame.
void _stillMotion() =>
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );

/// The platform's own motion back.
void _movingMotion() => TestWidgetsFlutterBinding.instance.platformDispatcher
    .clearAccessibilityFeaturesTestValue();

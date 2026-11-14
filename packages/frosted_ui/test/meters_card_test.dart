// Frosted's meters and cards, one test each at Keel's own values: the prism
// track and its parts, the legend, bars, meters, the over bar, compare and
// merchant bars, in against out, the split, the statement, the visit strip,
// the due line, balance changes, the route, the done mark; the Keel Card
// (plain, frozen, on its desktop stage), the debit card, the card number,
// a goal's card and row, the new-goal card, the mosaic and a pane; then
// every one of them at 320 wide and text scale 1.3 in both presets, light
// and dark.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pumps [child] across a phone's page (or a window of [size]), 20 in from
/// each side, under Frosted's host in [preset] and [brightness], at
/// [textScale] and reading [direction]; nothing may throw.
Future<void> _pump(
  WidgetTester t,
  Widget child, {
  Size size = const Size(390, 844),
  Brightness brightness = Brightness.light,
  String preset = 'opal',
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
  bool check = true,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? page) => FrostedHost(
        light: FrostedThemeData.preset(preset, Brightness.light),
        dark: FrostedThemeData.preset(preset, Brightness.dark),
        brightness: brightness,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Directionality(textDirection: direction, child: page!),
        ),
      ),
      home: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [child],
        ),
      ),
    ),
  );
  if (check) expect(t.takeException(), isNull);
}

/// The node a screen reader lands on for [label].
SemanticsNode _node(WidgetTester t, String label) =>
    t.getSemantics(find.bySemanticsLabel(label));

/// Where the pane named [name] lies.
Rect _paneRect(WidgetTester t, String name) => t.getRect(
  find.byWidgetPredicate((w) => w is FrostedPane && w.name == name),
);

/// The theme in force at the first [finder] match.
FrostedThemeData _theme(WidgetTester t, Finder finder) =>
    t.element(finder.first).frostedTheme;

/// The width the [Text] at [finder] takes laid out alone, in its style
/// and scale: what it measures when nothing has shortened it.
double _textWidth(WidgetTester t, Finder finder) {
  final element = t.element(finder);
  final text = element.widget as Text;
  final painter = TextPainter(
    text: TextSpan(
      text: text.data,
      style: DefaultTextStyle.of(element).style.merge(text.style),
    ),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(element),
  )..layout();
  return painter.width;
}

/// The page's content width: the phone's 390 less the 20 gutters.
const double _w = 350;

const _aKey = ValueKey<String>('band-a');
const _bKey = ValueKey<String>('band-b');

Widget _track({double? pace, String? paceLabel, Widget? scaleStart}) => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedTrack(
      bands: [
        FrostedBand(3, hue: t.hues.cyan, name: 'Everyday', key: _aKey),
        FrostedBand(1, hue: t.hues.seafoam, name: 'Savings', key: _bKey),
      ],
      pace: pace,
      paceLabel: paceLabel,
      scaleStart: scaleStart,
    );
  },
);

Widget _goalsTrack() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        FrostedTrack(
          bands: [
            FrostedBand(20860, hue: t.hues.azure, name: 'Emergency fund'),
            FrostedBand(2840, hue: t.hues.sunset, name: 'Lisbon in May'),
            FrostedBand(640, hue: t.hues.lime, name: 'New bike'),
            FrostedBand(5460, variant: FrostedBandVariant.left, name: 'to go'),
          ],
        ),
        FrostedLegend(
          variant: FrostedLegendVariant.threeColumns,
          children: [
            FrostedLegendEntry(
              'Emergency fund',
              hue: t.hues.azure,
              amount: 20860,
            ),
            FrostedLegendEntry(
              'Lisbon in May',
              hue: t.hues.sunset,
              amount: 2840,
            ),
            FrostedLegendEntry('New bike', hue: t.hues.lime, amount: 640),
          ],
        ),
      ],
    );
  },
);

Widget _allocationLegend() => Builder(
  builder: (context) {
    final h = context.frostedTheme.hues;
    return FrostedLegend(
      variant: FrostedLegendVariant.allocation,
      children: [
        FrostedLegendEntry('Emergency fund', hue: h.azure, amount: 5586.27),
        FrostedLegendEntry('Lisbon in May', hue: h.sunset, amount: 2200),
        FrostedLegendEntry('New bike', hue: h.lime, amount: 640),
      ],
    );
  },
);

Widget _columnsLegend() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    const names = [
      'Rent',
      'Groceries',
      'Dining out',
      'Shopping',
      'Fun',
      'Transport',
      'Health',
      'Subscriptions',
    ];
    return FrostedLegend(
      children: [
        for (var i = 0; i < names.length; i++)
          FrostedLegendEntry(names[i], hue: t.hue(i), amount: 100 + i),
      ],
    );
  },
);

Widget _merchants({VoidCallback? onTap}) => Builder(
  builder: (context) {
    final hue = context.frostedTheme.hues.coral;
    return FrostedMerchantBars(
      children: [
        FrostedMerchant(
          name: 'Blue Fern Café',
          subtitle: '13 visits',
          amount: 84.25,
          fraction: 1,
          hue: hue,
          onPressed: onTap,
        ),
        FrostedMerchant(
          name: 'Rosemary & Rye',
          subtitle: '3 visits',
          amount: 65.49,
          fraction: 0.7773,
          hue: hue,
          onPressed: onTap,
        ),
        FrostedMerchant(
          name: 'Noodle Hall',
          subtitle: '3 visits',
          amount: 57.45,
          fraction: 0.6819,
          hue: hue,
          onPressed: onTap,
        ),
      ],
    );
  },
);

Widget _inOut() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedInOut(
      moneyIn: 6825,
      spent: 2486.12,
      bands: [
        FrostedBand(1150, hue: t.hues.periwinkle, name: 'Rent'),
        FrostedBand(412.36, hue: t.hues.orchid, name: 'Groceries'),
        FrostedBand(286.40, hue: t.hues.coral, name: 'Dining out'),
        FrostedBand(214.75, hue: t.hues.apricot, name: 'Shopping'),
        FrostedBand(143.45, hue: t.hues.lemon, name: 'Fun'),
        FrostedBand(118.20, hue: t.hues.mint, name: 'Transport'),
        FrostedBand(96, hue: t.hues.teal, name: 'Health'),
        FrostedBand(64.96, hue: t.hues.sky, name: 'Subscriptions'),
      ],
    );
  },
);

Widget _statement() => FrostedStatementTimeline(
  paid: DateTime(2026, 10, 12),
  closed: DateTime(2026, 10, 28),
  due: DateTime(2026, 11, 12),
  paidAmount: 1180.22,
  closedAmount: 1326.44,
);

Widget _strip() => Builder(
  builder: (context) => FrostedVisitStrip(
    month: DateTime(2026, 9),
    visits: [DateTime(2026, 9, 3), DateTime(2026, 9, 3), DateTime(2026, 9, 29)],
    current: DateTime(2026, 9, 29),
    hue: context.frostedTheme.hues.coral,
  ),
);

Widget _changes() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedBalanceChanges(
      children: [
        FrostedBalanceChange(
          name: 'Everyday',
          icon: LucideIcons.wallet,
          hue: t.hues.cyan,
          before: 6248.30,
          after: 5748.30,
        ),
        FrostedBalanceChange(
          name: 'Savings',
          icon: LucideIcons.landmark,
          hue: t.hues.seafoam,
          before: 21500,
          after: 22000,
        ),
      ],
    );
  },
);

Widget _route() => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedRoute(
      fromName: 'Everyday',
      fromIcon: LucideIcons.wallet,
      fromHue: t.hues.cyan,
      toName: 'Savings',
      toIcon: LucideIcons.landmark,
      toHue: t.hues.seafoam,
    );
  },
);

Widget _card({bool frozen = false, bool stage = false, VoidCallback? onTap}) =>
    FrostedCreditCard(
      balance: 1326.44,
      limit: 4000,
      mask: '4821',
      brand: 'keel',
      note: 'Autopay · due Nov 12',
      frozen: frozen,
      stage: stage,
      onPressed: onTap,
    );

Widget _goalCard({VoidCallback? onTap}) => Builder(
  builder: (context) => FrostedGoalCard(
    name: 'Lisbon in May',
    subtitle: 'by May 2027',
    icon: LucideIcons.plane,
    hue: context.frostedTheme.hues.sunset,
    saved: 2840,
    target: 4000,
    status: FrostedGoalStatus.behind,
    onPressed: onTap,
  ),
);

Widget _goalRow({VoidCallback? onTap}) => Builder(
  builder: (context) => FrostedGoalRow(
    name: 'Lisbon in May',
    icon: LucideIcons.plane,
    hue: context.frostedTheme.hues.sunset,
    saved: 2840,
    target: 4000,
    by: 'May 2027',
    status: FrostedGoalStatus.behind,
    first: true,
    onPressed: onTap,
  ),
);

Widget _pane({bool over = false}) => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return SizedBox(
      height: 120,
      child: over
          ? FrostedPane(
              name: 'Dining out',
              hue: t.hues.coral,
              spent: 286.40,
              budget: 250,
              variant: FrostedPaneVariant.featured,
              alert: 'Over by \$36.40',
            )
          : FrostedPane(
              name: 'Groceries',
              hue: t.hues.orchid,
              spent: 412.36,
              budget: 450,
              variant: FrostedPaneVariant.featured,
              meta: '8% less than Sep',
            ),
    );
  },
);

Widget _mosaic({VoidCallback? onTap}) => Builder(
  builder: (context) {
    final t = context.frostedTheme;
    return FrostedMosaic(
      title: 'October',
      panes: [
        FrostedPane.rent(
          name: 'Rent & home',
          hue: t.hues.periwinkle,
          spent: 1150,
          budget: 1150,
          ticket: FrostedTicket(
            name: 'Linden Court',
            title: 'Linden Court Apartments',
            subtitle: 'One payment from Everyday',
            hue: t.hues.periwinkle,
            chip: 'Paid',
          ),
          paid: 'Paid Oct 1',
          nextDue: 'Next due Nov 1',
          onPressed: onTap,
        ),
        FrostedPane(
          name: 'Groceries',
          hue: t.hues.orchid,
          spent: 412.36,
          budget: 450,
          variant: FrostedPaneVariant.featured,
          meta: '8% less than Sep',
          onPressed: onTap,
        ),
        FrostedPane(
          name: 'Dining out',
          hue: t.hues.coral,
          spent: 286.40,
          budget: 250,
          variant: FrostedPaneVariant.featured,
          alert: 'Over by \$36.40',
          onPressed: onTap,
        ),
        FrostedPane(
          name: 'Shopping',
          hue: t.hues.apricot,
          spent: 214.75,
          budget: 300,
          onPressed: onTap,
        ),
        FrostedPane(
          name: 'Fun',
          hue: t.hues.lemon,
          spent: 143.45,
          budget: 200,
          variant: FrostedPaneVariant.small,
          onPressed: onTap,
        ),
        FrostedPane(
          name: 'Transport',
          hue: t.hues.mint,
          spent: 118.20,
          budget: 160,
          variant: FrostedPaneVariant.small,
          onPressed: onTap,
        ),
        FrostedPane(
          name: 'Health',
          hue: t.hues.teal,
          spent: 96,
          budget: 120,
          variant: FrostedPaneVariant.small,
          onPressed: onTap,
        ),
        FrostedPane(
          name: 'Subs',
          hue: t.hues.sky,
          spent: 64.96,
          budget: 70,
          variant: FrostedPaneVariant.small,
          onPressed: onTap,
        ),
      ],
    );
  },
);

/// Every component once, for the sweep across presets, sizes and scales.
List<Widget> _everything() => [
  _track(pace: 0.5, paceLabel: 'Budget', scaleStart: const Text('\$0')),
  _goalsTrack(),
  _columnsLegend(),
  Builder(
    builder: (context) => FrostedSplitBar(
      hue: context.frostedTheme.hues.lemon,
      shares: const [FrostedShare('You', 14), FrostedShare('Jonah', 14)],
    ),
  ),
  Builder(
    builder: (context) => FrostedBar(
      0.63,
      hue: context.frostedTheme.hues.iris,
      variant: FrostedBarVariant.tubeLarge,
      tick: 0.5,
      scaleStart: '63% used',
      scaleEnd: '\$740.18 to go',
    ),
  ),
  Builder(
    builder: (context) =>
        FrostedMeter(0.87, hue: context.frostedTheme.hues.coral, over: true),
  ),
  Builder(
    builder: (context) => FrostedBudgetBar(
      spent: 286.40,
      budget: 250,
      hue: context.frostedTheme.hues.coral,
      size: FrostedBudgetBarSize.large,
    ),
  ),
  Builder(
    builder: (context) => FrostedCompareBars(
      children: [
        FrostedCompareRow(
          name: 'September',
          amount: 263.10,
          fraction: 0.9186,
          hue: context.frostedTheme.hues.coral,
          tick: 0.8729,
        ),
        FrostedCompareRow(
          name: 'October so far',
          amount: 286.40,
          fraction: 1,
          hue: context.frostedTheme.hues.coral,
          tick: 0.8729,
        ),
      ],
    ),
  ),
  _merchants(onTap: () {}),
  _inOut(),
  _statement(),
  _strip(),
  Builder(
    builder: (context) => FrostedDueLine(
      hue: context.frostedTheme.hues.periwinkle,
      start: 'Paid Oct 1',
      end: 'Next due Nov 1',
    ),
  ),
  _changes(),
  _route(),
  const FrostedDoneMark(),
  _card(onTap: () {}),
  _card(frozen: true),
  const FrostedDebitCard(mask: '3907'),
  const FrostedCardNumber(
    number: '4242424242427730',
    expires: '09/29',
    cvc: '317',
    name: 'Maren Holt',
  ),
  _goalCard(onTap: () {}),
  _goalRow(onTap: () {}),
  FrostedNewGoal(onPressed: () {}),
  _pane(over: true),
  _mosaic(onTap: () {}),
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

  group('meters', () {
    testWidgets('FrostedTrack lays its bands across the width by weight, 1 '
        'apart, and sets the pace tick at its fraction', (t) async {
      await _pump(t, _track(pace: 0.5));
      final a = t.getRect(find.byKey(_aKey));
      final b = t.getRect(find.byKey(_bKey));
      expect(a.left, 20);
      expect(a.width, moreOrLessEquals((_w - 1) * 0.75, epsilon: 0.01));
      expect(b.left, moreOrLessEquals(a.right + 1, epsilon: 0.01));
      expect(b.right, moreOrLessEquals(20 + _w, epsilon: 0.01));
      expect(a.height, 40);
      final tick = t.getRect(find.byType(FrostedPaceTick));
      expect(
        tick.center.dx,
        moreOrLessEquals(20 + (_w - 1) * 0.5, epsilon: 0.01),
      );
      expect(tick.top, a.top - 6);
      expect(tick.height, 40 + 12);
      expect(_node(t, 'Everyday 75%, Savings 25%'), isNotNull);
    });

    testWidgets('FrostedTrack counts the gaps before the pace tick and anchors '
        'the pace label 8 before it', (t) async {
      await _pump(
        t,
        _track(
          pace: 0.9,
          paceLabel: 'Budget \$250',
          scaleStart: const Text('\$0'),
        ),
      );
      final tickX = (_w - 1) * 0.9 + 1;
      final tick = t.getRect(find.byType(FrostedPaceTick));
      expect(tick.center.dx, moreOrLessEquals(20 + tickX, epsilon: 0.01));
      final label = t.getRect(find.text('Budget \$250'));
      expect(label.right, moreOrLessEquals(20 + tickX - 8, epsilon: 0.5));
      expect(label.top, greaterThanOrEqualTo(tick.bottom + 10 - 6));
      expect(find.text('\$0'), findsOneWidget);
    });

    testWidgets('FrostedScale sets its ends as captions on the pace label\'s '
        'line; a long start keeps the line a short end leaves it', (t) async {
      // In the test font (a glyph as wide as its size) 228 and 96 of 350:
      // a start longer than half the line still keeps one line.
      await _pump(
        t,
        const FrostedScale(
          start: Text('36% of what came in'),
          trailing: Text('Net +\$4k'),
          paceAt: 200,
          paceLabel: 'Pace',
        ),
      );
      final th = t.element(find.byType(FrostedScale)).frostedTheme;
      final start = find.text('36% of what came in');
      final end = find.text('Net +\$4k');
      for (final f in [start, end]) {
        final style = DefaultTextStyle.of(t.element(f)).style;
        expect(style.fontSize, th.textTheme.labelMedium.fontSize);
        expect(style.color, th.textTheme.labelMedium.color);
      }
      // Both on one line, on the pace label's line, the end at the end.
      expect(t.getSize(start).height, t.getSize(find.text('Pace')).height);
      expect(t.getRect(start).top, t.getRect(find.text('Pace')).top);
      expect(t.getRect(end).right, moreOrLessEquals(370, epsilon: 0.01));
      expect(t.getRect(start).left, 20);
      // Too long for one line, both narrow in proportion to their words.
      await _pump(
        t,
        const FrostedScale(
          start: Text('What came in this month, by everything it went to'),
          trailing: Text('Net of what went out, +\$4,338.88 kept'),
        ),
        size: const Size(320, 640),
      );
      final a = t.getSize(
        find.text('What came in this month, by everything it went to'),
      );
      final b = t.getSize(find.text('Net of what went out, +\$4,338.88 kept'));
      expect(a.width + b.width, lessThanOrEqualTo(280));
      expect(a.width, greaterThan(b.width));
      // A track stands its scale 10 under it, or its own scaleGap.
      for (final gap in const [10.0, 8.0]) {
        await _pump(
          t,
          Builder(
            builder: (context) => FrostedTrack(
              size: FrostedTrackSize.small,
              bands: [FrostedBand(3, hue: context.frostedTheme.hues.coral)],
              scaleStart: const Text('36%'),
              scaleGap: gap,
            ),
          ),
        );
        expect(
          t.getRect(find.byType(FrostedScale)).top -
              t.getRect(find.byType(FrostedTrack)).top,
          16 + gap,
        );
      }
    });

    testWidgets('FrostedTrack reads right to left: the first band at the end', (
      t,
    ) async {
      await _pump(t, _track(), direction: TextDirection.rtl);
      final a = t.getRect(find.byKey(_aKey));
      final b = t.getRect(find.byKey(_bKey));
      expect(a.right, moreOrLessEquals(20 + _w, epsilon: 0.01));
      expect(b.left, 20);
    });

    testWidgets('FrostedTrack at its sizes: 16 small, 10 least, 56 large on '
        'the desktop', (t) async {
      Widget at(FrostedTrackSize size) => Builder(
        builder: (context) => FrostedTrack(
          size: size,
          bands: [
            FrostedBand(1, hue: context.frostedTheme.hues.seafoam, key: _aKey),
          ],
        ),
      );
      await _pump(t, at(FrostedTrackSize.small));
      expect(t.getSize(find.byKey(_aKey)).height, 16);
      await _pump(t, at(FrostedTrackSize.extraSmall));
      expect(t.getSize(find.byKey(_aKey)).height, 10);
      await _pump(t, at(FrostedTrackSize.large), size: const Size(1280, 900));
      expect(t.getSize(find.byKey(_aKey)).height, 56);
    });

    testWidgets('FrostedSplitBar names each share inside its band, the first '
        'at its start and the second at its end', (t) async {
      await _pump(
        t,
        Builder(
          builder: (context) => FrostedSplitBar(
            hue: context.frostedTheme.hues.lemon,
            shares: const [FrostedShare('You', 14), FrostedShare('Jonah', 14)],
          ),
        ),
      );
      expect(find.text('You'), findsOneWidget);
      expect(find.text('\$14.00'), findsNWidgets(2));
      expect(t.getTopLeft(find.text('You')).dx, 20 + 16);
      expect(
        t.getTopRight(find.text('Jonah')).dx,
        moreOrLessEquals(20 + _w - 16, epsilon: 0.5),
      );
      expect(_node(t, 'You \$14.00, Jonah \$14.00'), isNotNull);
    });

    testWidgets('FrostedLegend fills two columns of four top to bottom, three '
        'across between the ends, and rows with their shares', (t) async {
      await _pump(t, _columnsLegend());
      final rent = t.getTopLeft(find.text('Rent'));
      final fun = t.getTopLeft(find.text('Fun'));
      final groceries = t.getTopLeft(find.text('Groceries'));
      expect(fun.dy, rent.dy);
      expect(fun.dx, greaterThan(rent.dx + 100));
      expect(groceries.dx, rent.dx);
      expect(groceries.dy, greaterThan(rent.dy));
      expect(find.textContaining('\$100.00'), findsOneWidget);
      await _pump(t, _goalsTrack());
      expect(t.getTopLeft(find.byType(FrostedSwatch).first).dx, 20);
      expect(
        t.getTopRight(find.textContaining('\$640.00')).dx,
        lessThanOrEqualTo(20 + _w + 0.5),
      );
      expect(_node(t, 'Emergency fund, \$20,860.00'), isNotNull);
      // Where the three fit (the test face is wide: a 600 page), the last
      // ends at the end and the first two keep their own widths.
      await _pump(t, _goalsTrack(), size: const Size(600, 844));
      expect(
        t.getTopLeft(find.text('Emergency fund').last).dy,
        t.getTopLeft(find.text('New bike').last).dy,
      );
      expect(
        t.getTopRight(find.textContaining('\$640.00')).dx,
        moreOrLessEquals(20 + 560, epsilon: 1),
      );
      // Where the three fit, each name is whole at its own width and the
      // gaps between them share the rest (`repeat(3, auto)`, space-between).
      await _pump(t, _goalsTrack(), size: const Size(1280, 900));
      for (final name in ['Emergency fund', 'Lisbon in May', 'New bike']) {
        final finder = find.text(name).last;
        expect(
          t.getSize(finder).width,
          moreOrLessEquals(_textWidth(t, finder), epsilon: 0.5),
          reason: '$name whole',
        );
      }
      expect(
        t.getTopLeft(find.text('Lisbon in May').last).dx -
            t.getTopRight(find.textContaining('\$20,860.00')).dx,
        greaterThan(16),
      );
      expect(
        t.getTopRight(find.textContaining('\$640.00')).dx,
        moreOrLessEquals(20 + 1240, epsilon: 1),
      );
      await _pump(
        t,
        Builder(
          builder: (context) {
            final h = context.frostedTheme.hues;
            return FrostedLegend(
              variant: FrostedLegendVariant.rows,
              children: [
                FrostedLegendEntry(
                  'Stocks',
                  hue: h.turquoise,
                  share: 81,
                  amount: 39432.60,
                ),
                FrostedLegendEntry(
                  'Bonds',
                  hue: h.lavender,
                  share: 15,
                  amount: 7336.10,
                ),
                FrostedLegendEntry(
                  'Cash',
                  hue: h.silver,
                  share: 4,
                  amount: 2152,
                ),
              ],
            );
          },
        ),
      );
      expect(find.text('81%'), findsOneWidget);
      expect(_node(t, 'Stocks, 81%, \$39,432.60'), isNotNull);
      await _pump(t, _allocationLegend());
      expect(
        t.getTopRight(find.textContaining('\$640.00')).dx,
        lessThanOrEqualTo(20 + _w + 0.5),
      );
      await _pump(t, _allocationLegend(), size: const Size(600, 844));
      expect(
        t.getTopLeft(find.text('Emergency fund')).dy,
        t.getTopLeft(find.text('New bike')).dy,
      );
      expect(
        t.getTopRight(find.textContaining('\$640.00')).dx,
        moreOrLessEquals(20 + 560, epsilon: 1),
      );
      await _pump(t, _allocationLegend(), size: const Size(1280, 900));
      final fund = t.getTopLeft(find.text('Emergency fund'));
      final bike = t.getTopLeft(find.text('New bike'));
      expect(bike.dx, fund.dx);
      expect(bike.dy, greaterThan(fund.dy + 40));
      // `.lg { padding: 10px 0 } .lg + .lg { border-top: 1px }`: a row past
      // the first is its rule, 10, its own line and 10.
      final lisbon = find.text('Lisbon in May');
      final line = t
          .getSize(find.ancestor(of: lisbon, matching: find.byType(Row)).first)
          .height;
      expect(
        bike.dy - t.getTopLeft(lisbon).dy,
        moreOrLessEquals(1 + 10 + line + 10, epsilon: 0.01),
      );
      // `.lg { column-gap: 8px }`: the name 8 past its swatch.
      final swatch = t.getRect(find.byType(FrostedSwatch).first);
      expect(fund.dx - swatch.right, moreOrLessEquals(8, epsilon: 0.01));
      expect(
        t.getTopRight(find.textContaining('\$640.00')).dx,
        moreOrLessEquals(20 + 1240, epsilon: 1),
      );
      expect(find.byType(DecoratedBox), findsWidgets);
    });

    testWidgets('FrostedBar fills its share in each style and says it; a tick '
        'stands at its fraction', (t) async {
      Widget bar(FrostedBarVariant style, {double? tick}) => Builder(
        builder: (context) => FrostedBar(
          0.71,
          hue: context.frostedTheme.hues.sunset,
          variant: style,
          tick: tick,
        ),
      );
      Rect fill() => t.getRect(
        find.descendant(
          of: find.byType(FractionallySizedBox),
          matching: find.byType(FrostedFace),
        ),
      );
      await _pump(t, bar(FrostedBarVariant.tube));
      expect(fill().width, moreOrLessEquals(_w * 0.71, epsilon: 0.01));
      expect(fill().height, 8);
      expect(fill().left, 20);
      expect(_node(t, '71%'), isNotNull);
      await _pump(t, bar(FrostedBarVariant.thin));
      expect(fill().height, 4);
      await _pump(t, bar(FrostedBarVariant.bar));
      expect(fill().height, 6);
      await _pump(t, bar(FrostedBarVariant.tubeLarge, tick: 0.63));
      expect(fill().height, 12);
      final tick = t.getRect(find.byType(FrostedPaceTick));
      expect(tick.center.dx, moreOrLessEquals(20 + _w * 0.63, epsilon: 0.01));
      expect(tick.height, 20);
    });

    testWidgets('FrostedBar under a scale names its ends and dims when off', (
      t,
    ) async {
      await _pump(
        t,
        Builder(
          builder: (context) => FrostedBar(
            0.63,
            hue: context.frostedTheme.hues.iris,
            variant: FrostedBarVariant.tubeLarge,
            scaleStart: '63% used',
            scaleEnd: '\$740.18 to go',
            dimmed: true,
          ),
        ),
      );
      expect(t.getTopLeft(find.text('63% used')).dx, 20);
      expect(
        t.getTopRight(find.text('\$740.18 to go')).dx,
        moreOrLessEquals(20 + _w, epsilon: 0.5),
      );
      expect(t.widget<Opacity>(find.byType(Opacity)).opacity, 0.45);
    });

    testWidgets('FrostedMeter fills its share on a white track; over, the '
        'budget in the hue and the rest in the over red; small is 3', (
      t,
    ) async {
      Widget meter({bool over = false, bool small = false}) => Builder(
        builder: (context) => FrostedMeter(
          0.9,
          hue: context.frostedTheme.hues.orchid,
          over: over,
          size: small ? FrostedMeterSize.small : FrostedMeterSize.regular,
        ),
      );
      await _pump(t, meter());
      expect(t.getSize(find.byType(FrostedMeter)).height, 4);
      final fill = t.getRect(
        find.descendant(
          of: find.byType(FractionallySizedBox),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(fill.width, moreOrLessEquals(_w * 0.9, epsilon: 0.01));
      expect(_node(t, '90%'), isNotNull);
      await _pump(t, meter(over: true));
      final theme = _theme(t, find.byType(FrostedMeter));
      final boxes = t.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(FrostedMeter),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        boxes.any(
          (b) =>
              (b.decoration as BoxDecoration).color == theme.colorScheme.over,
        ),
        isTrue,
      );
      expect(_node(t, 'Over budget'), isNotNull);
      await _pump(t, meter(small: true));
      expect(t.getSize(find.byType(FrostedMeter)).height, 3);
    });

    testWidgets("FrostedBudgetBar sizes the budget's share of what was spent, "
        'names the budget and the amount over', (t) async {
      await _pump(
        t,
        Builder(
          builder: (context) => FrostedBudgetBar(
            spent: 286.40,
            budget: 250,
            hue: context.frostedTheme.hues.coral,
            size: FrostedBudgetBarSize.large,
          ),
        ),
      );
      final fill = t.getRect(find.byType(FrostedFace));
      expect(
        fill.width,
        moreOrLessEquals((_w - 2) * 250 / 286.40, epsilon: 0.01),
      );
      expect(fill.height, 10);
      expect(find.text('Budget \$250'), findsOneWidget);
      expect(find.text('+\$36.40 over'), findsOneWidget);
      expect(
        t.getTopRight(find.text('+\$36.40 over')).dx,
        moreOrLessEquals(20 + _w, epsilon: 0.5),
      );
      expect(_node(t, 'Over by \$36.40'), isNotNull);
      final theme = _theme(t, find.text('Budget \$250'));
      expect(
        t.widget<Text>(find.text('Budget \$250')).style!.color,
        theme.colorScheme.textPrimary,
      );
      expect(
        t.widget<Text>(find.text('+\$36.40 over')).style!.color,
        theme.colorScheme.over,
      );
      // `.ob-scale` inherits its ink: the words round it, or [ink].
      await _pump(
        t,
        Builder(
          builder: (context) => DefaultTextStyle.merge(
            style: const TextStyle(color: Color(0xFF123456)),
            child: FrostedBudgetBar(
              spent: 200,
              budget: 250,
              hue: context.frostedTheme.hues.coral,
            ),
          ),
        ),
      );
      expect(
        t.widget<Text>(find.text('Budget \$250')).style!.color,
        const Color(0xFF123456),
      );
      expect(find.textContaining('over'), findsNothing);
    });

    testWidgets('FrostedCompareBars sets each month over its tube with the '
        "budget's tick on both", (t) async {
      await _pump(
        t,
        Builder(
          builder: (context) {
            final hue = context.frostedTheme.hues.coral;
            return FrostedCompareBars(
              children: [
                FrostedCompareRow(
                  name: 'September',
                  amount: 263.10,
                  fraction: 0.9186,
                  hue: hue,
                  tick: 0.8729,
                ),
                FrostedCompareRow(
                  name: 'October so far',
                  amount: 286.40,
                  fraction: 1,
                  hue: hue,
                  tick: 0.8729,
                ),
              ],
            );
          },
        ),
      );
      expect(find.text('September'), findsOneWidget);
      expect(find.textContaining('263'), findsOneWidget);
      expect(find.byType(FrostedPaceTick), findsNWidgets(2));
      expect(t.getSize(find.byType(FrostedPaceTick).first).height, 16);
      final first = t.getRect(find.byType(FrostedBar).first);
      final second = t.getRect(find.byType(FrostedBar).last);
      expect(second.top - first.bottom, greaterThanOrEqualTo(16 + 20 + 8));
      expect(_node(t, 'September, \$263.10'), isNotNull);
    });

    testWidgets('FrostedMerchantBars: each merchant a link with its bar 48 in, '
        'cards four across on the desktop', (t) async {
      var opened = 0;
      await _pump(t, _merchants(onTap: () => opened++));
      expect(
        _node(t, 'Blue Fern Café, 13 visits, \$84.25'),
        isSemantics(isLink: true, hasTapAction: true),
      );
      await t.tap(find.text('Noodle Hall'));
      expect(opened, 1);
      final bar = t.getRect(find.byType(FrostedBar).first);
      expect(bar.left, 20 + 36 + 12);
      expect(bar.height, 4);
      await _pump(t, _merchants(), size: const Size(1280, 900));
      final card = t.getRect(find.byType(FrostedMerchant).first);
      expect(card.width, moreOrLessEquals((1240 - 3 * 16) / 4, epsilon: 0.01));
      expect(
        t.getTopLeft(find.byType(FrostedMerchant).last).dy,
        t.getTopLeft(find.byType(FrostedMerchant).first).dy,
      );
    });

    testWidgets('FrostedInOut sets money in against what went out, adds the '
        'kept band and says the net', (t) async {
      await _pump(t, _inOut());
      expect(find.text('Money in'), findsOneWidget);
      expect(find.text('Spent'), findsOneWidget);
      expect(find.textContaining('6,825'), findsOneWidget);
      final track = t.widget<FrostedTrack>(find.byType(FrostedTrack));
      expect(track.bands.length, 9);
      expect(track.bands.last.variant, FrostedBandVariant.kept);
      expect(track.bands.last.weight, moreOrLessEquals(6825 - 2486.12));
      expect(find.text('36% of what came in went to spending'), findsOneWidget);
      expect(find.text('Net +\$4,338.88'), findsOneWidget);
      expect(find.byType(FrostedPaceTick), findsNothing);
    });

    testWidgets('FrostedInOut sets its captions 8 under the track, or the '
        'scale\'s own 10 when it is handed that', (t) async {
      double gap() =>
          t.getTopLeft(find.byType(FrostedScale)).dy -
          t.getBottomLeft(find.byType(FrostedTrack)).dy;
      await _pump(t, _inOut());
      expect(gap(), FrostedChromeMetrics.flowScaleGap);
      await _pump(
        t,
        Builder(
          builder: (context) => FrostedInOut(
            moneyIn: 6825,
            spent: 2486.12,
            bands: [
              FrostedBand(
                1150,
                hue: context.frostedTheme.hues.periwinkle,
                name: 'Rent',
              ),
            ],
            scaleGap: FrostedChromeMetrics.frostedScaleGap,
          ),
        ),
      );
      expect(gap(), 10);
    });

    testWidgets('FrostedStatementTimeline places its beads by date and centres '
        'the closing words under theirs', (t) async {
      await _pump(t, _statement());
      const at = 16 / 31;
      final closed = t.getRect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              (w.decoration as BoxDecoration).border?.top.width == 2.5,
        ),
      );
      expect(closed.width, 12);
      expect(
        closed.center.dx,
        moreOrLessEquals(20 + 6 + (_w - 12) * at, epsilon: 0.5),
      );
      // The line 12, the words 10 under it and 42 tall, 10 over what
      // follows; the line's 2 over collapses into a head's 12 above.
      final whole = t.getRect(find.byType(FrostedStatementTimeline));
      expect(whole.height, 12 + 10 + 42 + 10);
      expect(closed.top, whole.top);
      expect(find.text('Paid Oct 12'), findsOneWidget);
      expect(find.text('Due Nov 12'), findsOneWidget);
      expect(find.text('Autopay'), findsOneWidget);
      expect(
        t.getCenter(find.text('Closed Oct 28')).dx,
        moreOrLessEquals(20 + _w * at, epsilon: 0.5),
      );
      expect(
        t.getTopRight(find.text('Due Nov 12')).dx,
        moreOrLessEquals(20 + _w, epsilon: 0.5),
      );
      expect(
        _node(
          t,
          'Paid \$1,180.22 on Oct 12, closed Oct 28 at \$1,326.44, due Nov 12, '
          'Autopay',
        ),
        isNotNull,
      );
    });

    testWidgets('FrostedVisitStrip dots each visit on its day, the record\'s '
        'own ringed, under the month\'s first, middle and last day', (t) async {
      await _pump(t, _strip());
      final theme = _theme(t, find.byType(FrostedVisitStrip));
      final own = find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            (w.decoration as BoxDecoration).border?.top.color ==
                theme.hues.coral.b,
      );
      expect(own, findsOneWidget);
      expect(
        t.getCenter(own).dx,
        moreOrLessEquals(20 + _w * 28.5 / 30, epsilon: 0.5),
      );
      expect(t.getSize(own), const Size(10, 10));
      final plain = find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            (w.decoration as BoxDecoration).gradient == theme.hues.coral.dot,
      );
      expect(plain, findsNWidgets(2));
      expect(find.text('Sep 1'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Sep 30'), findsOneWidget);
      expect(_node(t, '3 visits in September'), isNotNull);
      // In the month that is running, Today stands in the month end's
      // place (screens.py visit_strip()), not over it.
      await _pump(
        t,
        Builder(
          builder: (context) => FrostedVisitStrip(
            month: DateTime(2026, 9),
            visits: [DateTime(2026, 9, 3)],
            now: DateTime(2026, 9, 28),
            hue: context.frostedTheme.hues.coral,
          ),
        ),
      );
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Sep 30'), findsNothing);
      expect(
        t.getCenter(find.text('Today')).dx,
        moreOrLessEquals(20 + _w * 27.5 / 30, epsilon: 0.5),
      );
    });

    testWidgets(
      'FrostedDueLine runs between its two dots and names both ends',
      (t) async {
        await _pump(
          t,
          Builder(
            builder: (context) => FrostedDueLine(
              hue: context.frostedTheme.hues.periwinkle,
              start: 'Paid Oct 1',
              end: 'Next due Nov 1',
            ),
          ),
        );
        expect(t.getTopLeft(find.text('Paid Oct 1')).dx, 20);
        expect(
          t.getTopRight(find.text('Next due Nov 1')).dx,
          moreOrLessEquals(20 + _w, epsilon: 0.5),
        );
        expect(_node(t, 'Paid Oct 1, Next due Nov 1'), isNotNull);
      },
    );

    testWidgets('FrostedBalanceChanges sets each account before and after, the '
        'old balance struck, the part moved leaving or arriving', (t) async {
      await _pump(t, _changes());
      expect(find.text('Everyday'), findsOneWidget);
      expect(find.text('−\$500.00'), findsOneWidget);
      expect(find.text('+\$500.00'), findsOneWidget);
      final struck = t.widget<Text>(find.text('\$6,248.30'));
      expect(struck.style!.decoration, TextDecoration.lineThrough);
      final tracks = t
          .widgetList<FrostedTrack>(find.byType(FrostedTrack))
          .toList();
      expect(tracks.length, 2);
      expect(tracks[0].bands[1].variant, FrostedBandVariant.leave);
      expect(tracks[0].bands[0].weight, 5748.30);
      expect(tracks[1].bands[1].variant, FrostedBandVariant.arrive);
      expect(tracks[1].bands[0].weight, 21500);
      expect(tracks[1].size, FrostedTrackSize.extraSmall);
      expect(
        _node(t, 'Everyday, −\$500.00, from \$6,248.30 to \$5,748.30'),
        isNotNull,
      );
    });

    testWidgets('FrostedRoute beams from the source to the destination', (
      t,
    ) async {
      await _pump(t, _route());
      expect(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 36 && w.height == 2,
        ),
        findsNWidgets(2),
      );
      // The kit's arrow, which turns round right to left.
      expect(find.byIcon(FrostedGlyphs.arrowRight), findsOneWidget);
      expect(find.byType(FrostedIconMark), findsNWidgets(2));
      expect(_node(t, 'From Everyday to Savings'), isNotNull);
    });

    testWidgets('FrostedDoneMark draws its rings round the check, 200 across '
        'and pulled 16 into its neighbours', (t) async {
      await _pump(t, const FrostedDoneMark());
      expect(t.getSize(find.byType(FrostedDoneMark)).height, 200 - 16);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      final check = t.getRect(find.byIcon(LucideIcons.check));
      expect(check.center.dx, moreOrLessEquals(20 + _w / 2, epsilon: 0.5));
      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter != null),
        paints
          ..circle()
          ..circle()
          ..circle()
          ..circle()
          ..circle(),
      );
      expect(_node(t, 'Done'), isSemantics(isImage: true));
    });
  });

  group('card', () {
    testWidgets('FrostedCreditCard says the card and what is owed, keeps its '
        'aspect and opens', (t) async {
      var opened = 0;
      await _pump(t, _card(onTap: () => opened++));
      expect(
        _node(
          t,
          'Card ·· 4821, Balance \$1,326.44 of \$4,000 limit, Autopay · due '
          'Nov 12',
        ),
        isSemantics(isLink: true, hasTapAction: true),
      );
      await t.tap(find.byType(FrostedCreditCard));
      expect(opened, 1);
      final face = t.getSize(find.byType(AspectRatio));
      expect(face.width, _w);
      expect(face.height, moreOrLessEquals(_w / 1.586, epsilon: 0.01));
      expect(find.text('keel'), findsOneWidget);
      expect(find.text('Credit'), findsOneWidget);
      expect(find.text('Balance'), findsOneWidget);
      expect(find.text('•• 4821'), findsOneWidget);
      expect(find.text('Autopay · due Nov 12'), findsOneWidget);
      expect(find.text('\$4,000'), findsOneWidget);
      final util = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 180 && w.height == 4,
      );
      expect(util, findsOneWidget);
      final used = t.widget<FractionallySizedBox>(
        find.descendant(of: util, matching: find.byType(FractionallySizedBox)),
      );
      expect(used.widthFactor, moreOrLessEquals(1326.44 / 4000));
      expect(find.byType(FrostedOrbits), findsOneWidget);
      expect(find.byType(FrostedCardGlow), findsOneWidget);
      expect(find.byType(FrostedFrost), findsNothing);
    });

    testWidgets('FrostedCreditCard frozen lays the frost over the pearl', (
      t,
    ) async {
      await _pump(t, _card(frozen: true));
      expect(find.byType(FrostedFrost), findsOneWidget);
      expect(find.text('Frozen'), findsOneWidget);
      expect(find.byIcon(LucideIcons.snowflake), findsOneWidget);
      expect(
        t.getRect(find.byType(FrostedFrost)),
        t.getRect(find.byType(AspectRatio)),
      );
      expect(
        _node(
          t,
          'Frozen card ·· 4821, Balance \$1,326.44 of \$4,000 limit, Autopay · '
          'due Nov 12',
        ),
        isNotNull,
      );
    });

    testWidgets('FrostedCreditCard on the desktop turns on its 300 stage, or '
        'across Home stands in the middle of its row', (t) async {
      await _pump(t, _card(stage: true), size: const Size(1280, 900));
      expect(find.byType(Transform), findsWidgets);
      expect(t.getSize(find.byType(AspectRatio)).width, 300 - 16);
      // The stage's 284 is narrower than the face lays its words out in
      // (the self-review's shots: the balance ran into the brand, the
      // limit into the last four), so the face is drawn at a phone card's
      // 358 and its picture scaled down to the stage. Its rows stand as
      // `.kcard`'s flex column lays them (space-between): where they are
      // shorter than the room inside the rim and the 20 inset, the room
      // left is shared between them, the brand row at the top and the foot
      // on the floor; where they are taller, they stack from the top at
      // their own heights and the foot runs into the inset, the balance
      // unscaled. Measured in the face's own, unturned, unscaled frame.
      Finder stageFace() => find.descendant(
        of: find.byType(AspectRatio),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 358,
        ),
      );
      expect(stageFace(), findsOneWidget);
      for (final label in ['Balance', 'Balance\nthis statement']) {
        await _pump(
          t,
          FrostedCreditCard(
            balance: 26.44,
            limit: 4000,
            mask: '4821',
            brand: 'keel',
            note: 'Autopay · due Nov 12',
            balanceLabel: label,
            stage: true,
          ),
          size: const Size(1280, 900),
        );
        final faceBox = t.renderObject<RenderBox>(stageFace());
        double top(Finder f) => t
            .renderObject<RenderBox>(f)
            .localToGlobal(Offset.zero, ancestor: faceBox)
            .dy;
        final head = find
            .ancestor(of: find.text('Credit'), matching: find.byType(LayoutId))
            .first;
        final mid = find
            .ancestor(of: find.text(label), matching: find.byType(FittedBox))
            .first;
        final foot = find
            .ancestor(of: find.text('•• 4821'), matching: find.byType(Row))
            .first;
        final floor = faceBox.size.height - 1 - 20;
        final rows =
            t.getSize(head).height +
            t.getSize(mid).height +
            t.getSize(foot).height;
        final gap = (floor - (1 + 20) - rows) / 2;
        expect(top(head), moreOrLessEquals(1 + 20, epsilon: 0.01));
        // The card's own words fit the stage's face.
        if (label == 'Balance') expect(gap, greaterThan(0));
        if (gap > 0) {
          // Shorter than the room: spread, the foot on the floor.
          expect(
            top(foot) + t.getSize(foot).height,
            moreOrLessEquals(floor, epsilon: 0.01),
          );
        } else {
          // Taller than the room: stacked, the foot into the inset.
          expect(top(foot) + t.getSize(foot).height, greaterThan(floor));
        }
        final share = gap > 0 ? gap : 0.0;
        expect(
          top(mid),
          moreOrLessEquals(
            top(head) + t.getSize(head).height + share,
            epsilon: 0.01,
          ),
        );
        expect(
          top(foot),
          moreOrLessEquals(
            top(mid) + t.getSize(mid).height + share,
            epsilon: 0.01,
          ),
        );
        // The balance at its own size, not scaled down to fit.
        expect(
          t.getSize(mid),
          t.getSize(
            find.descendant(of: mid, matching: find.byType(Column)).first,
          ),
        );
      }
      await _pump(t, _card(), size: const Size(1280, 900));
      // From 600 up a card keeps a card's size: at most 408 (the source's
      // desktop Home card) across a wide row, in its middle.
      expect(t.getSize(find.byType(AspectRatio)).width, 408);
      expect(
        t.getCenter(find.byType(AspectRatio)).dx,
        moreOrLessEquals(
          t.getCenter(find.byType(FrostedCreditCard)).dx,
          epsilon: 0.01,
        ),
      );
      // `.kc { display: grid; place-items: center; padding: 16px 28px 4px }`:
      // in a row taller than it, the card centred in what its inset leaves.
      await _pump(
        t,
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 456, height: 380, child: _card()),
        ),
        size: const Size(1280, 900),
      );
      final row = t.getRect(find.byType(FrostedCreditCard));
      final face = t.getCenter(find.byType(AspectRatio));
      expect(t.getSize(find.byType(AspectRatio)).width, 456 - 56);
      expect(face.dx, moreOrLessEquals(row.left + 456 / 2, epsilon: 0.01));
      expect(
        face.dy,
        moreOrLessEquals(row.top + 16 + (380 - 16 - 4) / 2, epsilon: 0.01),
      );
    });

    testWidgets('FrostedDebitCard is a 92 x 58 picture of its kind and last '
        'four', (t) async {
      await _pump(t, const Center(child: FrostedDebitCard(mask: '3907')));
      expect(t.getSize(find.byType(FrostedDebitCard)), const Size(92, 58));
      expect(find.text('Debit'), findsOneWidget);
      expect(find.text('•• 3907'), findsOneWidget);
      expect(_node(t, 'Debit card ·· 3907'), isSemantics(isImage: true));
    });

    testWidgets('FrostedCardNumber spreads the four groups across its well and '
        'lays the three facts under it', (t) async {
      await _pump(
        t,
        const FrostedCardNumber(
          number: '4242 4242 4242 7730',
          expires: '09/29',
          cvc: '317',
          name: 'Maren Holt',
        ),
      );
      expect(find.text('4242'), findsNWidgets(3));
      expect(t.getTopLeft(find.text('4242').first).dx, 20 + 16);
      expect(
        t.getTopRight(find.text('7730')).dx,
        moreOrLessEquals(20 + _w - 16, epsilon: 0.5),
      );
      expect(find.text('09/29'), findsOneWidget);
      expect(find.text('317'), findsOneWidget);
      expect(find.text('Maren Holt'), findsOneWidget);
      // `.cnum-s.num`: 20 on a 24 line (`.cnum-s`'s 1.2).
      final expiry = t.widget<Text>(find.text('09/29')).style!;
      expect(expiry.fontSize, 20);
      expect(
        expiry.fontSize! * expiry.height!,
        moreOrLessEquals(24, epsilon: 0.01),
      );
      // In the display face's own figures: `.cnum-s` and `.cnum-v`'s `font`
      // shorthand comes after `.num` and resets its tabular-nums.
      for (final figure in ['09/29', '317', '7730']) {
        final style = t.widget<Text>(find.text(figure)).style!;
        expect(style.fontFamily, FrostedThemeData.face);
        expect(style.fontFeatures ?? const [], isEmpty);
      }
      expect(
        t.getTopLeft(find.text('Maren Holt')).dx,
        greaterThan(t.getTopLeft(find.text('317')).dx),
      );
      expect(
        _node(
          t,
          'Card number 4242 4242 4242 7730, Expires 09/29, CVC 317, Maren Holt',
        ),
        isNotNull,
      );
    });

    testWidgets(
      "FrostedGoalCard names the goal, its status, its figure against "
      'the target and its percent; the desktop stacks the token over the '
      'name',
      (t) async {
        var opened = 0;
        await _pump(t, _goalCard(onTap: () => opened++));
        expect(find.text('Lisbon in May'), findsOneWidget);
        expect(find.text('by May 2027'), findsOneWidget);
        expect(find.text('Behind'), findsOneWidget);
        expect(find.text('\$4,000'), findsOneWidget);
        expect(find.textContaining('71'), findsOneWidget);
        expect(
          t.getTopLeft(find.text('Lisbon in May')).dy,
          lessThan(t.getTopLeft(find.text('Behind')).dy + 20),
        );
        expect(
          _node(
            t,
            'Lisbon in May, by May 2027, Behind, \$2,840.00 of \$4,000, 71%',
          ),
          isSemantics(isLink: true, hasTapAction: true),
        );
        await t.tap(find.text('Lisbon in May'));
        expect(opened, 1);
        // A plain tile's inset (`--pad` 16, 20 on the desktop) round the
        // account wash.
        expect(t.getTopLeft(find.byType(FrostedIconMark)).dx, 20 + 16);
        // The date on .row-s's 18.2 line (which the engine rounds to a whole
        // pixel when it lays it); the percent on its own 16 line (`.gc-p {
        // font: 500 16px/1 }`), no taller for its small sign.
        final date = t.widget<Text>(find.text('by May 2027')).style!;
        expect(date.fontSize! * date.height!, closeTo(18.2, 0.01));
        expect(t.getSize(find.byType(FrostedPercent)).height, 16);
        await _pump(t, _goalCard(), size: const Size(1280, 900));
        expect(
          t.getTopLeft(find.text('Lisbon in May')).dy,
          greaterThan(t.getBottomLeft(find.text('Behind')).dy),
        );
        expect(t.getTopLeft(find.byType(FrostedIconMark)).dx, 20 + 20);
      },
    );

    testWidgets('FrostedGoalRow says the goal and its percent, its status in '
        'the warn ink, over its tube', (t) async {
      var opened = 0;
      await _pump(t, _goalRow(onTap: () => opened++));
      final theme = _theme(t, find.byType(FrostedGoalRow));
      expect(find.text('Behind'), findsOneWidget);
      expect(
        t.widget<Text>(find.text('Behind')).style!.color,
        theme.colorScheme.warning,
      );
      expect(find.textContaining('71'), findsOneWidget);
      expect(find.byType(FrostedBar), findsOneWidget);
      expect(t.getTopLeft(find.byType(FrostedIconMark)).dy, 844 / 2 - 32);
      expect(
        _node(t, 'Lisbon in May, \$2,840 of \$4,000, by May 2027, 71%, Behind'),
        isSemantics(isLink: true, hasTapAction: true),
      );
      await t.tap(find.text('Lisbon in May'));
      expect(opened, 1);
    });

    testWidgets(
      'FrostedNewGoal is a link to start a goal, its plus on the ink, '
      'a chevron at its end on a phone only',
      (t) async {
        var opened = 0;
        await _pump(t, FrostedNewGoal(onPressed: () => opened++));
        expect(
          _node(t, 'New goal, Save toward something new'),
          isSemantics(isLink: true, hasTapAction: true),
        );
        await t.tap(find.text('New goal'));
        expect(opened, 1);
        expect(find.byIcon(LucideIcons.plus), findsOneWidget);
        expect(find.byIcon(FrostedGlyphs.forward), findsOneWidget);
        await _pump(
          t,
          FrostedNewGoal(onPressed: () {}),
          size: const Size(1280, 900),
        );
        expect(find.byIcon(FrostedGlyphs.forward), findsNothing);
        expect(
          t.getTopLeft(find.text('New goal')).dy,
          greaterThan(t.getBottomLeft(find.byIcon(LucideIcons.plus)).dy),
        );
        // On the desktop, as tall as its row: a tile's 20 inset, the plus at
        // the top and the words 16 under it, the slack under them
        // (`.row-main { flex: 1 }` leaves `space-between` none to share).
        await _pump(
          t,
          SizedBox(height: 200, child: FrostedNewGoal(onPressed: () {})),
          size: const Size(1280, 900),
        );
        final card = t.getRect(find.byType(FrostedNewGoal));
        final plus = t.getRect(find.byIcon(LucideIcons.plus));
        final title = t.getRect(find.text('New goal'));
        expect(card.height, 200);
        expect(title.left - card.left, FrostedChromeMetrics.tileInsetWide);
        expect(
          title.top - card.top,
          FrostedChromeMetrics.tileInsetWide +
              FrostedChromeMetrics.newGoalPlus +
              FrostedChromeMetrics.newGoalGapWide,
        );
        expect(
          plus.center.dy - card.top,
          20 + FrostedChromeMetrics.newGoalPlus / 2,
        );
      },
    );

    testWidgets('FrostedMosaic stands 540 tall, the rent across the top by its '
        'weight, the rest in two columns, every pane a link; a small pane '
        'hides its share on a phone and says its percent alone on the '
        'desktop, where the rent\'s ticket stands centred down its band', (
      t,
    ) async {
      var opened = 0;
      await _pump(
        t,
        _mosaic(onTap: () => opened++),
        size: const Size(390, 1000),
      );
      final panes = find.byType(FrostedPane);
      expect(panes, findsNWidgets(8));
      final tile = t.getRect(find.byType(FrostedCard));
      expect(tile.width, _w);
      final rent = _paneRect(t, 'Rent & home');
      // The rent starts from its 20 of padding and the columns from 24, then
      // each takes its spend's share of the 490 left; in a column, a pane
      // starts from its 20 and the block from 24.
      const free = 540.0 - 20 - 24 - 6;
      expect(
        rent.height,
        moreOrLessEquals(20 + free * 1150 / 2486.12, epsilon: 0.01),
      );
      expect(rent.width, _w - 16);
      final groceries = _paneRect(t, 'Groceries');
      final dining = _paneRect(t, 'Dining out');
      const columns = 24 + free * 1336.12 / 2486.12;
      expect(
        groceries.height,
        moreOrLessEquals(
          20 + (columns - 6 - 40) * 412.36 / 627.11,
          epsilon: 0.01,
        ),
      );
      expect(
        dining.height,
        moreOrLessEquals(
          20 + (columns - 6 - 20 - 24) * 286.40 / 709.01,
          epsilon: 0.01,
        ),
      );
      expect(groceries.top, moreOrLessEquals(rent.bottom + 6, epsilon: 0.01));
      expect(dining.top, groceries.top);
      expect(dining.left, moreOrLessEquals(groceries.right + 6, epsilon: 0.01));
      final shopping = _paneRect(t, 'Shopping');
      expect(shopping.left, groceries.left);
      expect(shopping.top, greaterThan(groceries.bottom));
      final fun = _paneRect(t, 'Fun');
      final transport = _paneRect(t, 'Transport');
      expect(fun.top, transport.top);
      expect(fun.top, greaterThan(dining.bottom));
      expect(transport.left, moreOrLessEquals(fun.right + 6, epsilon: 0.01));
      expect(find.text('October'), findsOneWidget);
      expect(find.text('Linden Court Apartments'), findsOneWidget);
      expect(find.text('Paid Oct 1'), findsOneWidget);
      expect(find.text('Over by \$36.40'), findsOneWidget);
      expect(find.text('72% of \$200'), findsNothing);
      expect(find.text('92% of \$450'), findsOneWidget);
      expect(
        _node(t, 'Groceries, \$412.36, 92% of \$450, 8% less than Sep'),
        isSemantics(isLink: true, hasTapAction: true),
      );
      await t.tap(find.text('Subs'));
      expect(opened, 1);
      await _pump(t, _mosaic(), size: const Size(1280, 900));
      // `head(cid, full=False)`: the small pane's percent alone.
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('72% of \$200'), findsNothing);
      final band = _paneRect(t, 'Rent & home');
      expect(band.height, lessThan(520));
      // `.rent-mid { flex: 1; align-items: center }`: the ticket at the
      // band's end, centred between the head and the due line, 6 from each.
      final ticket = t.getRect(find.byType(FrostedTicket));
      final top = t.getRect(find.text('Rent & home')).bottom + 6;
      final floor = t.getRect(find.byType(FrostedDueLine)).top - 6;
      expect(ticket.right, moreOrLessEquals(band.right - 12, epsilon: 0.01));
      expect(
        ticket.center.dy,
        moreOrLessEquals((top + floor) / 2, epsilon: 0.5),
      );
      expect(
        t
            .getRect(
              find.descendant(
                of: find.byWidgetPredicate(
                  (w) => w is FrostedPane && w.name == 'Rent & home',
                ),
                matching: find.byType(FrostedMoney),
              ),
            )
            .top,
        moreOrLessEquals(top, epsilon: 0.5),
      );
    });

    testWidgets('FrostedPane says its name, figure and share, its note under '
        'its meter; over its budget its alert stands in bold under an over '
        'meter; its head keeps the name and the share whole', (t) async {
      await _pump(t, _pane());
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('92% of \$450'), findsOneWidget);
      expect(find.text('8% less than Sep'), findsOneWidget);
      expect(
        t.getTopLeft(find.text('8% less than Sep')).dy,
        moreOrLessEquals(
          t.getBottomLeft(find.byType(FrostedMeter)).dy + 8,
          epsilon: 0.01,
        ),
      );
      expect(find.textContaining('412'), findsOneWidget);
      expect(t.widget<FrostedMeter>(find.byType(FrostedMeter)).over, isFalse);
      await _pump(t, _pane(over: true));
      expect(find.text('Over by \$36.40'), findsOneWidget);
      expect(
        t.widget<Text>(find.text('Over by \$36.40')).style!.fontWeight,
        FontWeight.w600,
      );
      final meter = t.widget<FrostedMeter>(find.byType(FrostedMeter));
      expect(meter.over, isTrue);
      expect(meter.fraction, moreOrLessEquals(250 / 286.40));
      expect(
        _node(t, 'Dining out, \$286.40, 115% of \$250, Over by \$36.40'),
        isNotNull,
      );
      // In a pane too narrow for both, neither word shrinks: the share runs
      // past the end under the clip (`white-space: nowrap; overflow: hidden`).
      await _pump(
        t,
        Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: 160, child: _pane()),
        ),
      );
      final name = find.text('Groceries');
      final share = find.text('92% of \$450');
      expect(
        t.getSize(name).width,
        moreOrLessEquals(_textWidth(t, name), epsilon: 0.5),
      );
      expect(
        t.getSize(share).width,
        moreOrLessEquals(_textWidth(t, share), epsilon: 0.5),
      );
      expect(
        t.getTopLeft(share).dx - t.getTopRight(name).dx,
        greaterThanOrEqualTo(8 - 0.01),
      );
    });
  });

  group('sweep', () {
    for (final preset in FrostedThemeData.presets) {
      for (final brightness in Brightness.values) {
        testWidgets(
          'every meter and card at 320 wide and text scale 1.3, $preset '
          '${brightness.name}',
          (t) async {
            final failures = <String>[];
            final all = _everything();
            for (var i = 0; i < all.length; i++) {
              await _pump(
                t,
                all[i],
                size: const Size(320, 1400),
                brightness: brightness,
                preset: preset,
                textScale: 1.3,
                check: false,
              );
              final error = t.takeException();
              if (error != null) {
                failures.add('#$i ${all[i].runtimeType}: $error');
              }
            }
            expect(failures, isEmpty);
          },
        );
      }
    }
  });
}

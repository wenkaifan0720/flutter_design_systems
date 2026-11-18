import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _quarters = [
  DesignChartSeries(
    label: 'Revenue',
    points: [
      DesignChartPoint(0, 820),
      DesignChartPoint(1, 1240),
      DesignChartPoint(2, 1640),
      DesignChartPoint(3, 1100),
    ],
  ),
  DesignChartSeries(
    label: 'Costs',
    points: [
      DesignChartPoint(0, 600),
      DesignChartPoint(1, 700),
      DesignChartPoint(2, 900),
      DesignChartPoint(3, 800),
    ],
  ),
];

const _summary = '2 series, 4 points, 0 to 3, lowest 600, highest 1,640';

DesignChartDetails? _last;

// The bare reference painter: the y ticks' labels down the start edge.
Widget _plain(BuildContext context, DesignChartDetails d) {
  _last = d;
  return Stack(
    children: [
      for (final t in d.yTicks)
        Positioned(left: 0, top: t.position - 8, child: Text(t.label)),
    ],
  );
}

late _HostState _host;

class _Host extends StatefulWidget {
  const _Host({
    super.key,
    this.series = _quarters,
    this.xAxis = DesignChartXAxis.linear,
    this.categories,
    this.formatY,
    this.focusNode,
  });

  final List<DesignChartSeries> series;
  final DesignChartXAxis xAxis;
  final List<String>? categories;
  final DesignChartFormat? formatY;
  final FocusNode? focusNode;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late List<DesignChartSeries> series = widget.series;
  final List<DesignChartPointRef?> picked = [];
  int tables = 0;

  void show(List<DesignChartSeries> next) => setState(() => series = next);

  @override
  Widget build(BuildContext context) {
    _host = this;
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 300,
        height: 150,
        child: DesignChart(
          semanticLabel: 'Revenue by quarter',
          series: series,
          xAxis: widget.xAxis,
          categories: widget.categories,
          formatY: widget.formatY,
          focusNode: widget.focusNode,
          // Start 40, end 20: the room a look keeps for its y labels.
          padding: const EdgeInsetsDirectional.fromSTEB(40, 10, 20, 10),
          onActivePointChanged: picked.add,
          onShowTable: () => tables++,
          builder: _plain,
        ),
      ),
    );
  }
}

// Where [ref] is drawn, on screen, nudged [by].
Offset _at(
  WidgetTester tester,
  DesignChartPointRef ref, [
  Offset by = Offset.zero,
]) => tester.getTopLeft(find.byType(DesignChart)) + _last!.positionOf(ref) + by;

SemanticsNode _node(WidgetTester tester) =>
    semanticsOf(tester, find.bySemanticsLabel('Revenue by quarter'));

const _p = DesignChartPointRef.new;

void main() {
  setUp(() => _last = null);

  behaviourContract(
    'DesignChart',
    build: (c) => const _Host(),
    node: () => find.bySemanticsLabel('Revenue by quarter'),
    root: () => find.byType(DesignChart),
    semantics: isSemantics(
      label: 'Revenue by quarter',
      value: _summary,
      increasedValue: '0, Revenue: 820',
      decreasedValue: '3, Costs: 800',
      isFocusable: true,
      hasIncreaseAction: true,
      hasDecreaseAction: true,
      customActions: const [CustomSemanticsAction(label: 'Show data table')],
    ),
    noDisabledState: 'a chart shows data: there is no input to turn off',
    // The look's tick labels are drawn; a screen reader hears the data.
    hidden: const ['1,500', '2,000'],
    keyboard: (p) async {
      await p.tabInto();
      expect(_last!.states, contains(WidgetState.focused));
      p.tester.takeAnnouncements();
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(_last!.active, _p(0, 0));
      expect(_last!.activeBy, isNull, reason: 'the keys');
      expect(p.data.value, '0, Revenue: 820');
      expect(p.tester.takeAnnouncements().map((a) => a.message), [
        '0, Revenue: 820',
      ]);
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(_last!.active, _p(0, 1));
      await p.key(LogicalKeyboardKey.arrowUp);
      expect(_last!.active, _p(0, 1), reason: 'nothing above Revenue there');
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(_last!.active, _p(1, 1));
      await p.key(LogicalKeyboardKey.arrowUp);
      expect(_last!.active, _p(0, 1));
      await p.key(LogicalKeyboardKey.end);
      expect(_last!.active, _p(0, 3));
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(_last!.active, _p(0, 3), reason: 'nothing after the last');
      await p.key(LogicalKeyboardKey.home);
      expect(_last!.active, _p(0, 0));
      await p.key(LogicalKeyboardKey.escape);
      expect(_last!.active, isNull);
      expect(p.data.value, _summary);
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(_last!.active, _p(0, 3), reason: 'Left from nothing: the last');
      await p.key(LogicalKeyboardKey.keyA);
      expect(_last!.active, _p(0, 3));
      // Leaving lets go of the keys' pick.
      FocusManager.instance.primaryFocus!.unfocus();
      await p.tester.pumpAndSettle();
      expect(_last!.active, isNull);
      expect(_last!.states, isEmpty);
      expect(_host.picked.last, isNull);
    },
    rtl: (p) async {
      expect(_last!.plotArea.left, 20, reason: 'the start padding is right');
      expect(_last!.plotArea.right, 260);
      expect(
        _last!.x.map(0),
        greaterThan(_last!.x.map(3)),
        reason: 'x runs right to left',
      );
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(_last!.active, _p(0, 0), reason: 'Left is onward');
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(_last!.active, _p(0, 1));
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(_last!.active, _p(0, 0));
      expect(_last!.activePosition!.dx, 260);
    },
    motion: (p) async {
      _host.show(const [
        DesignChartSeries(
          label: 'Revenue',
          points: [DesignChartPoint(0, 400), DesignChartPoint(1, 300)],
        ),
      ]);
      await p.tester.pump();
    },
  );

  group('a pointer', () {
    testWidgets('a mouse: the point nearest along x, the series nearest '
        'by y; leaving clears it', (tester) async {
      await tester.pumpWidget(harness(const _Host()));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(700, 500));
      await mouse.moveTo(_at(tester, _p(1, 2), const Offset(12, 4)));
      await tester.pump();
      expect(_last!.active, _p(1, 2));
      expect(_last!.activeBy, PointerDeviceKind.mouse);
      expect(_last!.activePosition, _last!.positionOf(_p(1, 2)));
      expect(_last!.states, contains(WidgetState.hovered));
      await mouse.moveTo(_at(tester, _p(0, 2), const Offset(-12, 4)));
      await tester.pump();
      expect(_last!.active, _p(0, 2));
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump();
      expect(_last!.active, isNull);
      expect(_last!.states, isEmpty);
      expect(_host.picked, [_p(1, 2), _p(0, 2), null]);
      await mouse.removePointer();
    });

    testWidgets('a finger scrubs across; lifting lets go', (tester) async {
      await tester.pumpWidget(harness(const _Host()));
      final finger = await tester.startGesture(_at(tester, _p(0, 0)));
      await finger.moveBy(const Offset(30, 0));
      await tester.pump();
      for (final i in [1, 2, 3]) {
        await finger.moveTo(_at(tester, _p(0, i)));
        await tester.pump();
        expect(_last!.active, _p(0, i));
        expect(_last!.activeBy, PointerDeviceKind.touch);
      }
      await finger.up();
      await tester.pump();
      expect(_last!.active, isNull);
    });

    testWidgets('a vertical drag scrolls the list it is in', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        harness(
          ListView(
            controller: scroll,
            children: const [_Host(), SizedBox(height: 1200)],
          ),
        ),
      );
      await tester.drag(
        find.byType(DesignChart),
        const Offset(0, -100),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump();
      expect(scroll.offset, greaterThan(0));
      expect(_host.picked, isEmpty);
    });

    testWidgets('a tap holds its point until a tap elsewhere', (tester) async {
      await tester.pumpWidget(harness(const _Host()));
      await tester.tapAt(_at(tester, _p(0, 1)));
      await tester.pump(const Duration(seconds: 1));
      expect(_last!.active, _p(0, 1));
      await tester.tapAt(_at(tester, _p(1, 3)));
      await tester.pump();
      expect(_last!.active, _p(1, 3));
      await tester.tapAt(const Offset(600, 500));
      await tester.pump();
      expect(_last!.active, isNull);
      expect(_host.picked, [_p(0, 1), _p(1, 3), null]);
    });

    testWidgets('bars: the band under the pointer, its padding too; the '
        'axes, nothing', (tester) async {
      await tester.pumpWidget(
        harness(
          const _Host(
            xAxis: DesignChartXAxis.band,
            categories: ['Q1', 'Q2', 'Q3', 'Q4'],
          ),
        ),
      );
      final x = _last!.x as DesignBandScale;
      expect(x.count, 4);
      expect(_last!.xTicks.map((t) => t.label), ['Q1', 'Q2', 'Q3', 'Q4']);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(700, 500));
      // Between bands 2 and 3, on 2's side, level with Revenue.
      await mouse.moveTo(_at(tester, _p(0, 2), Offset(x.step / 2 - 1, 0)));
      await tester.pump();
      expect(_last!.active, _p(0, 2));
      expect(_node(tester).getSemanticsData().value, 'Q3, Revenue: 1,640');
      await mouse.moveTo(const Offset(5, 75));
      await tester.pump();
      expect(_last!.active, isNull, reason: 'over the y axis');
      await mouse.removePointer();
      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('Revenue by quarter'),
        ).getSemanticsData().value,
        '2 series, 4 points, Q1 to Q4, lowest 600, highest 1,640',
      );
    });
  });

  testWidgets('a screen reader steps through every point, series after '
      'series, and asks for the table', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(harness(const _Host()));
    final said = <String>[];
    for (var i = 0; i < 9; i++) {
      final node = _node(tester);
      if (!node.getSemanticsData().hasAction(SemanticsAction.increase)) break;
      semanticsOwner().performAction(node.id, SemanticsAction.increase);
      await tester.pump();
      said.add(_node(tester).getSemanticsData().value);
    }
    expect(said, [
      '0, Revenue: 820',
      '1, Revenue: 1,240',
      '2, Revenue: 1,640',
      '3, Revenue: 1,100',
      '0, Costs: 600',
      '1, Costs: 700',
      '2, Costs: 900',
      '3, Costs: 800',
    ]);
    expect(
      tester.takeAnnouncements().map((a) => a.message),
      containsAllInOrder(said),
    );
    semanticsOwner().performAction(_node(tester).id, SemanticsAction.decrease);
    await tester.pump();
    expect(_last!.active, _p(1, 2));
    semanticsOwner().performAction(
      _node(tester).id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(
        const CustomSemanticsAction(label: 'Show data table'),
      ),
    );
    expect(_host.tables, 1);
    handle.dispose();
  });

  testWidgets('a gap: no mark to pick, no step, no extreme', (tester) async {
    await tester.pumpWidget(
      harness(
        const _Host(
          series: [
            DesignChartSeries(
              label: 'Steps',
              points: [
                DesignChartPoint(0, 4000),
                DesignChartPoint(1, null),
                DesignChartPoint(2, 6000),
              ],
            ),
          ],
        ),
      ),
    );
    expect(
      _node(tester).getSemanticsData().value,
      '1 series, 2 points, 0 to 2, lowest 4,000, highest 6,000',
    );
    expect(_last!.positionOf(_p(0, 1)).dy, _last!.y.map(_last!.y.min));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_last!.active, _p(0, 2));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_last!.active, _p(0, 2), reason: 'one series: nothing below');
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(700, 500));
    await mouse.moveTo(_at(tester, _p(0, 1), const Offset(-10, 0)));
    await tester.pump();
    expect(_last!.active, _p(0, 0));
    await mouse.removePointer();
  });

  testWidgets('new data springs from the values drawn; a new point rises '
      'from the baseline; a picked point that goes lets go', (tester) async {
    await tester.pumpWidget(harness(const _Host()));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(_last!.active, _p(0, 3));
    final next = [
      const DesignChartSeries(
        label: 'Revenue',
        points: [
          DesignChartPoint(0, 1820),
          DesignChartPoint(1, 1240),
          DesignChartPoint(2, 1000),
        ],
      ),
      const DesignChartSeries(
        label: 'Costs',
        points: [
          DesignChartPoint(0, 600),
          DesignChartPoint(1, 700),
          DesignChartPoint(2, 900),
          DesignChartPoint(3, 800),
          DesignChartPoint(4, 1000),
        ],
      ),
    ];
    _host.show(next);
    await tester.pump();
    expect(_last!.active, isNull);
    expect(_host.picked.last, isNull);
    await tester.pump(const Duration(milliseconds: 50));
    final y = _last!.series[0].points[0].y!;
    expect(y, inExclusiveRange(820, 1820));
    final risen = _last!.series[1].points[4].y!;
    expect(risen, inExclusiveRange(0, 1000));
    await tester.pumpAndSettle();
    expect(_last!.series, next);
    expect(_last!.x.map(4), _last!.plotArea.right, reason: 'x widened too');
    expect(tester.binding.hasScheduledFrame, isFalse);
    // A second change mid-flight springs on from where it was.
    _host.show(_quarters);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    _host.show(next);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(_last!.series, next);
  });

  group('words', () {
    Future<String> said(
      WidgetTester tester,
      List<DesignChartPoint> points,
    ) async {
      await tester.pumpWidget(
        harness(
          _Host(
            key: UniqueKey(),
            xAxis: DesignChartXAxis.time,
            series: [DesignChartSeries(label: 'Visits', points: points)],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      return _node(tester).getSemanticsData().value.replaceAll(' ', ' ');
    }

    testWidgets('time: as fine as the points are apart', (tester) async {
      expect(
        await said(tester, [
          for (var m = 1; m <= 12; m++)
            DesignChartPoint.time(DateTime(2026, m), m * 10),
        ]),
        'January 2026, Visits: 10',
      );
      final months = _node(tester).getSemanticsData();
      expect(months.increasedValue, 'February 2026, Visits: 20');
      expect(_last!.x, isA<DesignTimeScale>());
      expect(
        await said(tester, [
          DesignChartPoint.time(DateTime(2026, 11, 16), 1),
          DesignChartPoint.time(DateTime(2026, 11, 17), 2),
        ]),
        'Monday, 16 November 2026, Visits: 1',
      );
      expect(
        await said(tester, [
          DesignChartPoint.time(DateTime(2026, 11, 16, 15), 1),
          DesignChartPoint.time(DateTime(2026, 11, 16, 16), 2),
        ]),
        'Nov 16, 3:00 PM, Visits: 1',
      );
      expect(
        await said(tester, [
          DesignChartPoint.time(DateTime(2025), 1),
          DesignChartPoint.time(DateTime(2026), 2),
        ]),
        '2025, Visits: 1',
      );
      expect(
        await said(tester, [DesignChartPoint.time(DateTime(2026, 11, 16), 1)]),
        'Monday, 16 November 2026, Visits: 1',
        reason: 'one point: its whole date',
      );
    });

    testWidgets('formatY: the ticks, the readout and the speech', (
      tester,
    ) async {
      await tester.pumpWidget(harness(_Host(formatY: (v) => '\$${v.round()}')));
      expect(_last!.yTicks.map((t) => t.label), [
        r'$0',
        r'$500',
        r'$1000',
        r'$1500',
        r'$2000',
      ]);
      expect(
        _node(tester).getSemanticsData().value,
        r'2 series, 4 points, 0 to 3, lowest $600, highest $1640',
      );
    });

    testWidgets('a summary of the caller\'s; no data at all', (tester) async {
      await tester.pumpWidget(
        harness(
          const SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 200,
                child: DesignChart(
                  semanticLabel: 'Empty',
                  series: [],
                  semanticSummary: 'No visits yet',
                  builder: _plain,
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('Empty'),
        ).getSemanticsData().value,
        'No visits yet',
      );
      expect(_last!.size, const Size(200, 100), reason: 'half as tall');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(_last!.active, isNull);
      await tester.pumpWidget(
        harness(
          const UnconstrainedBox(
            child: DesignChart(
              semanticLabel: 'None',
              series: [],
              builder: _plain,
            ),
          ),
        ),
      );
      expect(_last!.size, const Size(300, 150), reason: 'unbounded: 300');
      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('None'),
        ).getSemanticsData().value,
        '0 series',
      );
    });
  });

  testWidgets('a focus node of the caller\'s, swapped and kept', (
    tester,
  ) async {
    final a = FocusNode();
    final b = FocusNode();
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    await tester.pumpWidget(
      harness(_Host(key: const ValueKey(1), focusNode: a)),
    );
    a.requestFocus();
    await tester.pump();
    expect(_last!.states, contains(WidgetState.focused));
    await tester.pumpWidget(
      harness(_Host(key: const ValueKey(1), focusNode: b)),
    );
    b.requestFocus();
    await tester.pump();
    expect(_last!.states, contains(WidgetState.focused));
    await tester.pumpWidget(harness(const SizedBox()));
    expect(() => a.requestFocus(), returnsNormally, reason: 'not disposed');
  });

  test('values say what they are', () {
    const point = DesignChartPoint(1, 2);
    expect(point, const DesignChartPoint(1, 2));
    expect(point.hashCode, const DesignChartPoint(1, 2).hashCode);
    expect('$point', 'DesignChartPoint(1.0, 2.0)');
    expect(
      DesignChartPoint.time(DateTime.utc(1970, 1, 1, 0, 0, 1), null).x,
      1000,
    );
    const series = DesignChartSeries(label: 'A', points: [point]);
    expect(series, const DesignChartSeries(label: 'A', points: [point]));
    expect(
      series.hashCode,
      const DesignChartSeries(label: 'A', points: [point]).hashCode,
    );
    expect('$series', 'DesignChartSeries(A, 1 points)');
    expect(_p(1, 2), _p(1, 2));
    expect(_p(1, 2).hashCode, _p(1, 2).hashCode);
    expect('${_p(1, 2)}', 'DesignChartPointRef(1, 2)');
    const chart = DesignChart(
      semanticLabel: 'A',
      series: [series],
      builder: _plain,
      xAxis: DesignChartXAxis.band,
      autofocus: true,
    );
    expect(
      chart.toDiagnosticsNode().getProperties().map((p) => p.name),
      containsAll(['series', 'semanticLabel', 'xAxis', 'autofocus']),
    );
  });

  _pie();
  _table();
}

// ---- The pie.

DesignPieChartDetails? _lastPie;

Widget _plainPie(BuildContext context, DesignPieChartDetails d) {
  _lastPie = d;
  return const Center(child: Text('Legend'));
}

const _spending = [
  DesignPieSlice(label: 'Rent', value: 1200),
  DesignPieSlice(label: 'Food', value: 600),
  DesignPieSlice(label: 'Fun', value: 200),
];

late _PieHostState _pieHost;

class _PieHost extends StatefulWidget {
  const _PieHost({this.holeRadius = 0});

  final double holeRadius;

  @override
  State<_PieHost> createState() => _PieHostState();
}

class _PieHostState extends State<_PieHost> {
  List<DesignPieSlice> slices = _spending;
  final List<int?> picked = [];

  void show(List<DesignPieSlice> next) => setState(() => slices = next);

  @override
  Widget build(BuildContext context) {
    _pieHost = this;
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 200,
        height: 200,
        child: DesignPieChart(
          semanticLabel: 'Spending',
          slices: slices,
          holeRadius: widget.holeRadius,
          onActiveSliceChanged: picked.add,
          onShowTable: () {},
          builder: _plainPie,
        ),
      ),
    );
  }
}

// A point [fraction] of the radius out, [degrees] clockwise from twelve.
Offset _clock(double degrees, [double fraction = 0.8]) {
  final a = degrees * math.pi / 180;
  return const Offset(100, 100) +
      Offset(math.sin(a), -math.cos(a)) * 100 * fraction;
}

void _pie() {
  group('DesignPieChart', () {
    setUp(() => _lastPie = null);

    behaviourContract(
      'DesignPieChart',
      build: (c) => const _PieHost(),
      node: () => find.bySemanticsLabel('Spending'),
      root: () => find.byType(DesignPieChart),
      semantics: isSemantics(
        label: 'Spending',
        value: '3 slices, lowest 200, highest 1,200',
        increasedValue: '60%, Rent: 1,200',
        decreasedValue: '10%, Fun: 200',
        isFocusable: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
        customActions: const [CustomSemanticsAction(label: 'Show data table')],
      ),
      noDisabledState: 'a chart shows data: there is no input to turn off',
      hidden: const ['Legend'],
      keyboard: (p) async {
        await p.tabInto();
        Future<void> press(LogicalKeyboardKey key, int? slice) async {
          await p.key(key);
          expect(_lastPie!.active, slice, reason: '$key');
        }

        await press(LogicalKeyboardKey.arrowRight, 0);
        expect(p.data.value, '60%, Rent: 1,200');
        await press(LogicalKeyboardKey.arrowRight, 1);
        await press(LogicalKeyboardKey.arrowDown, 2);
        await press(LogicalKeyboardKey.arrowDown, 2);
        await press(LogicalKeyboardKey.arrowUp, 1);
        await press(LogicalKeyboardKey.arrowLeft, 0);
        await press(LogicalKeyboardKey.end, 2);
        await press(LogicalKeyboardKey.home, 0);
        await press(LogicalKeyboardKey.escape, null);
        await press(LogicalKeyboardKey.arrowUp, 2);
        // Leaving lets go of the keys' pick.
        FocusManager.instance.primaryFocus!.unfocus();
        await p.tester.pumpAndSettle();
        expect(_lastPie!.active, isNull);
      },
      rtl: (p) async {
        expect(_lastPie!.slices[0].sweepAngle, lessThan(0));
        await p.tabInto();
        await p.key(LogicalKeyboardKey.arrowLeft);
        expect(_lastPie!.active, 0, reason: 'Left is onward');
        await p.key(LogicalKeyboardKey.arrowLeft);
        expect(_lastPie!.active, 1);
        await p.key(LogicalKeyboardKey.arrowRight);
        expect(_lastPie!.active, 0);
        // Counter-clockwise: three o'clock is Food's, nine Rent's.
        final mouse = await p.tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await mouse.addPointer(location: const Offset(700, 500));
        await mouse.moveTo(_clock(90));
        await p.tester.pump();
        expect(_lastPie!.active, 1);
        await mouse.moveTo(_clock(270));
        await p.tester.pump();
        expect(_lastPie!.active, 0);
        await mouse.removePointer();
      },
      motion: (p) async {
        _pieHost.show(const [DesignPieSlice(label: 'Rent', value: 100)]);
        await p.tester.pump();
      },
    );

    testWidgets('angles clockwise from twelve; a pointer picks by angle, '
        'inside the radius, outside the hole', (tester) async {
      await tester.pumpWidget(harness(const _PieHost(holeRadius: 0.5)));
      final d = _lastPie!;
      expect(d.centre, const Offset(100, 100));
      expect(d.radius, 100);
      expect(d.holeRadius, 50);
      expect(d.slices.map((s) => s.share), [0.6, 0.3, closeTo(0.1, 1e-9)]);
      expect(d.slices[0].startAngle, -math.pi / 2);
      expect(d.slices[0].sweepAngle, closeTo(0.6 * 2 * math.pi, 1e-9));
      expect(
        d.slices[1].startAngle,
        closeTo(-math.pi / 2 + 0.6 * 2 * math.pi, 1e-9),
      );
      expect(d.slices[0].midAngle, closeTo(0.1 * math.pi, 1e-9));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(700, 500));
      for (final (degrees, slice) in [(90.0, 0), (270.0, 1), (345.0, 2)]) {
        await mouse.moveTo(_clock(degrees));
        await tester.pump();
        expect(_lastPie!.active, slice, reason: '$degrees°');
      }
      expect(_lastPie!.activeBy, PointerDeviceKind.mouse);
      await mouse.moveTo(_clock(90, 0.3));
      await tester.pump();
      expect(_lastPie!.active, isNull, reason: 'in the hole');
      await mouse.moveTo(const Offset(199, 199));
      await tester.pump();
      expect(_lastPie!.active, isNull, reason: 'past the rim');
      await mouse.removePointer();
      await tester.tapAt(_clock(90));
      await tester.pump();
      expect(_lastPie!.active, 0);
      expect(
        _lastPie!.activePosition!.dx,
        closeTo(100 + 100 * math.cos(0.1 * math.pi), 1e-9),
      );
      expect(_pieHost.picked, [0, 1, 2, null, 0]);
    });

    testWidgets('a screen reader steps through the slices; an empty slice '
        'is passed by', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(harness(const _PieHost()));
      _pieHost.show(const [
        DesignPieSlice(label: 'Rent', value: 1200),
        DesignPieSlice(label: 'Gifts', value: 0),
        DesignPieSlice(label: 'Fun', value: 300),
      ]);
      await tester.pumpAndSettle();
      final said = <String>[];
      for (var i = 0; i < 4; i++) {
        final node = semanticsOf(tester, find.bySemanticsLabel('Spending'));
        if (!node.getSemanticsData().hasAction(SemanticsAction.increase)) break;
        semanticsOwner().performAction(node.id, SemanticsAction.increase);
        await tester.pump();
        said.add(
          semanticsOf(
            tester,
            find.bySemanticsLabel('Spending'),
          ).getSemanticsData().value,
        );
      }
      expect(said, ['80%, Rent: 1,200', '20%, Fun: 300']);
      final node = semanticsOf(tester, find.bySemanticsLabel('Spending'));
      semanticsOwner().performAction(node.id, SemanticsAction.decrease);
      await tester.pump();
      expect(_lastPie!.active, 0);
      handle.dispose();
    });

    testWidgets('new values spring; a new slice grows from nothing; a picked '
        'slice that goes lets go', (tester) async {
      await tester.pumpWidget(harness(const _PieHost()));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(_lastPie!.active, 2);
      _pieHost.show(const [
        DesignPieSlice(label: 'Rent', value: 600),
        DesignPieSlice(label: 'Food', value: 600),
      ]);
      await tester.pump();
      expect(_lastPie!.active, isNull);
      await tester.pump(const Duration(milliseconds: 50));
      expect(_lastPie!.slices[0].value, inExclusiveRange(600, 1200));
      await tester.pumpAndSettle();
      expect(_lastPie!.slices.map((s) => s.share), [0.5, 0.5]);
      _pieHost.show(const [
        DesignPieSlice(label: 'Rent', value: 600),
        DesignPieSlice(label: 'Food', value: 600),
        DesignPieSlice(label: 'New', value: 600),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(_lastPie!.slices[2].value, inExclusiveRange(0, 600));
      await tester.pumpAndSettle();
      _pieHost.show(const []);
      await tester.pumpAndSettle();
      expect(
        semanticsOf(
          tester,
          find.bySemanticsLabel('Spending'),
        ).getSemanticsData().value,
        '0 slices',
      );
    });

    testWidgets('a summary and a format of the caller\'s; a square when '
        'unbounded', (tester) async {
      await tester.pumpWidget(
        harness(
          SingleChildScrollView(
            child: DesignPieChart(
              semanticLabel: 'Pie',
              slices: _spending,
              semanticSummary: 'Mostly rent',
              formatValue: (v) => '€${v.round()}',
              builder: _plainPie,
            ),
          ),
        ),
      );
      expect(_lastPie!.size, const Size(800, 800));
      final node = semanticsOf(tester, find.bySemanticsLabel('Pie'));
      expect(node.getSemanticsData().value, 'Mostly rent');
      expect(node.getSemanticsData().increasedValue, '60%, Rent: €1200');
      const pie = DesignPieChart(
        semanticLabel: 'Pie',
        slices: _spending,
        builder: _plainPie,
        holeRadius: 0.5,
        autofocus: true,
      );
      expect(
        pie.toDiagnosticsNode().getProperties().map((p) => p.name),
        containsAll(['slices', 'semanticLabel', 'holeRadius', 'autofocus']),
      );
      expect(_spending.first, const DesignPieSlice(label: 'Rent', value: 1200));
      expect(
        _spending.first.hashCode,
        const DesignPieSlice(label: 'Rent', value: 1200).hashCode,
      );
      expect('${_spending.first}', 'DesignPieSlice(Rent, 1200.0)');
    });
  });
}

// ---- The table.

final List<DesignChartTableCellDetails> _cells = [];

Widget _cell(BuildContext context, DesignChartTableCellDetails cell) {
  _cells.add(cell);
  return Padding(padding: const EdgeInsets.all(4), child: Text(cell.text));
}

// The table's rows, each its cells' roles and words.
List<List<String>> _read(WidgetTester tester) {
  final table = semanticsOf(tester, find.byType(Table));
  expect(table.getSemanticsData().role, SemanticsRole.table);
  final rows = <List<String>>[];
  table.visitChildren((row) {
    expect(row.getSemanticsData().role, SemanticsRole.row);
    final cells = <String>[];
    row.visitChildren((cell) {
      final d = cell.getSemanticsData();
      cells.add(
        '${d.role == SemanticsRole.columnHeader ? 'th' : 'td'} ${d.label}',
      );
      return true;
    });
    rows.add(cells);
    return true;
  });
  return rows;
}

void _table() {
  group('DesignChartTable', () {
    setUp(_cells.clear);

    testWidgets('a row per x, a column per series; a missing value is '
        '"Empty"', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        harness(
          const DesignChartTable(
            semanticLabel: 'Revenue by quarter',
            xHeader: 'Quarter',
            xAxis: DesignChartXAxis.band,
            categories: ['Q1', 'Q2', 'Q3'],
            series: [
              DesignChartSeries(
                label: 'Revenue',
                points: [
                  DesignChartPoint(0, 820),
                  DesignChartPoint(1, 1240),
                  DesignChartPoint(2, null),
                ],
              ),
              DesignChartSeries(
                label: 'Costs',
                points: [DesignChartPoint(0, 600), DesignChartPoint(1, 700)],
              ),
            ],
            cellBuilder: _cell,
          ),
        ),
      );
      expect(_read(tester), [
        ['th Quarter', 'th Revenue', 'th Costs'],
        ['td Q1', 'td 820', 'td 600'],
        ['td Q2', 'td 1,240', 'td 700'],
        ['td Q3', 'td Empty', 'td Empty'],
      ]);
      expect(find.bySemanticsLabel('Revenue by quarter'), findsOneWidget);
      final header = _cells.firstWhere((c) => c.column == 1 && c.row == 0);
      expect(header.isHeader, isTrue);
      expect(header.text, 'Revenue');
      expect(_cells.last.text, '', reason: 'nothing drawn for a gap');
      handle.dispose();
    });

    testWidgets('slices: name, value and share', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        harness(
          DesignChartTable.slices(
            slices: _spending,
            xHeader: 'Category',
            valueHeader: 'Amount',
            shareHeader: 'Share',
            formatValue: (v) => '€${v.round()}',
            cellBuilder: _cell,
          ),
        ),
      );
      expect(_read(tester), [
        ['th Category', 'th Amount', 'th Share'],
        ['td Rent', 'td €1200', 'td 60%'],
        ['td Food', 'td €600', 'td 30%'],
        ['td Fun', 'td €200', 'td 10%'],
      ]);
      handle.dispose();
    });

    testWidgets('times read as the chart says them; diagnostics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final table = DesignChartTable(
        xAxis: DesignChartXAxis.time,
        series: [
          DesignChartSeries(
            label: 'Visits',
            points: [
              DesignChartPoint.time(DateTime(2026), 1),
              DesignChartPoint.time(DateTime(2026, 2), 2),
            ],
          ),
        ],
        cellBuilder: _cell,
      );
      await tester.pumpWidget(harness(table));
      expect(_read(tester)[1], ['td January 2026', 'td 1']);
      expect(_read(tester)[0][0], 'th ', reason: 'no header given');
      expect(
        table.toDiagnosticsNode().getProperties().map((p) => p.name),
        contains('series'),
      );
      handle.dispose();
    });
  });
}

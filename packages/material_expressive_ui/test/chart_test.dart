/// The chart's scaled axis: the domain maths (padding, a flat series, a
/// value outside a fixed range), the sparse labels, the paired chart and
/// the line on a measure's axis at a phone's width and at text scale 1.3,
/// in every preset and brightness (the y labels' even-spacing assert runs
/// in each), the sparkline left to its row, and the donut in a bounded box
/// and a tile row's intrinsic height. The count chart's own
/// tests stay in content_test.dart, unchanged.
library;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

/// [child] in Expressive's host at [scale], [width] wide.
Widget _kit(
  Widget child, {
  String preset = 'baseline',
  Brightness brightness = Brightness.light,
  double scale = 1,
  double width = 390,
}) => MaterialApp(
  home: ExpressiveHost(
    light: ExpressiveThemeData.preset(preset, Brightness.light),
    dark: ExpressiveThemeData.preset(preset, Brightness.dark),
    brightness: brightness,
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ),
        ),
      ),
    ),
  ),
);

/// [days] of readings two a day (7 AM and 8 PM), starting [from] days into
/// a range [span] days wide; systolic around 128, diastolic around 82.
(ExpressiveChartSeries, ExpressiveChartSeries) _readings(
  int days, {
  int from = 0,
}) {
  final systolic = <ExpressiveChartPoint>[];
  final diastolic = <ExpressiveChartPoint>[];
  for (var d = from; d < from + days; d++) {
    for (final hour in <int>[7, 20]) {
      final at = d + hour / 24;
      final wobble = ((d * 7 + hour) % 11) - 5.0;
      systolic.add(ExpressiveChartPoint('Sep ${d + 1}', 128 + wobble, at: at));
      diastolic.add(
        ExpressiveChartPoint('Sep ${d + 1}', 82 + wobble / 2, at: at),
      );
    }
  }
  return (
    ExpressiveChartSeries('Systolic', systolic),
    ExpressiveChartSeries('Diastolic', diastolic),
  );
}

List<ExpressiveChartTick> _ticks(int days) => <ExpressiveChartTick>[
  for (var d = 0; d < days; d++) ExpressiveChartTick(d + 0.5, 'Sep ${d + 1}'),
];

void main() {
  group('ExpressiveChartDomain', () {
    test('a data domain pads, then snaps outward to a round step', () {
      expect(
        const ExpressiveChartDomain.data().resolve(<double>[64, 71, 78]),
        const ExpressiveChartAxis(60, 80, 5),
      );
      expect(
        const ExpressiveChartDomain.data().resolve(<double>[172.6, 173.8]),
        const ExpressiveChartAxis(172, 174, 0.5),
      );
    });

    test('a flat series gets one unit each side', () {
      final axis = const ExpressiveChartDomain.data(padding: 0)
          .resolve(<double>[70, 70, 70]);
      expect(axis.min, lessThanOrEqualTo(69));
      expect(axis.max, greaterThanOrEqualTo(71));
    });

    test('a fixed domain widens to a value outside it, at its step', () {
      const bp = ExpressiveChartDomain.fixed(60, 180, step: 20);
      expect(
        bp.resolve(<double>[82, 128]),
        const ExpressiveChartAxis(60, 180, 20),
      );
      expect(
        bp.resolve(<double>[55, 191]),
        const ExpressiveChartAxis(40, 200, 20),
      );
      expect(const ExpressiveChartAxis(60, 180, 20).lines, <double>[
        60,
        80,
        100,
        120,
        140,
        160,
        180,
      ]);
    });

    test(
      'the zero domain starts at zero; labels take the step\'s decimals',
      () {
        final axis = const ExpressiveChartDomain.zero().resolve(<double>[
          3,
          38,
        ]);
        expect(axis.min, 0);
        expect(axis.max, greaterThanOrEqualTo(38));
        expect(const ExpressiveChartAxis(172, 174, 0.5).format(173), '173.0');
        expect(const ExpressiveChartAxis(60, 80, 5).format(65), '65');
      },
    );
  });

  group('sparse labels', () {
    test('all of them when they fit', () {
      final ticks = _ticks(7);
      expect(
        expressiveSparseTicks(ticks, List<double>.filled(7, 30), scale: 48),
        <int>[0, 1, 2, 3, 4, 5, 6],
      );
    });

    test('otherwise every k-th, counted back from the last, at most 7', () {
      for (final days in <int>[30, 90]) {
        final ticks = _ticks(days);
        final kept = expressiveSparseTicks(
          ticks,
          List<double>.filled(days, 36),
          scale: 330 / days,
        );
        expect(kept.last, days - 1, reason: '$days days');
        expect(kept.length, lessThanOrEqualTo(7), reason: '$days days');
        final gaps = <int>{
          for (var i = 1; i < kept.length; i++) kept[i] - kept[i - 1],
        };
        expect(gaps, hasLength(1), reason: '$days days: $kept');
      }
    });
  });

  group('ExpressiveChart.paired', () {
    for (final preset in <String>['baseline', 'slate', 'bloom']) {
      for (final brightness in Brightness.values) {
        for (final scale in <double>[1, 1.3]) {
          for (final days in <int>[1, 7, 30, 90]) {
            testWidgets(
              'lays out $days days in $preset ${brightness.name} at $scale',
              (tester) async {
                final (systolic, diastolic) = _readings(days);
                await tester.pumpWidget(
                  _kit(
                    ExpressiveChart.paired(
                      first: systolic,
                      second: diastolic,
                      span: days.toDouble(),
                      ticks: _ticks(days),
                      band: const ExpressiveChartBand(
                        80,
                        120,
                        label: 'Your target',
                      ),
                    ),
                    preset: preset,
                    brightness: brightness,
                    scale: scale,
                  ),
                );
                await tester.pumpAndSettle();
                expect(tester.takeException(), isNull);
                expect(find.text('Systolic'), findsOneWidget);
                expect(find.text('Diastolic'), findsOneWidget);
                expect(find.text('Your target'), findsOneWidget);
              },
            );
          }
        }
      }
    }

    testWidgets('says the empty stretch and each series to a screen reader', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final (systolic, diastolic) = _readings(5, from: 25);
      await tester.pumpWidget(
        _kit(
          ExpressiveChart.paired(
            first: systolic,
            second: diastolic,
            span: 30,
            ticks: _ticks(30),
            emptyLabel: 'No readings before Sep 26',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final node = tester.getSemantics(find.byType(ExpressiveChart));
      expect(node.label, contains('Systolic: 10 points'));
      expect(node.label, contains('Diastolic: 10 points'));
      expect(node.label, contains('No readings before Sep 26'));
      expect(node.getSemanticsData().flagsCollection.isImage, isTrue);
      semantics.dispose();
    });
  });

  group('ExpressiveChart.line on a measure', () {
    for (final scale in <double>[1, 1.3]) {
      for (final days in <int>[7, 30, 90]) {
        testWidgets('a pulse of $days days at $scale', (tester) async {
          final points = <ExpressiveChartPoint>[
            for (var d = 0; d < days; d++)
              ExpressiveChartPoint(
                'Sep ${d + 1}',
                64 + (d * 5 % 15).toDouble(),
                at: d + 0.3,
              ),
          ];
          await tester.pumpWidget(
            _kit(
              ExpressiveChart.line(
                points: points,
                domain: const ExpressiveChartDomain.data(),
                labels: ExpressiveChartLabels.sparse,
                span: days.toDouble(),
                ticks: _ticks(days),
                aspectRatio: 1.6,
              ),
              scale: scale,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('a sparkline is left to its row', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _kit(
          Semantics(
            label: 'Pulse, 68 bpm',
            child: const SizedBox(
              width: 88,
              height: 36,
              child: ExpressiveChart.line(
                points: <ExpressiveChartPoint>[
                  ExpressiveChartPoint('Mon', 66),
                  ExpressiveChartPoint('Tue', 71),
                  ExpressiveChartPoint('Wed', 68),
                ],
                domain: ExpressiveChartDomain.data(),
                labels: ExpressiveChartLabels.none,
                aspectRatio: 88 / 36,
              ),
            ),
          ),
          scale: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Pulse, 68 bpm'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Mon')), findsNothing);
      semantics.dispose();
    });

    testWidgets('the defaults keep the count chart as it was', (tester) async {
      await tester.pumpWidget(
        _kit(
          const ExpressiveChart.line(
            points: <ExpressiveChartPoint>[
              ExpressiveChartPoint('M', 20),
              ExpressiveChartPoint('T', 40),
            ],
          ),
        ),
      );
      // A label under every point, as a Text of its own.
      expect(find.text('M'), findsOneWidget);
      expect(find.text('T'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ExpressiveChart.line on a card', () {
    const week = <ExpressiveChartPoint>[
      ExpressiveChartPoint('M', 58, at: 0),
      ExpressiveChartPoint('T', 56, at: 1),
      ExpressiveChartPoint('W', 57, at: 2),
      ExpressiveChartPoint('T', 63, at: 3, color: Color(0xFFB3261E)),
    ];
    final ticks = <ExpressiveChartTick>[
      for (final (i, day) in <String>[
        'M',
        'T',
        'W',
        'T',
        'F',
        'S',
        'S',
      ].indexed)
        ExpressiveChartTick(i.toDouble(), day),
    ];

    for (final scale in <double>[1, 1.3]) {
      testWidgets('plain labels, a usual range and a goal at $scale', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _kit(
            ExpressiveChart.line(
              points: week,
              highlight: 3,
              labels: ExpressiveChartLabels.plain,
              domain: const ExpressiveChartDomain.data(padding: 0.2),
              span: 6,
              ticks: ticks,
              band: const ExpressiveChartBand(
                55,
                61,
                label: 'Your range',
                color: Color(0x5534A853),
              ),
              target: const ExpressiveChartTarget(60, label: 'Goal'),
              semanticLabel: 'Resting heart rate this week',
              aspectRatio: 2.2,
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final node = tester.getSemantics(find.byType(ExpressiveChart));
        expect(node.label, contains('Resting heart rate this week'));
        semantics.dispose();
      });
    }

    testWidgets('the band and the goal are read out on a chart without a '
        'label of its own', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _kit(
          ExpressiveChart.line(
            points: week,
            labels: ExpressiveChartLabels.plain,
            span: 6,
            ticks: ticks,
            band: const ExpressiveChartBand(55, 61, label: 'Your range'),
            target: const ExpressiveChartTarget(60, label: 'Goal'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final node = tester.getSemantics(find.byType(ExpressiveChart));
      expect(node.label, contains('Your range: 55 to 61'));
      expect(node.label, contains('Goal: 60'));
      semantics.dispose();
    });

    testWidgets('bars take a goal, read out and reached by the axis, and a '
        'short bar holds its shape', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _kit(
          const ExpressiveChart.bar(
            points: <ExpressiveChartPoint>[
              ExpressiveChartPoint('M', 6200),
              ExpressiveChartPoint('T', 7400),
              ExpressiveChartPoint('W', 150),
            ],
            highlight: 2,
            target: ExpressiveChartTarget(8000, label: 'Goal'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final node = tester.getSemantics(find.byType(ExpressiveChart));
      expect(node.label, contains('W 150'));
      expect(node.label, contains('Goal: 8000'));
      semantics.dispose();
    });
  });

  group('ExpressivePieChart', () {
    const spend = <ExpressiveChartPoint>[
      ExpressiveChartPoint('Rent', 1200),
      ExpressiveChartPoint('Food', 620),
      ExpressiveChartPoint('Travel', 380),
      ExpressiveChartPoint('Other', 220),
    ];
    const pie = ExpressivePieChart(
      points: spend,
      centerValue: '2,420',
      centerLabel: 'Spent in March',
    );

    testWidgets('unbounded, the ring takes the width', (tester) async {
      await tester.pumpWidget(_kit(pie));
      await tester.pumpAndSettle();
      final ring = tester.getSize(find.byType(AspectRatio));
      expect(ring, const Size(358, 358));
    });

    testWidgets('in a box shorter than its width, the ring gives way to the '
        'legend instead of overflowing, still round and centred', (
      tester,
    ) async {
      await tester.pumpWidget(_kit(const SizedBox(height: 240, child: pie)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final box = tester.getRect(find.byType(ExpressivePieChart));
      final ring = tester.getRect(find.byType(AspectRatio));
      expect(ring.width, ring.height);
      expect(ring.height, lessThan(240));
      expect(ring.center.dx, closeTo(box.center.dx, 0.5));
      expect(
        tester.getRect(find.textContaining('Other')).bottom,
        lessThanOrEqualTo(box.bottom),
      );
    });

    testWidgets('it answers a tile row\'s intrinsic height', (tester) async {
      await tester.pumpWidget(
        _kit(
          const IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[Expanded(child: pie)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(AspectRatio)).width, closeTo(358, 0.5));
    });
  });
}

// The charts' matrices: nice linear scales over every magnitude and sign,
// time scales from seconds to centuries, a pie's angles all the way round
// both ways, and every locale × axis × direction, a chart built, said and
// stepped in the locale's words and digits.
@Tags(['sweep'])
library;

import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _rtl = {'ar', 'fa', 'he', 'ur'};

const RawWidgetsLocalizations _en = DefaultRawWidgetsLocalizations();

RawChartDetails? _last;
RawPieChartDetails? _lastPie;

void main() {
  test('linear: nice bounds hold the data, ticks on whole steps', () {
    final random = math.Random(7);
    for (var i = 0; i < 2000; i++) {
      final magnitude = math.pow(10, random.nextInt(13) - 3).toDouble();
      final a = (random.nextDouble() * 2 - 1) * magnitude;
      final b = a + random.nextDouble() * magnitude * 3;
      final count = 2 + random.nextInt(9);
      final s = RawLinearScale.nice(
        min: a,
        max: b,
        start: 0,
        end: 1,
        tickCount: count,
        includeZero: random.nextBool(),
      );
      final reason = '[$a, $b] by $count: $s';
      expect(s.min, lessThanOrEqualTo(a), reason: reason);
      expect(s.max, greaterThanOrEqualTo(b), reason: reason);
      final ticks = s.ticks(_en, count: count);
      expect(ticks.length, inInclusiveRange(2, count * 2 + 2), reason: reason);
      expect(ticks.first.value, closeTo(s.min, (s.max - s.min) * 1e-9));
      expect(ticks.last.value, closeTo(s.max, (s.max - s.min) * 1e-9));
      for (var j = 1; j < ticks.length; j++) {
        expect(ticks[j].value, greaterThan(ticks[j - 1].value), reason: reason);
      }
      expect(
        ticks.map((t) => t.label).toSet(),
        hasLength(ticks.length),
        reason: 'labels tell ticks apart: $reason',
      );
      for (final t in ticks) {
        expect(
          _en.parseDecimal(t.label),
          closeTo(t.value, (s.max - s.min) * 1e-9),
          reason: 'a label reads back: $reason',
        );
      }
    }
  });

  test('time: calendar steps from seconds to centuries', () {
    final random = math.Random(11);
    for (var i = 0; i < 600; i++) {
      final start = DateTime(
        1990 + random.nextInt(60),
        1 + random.nextInt(12),
        1 + random.nextInt(28),
        random.nextInt(24),
        random.nextInt(60),
        random.nextInt(60),
      );
      // 3 s to 300 years, evenly in log.
      final seconds = math.pow(10, 0.5 + random.nextDouble() * 9.5);
      final end = start.add(Duration(seconds: seconds.round()));
      final s = RawTimeScale.nice(min: start, max: end, start: 0, end: 1);
      final reason = '$start → $end: $s';
      expect(s.min.isAfter(start), isFalse, reason: reason);
      expect(s.max.isBefore(end), isFalse, reason: reason);
      final ticks = s.ticks(_en);
      expect(ticks.length, inInclusiveRange(2, 13), reason: reason);
      expect(ticks.first.value, s.min.millisecondsSinceEpoch, reason: reason);
      for (var j = 1; j < ticks.length; j++) {
        expect(ticks[j].value, greaterThan(ticks[j - 1].value), reason: reason);
      }
      expect(ticks.every((t) => t.label.isNotEmpty), isTrue, reason: reason);
      expect(
        ticks.every((t) => t.position >= -1e-9 && t.position <= 1 + 1e-9),
        isTrue,
        reason: reason,
      );
    }
  });

  testWidgets('a pie picks the slice its angles draw, all the way round, '
      'both ways', (tester) async {
    final random = math.Random(3);
    for (final direction in TextDirection.values) {
      for (var round = 0; round < 8; round++) {
        final slices = [
          for (var i = 0; i < 2 + random.nextInt(6); i++)
            RawPieSlice(label: 'S$i', value: 1 + random.nextInt(50).toDouble()),
        ];
        await tester.pumpWidget(
          harness(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 200,
                height: 200,
                child: RawPieChart(
                  key: UniqueKey(),
                  semanticLabel: 'Pie',
                  slices: slices,
                  builder: (context, pie) {
                    _lastPie = pie;
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
            textDirection: direction,
          ),
        );
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: const Offset(700, 500));
        for (var degrees = 1.0; degrees < 360; degrees += 7) {
          final a = degrees * math.pi / 180;
          await mouse.moveTo(
            const Offset(100, 100) + Offset(math.sin(a), -math.cos(a)) * 70,
          );
          await tester.pump();
          // The canvas angle of that point, 0 at three o'clock, clockwise.
          final canvas = a - math.pi / 2;
          final drawn = [
            for (var i = 0; i < _lastPie!.slices.length; i++)
              if (_within(canvas, _lastPie!.slices[i])) i,
          ];
          if (drawn.isEmpty) continue; // on an edge, to rounding
          expect(
            _lastPie!.active,
            drawn.single,
            reason: '$direction, $degrees°',
          );
        }
        await mouse.removePointer();
      }
    }
  });

  for (final locale in RawWidgetsLocalizations.supportedLocales) {
    for (final axis in RawChartXAxis.values) {
      final direction = _rtl.contains(locale.languageCode)
          ? TextDirection.rtl
          : TextDirection.ltr;
      testWidgets('$locale, ${axis.name}: built, said and stepped in the '
          'locale\'s words', (tester) async {
        final handle = tester.ensureSemantics();
        final series = [
          for (final name in ['A', 'B'])
            RawChartSeries(
              label: name,
              points: [
                for (var i = 0; i < 6; i++)
                  axis == RawChartXAxis.time
                      ? RawChartPoint.time(
                          DateTime(2026, i + 1),
                          1000.5 * (i + 1) + (name == 'A' ? 0 : 300),
                        )
                      : RawChartPoint(
                          i.toDouble(),
                          1000.5 * (i + 1) + (name == 'A' ? 0 : 300),
                        ),
              ],
            ),
        ];
        await tester.pumpWidget(
          harness(
            Localizations(
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
                    width: 320,
                    height: 160,
                    child: RawChart(
                      semanticLabel: 'Chart',
                      series: series,
                      xAxis: axis,
                      builder: (context, chart) {
                        _last = chart;
                        return const SizedBox.expand();
                      },
                    ),
                  ),
                ),
              ),
            ),
            textDirection: direction,
          ),
        );
        final l = await RawWidgetsLocalizations.delegate.load(locale);
        final node = semanticsOf(tester, find.bySemanticsLabel('Chart'));
        final summary = node.getSemanticsData().value;
        expect(summary, startsWith(l.chartSeriesCountLabel(2)));
        expect(summary, contains(l.formatDecimal(1000.5)));
        // A locale with digits of its own writes its ticks in them.
        if (l.formatDecimal(1) != '1') {
          expect(
            _last!.yTicks.map((t) => t.label),
            everyElement(isNot(contains(RegExp('[0-9]')))),
            reason: 'ticks in the locale\'s digits',
          );
        }
        expect(
          _last!.x.map(0) > _last!.x.map(5),
          direction == TextDirection.rtl,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(
          direction == TextDirection.rtl
              ? LogicalKeyboardKey.arrowLeft
              : LogicalKeyboardKey.arrowRight,
        );
        await tester.pump();
        expect(_last!.active, const RawChartPointRef(0, 0));
        final said = semanticsOf(
          tester,
          find.bySemanticsLabel('Chart'),
        ).getSemanticsData().value;
        expect(said, contains(l.formatDecimal(1000.5)));
        expect(said, contains('A'));
        handle.dispose();
      });
    }
  }
}

// Whether the canvas angle [a] falls within [slice]'s arc, either way
// round.
bool _within(double a, RawPieSliceDetails slice) {
  final lo = math.min(slice.startAngle, slice.startAngle + slice.sweepAngle);
  final hi = math.max(slice.startAngle, slice.startAngle + slice.sweepAngle);
  const edge = 1e-3;
  for (var k = -2; k <= 2; k++) {
    final x = a + k * 2 * math.pi;
    if (x > lo + edge && x < hi - edge) return true;
  }
  return false;
}

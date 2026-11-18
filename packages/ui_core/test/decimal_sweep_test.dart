// Every step × bound: a step lands on the grid counted from min, moves the
// way asked, stays within the bounds, and steps back where it came from.
@Tags(['sweep'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/src/internal/decimal.dart';

void main() {
  const steps = <double>[0.001, 0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 100];
  const mins = <double?>[null, -10, -0.3, 0, 0.05, 1, 7.5];
  const maxes = <double?>[null, 0.5, 9.95, 10, 1000];

  test('every step × bound', () {
    var checked = 0;
    for (final step in steps) {
      for (final min in mins) {
        for (final max in maxes) {
          if (min != null && max != null && max <= min) continue;
          final base = min ?? 0;
          final digits = [
            decimalsOf(step),
            decimalsOf(base),
          ].reduce((a, b) => a > b ? a : b);
          for (var k = -3; k <= 3; k++) {
            var value = roundTo(base + k * step, digits);
            if (min != null && value < min) value = min;
            if (max != null && value > max) value = max;
            for (final count in [-10, -1, 1, 10]) {
              final next = stepDecimal(
                value,
                step: step,
                count: count,
                min: min,
                max: max,
              );
              final where =
                  '$value ${count > 0 ? '+' : ''}$count×$step '
                  'in [$min, $max] → $next';
              if (min != null) expect(next, greaterThanOrEqualTo(min));
              if (max != null) expect(next, lessThanOrEqualTo(max));
              if (count > 0) expect(next, greaterThanOrEqualTo(value));
              if (count < 0) expect(next, lessThanOrEqualTo(value));
              // On the grid from the base, unless a bound clamped it.
              final atBound = next == min || next == max;
              if (!atBound) {
                final n = (next - base) / step;
                expect(n, closeTo(n.roundToDouble(), 1e-9), reason: where);
                expect(
                  decimalsOf(next),
                  lessThanOrEqualTo(digits),
                  reason: where,
                );
              }
              checked++;
            }
          }
        }
      }
    }
    expect(checked, greaterThan(5000));
  });
}

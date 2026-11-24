// Decimal steps in scaled integers, rounding as a number is written, and a
// pattern's grouping. Every step × bound: decimal_sweep_test.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/src/internal/decimal.dart';
import 'package:ui_core/src/internal/localizations_data.dart';

void main() {
  group('stepDecimal', () {
    test('steps exactly in decimals', () {
      expect(stepDecimal(0.2, step: 0.1, count: 1), 0.3);
      expect(stepDecimal(0.3, step: 0.1, count: -1), 0.2);
      expect(stepDecimal(0.7, step: 0.1, count: 3), 1.0);
      expect(stepDecimal(1.1, step: 0.01, count: 1), 1.11);
    });

    test('off the grid, a step goes to the next multiple that way', () {
      expect(stepDecimal(0.25, step: 0.1, count: 1), 0.3);
      expect(stepDecimal(0.25, step: 0.1, count: -1), 0.2);
      expect(stepDecimal(7, step: 5, count: 1), 10);
      expect(stepDecimal(7, step: 5, count: -1), 5);
      expect(stepDecimal(7, step: 5, count: 2), 15);
      expect(stepDecimal(7, step: 5, count: -2), 0);
    });

    test('counted from min, and below zero', () {
      expect(stepDecimal(0.05, step: 0.1, count: 1, min: 0.05), 0.15);
      expect(stepDecimal(0.1, step: 0.1, count: 1, min: 0.05), 0.15);
      expect(stepDecimal(-0.5, step: 0.2, count: 1), -0.4);
      expect(stepDecimal(-0.5, step: 0.2, count: -1), -0.6);
      expect(stepDecimal(-0.4, step: 0.2, count: -1), -0.6);
    });

    test('clamped to min and max', () {
      expect(stepDecimal(9.5, step: 1, count: 1, max: 10), 10);
      expect(stepDecimal(10, step: 1, count: 1, max: 10), 10);
      expect(stepDecimal(0, step: 1, count: -1, min: 0), 0);
      expect(stepDecimal(3, step: 2, count: 10, min: 1, max: 9.5), 9.5);
    });

    test('a large value keeps what decimals a double can', () {
      expect(stepDecimal(1e12, step: 0.01, count: 1), 1e12 + 0.01);
      expect(stepDecimal(4e15, step: 0.5, count: 1), closeTo(4e15 + 1, 1));
    });
  });

  test('decimalsOf counts what a number is written with', () {
    expect(decimalsOf(1), 0);
    expect(decimalsOf(0.25), 2);
    expect(decimalsOf(0.1 + 0.2), 1);
    expect(decimalsOf(1e-7), 7);
    expect(decimalsOf(1 / 3), 10);
    expect(decimalsOf(double.nan), 0);
  });

  test('roundTo rounds half away from zero, as written', () {
    expect(roundTo(2.345, 2), 2.35);
    expect(roundTo(1.005, 2), 1.01);
    expect(roundTo(-2.5, 0), -3);
    expect(roundTo(0.125, 2), 0.13);
    expect(roundTo(0.996, 2), 1.0);
    expect(roundTo(1.5, 3), 1.5);
    expect(roundTo(1e-7, 3), 0);
    expect(roundTo(1.23e25, 2), 1.23e25);
    expect(roundTo(double.infinity, 2), double.infinity);
  });

  test('a pattern\'s grouping: primary and secondary', () {
    expect(DecimalSymbols.primaryGroup('#,##0.###'), 3);
    expect(DecimalSymbols.secondaryGroup('#,##0.###'), 3);
    expect(DecimalSymbols.primaryGroup('#,##,##0.###'), 3);
    expect(DecimalSymbols.secondaryGroup('#,##,##0.###'), 2);
    expect(DecimalSymbols.primaryGroup('0.###'), 0);
    expect(DecimalSymbols.secondaryGroup('0.###'), 0);
    final none = DecimalSymbols.of(rawLocaleData['en']!);
    final ungrouped = DecimalSymbols(
      zeroDigit: none.zeroDigit,
      decimalSeparator: '.',
      groupSeparator: ',',
      minusSign: '-',
      percentSign: '%',
      decimalPattern: '0.###',
      percentPattern: '0%',
    );
    expect(formatDecimal(1234567, ungrouped), '1234567');
    expect(parseDecimal('1,234', ungrouped), isNull);
    expect(formatPercent(12.345, ungrouped), '1235%');
  });
}

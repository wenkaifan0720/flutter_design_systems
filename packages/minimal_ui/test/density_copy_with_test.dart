// MinimalDensity.copyWith replaces the steps it is given and keeps the
// rest, as VisualDensity.copyWith does; equal steps make equal densities.
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

void main() {
  test('copyWith replaces the steps it is given and keeps the rest', () {
    const density = MinimalDensity(horizontal: -1, vertical: -2);
    expect(
      density.copyWith(vertical: 1),
      const MinimalDensity(horizontal: -1, vertical: 1),
    );
    expect(
      density.copyWith(horizontal: 2),
      const MinimalDensity(horizontal: 2, vertical: -2),
    );
    expect(density.copyWith(), density);
    expect(MinimalDensity.compact.copyWith(), MinimalDensity.compact);
  });

  test('equal steps make equal densities, with equal hash codes', () {
    final a = MinimalDensity.comfortable.copyWith(horizontal: -2, vertical: -2);
    expect(identical(a, MinimalDensity.compact), isFalse);
    expect(a, MinimalDensity.compact);
    expect(a.hashCode, MinimalDensity.compact.hashCode);
    expect(a, isNot(MinimalDensity.comfortable));
  });
}

// Ledger's shapes: its own scheme, an app's held to Ledger's bands, and the
// theme's constructors taking one.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

void main() {
  test("Ledger's own scheme: corners of 3, 6, 6, 6 and 12, controls round, "
      'no stroke, no depth', () {
    final c = LedgerThemeData.light().shapeScheme.corners;
    expect(c.style, RawCornerStyle.round);
    expect(
      [c.extraSmall, c.small, c.medium, c.large, c.extraLarge],
      [3, 6, 6, 6, 12],
    );
    expect(c.fullMaxRadius, isNull);
    expect(LedgerThemeData.light().shapeScheme.stroke, isNull);
    expect(LedgerThemeData.light().shapeScheme.depth, isNull);
    expect(
      LedgerThemeData.dark().shapeScheme,
      LedgerThemeData.defaultShapeScheme,
    );
  });

  test('light, dark, from and copyWith take an app\'s scheme, held', () {
    const rounder = RawShapeScheme(
      corners: RawCornerScale(
        extraSmall: 4,
        small: 8,
        medium: 10,
        large: 12,
        extraLarge: 16,
      ),
    );
    for (final t in [
      LedgerThemeData.light(shapeScheme: rounder),
      LedgerThemeData.dark(shapeScheme: rounder),
      LedgerThemeData.from(
        paper: const Color(0xFFF4F1EA),
        ink: const Color(0xFF1B2433),
        accent: const Color(0xFF2B4C9B),
        shapeScheme: rounder,
      ),
      LedgerThemeData.light().copyWith(shapeScheme: rounder),
    ]) {
      expect(t.shapeScheme, rounder);
    }
    final held = LedgerThemeData.light(
      shapeScheme: const RawShapeScheme(
        corners: RawCornerScale(medium: 40, large: 0),
        stroke: 2,
      ),
    ).shapeScheme;
    expect(held.corners.medium, 12);
    expect(held.corners.large, 4);
    expect(held.stroke, isNull);
  });

  test("a theme's lerp moves its corners between two schemes", () {
    final a = LedgerThemeData.light();
    final b = LedgerThemeData.light(
      shapeScheme: const RawShapeScheme(
        corners: RawCornerScale(
          extraSmall: 5,
          small: 10,
          medium: 12,
          large: 16,
          extraLarge: 16,
        ),
      ),
    );
    final c = LedgerThemeData.lerp(a, b, .25).shapeScheme.corners;
    expect(c.medium, 7.5);
    expect(c.extraLarge, 13);
  });

  test('a scheme held to its bands says so once in debug', () {
    final lines = <String>[];
    final before = debugPrint;
    debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');
    try {
      for (var i = 0; i < 2; i++) {
        LedgerThemeData.light(
          shapeScheme: const RawShapeScheme(
            corners: RawCornerScale(
              extraSmall: 9,
              small: 6,
              medium: 6,
              large: 6,
              extraLarge: 12,
            ),
          ),
        );
      }
    } finally {
      debugPrint = before;
    }
    expect(lines.where((l) => l.contains('Ledger')), hasLength(1));
  });
}

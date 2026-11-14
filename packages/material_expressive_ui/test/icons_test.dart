/// The icon set: w1-type's test, with `icons.dart`, its generated
/// `internal/icons/` part and `tools/expressive_tokens/fonts/`. Every glyph
/// names the bundled Material Symbols Rounded subset, and a symbol's FILL
/// follows its selected state on the fast effects spring.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import 'support/font_glyphs.dart';

double _fill(WidgetTester tester) =>
    tester.widget<Icon>(find.byType(Icon)).fill!;

Widget _symbol({required bool selected, bool reduceMotion = false}) =>
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: ExpressiveIcon(ExpressiveSymbols.star, selected: selected),
        ),
      ),
    );

void main() {
  test('every glyph is drawn by the bundled font, never the missing-glyph '
      'box', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final drawn = outlinedGlyphs(
      await loadBundledFont('MaterialSymbolsRounded.ttf'),
    );
    expect([
      for (final MapEntry(key: name, value: icon)
          in ExpressiveSymbols.byName.entries)
        if (!drawn.containsKey(icon.codePoint)) name,
    ], isEmpty);
  });

  test('every glyph is a private-use codepoint of the bundled subset', () {
    expect(ExpressiveSymbols.byName, hasLength(315));
    for (final MapEntry(key: name, value: icon)
        in ExpressiveSymbols.byName.entries) {
      expect(icon.fontFamily, ExpressiveSymbolsFont.family, reason: name);
      expect(icon.fontPackage, expressiveFontPackage, reason: name);
      expect(
        icon.codePoint >= 0xe000 && icon.codePoint <= 0xf8ff ||
            icon.codePoint >= 0xf0000,
        isTrue,
        reason: name,
      );
    }
    expect(ExpressiveSymbols.byName['arrow_back'], ExpressiveSymbols.arrowBack);
    expect(ExpressiveSymbols.arrowBack.matchTextDirection, isTrue);
    expect(ExpressiveSymbols.add.matchTextDirection, isFalse);
  });

  test('the subset font is bundled', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final font = await rootBundle.load(
      'assets/fonts/MaterialSymbolsRounded.ttf',
    );
    expect(font.lengthInBytes, greaterThan(0));
  });

  testWidgets('FILL follows selection on a spring', (tester) async {
    await tester.pumpWidget(_symbol(selected: false));
    expect(_fill(tester), ExpressiveSymbolsFont.outlined);

    await tester.pumpWidget(_symbol(selected: true));
    await tester.pump(const Duration(milliseconds: 16));
    final midway = _fill(tester);
    expect(midway, greaterThan(ExpressiveSymbolsFont.outlined));
    expect(midway, lessThan(ExpressiveSymbolsFont.filled));
    await tester.pumpAndSettle();
    expect(_fill(tester), ExpressiveSymbolsFont.filled);

    await tester.pumpWidget(_symbol(selected: false));
    await tester.pumpAndSettle();
    expect(_fill(tester), ExpressiveSymbolsFont.outlined);
  });

  testWidgets(
    'rests at the ambient fill: a solid glyph, filled when selected',
    (tester) async {
      Widget solid({required bool selected}) => IconTheme.merge(
        data: const IconThemeData(fill: ExpressiveSymbolsFont.filled),
        child: _symbol(selected: selected),
      );
      await tester.pumpWidget(solid(selected: false));
      expect(_fill(tester), ExpressiveSymbolsFont.filled);
      await tester.pumpWidget(solid(selected: true));
      await tester.pumpAndSettle();
      expect(_fill(tester), ExpressiveSymbolsFont.filled);
      await tester.pumpWidget(solid(selected: false));
      await tester.pumpAndSettle();
      expect(_fill(tester), ExpressiveSymbolsFont.filled);
    },
  );

  testWidgets('fast effects: settles within a few frames, never overshoots', (
    tester,
  ) async {
    await tester.pumpWidget(_symbol(selected: false));
    await tester.pumpWidget(_symbol(selected: true));
    var frames = 0;
    var previous = ExpressiveSymbolsFont.outlined;
    while (_fill(tester) < ExpressiveSymbolsFont.filled && frames < 60) {
      await tester.pump(const Duration(milliseconds: 16));
      final fill = _fill(tester);
      expect(fill, greaterThanOrEqualTo(previous));
      previous = fill;
      frames++;
    }
    // ζ = 1, k = 3800: settles to 0.001 in ≈ 150 ms.
    expect(frames, lessThan(15));
  });

  testWidgets('Reduce Motion leaves the effects spring alone', (tester) async {
    await tester.pumpWidget(_symbol(selected: false, reduceMotion: true));
    await tester.pumpWidget(_symbol(selected: true, reduceMotion: true));
    await tester.pump(const Duration(milliseconds: 16));
    expect(_fill(tester), lessThan(ExpressiveSymbolsFont.filled));
    await tester.pumpAndSettle();
    expect(_fill(tester), ExpressiveSymbolsFont.filled);
  });
}

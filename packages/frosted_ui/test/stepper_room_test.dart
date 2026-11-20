// A stepper's rounds stand as tall as its well, and give way only as far as its figure needs: at 200% on a phone,
// rounds as tall as the well (80) would squeeze the well until its figure scrolled out of sight ("250" cut at its 0).
// In Frosted's own fonts, as the gallery shows it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

Future<void> _pump(
  WidgetTester t, {
  required double scale,
  double width = 390,
}) async {
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  t.view.physicalSize = Size(width, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => FrostedHost(child: page!),
      home: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FrostedNumberField(
              value: 250,
              label: 'the budget',
              note: 'a month',
              money: true,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    ),
  );
}

/// The row, and each round's box in it.
(Rect, List<Rect>) _boxes(WidgetTester t) => (
  t.getRect(
    find.byWidgetPredicate((w) => w.runtimeType.toString() == '_StepperRow'),
  ),
  [
    for (final glyph in [FrostedGlyphs.remove, FrostedGlyphs.add])
      t.getRect(
        find
            .ancestor(of: find.byIcon(glyph), matching: find.byType(SizedBox))
            .first,
      ),
  ],
);

/// Whether the field shows three figures whole, unscrolled.
void _figureWhole(WidgetTester t, double scale) {
  final style = t.widget<TextField>(find.byType(TextField)).style!;
  final room = TextPainter(
    text: TextSpan(
      text: '000',
      style: style.copyWith(letterSpacing: 0, fontFeatures: const []),
    ),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.linear(scale),
  )..layout();
  final need = room.width;
  room.dispose();
  expect(
    t.getSize(find.byType(TextField)).width,
    greaterThanOrEqualTo(need - .01),
  );
}

void main() {
  setUpAll(frostedLoadFonts);

  testWidgets('at 100% on a phone the rounds are as tall as the well', (
    t,
  ) async {
    await _pump(t, scale: 1);
    final (row, rounds) = _boxes(t);
    for (final round in rounds) {
      expect(round.height, row.height);
      expect(round.center.dy, moreOrLessEquals(row.center.dy, epsilon: .01));
    }
    _figureWhole(t, 1);
  });

  testWidgets('at 200% on a phone the figure stays whole: the rounds give '
      'way as far as it needs, centred on the well', (t) async {
    await _pump(t, scale: 2);
    final (row, rounds) = _boxes(t);
    _figureWhole(t, 2);
    for (final round in rounds) {
      expect(round.height, lessThan(row.height));
      expect(round.height, greaterThan(48), reason: 'no further than needed');
      expect(round.width, round.height);
      expect(round.center.dy, moreOrLessEquals(row.center.dy, epsilon: .01));
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('at 200% with room the rounds are as tall as the well', (
    t,
  ) async {
    await _pump(t, scale: 2, width: 700);
    final (row, rounds) = _boxes(t);
    for (final round in rounds) {
      expect(round.height, row.height);
    }
    _figureWhole(t, 2);
  });
}

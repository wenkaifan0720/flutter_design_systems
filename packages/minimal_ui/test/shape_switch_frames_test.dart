// A theme switch that moves the corners eases them through every frame, as
// the rest of the theme blends; under reduced motion it switches at once.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

const _card = Key('card');

Widget _app(MinimalThemeData t) => MaterialApp(
  builder: (context, app) =>
      MinimalHost(light: t, brightness: Brightness.light, child: app!),
  home: const Scaffold(
    body: Center(
      child: MinimalCard(key: _card, child: Text('Plan')),
    ),
  ),
);

double _radius(WidgetTester tester) {
  final box = tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(_card),
          matching: find.byType(DecoratedBox),
        ),
      )
      .first;
  return (box.decoration as BoxDecoration).borderRadius!
      .resolve(TextDirection.ltr)
      .topLeft
      .x;
}

void main() {
  final square = MinimalThemeData.standard();
  final round = square.copyWith(
    shapeScheme: const MinimalShapes(radius: 12).scheme,
  );

  testWidgets('a card eases from 10 to 14 through every frame', (tester) async {
    await tester.pumpWidget(_app(square));
    await tester.pumpAndSettle();
    expect(_radius(tester), 10);
    await tester.pumpWidget(_app(round));
    final seen = <double>[];
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      seen.add(_radius(tester));
    }
    expect(seen.last, 14);
    for (var i = 1; i < seen.length; i++) {
      expect(seen[i], greaterThanOrEqualTo(seen[i - 1]));
      expect(seen[i] - seen[i - 1], lessThan(2), reason: 'no jump: $seen');
    }
    expect(seen.where((r) => r > 10 && r < 14).length, greaterThan(3));
  });

  testWidgets('under reduced motion the corners switch at once', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(_app(square));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(round));
    await tester.pump();
    expect(_radius(tester), 14);
  });
}

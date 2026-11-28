// A palette and the app's own changes together:
// MinimalHost(palette:, customize:) builds the palette's themes and hands
// both through customize; the blend between appearances still runs.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

final _iris = MinimalThemeData.palettes.firstWhere((p) => p.id == 'iris');

MinimalThemeData _round(MinimalThemeData t) =>
    t.copyWith(shapeScheme: const MinimalShapes(radius: 12).scheme);

Widget _app(Brightness b, {RawNamedPalette? palette}) => MaterialApp(
  builder: (context, app) => MinimalHost(
    palette: palette ?? _iris,
    brightness: b,
    customize: _round,
    child: app!,
  ),
  home: const Scaffold(body: SizedBox()),
);

MinimalThemeData _theme(WidgetTester tester) =>
    MinimalTheme.of(tester.element(find.byType(SizedBox).last));

void main() {
  for (final b in Brightness.values) {
    testWidgets('the palette and the change, ${b.name}', (tester) async {
      await tester.pumpWidget(_app(b));
      await tester.pumpAndSettle();
      final t = _theme(tester);
      expect(t, _round(MinimalThemeData.preset('iris', b)));
      expect(t.controlRadius, 12);
      expect(t.id, 'iris');
    });
  }

  testWidgets('given themes take the change too', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => MinimalHost(
          light: MinimalThemeData.preset('ember', Brightness.light),
          dark: MinimalThemeData.preset('ember', Brightness.dark),
          brightness: Brightness.dark,
          customize: _round,
          child: app!,
        ),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      _theme(tester),
      _round(MinimalThemeData.preset('ember', Brightness.dark)),
    );
  });

  testWidgets('day to night still blends', (tester) async {
    await tester.pumpWidget(_app(Brightness.light));
    await tester.pumpAndSettle();
    final day = _theme(tester).background;
    await tester.pumpWidget(_app(Brightness.dark));
    await tester.pump(const Duration(milliseconds: 60));
    final mid = _theme(tester).background;
    await tester.pumpAndSettle();
    final night = _theme(tester).background;
    expect(mid, isNot(day));
    expect(mid, isNot(night));
    expect(_theme(tester).controlRadius, 12);
  });
}

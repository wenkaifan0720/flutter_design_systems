// The six palettes through ui_core's RawNamedPalette: their ids are the
// preset ids, their swatches are each theme's accent and ground by day and by
// night, the host builds a palette's themes, and a change of palette or of
// appearance blends rather than snapping.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

const _probe = Key('probe');

Widget _host({RawNamedPalette? palette, Brightness? brightness}) => MaterialApp(
  builder: (context, app) =>
      MinimalHost(palette: palette, brightness: brightness, child: app!),
  home: const SizedBox(key: _probe),
);

MinimalThemeData _theme(WidgetTester tester) =>
    MinimalTheme.of(tester.element(find.byKey(_probe)));

void main() {
  test('six palettes, the ids the presets had, standard first', () {
    expect(
      [for (final palette in MinimalThemeData.palettes) palette.id],
      ['standard', 'graphite', 'ember', 'iris', 'lagoon', 'berry'],
    );
    expect({
      for (final palette in MinimalThemeData.palettes) palette.label,
    }, hasLength(6));
  });

  test("each palette's swatches are its accent and its ground", () {
    for (final palette in MinimalThemeData.palettes) {
      for (final brightness in Brightness.values) {
        final t = MinimalThemeData.preset(palette.id, brightness);
        expect(palette.swatchesFor(brightness), [
          t.primary,
          t.background,
        ], reason: '${palette.id} ${brightness.name}');
      }
    }
  });

  testWidgets("the host builds a palette's theme, standard when none", (
    tester,
  ) async {
    await tester.pumpWidget(_host(brightness: Brightness.light));
    expect(_theme(tester).id, 'standard');
    await tester.pumpWidget(
      _host(palette: MinimalThemeData.palettes[2], brightness: Brightness.dark),
    );
    await tester.pumpAndSettle();
    expect(
      _theme(tester).primary,
      MinimalThemeData.preset('ember', Brightness.dark).primary,
    );
  });

  testWidgets('a change of palette or of appearance blends', (tester) async {
    final iris = MinimalThemeData.palettes[3];
    await tester.pumpWidget(_host(brightness: Brightness.light));
    final from = _theme(tester).primary;
    final to = MinimalThemeData.preset(iris.id, Brightness.light).primary;
    await tester.pumpWidget(_host(palette: iris, brightness: Brightness.light));
    await tester.pump(const Duration(milliseconds: 60));
    final mid = _theme(tester).primary;
    expect(mid, isNot(from));
    expect(mid, isNot(to));
    await tester.pumpAndSettle();
    expect(_theme(tester).primary, to);

    final day = _theme(tester).background;
    await tester.pumpWidget(_host(palette: iris, brightness: Brightness.dark));
    await tester.pump(const Duration(milliseconds: 60));
    expect(_theme(tester).background, isNot(day));
    expect(
      _theme(tester).background,
      isNot(MinimalThemeData.preset(iris.id, Brightness.dark).background),
    );
  });
}

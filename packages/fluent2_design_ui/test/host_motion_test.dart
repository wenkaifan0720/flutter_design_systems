// The host eases a change of palette and of day to night over Fluent's
// durationNormal, every token at once, and cuts at once under Reduce Motion.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

Widget _app({
  required RawNamedPalette palette,
  required Brightness brightness,
  bool reduceMotion = false,
}) => MaterialApp(
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: Fluent2Host(palette: palette, brightness: brightness, child: app!),
  ),
  home: Builder(
    builder: (context) {
      final t = context.fluent2Theme;
      return Column(
        children: [
          SizedBox(
            key: const Key('brand'),
            height: 10,
            child: ColoredBox(color: t.colors.brandBackground),
          ),
          SizedBox(
            key: const Key('ground'),
            height: 10,
            child: ColoredBox(color: t.background),
          ),
        ],
      );
    },
  ),
);

Color _colour(WidgetTester tester, String key) => tester
    .widget<ColoredBox>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(ColoredBox),
      ),
    )
    .color;

void main() {
  final first = Fluent2ThemeData.palettes.first;
  final second = Fluent2ThemeData.palettes[1];
  Color brandOf(RawNamedPalette p) =>
      Fluent2ThemeData.preset(p.id, Brightness.light).colors.brandBackground;
  Color groundOf(Brightness b) =>
      Fluent2ThemeData.preset(first.id, b).background;

  testWidgets('a new palette eases in', (tester) async {
    await tester.pumpWidget(_app(palette: first, brightness: Brightness.light));
    expect(_colour(tester, 'brand'), brandOf(first));
    await tester.pumpWidget(
      _app(palette: second, brightness: Brightness.light),
    );
    await tester.pump(const Duration(milliseconds: 80));
    final mid = _colour(tester, 'brand');
    expect(mid, isNot(brandOf(first)));
    expect(mid, isNot(brandOf(second)));
    await tester.pumpAndSettle();
    expect(_colour(tester, 'brand'), brandOf(second));
  });

  testWidgets('day to night eases in', (tester) async {
    await tester.pumpWidget(_app(palette: first, brightness: Brightness.light));
    await tester.pumpWidget(_app(palette: first, brightness: Brightness.dark));
    await tester.pump(const Duration(milliseconds: 80));
    final mid = _colour(tester, 'ground');
    expect(mid, isNot(groundOf(Brightness.light)));
    expect(mid, isNot(groundOf(Brightness.dark)));
    await tester.pumpAndSettle();
    expect(_colour(tester, 'ground'), groundOf(Brightness.dark));
  });

  testWidgets('under Reduce Motion it cuts at once', (tester) async {
    await tester.pumpWidget(
      _app(palette: first, brightness: Brightness.light, reduceMotion: true),
    );
    await tester.pumpWidget(
      _app(palette: second, brightness: Brightness.dark, reduceMotion: true),
    );
    await tester.pump();
    expect(
      _colour(tester, 'ground'),
      Fluent2ThemeData.preset(second.id, Brightness.dark).background,
    );
  });
}

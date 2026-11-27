// The host moves to a new palette and from day to night smoothly, every
// colour at once, and at once under Reduce Motion.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

Widget _app({
  required RawNamedPalette palette,
  required Brightness brightness,
  bool reduceMotion = false,
}) => MaterialApp(
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: StudioHost(palette: palette, brightness: brightness, child: app!),
  ),
  home: Builder(
    builder: (context) {
      final c = context.studioTheme.colors;
      return Column(
        children: [
          SizedBox(
            key: const Key('lamp'),
            height: 10,
            child: ColoredBox(color: c.indicator),
          ),
          SizedBox(
            key: const Key('metal'),
            height: 10,
            child: ColoredBox(color: c.panel),
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
  setUpAll(studioLoadFonts);
  final first = StudioThemeData.palettes.first;
  final second = StudioThemeData.palettes[1];
  Color lampOf(RawNamedPalette p) =>
      StudioThemeData.preset(p.id, Brightness.light).colors.indicator;
  Color metalOf(Brightness b) =>
      StudioThemeData.preset(first.id, b).colors.panel;
  Color chassisOf(Brightness b) =>
      StudioThemeData.preset(first.id, b).colors.chassis;
  Color chassis(WidgetTester tester) => tester
      .widgetList<ColoredBox>(find.byType(ColoredBox))
      .firstWhere(
        (box) =>
            box.color == chassisOf(Brightness.light) ||
            box.color.a == 1 && box.child is! SizedBox,
      )
      .color;

  testWidgets('a new palette eases in', (tester) async {
    await tester.pumpWidget(_app(palette: first, brightness: Brightness.light));
    expect(_colour(tester, 'lamp'), lampOf(first));
    await tester.pumpWidget(
      _app(palette: second, brightness: Brightness.light),
    );
    await tester.pump(const Duration(milliseconds: 80));
    final mid = _colour(tester, 'lamp');
    expect(mid, isNot(lampOf(first)));
    expect(mid, isNot(lampOf(second)));
    await tester.pumpAndSettle();
    expect(_colour(tester, 'lamp'), lampOf(second));
  });

  testWidgets('day to night eases in, the chassis too', (tester) async {
    await tester.pumpWidget(_app(palette: first, brightness: Brightness.light));
    expect(chassis(tester), chassisOf(Brightness.light));
    await tester.pumpWidget(_app(palette: first, brightness: Brightness.dark));
    await tester.pump(const Duration(milliseconds: 80));
    final mid = _colour(tester, 'metal');
    expect(mid, isNot(metalOf(Brightness.light)));
    expect(mid, isNot(metalOf(Brightness.dark)));
    final midChassis = chassis(tester);
    expect(midChassis, isNot(chassisOf(Brightness.light)));
    expect(midChassis, isNot(chassisOf(Brightness.dark)));
    await tester.pumpAndSettle();
    expect(_colour(tester, 'metal'), metalOf(Brightness.dark));
    expect(chassis(tester), chassisOf(Brightness.dark));
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
      _colour(tester, 'metal'),
      StudioThemeData.preset(second.id, Brightness.dark).colors.panel,
    );
  });
}

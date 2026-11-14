// Neumorphism's theme behaves as Material's does: a value with copyWith, lerp, equality and diagnostics; an InheritedTheme
// that routes and overlays carry; one install in any app's builder (Material, Cupertino or Widgets); an animated theme.
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoApp;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);

  final day = NeumorphicThemeData.preset('porcelain', Brightness.light);
  final night = NeumorphicThemeData.preset('porcelain', Brightness.dark);

  test(
    'a theme is a value: equal when its parts are, and copyWith keeps the rest',
    () {
      expect(NeumorphicThemeData.porcelain(), same(day));
      expect(NeumorphicThemeData.pompeii(Brightness.dark).id, 'pompeii');
      expect(day.copyWith(), equals(day));
      expect(day.copyWith().hashCode, day.hashCode);
      expect(day, isNot(equals(night)));
      final firm = day.copyWith(highContrast: true);
      expect(firm.highContrast, isTrue);
      expect(day.highContrast, isFalse, reason: 'the platform asks for none');
      expect(firm.colors, same(day.colors));
      expect(firm, isNot(equals(day)));
      expect(
        NeumorphicColors.lerp(day.colors, day.colors, .5),
        equals(day.colors),
        reason: 'colours compare by value',
      );
      expect(day.atWidth(1200).desk, isTrue);
      expect(day.atWidth(1200), same(day.atWidth(1200)));
      expect(day.atWidth(1200), isNot(equals(day)));
    },
  );

  testWidgets(
    'public primitives compose a branded control through the barrel',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        neumorphicApp(
          Builder(
            builder: (context) {
              final c = NeumorphicTheme.of(context).colors;
              return Center(
                child: NeumorphicTap(
                  label: 'Custom action',
                  onPressed: () => calls++,
                  child: NeumorphicSurface(
                    cast: NeumorphicSurfaceLevel.part,
                    style: NeumorphicStyle(
                      fill: WidgetStatePropertyAll(c.accent),
                      foreground: WidgetStatePropertyAll(c.onAccent),
                    ),
                    child: const Text('Custom action'),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Custom action'));
      expect(calls, 1);
      expect(day.colors.accentInk.a, 1);
      expect(tester.takeException(), isNull);
    },
  );

  test('high contrast is an explicit theme value', () {
    final strong = day.copyWith(highContrast: true);
    expect(day.highContrast, isFalse);
    expect(strong.highContrast, isTrue);
    expect(strong.copyWith(), strong);
    expect(strong, isNot(day));
    expect(strong.hashCode, isNot(day.hashCode));
    expect(NeumorphicThemeData.lerp(day, strong, .25).highContrast, isFalse);
    expect(NeumorphicThemeData.lerp(day, strong, .75).highContrast, isTrue);
    expect(
      strong.toDiagnosticsNode().toStringDeep(),
      contains('highContrast: true'),
    );
  });

  test('lerp blends the colours and lands on each end', () {
    expect(NeumorphicThemeData.lerp(day, night, 0), equals(day));
    expect(
      NeumorphicThemeData.lerp(day, night, 1).colors,
      equals(night.colors),
    );
    final mid = NeumorphicThemeData.lerp(day, night, .5);
    expect(
      mid.colors.ground,
      Color.lerp(day.colors.ground, night.colors.ground, .5),
    );
    expect(mid.colors.ink, Color.lerp(day.colors.ink, night.colors.ink, .5));
  });

  test('every preset lerps to every other without a fault', () {
    for (final a in NeumorphicThemeData.presets) {
      for (final b in NeumorphicThemeData.presets) {
        for (final t in [0.0, .5, 1.0]) {
          final m = NeumorphicThemeData.lerp(
            NeumorphicThemeData.preset(a, Brightness.light),
            NeumorphicThemeData.preset(b, Brightness.dark),
            t,
          );
          expect(m.colors.ground.a, 1.0);
        }
      }
    }
  });

  test('diagnostics name the preset and the mode', () {
    final text = day.toDiagnosticsNode().toStringDeep();
    expect(text, contains('id: "porcelain"'));
    expect(text, contains('dark: false'));
    expect(text, contains('ink'));
  });

  test('the motion is zero under reduced motion', () {
    const motion = NeumorphicMotion();
    expect(motion.still.press, Duration.zero);
    expect(motion.still.raise, Duration.zero);
    expect(motion.press, isNot(Duration.zero));
  });

  testWidgets(
    'of reads the nearest NeumorphicTheme, and maybeOf is null with none',
    (tester) async {
      NeumorphicThemeData? seen, none;
      await tester.pumpWidget(
        Column(
          children: [
            Builder(
              builder: (context) {
                none = NeumorphicTheme.maybeOf(context);
                return const SizedBox();
              },
            ),
            MediaQuery(
              data: const MediaQueryData(size: Size(400, 800)),
              child: NeumorphicTheme(
                data: night,
                child: Builder(
                  builder: (context) {
                    seen = NeumorphicTheme.of(context);
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ],
        ),
      );
      expect(none, isNull);
      expect(seen!.colors, night.colors);
      expect(seen!.width, 400, reason: 'set for the window it is in');
    },
  );

  // One install for every app: NeumorphicTheme in the app's builder. A field types, a button presses, and nothing of
  // Material's shows: no ink.
  for (final (kind, app)
      in <
        (
          String,
          Widget Function(Widget Function(BuildContext, Widget?), Widget),
        )
      >[
        (
          'MaterialApp',
          (builder, home) => MaterialApp(builder: builder, home: home),
        ),
        (
          'CupertinoApp',
          (builder, home) => CupertinoApp(builder: builder, home: home),
        ),
        (
          'WidgetsApp',
          (builder, home) => WidgetsApp(
            color: const Color(0xFF000000),
            builder: builder,
            home: home,
            pageRouteBuilder: <T>(settings, build) => PageRouteBuilder<T>(
              settings: settings,
              pageBuilder: (context, _, _) => build(context),
            ),
          ),
        ),
      ]) {
    testWidgets("NeumorphicTheme in a $kind's builder is the whole install", (
      tester,
    ) async {
      var pressed = 0;
      String? typed;
      await tester.pumpWidget(
        app(
          (context, child) => NeumorphicTheme(
            data: NeumorphicThemeData.preset(
              'porcelain',
              MediaQuery.platformBrightnessOf(context),
            ),
            child: child!,
          ),
          Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                NeumorphicTextField(onChanged: (v) => typed = v),
                NeumorphicButton.filled('Book', onPressed: () => pressed++),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(EditableText), 'Ada');
      await tester.tap(find.text('Book'));
      await tester.pump();
      expect(typed, 'Ada');
      expect(pressed, 1);
      expect(find.byType(InkWell), findsNothing, reason: 'no ink anywhere');
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.cursorColor, day.colors.ink);
    });
  }

  testWidgets('an animated theme eases to the new one and lands on it', (
    tester,
  ) async {
    NeumorphicThemeData? seen;
    Widget build(NeumorphicThemeData data) => AnimatedNeumorphicTheme(
      data: data,
      duration: const Duration(milliseconds: 100),
      child: Builder(
        builder: (context) {
          seen = NeumorphicTheme.of(context);
          return const SizedBox();
        },
      ),
    );
    await tester.pumpWidget(build(day));
    expect(seen!.colors, day.colors);
    await tester.pumpWidget(build(night));
    await tester.pump(const Duration(milliseconds: 50));
    expect(seen!.colors.ground, isNot(day.colors.ground));
    expect(seen!.colors.ground, isNot(night.colors.ground));
    await tester.pump(const Duration(milliseconds: 100));
    expect(seen!.colors, night.colors);
  });
}

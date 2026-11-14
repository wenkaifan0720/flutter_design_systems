import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

/// The theme as an API: Material's `ThemeData` contract (copyWith, lerp,
/// equality, diagnostics), the install widget, the knobs and the style
/// layers.
void main() {
  final light = MinimalThemeData.standard();
  final dark = MinimalThemeData.standard(Brightness.dark);

  group('MinimalThemeData', () {
    test('the named presets are the presets', () {
      expect(
        identical(light, MinimalThemeData.preset('standard', Brightness.light)),
        isTrue,
      );
      expect(
        identical(
          MinimalThemeData.graphite(Brightness.dark),
          MinimalThemeData.preset('graphite', Brightness.dark),
        ),
        isTrue,
      );
      expect(
        identical(
          MinimalThemeData.ember(),
          MinimalThemeData.preset('ember', Brightness.light),
        ),
        isTrue,
      );
      expect(light.id, 'standard');
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
    });

    test('copyWith of nothing is an equal theme', () {
      final copy = light.copyWith();
      expect(identical(copy, light), isFalse);
      expect(copy, light);
      expect(copy.hashCode, light.hashCode);
    });

    test('copyWith changes what it names and nothing else', () {
      final squared = light.copyWith(shapes: const MinimalShapes(radius: 0));
      expect(squared.cardRadius, 0);
      expect(squared.controlRadius, 0);
      expect(squared.colors, light.colors);
      expect(squared.text, light.text);
      expect(squared, isNot(light));

      expect(light.hairline, 1);
      expect(light.rim, 1);
      expect(light.focusWidth, 2);
    });

    test('new colours re-ink the type scale and recast the shadows', () {
      const ink = Color(0xFF102030);
      final inked = light.copyWith(
        colors: light.colors.copyWith(foreground: ink),
      );
      expect(inked.body.color, ink);
      expect(inked.h1.color, ink);
      // The quiet steps keep the quiet ink.
      expect(inked.caption.color, light.mutedForeground);
      // Same appearance: the same shadows.
      expect(inked.shadowMd, light.shadowMd);
      final night = light.copyWith(colors: dark.colors);
      expect(night.shadowLg, dark.shadowLg);
      // Given text is kept as given.
      final kept = light.copyWith(
        colors: light.colors.copyWith(foreground: ink),
        text: light.text,
      );
      expect(kept.body.color, light.foreground);
    });

    test('a new typeface sets the type anew in it', () {
      final own = light.copyWith(
        typeface: const MinimalTypeface.app(sans: 'Inter', mono: 'JetBrains'),
      );
      expect(own.body.fontFamily, 'Inter');
      expect(own.figure.fontFamily, 'JetBrains');
      // Geist Mono's word gap belongs to Geist Mono alone.
      expect(own.mono.wordSpacing, isNull);
      expect(light.mono.wordSpacing, isNotNull);
    });

    test('lerp lands on its ends and blends between', () {
      expect(light.lerp(dark, 0), light);
      expect(light.lerp(dark, 1), dark);
      expect(light.lerp(null, .5), light);
      final mid = light.lerp(dark, .5);
      expect(mid.background, Color.lerp(light.background, dark.background, .5));
      expect(mid.body.color, Color.lerp(light.body.color, dark.body.color, .5));
      expect(light.lerp(dark, .4).brightness, Brightness.light);
      expect(light.lerp(dark, .6).brightness, Brightness.dark);
      final rounder = light.copyWith(shapes: const MinimalShapes(radius: 16));
      expect(light.lerp(rounder, .5).controlRadius, 12);
    });

    test('equality is by value', () {
      final a = MinimalThemeData(colors: light.colors);
      final b = MinimalThemeData(colors: light.colors);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(light), reason: 'the id differs');
      expect(a.copyWith(id: 'standard'), light);
    });

    test('diagnostics name the preset and every knob set', () {
      final shown = light
          .copyWith(density: MinimalDensity.compact)
          .toDiagnosticsNode()
          .toStringDeep();
      expect(shown, contains('standard'));
      expect(shown, contains('density'));
      expect(
        light.toDiagnosticsNode().toStringDeep(),
        isNot(contains('density')),
      );
    });

    test('from keeps an accent that holds, and caches', () {
      final blue = MinimalThemeData.from(primary: const Color(0xFF3E63DD));
      expect(blue.primary, const Color(0xFF3E63DD));
      expect(blue.primaryForeground, const Color(0xFFFFFFFF));
      expect(blue.id, 'custom');
      expect(
        identical(
          blue,
          MinimalThemeData.from(primary: const Color(0xFF3E63DD)),
        ),
        isTrue,
      );
      // A pale accent no label reads on is moved until one does.
      final pale = MinimalThemeData.from(primary: const Color(0xFFFFE066));
      expect(pale.primary, isNot(const Color(0xFFFFE066)));
    });
  });

  group('MinimalShapes', () {
    test("a radius of 8 is the look's own scale", () {
      expect(const MinimalShapes(), MinimalShapes.look);
      expect(light.shapes, MinimalShapes.look);
      expect(light.cardRadius, 10);
      expect(light.controlRadius, 8);
      expect(light.smallRadius, 4);
      expect(light.sheetRadius, 14);
    });

    test('a radius of 0 squares every step, and none goes below zero', () {
      const square = MinimalShapes(radius: 0);
      for (final s in [
        square.mark,
        square.small,
        square.medium,
        square.large,
        square.pill,
      ]) {
        expect(MinimalShapes.radiusOf(s), 0);
      }
      expect(MinimalShapes.radiusOf(const MinimalShapes(radius: 2).mark), 0);
    });

    test('radiusOf reads any border', () {
      expect(
        MinimalShapes.radiusOf(const StadiumBorder()),
        MinimalShapes.fullRadius,
      );
      expect(
        MinimalShapes.radiusOf(const CircleBorder()),
        MinimalShapes.fullRadius,
      );
      expect(
        MinimalShapes.radiusOf(
          const BeveledRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ),
        6,
      );
      expect(MinimalShapes.radiusOf(null), 0);
    });

    test('inset keeps a plate concentric with its frame', () {
      final inner = MinimalShapes.inset(MinimalShapes.look.small, 2);
      expect(MinimalShapes.radiusOf(inner), 6);
      expect(
        MinimalShapes.radiusOf(MinimalShapes.inset(MinimalShapes.look.mark, 6)),
        0,
      );
      expect(
        MinimalShapes.inset(const StadiumBorder(), 2),
        const StadiumBorder(),
      );
    });

    test('lerp eases radii at 0, .5 and 1', () {
      const a = MinimalShapes(radius: 0), b = MinimalShapes();
      expect(MinimalShapes.lerp(a, b, 0), a);
      expect(MinimalShapes.lerp(a, b, 1), b);
      expect(MinimalShapes.radiusOf(MinimalShapes.lerp(a, b, .5).small), 4);
    });

    test('copyWith and equality', () {
      final softer = MinimalShapes.look.copyWith(radius: 12);
      expect(softer.radius, 12);
      expect(softer, isNot(MinimalShapes.look));
      expect(softer, const MinimalShapes(radius: 12));
      expect(softer.toDiagnosticsNode().toStringDeep(), contains('radius'));
    });
  });

  group('the knobs', () {
    test('density moves heights and padding, never below its floor', () {
      expect(MinimalDensity.standard.height(32), 32);
      expect(MinimalDensity.comfortable.height(32), 30);
      expect(MinimalDensity.compact.height(32), 28);
      expect(const MinimalDensity(vertical: 4).height(32), 40);
      expect(const MinimalDensity(vertical: -4).height(24), 20);
      expect(
        const MinimalDensity(horizontal: 4)
            .padding(const EdgeInsets.symmetric(horizontal: 12)),
        const EdgeInsets.symmetric(horizontal: 16),
      );
    });

    test('rows follow the density, a row never below a tap target', () {
      final compact = light.copyWith(density: MinimalDensity.compact);
      final loose = light.copyWith(density: const MinimalDensity(vertical: 2));
      expect(light.rowHeight, 44);
      expect(light.rowHeightCompact, 36);
      expect(compact.rowHeight, 44);
      expect(compact.rowHeightCompact, 32);
      expect(loose.rowHeight, 48);
    });

    test("an unset density is the platform's own", () {
      expect(light.followsPlatformDensity, isTrue);
      expect(light.density, MinimalDensity.standard);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(light.density, MinimalDensity.compact);
      expect(light.rowHeightCompact, 32);
      final chosen = light.copyWith(density: MinimalDensity.standard);
      expect(chosen.followsPlatformDensity, isFalse);
      expect(chosen.rowHeightCompact, 36);
      debugDefaultTargetPlatformOverride = null;
    });

    test('typeface flips its faces at the middle', () {
      const app = MinimalTypeface.app(sans: 'Inter', mono: 'JetBrains');
      expect(MinimalTypeface.lerp(MinimalTypeface.look, app, .5).sans, 'Inter');
      expect(MinimalTypeface.lerp(MinimalTypeface.look, app, .4).sans, 'Geist');
      expect(app.sansPackage, isNull);
    });
  });

  group('MinimalStyle', () {
    const red = Color(0xFFFF0000), blue = Color(0xFF0000FF);
    const own = MinimalStyle(fill: WidgetStatePropertyAll(red));
    const theme = MinimalStyle(
      fill: WidgetStatePropertyAll(blue),
      edge: WidgetStatePropertyAll(blue),
    );

    test('first reads the widget, then the theme, then gives up', () {
      expect(MinimalStyle.first([own, theme], (s) => s.fill, {}), red);
      expect(MinimalStyle.first([own, theme], (s) => s.edge, {}), blue);
      expect(MinimalStyle.first([own, theme], (s) => s.side, {}), isNull);
      expect(MinimalStyle.first([null, theme], (s) => s.fill, {}), blue);
    });

    test('a state resolves its slot', () {
      final pressed = MinimalStyle(
        fill: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.pressed) ? red : null,
        ),
      );
      expect(
        MinimalStyle.first(
          [pressed, theme],
          (s) => s.fill,
          {WidgetState.pressed},
        ),
        red,
      );
      expect(MinimalStyle.first([pressed, theme], (s) => s.fill, {}), blue);
    });

    test('merge, copyWith, lerp and equality', () {
      final merged = own.merge(theme);
      expect(merged.fill!.resolve({}), red);
      expect(merged.edge!.resolve({}), blue);
      expect(own.merge(null), own);
      expect(
        own
            .copyWith(edge: const WidgetStatePropertyAll(blue))
            .edge!
            .resolve({}),
        blue,
      );
      expect(
        MinimalStyle.lerp(own, theme, .5)!.fill!.resolve({}),
        Color.lerp(red, blue, .5),
      );
      expect(MinimalStyle.lerp(null, null, .5), isNull);
      expect(const MinimalStyle().isEmpty, isTrue);
      expect(own, const MinimalStyle(fill: WidgetStatePropertyAll(red)));
    });

    test('the component themes copy, lerp and compare', () {
      const none = MinimalComponentThemes();
      expect(none.isEmpty, isTrue);
      final some = none.copyWith(chip: own);
      expect(some.chip, own);
      expect(some.isEmpty, isFalse);
      expect(some, none.copyWith(chip: own));
      expect(
        MinimalComponentThemes.lerp(none, some, 1).chip!.fill!.resolve({}),
        red,
      );
      expect(light.copyWith(components: some).components.chip, own);
      expect(some.toDiagnosticsNode().toStringDeep(), contains('chip'));
    });
  });

  group('MinimalTheme', () {
    testWidgets('Increase Contrast steps the quiet inks and the rules up', (
      tester,
    ) async {
      late MinimalThemeData read;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(highContrast: true),
          child: MinimalTheme(
            data: light,
            child: Builder(
              builder: (context) {
                read = context.minimalTheme;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(read.mutedForeground, light.foreground);
      expect(read.textTertiary, light.mutedForeground);
      expect(read.border, light.textTertiary);
      expect(read.input, light.mutedForeground);
      expect(read.primary, light.primary);
      expect(identical(light.highContrast, light.highContrast), isTrue);
    });

    testWidgets(
      'installs under a bare WidgetsApp with no fallback text style',
      (tester) async {
        late MinimalThemeData read;
        late TextStyle style;
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFFFFFFFF),
            builder: (context, _) => MinimalTheme(
              data: light,
              child: Builder(
                builder: (context) {
                  read = MinimalTheme.of(context);
                  style = DefaultTextStyle.of(context).style;
                  return const Text('Hello');
                },
              ),
            ),
          ),
        );
        expect(read, light);
        expect(style.decoration, isNot(TextDecoration.underline));
        expect(style.color, light.body.color);
        expect(style.fontFamily, light.body.fontFamily);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('keeps the direction an app set when it lends Material words', (
      tester,
    ) async {
      late TextDirection direction;
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFFFFFFFF),
          builder: (context, _) => Directionality(
            textDirection: TextDirection.rtl,
            child: MinimalTheme(
              data: light,
              child: Builder(
                builder: (context) {
                  direction = Directionality.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      expect(direction, TextDirection.rtl);
    });

    testWidgets('of throws, and maybeOf answers null, without one', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );
      expect(MinimalTheme.maybeOf(context), isNull);
      expect(() => MinimalTheme.of(context), throwsFlutterError);
    });

    testWidgets(
      'a nested one restyles its subtree, and darkOf reads the dark',
      (tester) async {
        late MinimalThemeData inner, media;
        await tester.pumpWidget(
          MinimalTheme(
            data: light,
            darkData: dark,
            child: MinimalTheme(
              data: MinimalThemeData.ember(),
              child: Builder(
                builder: (context) {
                  inner = context.minimalTheme;
                  media = MinimalTheme.darkOf(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        expect(inner, MinimalThemeData.ember());
        // The nested scope names no dark: its own data.
        expect(media, MinimalThemeData.ember());
      },
    );

    testWidgets('AnimatedMinimalTheme eases to a new theme', (tester) async {
      late MinimalThemeData read;
      Widget at(MinimalThemeData data) => AnimatedMinimalTheme(
        data: data,
        child: Builder(
          builder: (context) {
            read = context.minimalTheme;
            return const SizedBox();
          },
        ),
      );
      await tester.pumpWidget(at(light));
      expect(read, light);
      await tester.pumpWidget(at(dark));
      await tester.pump(const Duration(milliseconds: 100));
      expect(read.background, isNot(light.background));
      expect(read.background, isNot(dark.background));
      await tester.pumpAndSettle();
      expect(read, dark);
    });

    test('the tween is the lerp', () {
      final tween = MinimalThemeDataTween(begin: light, end: dark);
      expect(tween.lerp(.5), light.lerp(dark, .5));
    });
  });
}

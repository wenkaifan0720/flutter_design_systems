/// The theme's wiring: the presets, the record, one part per foundation
/// composed from its resolver, the scope and the host. Nothing here pins
/// what a foundation holds, so wave 1's parallel foundation items never
/// meet in this file: each foundation's values are pinned in its own test
/// (color_test.dart, type_test.dart, shape_test.dart, motion_test.dart),
/// owned by the item that fills it.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import 'package:material_expressive_ui/src/material_expressive/internal/themes/baked_theme.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/themes/registry.g.dart';

void main() {
  testWidgets('a root scope replaces the fallback text style; a nested one '
      'keeps the style it is given', (tester) async {
    final theme = ExpressiveThemeData.preset('baseline', Brightness.light);
    // MaterialApp hands WidgetsApp this error style; a bare WidgetsApp none.
    const error = TextStyle(
      color: Color(0xD0FF0000),
      fontSize: 48,
      decoration: TextDecoration.underline,
      decorationColor: Color(0xFFFFFF00),
      decorationStyle: TextDecorationStyle.double,
    );
    for (final ground in <TextStyle?>[error, null]) {
      await tester.pumpWidget(
        WidgetsApp(
          key: ValueKey(ground),
          color: const Color(0xFF000000),
          textStyle: ground,
          builder: (context, _) =>
              ExpressiveTheme(data: theme, child: const Text('Words')),
        ),
      );
      final style = tester
          .renderObject<RenderParagraph>(find.text('Words'))
          .text
          .style!;
      expect(style.decoration, isNot(TextDecoration.underline));
      expect(style.fontSize, theme.type.bodyLarge.fontSize);
      expect(style.color, theme.colors.onSurface);
    }
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 11, letterSpacing: 2),
          child: ExpressiveTheme(data: theme, child: const Text('Words')),
        ),
      ),
    );
    final nested = tester
        .renderObject<RenderParagraph>(find.text('Words'))
        .text
        .style!;
    expect(nested.fontSize, 11);
    expect(nested.letterSpacing, 2);
    expect(nested.color, theme.colors.onSurface);
  });

  test('the shape scale is the one way to an app\'s corners', () {
    final base = ExpressiveThemeData.preset('baseline', Brightness.light);
    const zero = ExpressiveCornerBorder.all(ExpressiveCornerSize.dp(0));
    const square = ExpressiveShapes(
      none: zero,
      extraSmall: zero,
      small: zero,
      medium: zero,
      large: zero,
      largeIncreased: zero,
      extraLarge: zero,
      extraLargeIncreased: zero,
      extraExtraLarge: zero,
      full: zero,
    );
    final themed = base.copyWith(shapes: square);
    for (final step in ExpressiveCorner.values) {
      expect(
        themed.shapes.corner(step).topStart.resolve(const Size(100, 40)),
        0,
        reason: step.name,
      );
    }
    expect(themed, base.copyWith(shapes: square));
    expect(themed.hashCode, base.copyWith(shapes: square).hashCode);
    expect(themed, isNot(base));
    expect(themed.copyWith().shapes, square);
    expect(
      ExpressiveThemeData.lerp(
        base,
        themed,
        .5,
      ).shapes.medium.topStart.resolve(const Size(100, 40)),
      base.shapes.medium.topStart.resolve(const Size(100, 40)) / 2,
    );
    expect(themed.toDiagnosticsNode().toStringDeep(), contains('shapes'));
  });

  test('a nested outline subtracts the actual inset in rounded and square outlines', () {
    const rect = Rect.fromLTWH(0, 0, 100, 40);
    for (final radius in [0.0, 8.0, 28.0]) {
      final outer = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      );
      final inner = ExpressiveInsetBorder(outer, inset: 4);
      final expected = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          (radius - 4).clamp(0, double.infinity),
        ),
      );
      final actualPath = inner.getOuterPath(rect);
      final expectedPath = expected.getOuterPath(rect);
      for (var y = .25; y < rect.height; y += .5) {
        for (var x = .25; x < rect.width; x += .5) {
          final point = Offset(x, y);
          expect(
            actualPath.contains(point),
            expectedPath.contains(point),
            reason: '$radius at $point',
          );
        }
      }
    }
  });

  group('ExpressiveThemeData.preset', () {
    test('offers the baked themes, baseline first and the default', () {
      expect(ExpressiveThemeData.presets, expressiveBakedThemes.keys.toList());
      expect(ExpressiveThemeData.presets.first, 'baseline');
      expect(ExpressiveThemeData.defaultPreset, 'baseline');
    });

    test('carries the theme record in the brightness asked for', () {
      for (final brightness in Brightness.values) {
        final t = ExpressiveThemeData.preset('baseline', brightness);
        expect(t.id, 'baseline');
        expect(t.brightness, brightness);
        expect(t.expression, ExpressiveExpression.balanced);
        expect(ExpressiveThemeData.preset('baseline', brightness), t);
      }
    });

    // Each part is its foundation's resolver's, in the brightness asked
    // for, and has value equality (the scope's updateShouldNotify reads
    // it). What each part holds is pinned in its foundation's own test.
    test('composes one part per foundation, each from its resolver', () {
      for (final id in ExpressiveThemeData.presets) {
        final baked = expressiveBakedThemes[id]!;
        for (final brightness in Brightness.values) {
          final t = ExpressiveThemeData.preset(id, brightness);
          expect(t.colors, expressiveResolveColors(baked, brightness));
          expect(t.type, expressiveResolveTextTheme(baked, brightness));
          expect(t.shapes, expressiveResolveShapes(baked, brightness));
          expect(t.motion, expressiveResolveMotion(baked, brightness));
        }
      }
    });

    test('refuses a theme it does not have', () {
      expect(
        () => ExpressiveThemeData.preset('nope', Brightness.light),
        throwsArgumentError,
      );
    });
  });

  group('ExpressiveThemeData.fromBaked', () {
    test('builds an app\'s baked theme as the preset of the same bake', () {
      for (final id in ExpressiveThemeData.presets) {
        final spec = _specOf(expressiveBakedThemes[id]!, id: 'app-$id');
        for (final brightness in Brightness.values) {
          final preset = ExpressiveThemeData.preset(id, brightness);
          final app = ExpressiveThemeData.fromBaked(spec, brightness);
          expect(app.id, 'app-$id');
          expect(app.brightness, brightness);
          expect(app.expression, preset.expression);
          expect(app.colors, preset.colors);
          expect(app.type, preset.type);
          expect(app.shapes, preset.shapes);
          expect(app.motion, preset.motion);
        }
      }
    });

    test('reads its record: the motion scheme and the expression', () {
      final slate = _specOf(expressiveBakedThemes['slate']!, id: 'clinic');
      final standard = ExpressiveThemeData.fromBaked(slate, Brightness.light);
      expect(standard.motion.scheme, ExpressiveMotionScheme.standard);
      expect(standard.expression, ExpressiveExpression.calm);

      final bold = _specOf(
        expressiveBakedThemes['slate']!,
        id: 'harbor',
        motion: ExpressiveMotionScheme.expressive,
        expression: ExpressiveExpression.bold,
      );
      final expressive = ExpressiveThemeData.fromBaked(bold, Brightness.dark);
      expect(expressive.motion.scheme, ExpressiveMotionScheme.expressive);
      expect(expressive.expression, ExpressiveExpression.bold);
    });

    test('wears the one type scale and Compose\'s corner scale', () {
      final spec = _specOf(expressiveBakedThemes['bloom']!, id: 'margin-paper');
      final baseline = ExpressiveThemeData.preset('baseline', Brightness.light);
      final app = ExpressiveThemeData.fromBaked(spec, Brightness.light);
      expect(app.type, baseline.type);
      expect(app.shapes, baseline.shapes);
    });

    test('takes a const spec, and still checks its roles', () {
      const spec = ExpressiveThemeSpec(
        id: 'fixture',
        seed: 0xFF6750A4,
        variant: 'tonalSpot',
        contrast: 0,
        motion: ExpressiveMotionScheme.expressive,
        expression: ExpressiveExpression.balanced,
        light: <String, int>{},
        dark: <String, int>{},
      );
      expect(
        identical(
          spec,
          const ExpressiveThemeSpec(
            id: 'fixture',
            seed: 0xFF6750A4,
            variant: 'tonalSpot',
            contrast: 0,
            motion: ExpressiveMotionScheme.expressive,
            expression: ExpressiveExpression.balanced,
            light: <String, int>{},
            dark: <String, int>{},
          ),
        ),
        isTrue,
      );
      expect(
        () => ExpressiveThemeData.fromBaked(spec, Brightness.light),
        throwsStateError,
      );
    });

    test('refuses a record theme.json would refuse', () {
      final slate = expressiveBakedThemes['slate']!;
      for (final spec in [
        _specOf(slate, id: 'Not A Slug'),
        _specOf(slate, id: 'fixture', variant: 'fidelity'),
        _specOf(slate, id: 'fixture', contrast: -1),
      ]) {
        expect(
          () => ExpressiveThemeData.fromBaked(spec, Brightness.light),
          throwsArgumentError,
        );
      }
    });

    test('refuses colours without exactly the roles', () {
      final slate = expressiveBakedThemes['slate']!;
      final missing = Map<String, int>.of(slate.colors.light)
        ..remove('primary');
      final extra = Map<String, int>.of(slate.colors.dark)
        ..['brand'] = 0xFF000000;
      expect(
        () => ExpressiveThemeData.fromBaked(
          _specOf(slate, id: 'fixture', light: missing),
          Brightness.light,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('has no role primary'),
          ),
        ),
      );
      expect(
        () => ExpressiveThemeData.fromBaked(
          _specOf(slate, id: 'fixture', dark: extra),
          Brightness.dark,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('unknown roles brand'),
          ),
        ),
      );
    });
  });

  group('ExpressiveThemeData.forApp', () {
    final harbor = _specOf(
      expressiveBakedThemes['bloom']!,
      id: 'harbor',
      expression: ExpressiveExpression.bold,
    );
    final clinic = _specOf(expressiveBakedThemes['slate']!, id: 'clinic');

    test('finds an app theme by id', () {
      for (final brightness in Brightness.values) {
        expect(
          ExpressiveThemeData.forApp('clinic', [harbor, clinic], brightness),
          ExpressiveThemeData.fromBaked(clinic, brightness),
        );
      }
    });

    test('falls back to the system presets', () {
      for (final id in ExpressiveThemeData.presets) {
        for (final brightness in Brightness.values) {
          expect(
            ExpressiveThemeData.forApp(id, [harbor, clinic], brightness),
            ExpressiveThemeData.preset(id, brightness),
          );
          expect(
            ExpressiveThemeData.forApp(id, const [], brightness),
            ExpressiveThemeData.preset(id, brightness),
          );
        }
      }
    });

    test('reads the app\'s themes before the presets', () {
      final slate = _specOf(expressiveBakedThemes['bloom']!, id: 'slate');
      final t = ExpressiveThemeData.forApp('slate', [slate], Brightness.light);
      expect(
        t.colors,
        ExpressiveThemeData.preset('bloom', Brightness.light).colors,
      );
    });

    test('refuses an id neither has, naming both sets', () {
      expect(
        () => ExpressiveThemeData.forApp('nope', [
          harbor,
          clinic,
        ], Brightness.light),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('harbor, clinic'),
              contains(ExpressiveThemeData.presets.join(', ')),
            ),
          ),
        ),
      );
    });

    test('refuses two app themes with one id', () {
      expect(
        () => ExpressiveThemeData.forApp('baseline', [
          clinic,
          clinic,
        ], Brightness.light),
        throwsArgumentError,
      );
    });
  });

  group('ExpressiveArtwork', () {
    final harbor = _specOf(expressiveBakedThemes['slate']!, id: 'harbor');
    // A picture's scheme: bloom's colours stand in for a baked cover.
    final bloom = expressiveBakedThemes['bloom']!.colors;
    const none = <String, int>{};
    final cover = ExpressiveArtworkScheme(
      slot: 'show-cover',
      image: '2252f6a33779',
      source: 0xFFB5487A,
      fallback: false,
      contrast: 0,
      light: bloom.light,
      dark: bloom.dark,
    );
    final artwork = ExpressiveArtwork(
      themes: const <String, double>{'harbor': 0},
      schemes: <ExpressiveArtworkScheme>[cover],
    );

    test('retints an app theme with the picture\'s colours, only colours', () {
      for (final brightness in Brightness.values) {
        final theme = ExpressiveThemeData.forApp('harbor', [
          harbor,
        ], brightness);
        final retinted = artwork.retint(theme, 'show-cover');
        expect(
          retinted.colors,
          ExpressiveThemeData.preset('bloom', brightness).colors,
        );
        expect(artwork.colorsFor('show-cover', theme), retinted.colors);
        expect(retinted.id, theme.id);
        expect(retinted.brightness, brightness);
        expect(retinted.type, theme.type);
        expect(retinted.shapes, theme.shapes);
        expect(retinted.motion, theme.motion);
        expect(retinted.expression, theme.expression);
      }
      expect(artwork.slots, <String>{'show-cover'});
    });

    test('never retints a system preset', () {
      final baseline = ExpressiveThemeData.preset('baseline', Brightness.dark);
      expect(artwork.colorsFor('show-cover', baseline), isNull);
      expect(artwork.retint(baseline, 'show-cover'), baseline);
    });

    test('refuses a slot with no scheme, or none at the theme\'s contrast', () {
      final theme = ExpressiveThemeData.forApp('harbor', [
        harbor,
      ], Brightness.light);
      expect(
        () => artwork.retint(theme, 'show-other'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('show-cover'),
          ),
        ),
      );
      final unbaked = ExpressiveArtwork(
        themes: const <String, double>{'harbor': 1},
        schemes: <ExpressiveArtworkScheme>[cover],
      );
      expect(() => unbaked.retint(theme, 'show-cover'), throwsStateError);
    });

    test('refuses a scheme without every role', () {
      final partial = ExpressiveArtworkScheme(
        slot: 'show-cover',
        image: '2252f6a33779',
        source: 0xFFB5487A,
        fallback: true,
        contrast: 0,
        light: none,
        dark: bloom.dark,
      );
      expect(
        () => partial.colors(Brightness.light),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('The artwork scheme of "show-cover" has no role'),
          ),
        ),
      );
      expect(partial.colors(Brightness.dark), isA<ExpressiveColorScheme>());
    });
  });

  group('context.expressiveTheme', () {
    testWidgets('reads the nearest scope', (tester) async {
      final dark = ExpressiveThemeData.preset('baseline', Brightness.dark);
      late ExpressiveThemeData read;
      await tester.pumpWidget(
        ExpressiveTheme(
          data: dark,
          child: Builder(
            builder: (context) {
              read = context.expressiveTheme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(read, dark);
    });

    testWidgets('outside any scope, wears the default preset', (tester) async {
      late ExpressiveThemeData read;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            read = context.expressiveTheme;
            return const SizedBox.shrink();
          },
        ),
      );
      expect(read.id, ExpressiveThemeData.defaultPreset);
    });
  });

  // A retinted page (Earshot's Show wears its cover's scheme inside the
  // app's host) must take the retint's ink: uncoloured text and glyphs
  // under a nested scope read its onSurface, not the ink of the theme the
  // host set around it.
  group('ExpressiveTheme ink', () {
    testWidgets('uncoloured ExpressiveText and glyphs inside a scope take '
        "the scope's onSurface", (tester) async {
      final app = ExpressiveThemeData.preset('baseline', Brightness.light);
      final page = ExpressiveThemeData.preset('bloom', Brightness.dark);
      expect(page.colors.onSurface, isNot(app.colors.onSurface));
      await tester.pumpWidget(
        ExpressiveHost(
          light: app,
          brightness: Brightness.light,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ExpressiveTheme(
              data: page,
              child: const Column(
                children: <Widget>[
                  ExpressiveText.headline('Slow Groove'),
                  ExpressiveIcon(ExpressiveSymbols.check),
                ],
              ),
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(ExpressiveText),
          matching: find.byType(Text),
        ),
      );
      expect(text.style?.color, page.colors.onSurface);
      final glyph = tester.element(find.byType(ExpressiveIcon));
      expect(IconTheme.of(glyph).color, page.colors.onSurface);
    });

    testWidgets("a surface's content colour inside the scope still wins", (
      tester,
    ) async {
      final page = ExpressiveThemeData.preset('bloom', Brightness.light);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ExpressiveTheme(
            data: page,
            child: ExpressiveSurface(
              shape: page.shapes.medium,
              color: page.colors.primary,
              contentColor: page.colors.onPrimary,
              child: const ExpressiveText.body('On primary'),
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(ExpressiveText),
          matching: find.byType(Text),
        ),
      );
      expect(text.style?.color, page.colors.onPrimary);
    });
  });

  group('ExpressiveHost', () {
    testWidgets('mounts the theme in the brightness asked for', (tester) async {
      late ExpressiveThemeData read;
      await tester.pumpWidget(
        ExpressiveHost(
          brightness: Brightness.dark,
          child: Builder(
            builder: (context) {
              read = context.expressiveTheme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(read.brightness, Brightness.dark);
    });

    testWidgets('follows a preview frame\'s register, never pinning one', (
      tester,
    ) async {
      for (final platform in PreviewPlatform.values) {
        late TargetPlatform read;
        await tester.pumpWidget(
          PreviewFrame(
            platform: platform,
            child: ExpressiveHost(
              child: Builder(
                builder: (context) {
                  read = Theme.of(context).platform;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
        expect(read, platform.targetPlatform);
      }
    });
  });
}

/// [baked] as an app would bake the same `theme.json`, under [id], with
/// any part given replaced.
ExpressiveThemeSpec _specOf(
  ExpressiveBakedTheme baked, {
  required String id,
  String? variant,
  double? contrast,
  ExpressiveMotionScheme? motion,
  ExpressiveExpression? expression,
  Map<String, int>? light,
  Map<String, int>? dark,
}) => ExpressiveThemeSpec(
  id: id,
  seed: baked.seed,
  variant: variant ?? baked.variant,
  contrast: contrast ?? baked.contrast,
  motion: motion ?? ExpressiveMotionScheme.values.byName(baked.motion.scheme),
  expression:
      expression ?? ExpressiveExpression.values.byName(baked.expression),
  light: light ?? baked.colors.light,
  dark: dark ?? baked.colors.dark,
);

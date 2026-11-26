// The customisation pattern (DECISIONS.md "Customisation"): a part's style over its theme slot over the look; the
// rule and shadow dials held to their ranges; a fill of the caller's own takes words by contrast; the brand factory
// holds the contrast bar; the typeface reaches the parts and the Material theme under them.
import 'package:brutal_ui/brutal_parts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const _gold = Color(0xFFFFD23F);
const _navy = Color(0xFF1B1B6F);

Widget _app(BrutalThemeData data, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, home) => BrutalTheme(data: data, child: home!),
  home: Center(child: child),
);

/// The face of the first surface under [of].
BrutalFace _faceUnder(WidgetTester tester, Finder of) {
  final animated = find.descendant(
    of: of,
    matching: find.byType(AnimatedBrutalSurface),
  );
  if (animated.evaluate().isNotEmpty) {
    return tester.widget<AnimatedBrutalSurface>(animated.first).face;
  }
  return tester
      .widget<BrutalSurface>(
        find.descendant(of: of, matching: find.byType(BrutalSurface)).first,
      )
      .face;
}

void main() {
  group('dials', () {
    test('the rule and the shadow take their ranges', () {
      final theme = BrutalThemeData.light().copyWith(
        borderWidth: 4,
        shadowOffset: 8,
      );
      expect(theme.borderWidth, 4);
      expect(theme.shadowOffset, 8);
    });

    test('a rule outside 2 to 4 px is refused', () {
      expect(
        () => BrutalThemeData.light().copyWith(borderWidth: 6),
        throwsAssertionError,
      );
      expect(
        () => BrutalThemeData.light().copyWith(borderWidth: 1),
        throwsAssertionError,
      );
    });

    test('a shadow outside 2 to 8 px is refused', () {
      expect(
        () => BrutalThemeData.light().copyWith(shadowOffset: 12),
        throwsAssertionError,
      );
    });

    testWidgets('the rule width reaches a part', (tester) async {
      await tester.pumpWidget(
        _app(
          BrutalThemeData.light().copyWith(borderWidth: 3),
          BrutalButton('Go', onPressed: () {}),
        ),
      );
      final face = _faceUnder(tester, find.byType(BrutalButton));
      // A null width means the theme's.
      expect(face.borderWidth, isNull);
      final surface = find.descendant(
        of: find.byType(BrutalButton),
        matching: find.byType(AnimatedBrutalSurface),
      );
      expect(BrutalTheme.of(tester.element(surface.first)).borderWidth, 3);
    });
  });

  group('layers', () {
    testWidgets('a kind slot styles every button of the kind', (tester) async {
      final theme = BrutalThemeData.light().copyWith(
        filledButtonStyle: const BrutalStyle(
          fill: WidgetStatePropertyAll(_gold),
        ),
      );
      await tester.pumpWidget(
        _app(
          theme,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrutalButton.filled(
                'Buy',
                key: const Key('filled'),
                onPressed: () {},
              ),
              BrutalButton('Later', key: const Key('framed'), onPressed: () {}),
            ],
          ),
        ),
      );
      expect(_faceUnder(tester, find.byKey(const Key('filled'))).fill, _gold);
      expect(
        _faceUnder(tester, find.byKey(const Key('framed'))).fill,
        theme.colors.surface,
      );
    });

    testWidgets('a part\'s style wins over its slot', (tester) async {
      final theme = BrutalThemeData.light().copyWith(
        chipStyle: const BrutalStyle(fill: WidgetStatePropertyAll(_navy)),
      );
      await tester.pumpWidget(
        _app(
          theme,
          BrutalChip(
            label: 'Free',
            selected: true,
            onSelected: (_) {},
            style: const BrutalStyle(fill: WidgetStatePropertyAll(_gold)),
          ),
        ),
      );
      final face = _faceUnder(tester, find.byType(BrutalChip));
      expect(face.fill, _gold);
      // No foreground given: the words take black on gold by contrast, not
      // the look's paper.
      expect(face.foreground, const Color(0xFF000000));
    });

    testWidgets('a destructive button reads its slot over its kind\'s', (
      tester,
    ) async {
      final theme = BrutalThemeData.light().copyWith(
        filledButtonStyle: const BrutalStyle(
          fill: WidgetStatePropertyAll(_gold),
        ),
        destructiveButtonStyle: const BrutalStyle(
          fill: WidgetStatePropertyAll(_navy),
        ),
      );
      await tester.pumpWidget(
        _app(
          theme,
          BrutalButton.filled(
            'Delete',
            onPressed: () {},
            isDestructiveAction: true,
          ),
        ),
      );
      expect(_faceUnder(tester, find.byType(BrutalButton)).fill, _navy);
    });
  });

  group('contrast', () {
    test('words on a colour are black or white, whichever reads', () {
      expect(BrutalColors.wordsOn(_navy), const Color(0xFFFFFFFF));
      expect(BrutalColors.wordsOn(_gold), const Color(0xFF000000));
    });

    testWidgets('a block of the caller\'s colour picks its words', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          BrutalThemeData.light(),
          const BrutalBlock(color: _navy, child: Text('Tonight')),
        ),
      );
      expect(
        _faceUnder(tester, find.byType(BrutalBlock)).foreground,
        const Color(0xFFFFFFFF),
      );
    });

    test('the brand factory refuses a block black words cannot read on', () {
      expect(
        () => BrutalThemeData.from(signal: _gold, blue: _navy),
        throwsAssertionError,
      );
      final brand = BrutalThemeData.from(signal: _navy);
      expect(brand.colors.signal, _navy);
      expect(brand.colors.onSignal, const Color(0xFFFFFFFF));
    });
  });

  group('typeface', () {
    test('a cap height outside 0.5 to 0.85 is refused', () {
      expect(
        () => BrutalTypeface(family: 'Face', capHeightFactor: 0.95),
        throwsAssertionError,
      );
    });

    testWidgets('the face reaches the parts and the Material theme', (
      tester,
    ) async {
      const face = BrutalTypeface(family: 'TestFace', capHeightFactor: 0.72);
      late BuildContext inside;
      await tester.pumpWidget(
        _app(
          BrutalThemeData.light(typeface: face),
          Builder(
            builder: (context) {
              inside = context;
              return const SizedBox();
            },
          ),
        ),
      );
      final brutal = BrutalTheme.of(inside);
      expect(brutal.textTheme.body.fontFamily, 'TestFace');
      expect(brutal.capHeightFactor, 0.72);
      expect(Theme.of(inside).textTheme.bodyMedium?.fontFamily, 'TestFace');
    });

    test('the same family with a fallback added takes the fallback', () {
      // An app that adds a script's face to the look's own (Arabic, CJK) by
      // copyWith keeps the family and gains the fallback in every style, as
      // a theme built in that typeface has it.
      final own = BrutalTypeface.spaceGrotesk;
      final face = BrutalTypeface(
        family: own.family,
        package: own.package,
        capHeightFactor: own.capHeightFactor,
        fallback: const ['Noto Sans Arabic'],
      );
      final copied = BrutalThemeData.light().copyWith(typeface: face);
      final built = BrutalThemeData.light(typeface: face).textTheme;
      // The bundled face under its package's name, the app's face behind it
      // under its own: read as the package's ('packages/brutal_ui/Noto Sans
      // Arabic'), no app has it registered and the platform's face draws.
      expect(built.body.fontFamily, _registered(own));
      expect(built.body.fontFamilyFallback, ['Noto Sans Arabic']);
      final t = copied.textTheme;
      for (final (name, style, want) in [
        ('display', t.display, built.display),
        ('headline', t.headline, built.headline),
        ('title', t.title, built.title),
        ('body', t.body, built.body),
        ('label', t.label, built.label),
        ('secondary', t.secondary, built.secondary),
        ('caption', t.caption, built.caption),
      ]) {
        expect(style.fontFamily, want.fontFamily, reason: name);
        expect(style.fontFamilyFallback, want.fontFamilyFallback, reason: name);
      }
      expect(copied.typeface, face);
    });

    testWidgets("an app's face behind the bundled one reaches the Material "
        'theme as named', (tester) async {
      final own = BrutalTypeface.spaceGrotesk;
      final face = BrutalTypeface(
        family: own.family,
        package: own.package,
        capHeightFactor: own.capHeightFactor,
        fallback: const ['Noto Sans Arabic'],
      );
      late BuildContext inside;
      await tester.pumpWidget(
        _app(
          BrutalThemeData.light().copyWith(typeface: face),
          Builder(
            builder: (context) {
              inside = context;
              return const SizedBox();
            },
          ),
        ),
      );
      final words = Theme.of(inside).textTheme.bodyMedium!;
      expect(words.fontFamily, _registered(own));
      expect(words.fontFamilyFallback, ['Noto Sans Arabic']);
      expect(BrutalTheme.of(inside).textTheme.body.fontFamilyFallback, [
        'Noto Sans Arabic',
      ]);
    });
  });
}

/// [typeface]'s family as the engine has it: a package's face under
/// `packages/<package>/`.
String _registered(BrutalTypeface typeface) => typeface.package == null
    ? typeface.family
    : 'packages/${typeface.package}/${typeface.family}';

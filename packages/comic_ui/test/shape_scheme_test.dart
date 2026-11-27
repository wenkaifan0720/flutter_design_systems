// F15: the corners, the ink's weight and the print's depth an app sets through ComicThemeData.shapeScheme, held to
// Comic's bands, drawn by its parts, and animated between two themes without a jump.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/src/comic/internal/pop.dart';
import 'package:comic_ui/src/comic/press.dart';
import 'package:comic_ui/src/comic/raised.dart';

double _radius(OutlinedBorder shape) => shape is RoundedRectangleBorder
    ? shape.borderRadius.resolve(TextDirection.ltr).topLeft.x
    : double.nan;

/// Comic's least: square, the thinnest ink, the shallowest print.
final _least = comicShapeScheme.copyWith(stroke: 2, depth: .5);

/// Comic's most: each corner step at its band's end, the heaviest ink, the deepest print.
final _most = comicShapeScheme.copyWith(
  corners: comicShapeScheme.corners.copyWith(
    extraSmall: 8,
    small: 8,
    medium: 12,
    large: 16,
  ),
  stroke: 4,
  depth: 1.5,
);

Widget _under(ComicThemeData theme, Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: ComicTheme(
    data: theme,
    child: Center(child: child),
  ),
);

void main() {
  test('a theme starts on Comic\'s own scheme: square, a 2.5 rim, the print as drawn', () {
    final own = ComicThemeData.offset();
    expect(own.shapeScheme, comicShapeScheme);
    expect(own.shapes, const ComicShapes());
    expect(own.stroke, 2.5);
    expect(own.depth, 1);
    expect(own.rim(), 2.5);
    expect(own.rim(3), 3);
    expect(own.rule(), 2);
    expect(own.focus.width, 3);
  });

  test('a scheme past a band stands at its end; a style Comic does not draw is round', () {
    final held = ComicThemeData(
      shapeScheme: const RawShapeScheme(
        corners: RawCornerScale(
          style: RawCornerStyle.bevel,
          extraSmall: 40,
          small: 40,
          medium: 40,
          large: 40,
          extraLarge: 40,
        ),
        stroke: 1,
        depth: 3,
      ),
    );
    final c = held.shapeScheme.corners;
    expect(c.style, RawCornerStyle.round);
    expect(
      [c.extraSmall, c.small, c.medium, c.large, c.extraLarge],
      [8, 8, 12, 16, 0],
    );
    expect(held.stroke, 2);
    expect(held.depth, 1.5);
    expect(
      ComicThemeData.shapeLimits.debugDescribeClamps(
        const RawShapeScheme(stroke: 9),
      ),
      isNotEmpty,
    );
    // The other way past: thinner and shallower than the bands' least.
    final thin = ComicThemeData.offset().copyWith(
      shapeScheme: comicShapeScheme.copyWith(stroke: .5, depth: .1),
    );
    expect(thin.stroke, 2);
    expect(thin.depth, .5);
  });

  test(
    'both band ends are kept as given, and the outlines follow the corners',
    () {
      final least = ComicThemeData.offset().copyWith(shapeScheme: _least);
      expect(least.shapeScheme, _least);
      expect(least.shapes, const ComicShapes());
      expect(least.rim(), 2);
      expect(least.focus.width, closeTo(2.4, 1e-9));

      final most = ComicThemeData.offset().copyWith(shapeScheme: _most);
      expect(most.shapeScheme, _most);
      expect(_radius(most.shapes.capsule), 8);
      expect(_radius(most.shapes.small), 8);
      expect(_radius(most.shapes.medium), 12);
      expect(_radius(most.shapes.large), 16);
      expect(most.shapes.full, const StadiumBorder());
      // A heavier pen draws every line heavier in proportion: a 4 rim, 3.2 rules, a 4.8 ring.
      expect(most.rim(), 4);
      expect(most.rim(3), closeTo(4.8, 1e-9));
      expect(most.rule(), closeTo(3.2, 1e-9));
      expect(most.focus.width, closeTo(4.8, 1e-9));
    },
  );

  test('a scheme leaves the other knobs, and the other knobs leave it', () {
    final theme = ComicThemeData.offset().copyWith(
      shapeScheme: _most,
      density: ComicDensity.compact,
    );
    expect(theme.density, ComicDensity.compact);
    expect(theme.copyWith(density: ComicDensity.standard).shapeScheme, _most);
    expect(theme.atWidth(1200).shapeScheme, _most);
    expect(theme.dotted.shapes, theme.shapes);
  });

  testWidgets('the depth moves a pressed face onto its print', (tester) async {
    Future<double> sink(double depth) async {
      final theme = ComicThemeData.offset().copyWith(
        shapeScheme: comicShapeScheme.copyWith(depth: depth),
      );
      await tester.pumpWidget(
        _under(
          theme,
          const ComicPlated(
            down: true,
            shape: RoundedRectangleBorder(),
            child: SizedBox(key: ValueKey('face'), width: 80, height: 40),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getTopLeft(find.byKey(const ValueKey('face'))).dy -
          tester.getTopLeft(find.byType(ComicPlated)).dy;
    }

    expect(await sink(1), closeTo(comicPressPlate, .01));
    expect(await sink(1.5), closeTo(comicPressPlate * 1.5, .01));
    expect(await sink(.5), closeTo(comicPressPlate * .5, .01));
  });

  testWidgets(
    'the depth moves a raised panel\'s plate and a focused field\'s lift',
    (tester) async {
      Future<(double, double)> at(double depth) async {
        final theme = ComicThemeData.offset().copyWith(
          shapeScheme: comicShapeScheme.copyWith(depth: depth),
        );
        late Widget lifted;
        await tester.pumpWidget(
          _under(
            theme,
            Builder(
              builder: (context) {
                lifted = comicListOnLiftedField(context, const SizedBox());
                return const SizedBox(
                  width: 200,
                  height: 120,
                  child: ComicRaisedFrame(child: Text('Panel')),
                );
              },
            ),
          ),
        );
        final plate = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .firstWhere((p) => p.runtimeType.toString() == '_PlatePainter');
        final lift = (lifted as Transform).transform.getTranslation().x;
        return ((plate as dynamic).plate as double, lift);
      }

      expect(await at(1), (comicRaisedPlate, -comicFocusLift));
      expect(await at(1.5), (comicRaisedPlate * 1.5, -comicFocusLift * 1.5));
    },
  );

  testWidgets(
    'a theme change animates the corners, the ink and the print without a jump',
    (tester) async {
      late ComicThemeData shown;
      Widget app(ComicThemeData theme) => Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedComicTheme(
          data: theme,
          child: Builder(
            builder: (context) {
              shown = ComicTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      final own = ComicThemeData.offset();
      final most = own.copyWith(shapeScheme: _most);
      await tester.pumpWidget(app(own));
      await tester.pumpWidget(app(most));
      final frames = <(double, double, double)>[];
      for (var i = 0; i < 40; i++) {
        frames.add((shown.stroke, shown.depth, _radius(shown.shapes.small)));
        await tester.pump(const Duration(milliseconds: 8));
      }
      frames.add((shown.stroke, shown.depth, _radius(shown.shapes.small)));
      expect(frames.first, (2.5, 1.0, 0.0));
      expect(frames.last, (4.0, 1.5, 8.0));
      final probes =
          <(String, double Function((double, double, double)), double)>[
            ('stroke', (f) => f.$1, 1.5),
            ('depth', (f) => f.$2, .5),
            ('small corner', (f) => f.$3, 8.0),
          ];
      for (final (what, of, whole) in probes) {
        for (var i = 1; i < frames.length; i++) {
          final step = of(frames[i]) - of(frames[i - 1]);
          expect(
            step,
            greaterThanOrEqualTo(-1e-9),
            reason: '$what went back at frame $i',
          );
          // Never more than a fifth of the way in one 8 ms frame: no value switches halfway.
          expect(
            step,
            lessThanOrEqualTo(whole / 5),
            reason: '$what jumped at frame $i',
          );
        }
      }
    },
  );

  test('two held schemes lerp without holding again', () {
    final a = ComicThemeData.offset().copyWith(shapeScheme: _least);
    final b = ComicThemeData.offset().copyWith(shapeScheme: _most);
    final mid = ComicThemeData.lerp(a, b, .5);
    expect(mid.stroke, 3);
    expect(mid.depth, 1);
    expect(mid.shapeScheme.corners.medium, 6);
    expect(_radius(mid.shapes.medium), 6);
  });
}

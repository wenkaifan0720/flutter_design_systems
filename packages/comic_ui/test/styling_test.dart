import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

double _ratio(Color a, Color b) =>
    (math.max(a.computeLuminance(), b.computeLuminance()) + .05) /
    (math.min(a.computeLuminance(), b.computeLuminance()) + .05);

void main() {
  test('corner scales are value objects and preserve caller outlines', () {
    final square = const ComicShapes();
    final round = ComicShapes.rounded(8);
    expect(square.capsule, const RoundedRectangleBorder());
    expect(round.capsule, const StadiumBorder());
    const full = ComicShapes(full: CircleBorder());
    expect(round.copyWith(), round);
    expect(round.copyWith().hashCode, round.hashCode);
    expect(ComicShapes.lerp(square, round, 0), same(square));
    expect(ComicShapes.lerp(square, round, 1), same(round));
    final middle = ComicShapes.lerp(square, round, .5);
    expect(
      (middle.small as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(4),
    );
    expect(
      round.copyWith(small: const BeveledRectangleBorder()).small,
      const BeveledRectangleBorder(),
    );
    for (final scale in [square, round, full]) {
      for (final shape in [
        scale.small,
        scale.medium,
        scale.large,
        scale.capsule,
        scale.full,
      ]) {
        for (final direction in TextDirection.values) {
          final path = shape.getOuterPath(
            const Rect.fromLTWH(0, 0, 160, 80),
            textDirection: direction,
          );
          expect(path.contains(const Offset(80, 40)), isTrue);
          expect(path.getBounds().isFinite, isTrue);
        }
      }
    }
  });
  test(
    'state styles fall through only when the earlier layer resolves null',
    () {
      final own = ComicStyle(
        fill: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.pressed) ? Colors.red : null,
        ),
      );
      const component = ComicStyle(fill: WidgetStatePropertyAll(Colors.blue));
      expect(ComicStyleOf([own, component], const {}).fill, Colors.blue);
      expect(
        ComicStyleOf([own, component], const {WidgetState.pressed}).fill,
        Colors.red,
      );
      expect(own.copyWith(), own);
      expect(own.merge(component).fill, own.fill);
    },
  );
  test(
    'forwarded styles retain state fall-through and freeze their layers',
    () {
      final pressed = ComicStyle(
        fill: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed) ? Colors.red : null,
        ),
      );
      const fallback = ComicStyle(
        fill: WidgetStatePropertyAll(Colors.blue),
        foreground: WidgetStatePropertyAll(Colors.white),
        edge: WidgetStatePropertyAll(Colors.black),
        overlay: WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(BorderSide(width: 3)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ),
        padding: WidgetStatePropertyAll(EdgeInsets.all(12)),
        minimumSize: WidgetStatePropertyAll(Size(56, 48)),
        textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 18)),
        iconSize: WidgetStatePropertyAll(20),
      );
      final layers = <ComicStyle?>[null, pressed, fallback];
      final forwarded = ComicStyle.layered(layers);
      layers.clear();
      final rest = ComicStyleOf([forwarded], const {});
      expect(rest.fill, Colors.blue);
      expect(rest.foreground, Colors.white);
      expect(rest.edge, Colors.black);
      expect(rest.overlay!.resolve({}), Colors.transparent);
      expect(rest.side, const BorderSide(width: 3));
      expect(
        rest.shape,
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
      );
      expect(rest.padding(TextDirection.ltr), const EdgeInsets.all(12));
      expect(rest.minimumSize, const Size(56, 48));
      expect(rest.textStyle, const TextStyle(fontSize: 18));
      expect(rest.iconSize, 20);
      expect(rest.at({WidgetState.pressed}).fill, Colors.red);
      expect(ComicStyle.layered([null]).isEmpty, isTrue);
      expect(ComicStyle.layered([pressed]).fill, same(pressed.fill));
      expect(ComicStyle.layered([pressed, pressed]).fill!.resolve({}), isNull);
    },
  );
  test('style and stroke interpolation preserves unset endpoint slots', () {
    const unset = ComicStyle();
    const styled = ComicStyle(fill: WidgetStatePropertyAll(Colors.red));
    expect(ComicStyle.lerp(unset, styled, 0), same(unset));
    expect(ComicStyle.lerp(unset, styled, 1), same(styled));
    expect(ComicStyle.lerp(null, styled, 0), isNull);
    expect(ComicStyle.lerp(styled, null, 1), isNull);
    expect(ComicStyle.lerp(unset, styled, .75)!.fill!.resolve({}), Colors.red);
    const ownStrokes = ComicStrokes();
    expect(ComicStrokes.lerp(ownStrokes, ComicStrokes.bold, 0), ownStrokes);
    expect(
      ComicStrokes.lerp(ownStrokes, ComicStrokes.bold, 1),
      ComicStrokes.bold,
    );
    expect(ComicStrokes.lerp(ownStrokes, ComicStrokes.bold, .5).regular, 3.25);
    const ownComponents = ComicComponentThemes();
    const themed = ComicComponentThemes(chip: styled);
    expect(
      ComicComponentThemes.lerp(ownComponents, themed, 0),
      same(ownComponents),
    );
    expect(ComicComponentThemes.lerp(ownComponents, themed, 1), same(themed));
  });
  test('all derived themes retain typography, outlines, motion and component settings', () {
    final theme = ComicThemeData.offset().copyWith(
      shapes: ComicShapes.rounded(9),
      strokes: ComicStrokes.bold,
      density: ComicDensity.compact,
      typeface: const ComicTypeface.app(
        display: 'Display',
        text: 'Text',
        scale: 1.2,
      ),
      motion: const ComicMotion(state: Duration(milliseconds: 270)),
      chipTheme: const ComicStyle(fill: WidgetStatePropertyAll(Colors.red)),
    );
    expect(theme.copyWith(), theme);
    expect(theme.copyWith().hashCode, theme.hashCode);
    for (final derived in [
      theme.atWidth(1200),
      theme.dotted,
      theme.lettersOn(Colors.white),
    ]) {
      expect(derived.shapes, theme.shapes);
      expect(derived.strokes, theme.strokes);
      expect(derived.density, theme.density);
      expect(derived.typeface, theme.typeface);
      expect(derived.components, theme.components);
      expect(derived.motion, theme.motion);
      expect(derived.type.body.fontFamily, 'Text');
      expect(derived.type.body.fontSize, closeTo(19.2, .001));
      expect(derived.focus.width, 5);
    }
    final plain = ComicThemeData.offset();
    expect(plain.lerp(theme, 0), plain);
    expect(plain.lerp(theme, 1), theme);
    expect(plain.lerp(theme, .5).motion.state.inMilliseconds, 195);
  });
  for (final (name, act, caption, shade, ground) in [
    (
      'plum',
      const Color(0xff802651),
      const Color(0xffeed36a),
      const Color(0xff276c99),
      const Color(0xfff7eadb),
    ),
    (
      'pale',
      const Color(0xffeeeeee),
      Colors.white,
      const Color(0xffdddddd),
      Colors.white,
    ),
    (
      'dark',
      const Color(0xff170e29),
      const Color(0xff271933),
      const Color(0xff121212),
      Colors.black,
    ),
    (
      'grey',
      const Color(0xff777777),
      const Color(0xff777777),
      const Color(0xff777777),
      const Color(0xff777777),
    ),
  ]) {
    for (final brightness in Brightness.values) {
      test(
        'from $name ${brightness.name} settles words, edges, tones and chart meanings',
        () {
          final theme = ComicThemeData.from(
            primary: act,
            caption: caption,
            shade: shade,
            background: ground,
            brightness: brightness,
          );
          final c = theme.colors;
          for (final ink in [
            c.text,
            c.textSecondary,
            c.primaryText,
            c.shadeText,
            c.tones.info,
            c.tones.success,
            c.tones.warning,
            c.tones.danger,
          ]) {
            for (final paper in [c.background, c.card, c.inset]) {
              expect(_ratio(ink, paper), greaterThanOrEqualTo(4.5));
            }
          }
          for (final (ink, paper) in [
            (c.onPrimary, c.primary),
            (c.onCaption, c.caption),
            (c.onShade, c.shade),
            (c.onPaper, c.paper),
            (c.onPaperSecondary, c.paper),
            (c.hint, c.control),
            (c.onPaper, c.unlit),
          ]) {
            expect(_ratio(ink, paper), greaterThanOrEqualTo(4.5));
          }
          for (final ground in [c.background, c.card, c.inset]) {
            expect(_ratio(c.outline, ground), greaterThanOrEqualTo(3));
          }
          expect(c.series, hasLength(6));
          expect({
            c.primary,
            c.shade,
            c.caption,
            c.drama,
            c.unlit,
          }, hasLength(5));
        },
      );
    }
  }
  testWidgets(
    'ComicTheme is captured as an InheritedTheme and applies motion',
    (tester) async {
      final data = ComicThemeData.offset().copyWith(
        motion: const ComicMotion(state: Duration(milliseconds: 270)),
      );
      final theme = ComicTheme(data: data, child: const SizedBox());
      expect(theme, isA<InheritedTheme>());
      await tester.pumpWidget(
        MaterialApp(
          home: ComicTheme(
            data: data,
            child: Builder(
              builder: (context) {
                expect(
                  ComicMotion.of(context).state,
                  const Duration(milliseconds: 270),
                );
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

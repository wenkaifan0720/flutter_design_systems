// Neumorphism's controls reach ui_core's floors: every control lays out at the touch floor on every platform, as the
// look's alignment contract has it, 40 each way unless an app's RawTapTargetScope declares another, and a face larger
// than the floor is its own target. A medium key stands at the medium line, the density's control height, so it shares
// a row's height with the buttons beside it. A breadcrumb's places stand in a chip group (ui_core's RawChipGroup): each link's
// reach takes the room between the words, so the words and their chevrons keep the look's spacing.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

import 'support.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 300,
  TextDirection direction = TextDirection.ltr,
  RawTapTargets? targets,
  NeumorphicDensity? density,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Widget body = Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.only(top: 40),
      child: SizedBox(width: width, child: child),
    ),
  );
  if (density != null) {
    final inner = body;
    body = Builder(
      builder: (context) => NeumorphicTheme(
        data: NeumorphicTheme.of(context).copyWith(density: density),
        child: inner,
      ),
    );
  }
  if (targets != null) body = RawTapTargetScope(targets: targets, child: body);
  await tester.pumpWidget(neumorphicApp(body, direction: direction));
  await tester.pumpAndSettle();
}

/// The reach round the first control drawing [of]: its tap target's box.
Rect _reach(WidgetTester tester, Finder of) => tester.getRect(
  find.ancestor(of: of, matching: find.byType(TapTargetPadding)).first,
);

/// The face inside the reach round [of].
Rect _face(WidgetTester tester, Finder of) {
  final target = tester.renderObject(
    find.ancestor(of: of, matching: find.byType(TapTargetPadding)).first,
  );
  final face = (target as RenderObjectWithChildMixin<RenderBox>).child!;
  return face.localToGlobal(Offset.zero) & face.size;
}

Widget _key({double size = 32}) => Align(
  alignment: AlignmentDirectional.centerStart,
  child: NeumorphicIconButton(
    NeumorphicGlyphs.chevronLeft,
    label: 'Back',
    size: size,
    onPressed: () {},
  ),
);

void main() {
  testWidgets(
    "the theme declares the floors it stands on, and an app's own above it stands",
    (tester) async {
      RawTapTargets? seen;
      Widget themed() => Directionality(
        textDirection: TextDirection.ltr,
        child: NeumorphicTheme(
          data: NeumorphicThemeData.preset('porcelain', Brightness.light),
          child: Builder(
            builder: (context) {
              seen = RawTapTargets.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(themed());
      expect(seen, RawTapTargets.fallback);
      const raised = RawTapTargets(touch: Size.square(56));
      await tester.pumpWidget(
        RawTapTargetScope(targets: raised, child: themed()),
      );
      expect(seen, raised);
    },
  );

  testWidgets(
    'the metrics read the floor in effect, and their old names say the default',
    (tester) async {
      late Size floor;
      await _pump(
        tester,
        Builder(
          builder: (context) {
            floor = NeumorphicChromeMetrics.targetOf(context);
            return const SizedBox();
          },
        ),
        targets: const RawTapTargets(touch: Size.square(56)),
      );
      expect(floor, const Size.square(56));
      // ignore: deprecated_member_use
      expect(NeumorphicChromeMetrics.targetSize, 40);
      // ignore: deprecated_member_use
      expect(NeumorphicChromeMetrics.touchTarget, 40);
    },
  );

  setUpAll(loadNeumorphicFonts);

  testWidgets(
    'a control reaches the touch floor, 40 each way, under a finger and a pointer alike',
    (tester) async {
      await _pump(tester, _key());
      final icon = find.byIcon(NeumorphicGlyphs.chevronLeft);
      expect(_reach(tester, icon).size, const Size(40, 40));
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.macOS,
    }),
  );

  testWidgets("a face larger than the floor and the line is its own target", (
    tester,
  ) async {
    await _pump(tester, _key(size: 56));
    final icon = find.byIcon(NeumorphicGlyphs.chevronLeft);
    expect(_reach(tester, icon).size, const Size(56, 56));
  });

  testWidgets(
    "a medium key stands at the medium line: the density's control height, never under the floor",
    (tester) async {
      for (final (density, line) in [
        (NeumorphicDensity.standard, 48.0),
        (NeumorphicDensity.comfortable, 44.0),
        (NeumorphicDensity.compact, 40.0),
      ]) {
        await _pump(tester, _key(size: 44), density: density);
        final icon = find.byIcon(NeumorphicGlyphs.chevronLeft);
        expect(_reach(tester, icon).size, Size(line, line), reason: '$density');
      }
    },
  );

  testWidgets(
    "a compact dial's less and more faces stand the look's ten apart at every density",
    (tester) async {
      for (final density in [
        NeumorphicDensity.standard,
        NeumorphicDensity.comfortable,
        NeumorphicDensity.compact,
      ]) {
        await _pump(
          tester,
          NeumorphicDial(
            value: 4,
            min: 0,
            max: 10,
            step: 1,
            compact: true,
            label: 'Alert volume',
            figure: '4',
            onDecrease: () {},
            onIncrease: () {},
          ),
          width: 360,
          density: density,
        );
        Rect face(IconData glyph) => tester.getRect(
          find
              .descendant(
                of: find.widgetWithIcon(NeumorphicRoundButton, glyph),
                matching: find.byType(NeumorphicSurface),
              )
              .first,
        );
        final (less, more) = (
          face(NeumorphicGlyphs.minus),
          face(NeumorphicGlyphs.plus),
        );
        expect(
          more.left - less.right,
          moreOrLessEquals(10, epsilon: .5),
          reason: '$density',
        );
      }
    },
  );

  testWidgets(
    "a snack bar's first line, its act and its dismiss key share one middle at every density",
    (tester) async {
      for (final density in [
        NeumorphicDensity.standard,
        NeumorphicDensity.comfortable,
        NeumorphicDensity.compact,
      ]) {
        await _pump(
          tester,
          NeumorphicSnackBar(
            'Saved',
            actionLabel: 'Undo',
            onAction: () {},
            onDismiss: () {},
          ),
          width: 360,
          density: density,
        );
        final key = tester
            .getRect(find.byType(NeumorphicRoundButton))
            .center
            .dy;
        expect(
          tester.getRect(find.text('Saved')).center.dy,
          moreOrLessEquals(key, epsilon: .5),
          reason: '$density',
        );
        expect(
          tester.getRect(find.text('Undo')).center.dy,
          moreOrLessEquals(key, epsilon: .5),
          reason: '$density',
        );
      }
    },
  );

  testWidgets(
    "a banner's mark, title and close key share one middle at every density and at large text",
    (tester) async {
      for (final (density, scale) in [
        (NeumorphicDensity.standard, 1.0),
        (NeumorphicDensity.comfortable, 1.0),
        (NeumorphicDensity.compact, 1.0),
        (NeumorphicDensity.standard, 2.0),
      ]) {
        await _pump(
          tester,
          MediaQuery.withClampedTextScaling(
            minScaleFactor: scale,
            maxScaleFactor: scale,
            child: NeumorphicBanner(
              'Your plan renews on 1 December.',
              title: 'Info',
              onDismiss: () {},
            ),
          ),
          width: 360,
          density: density,
        );
        final key = tester
            .getRect(find.byIcon(NeumorphicGlyphs.close))
            .center
            .dy;
        final reason = '$density at $scale';
        expect(
          tester.getRect(find.text('Info')).center.dy,
          moreOrLessEquals(key, epsilon: .5),
          reason: reason,
        );
        expect(
          tester.getRect(find.byIcon(NeumorphicGlyphs.info)).center.dy,
          moreOrLessEquals(key, epsilon: .5),
          reason: reason,
        );
      }
    },
  );

  testWidgets("an app's RawTapTargetScope sets the floor", (tester) async {
    await _pump(
      tester,
      _key(),
      targets: const RawTapTargets(touch: Size.square(56)),
    );
    expect(
      _reach(tester, find.byIcon(NeumorphicGlyphs.chevronLeft)).size,
      const Size(56, 56),
    );
  });

  const places = ['Everywhere', 'Upstairs', 'Rooms', 'Kitchen'];
  Widget trail() => NeumorphicBreadcrumb(
    crumbs: [
      for (final name in places.take(3))
        NeumorphicCrumb(name, onPressed: () {}),
      NeumorphicCrumb(places.last),
    ],
  );

  for (final direction in TextDirection.values) {
    testWidgets(
      "a breadcrumb's words and chevrons stand the look's 4 apart, each link reaching the floor (${direction.name})",
      (tester) async {
        await _pump(tester, trail(), width: 380, direction: direction);
        final rtl = direction == TextDirection.rtl;
        final chevrons = [
          for (final e
              in find
                  .byIcon(
                    rtl
                        ? NeumorphicGlyphs.chevronLeft
                        : NeumorphicGlyphs.chevronRight,
                  )
                  .evaluate())
            tester.getRect(find.byWidget(e.widget)),
        ];
        expect(chevrons, hasLength(3));
        for (final (i, name) in places.take(3).indexed) {
          final words = find.text(name);
          final face = _face(tester, words), reach = _reach(tester, words);
          expect(reach.height, 40);
          expect(reach.width, greaterThanOrEqualTo(40));
          // A link's words are its face: its target stands round them, not between them and the chevron.
          final gap = rtl
              ? face.left - chevrons[i].right
              : chevrons[i].left - face.right;
          expect(gap, moreOrLessEquals(4, epsilon: .5), reason: name);
          // The reach takes the room between the faces, never a neighbour's.
          expect(
            rtl ? reach.left : chevrons[i].left - reach.right,
            rtl
                ? greaterThanOrEqualTo(chevrons[i].right - .5)
                : greaterThanOrEqualTo(-.5),
          );
        }
        // The place you are on stands 4 past the last chevron too.
        final here = tester.getRect(find.text(places.last));
        final last = chevrons.last;
        expect(
          rtl ? last.left - here.right : here.left - last.right,
          moreOrLessEquals(4, epsilon: .5),
        );
      },
    );

    testWidgets(
      "a link narrower than the floor reaches across the trail's spacing to its chevrons, no further (${direction.name})",
      (tester) async {
        await _pump(
          tester,
          NeumorphicBreadcrumb(
            crumbs: [
              NeumorphicCrumb('Home', onPressed: () {}),
              NeumorphicCrumb('Up', onPressed: () {}),
              const NeumorphicCrumb('Kitchen'),
            ],
          ),
          width: 380,
          direction: direction,
        );
        final rtl = direction == TextDirection.rtl;
        // The chevrons in reading order: the one before Up, then the one after it.
        final chevrons =
            [
              for (final e
                  in find
                      .byIcon(
                        rtl
                            ? NeumorphicGlyphs.chevronLeft
                            : NeumorphicGlyphs.chevronRight,
                      )
                      .evaluate())
                tester.getRect(find.byWidget(e.widget)),
            ]..sort(
              (a, b) =>
                  rtl ? b.left.compareTo(a.left) : a.left.compareTo(b.left),
            );
        expect(chevrons, hasLength(2));
        final up = find.text('Up');
        expect(_face(tester, up).width, lessThan(40));
        final reach = _reach(tester, up);
        expect(reach.width, 40);
        // The group takes the trail's spacing inside the reach: the reach meets each chevron, with no spacing added
        // outside it.
        final (before, after) = (chevrons[0], chevrons[1]);
        expect(
          rtl ? before.left - reach.right : reach.left - before.right,
          moreOrLessEquals(0, epsilon: .5),
        );
        expect(
          rtl ? reach.left - after.right : after.left - reach.right,
          moreOrLessEquals(0, epsilon: .5),
        );
      },
    );

    testWidgets(
      "a breadcrumb's place on a line of its own keeps its links' rhythm and their start (${direction.name})",
      (tester) async {
        await _pump(tester, trail(), width: 90, direction: direction);
        final words = [
          for (final name in places) tester.getRect(find.text(name)),
        ];
        for (var i = 1; i < words.length; i++) {
          expect(
            words[i].top,
            greaterThan(words[i - 1].top),
            reason: places[i],
          );
        }
        // Line to line the words stand one reach apart: the place's words stand in a slot as tall as its links'.
        for (var i = 1; i < words.length; i++) {
          expect(
            words[i].top - words[i - 1].top,
            moreOrLessEquals(40, epsilon: .5),
          );
        }
        // Every line starts on the trail's start edge, with a place's words or the chevron before them.
        final trailBox = tester.getRect(find.byType(NeumorphicBreadcrumb));
        final chevrons = [
          for (final e
              in find
                  .byIcon(
                    direction == TextDirection.rtl
                        ? NeumorphicGlyphs.chevronLeft
                        : NeumorphicGlyphs.chevronRight,
                  )
                  .evaluate())
            tester.getRect(find.byWidget(e.widget)),
        ];
        final lines = <double, List<Rect>>{};
        for (final r in [...words, ...chevrons]) {
          final key = lines.keys.firstWhere(
            (y) => (y - r.center.dy).abs() < 4,
            orElse: () => r.center.dy,
          );
          (lines[key] ??= []).add(r);
        }
        expect(lines, hasLength(words.length));
        for (final line in lines.values) {
          if (direction == TextDirection.ltr) {
            final start = line
                .map((r) => r.left)
                .reduce((a, b) => a < b ? a : b);
            expect(start, moreOrLessEquals(trailBox.left, epsilon: 1));
          } else {
            final start = line
                .map((r) => r.right)
                .reduce((a, b) => a > b ? a : b);
            expect(start, moreOrLessEquals(trailBox.right, epsilon: 1));
          }
        }
      },
    );
  }
}

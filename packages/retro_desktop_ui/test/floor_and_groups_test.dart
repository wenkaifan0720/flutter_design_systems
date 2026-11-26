// Retro Desktop's controls reach ui_core's floors: 40 each way under a finger,
// the desk's 40 high under a pointer, and whatever an app's RawTapTargetScope
// declares (its floors and the input it names). A breadcrumb's places and a
// toolbar's tools stand in chip groups (ui_core's RawChipGroup): each reach
// takes the room between the faces, so the faces keep the look's spacing.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

import 'support.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 300,
  TextDirection direction = TextDirection.ltr,
  RawTapTargets? targets,
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
  if (targets != null) body = RawTapTargetScope(targets: targets, child: body);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: RetroDesktopHost(brightness: Brightness.light, child: app!),
      ),
      home: body,
    ),
  );
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

Widget _button() => RetroDesktopIconButton(
  RetroDesktopGlyphs.chevronLeft,
  label: 'Back',
  onPressed: () {},
);

void main() {
  testWidgets(
    'the theme declares the floors it stands on, and an app\'s own above it stands',
    (tester) async {
      RawTapTargets? seen;
      Widget themed() => Directionality(
        textDirection: TextDirection.ltr,
        child: RetroDesktopTheme(
          data: RetroDesktopThemeData.classic(),
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

  setUpAll(loadRetroDesktopFonts);

  testWidgets('under a finger a control reaches the touch floor, 40 each way', (
    tester,
  ) async {
    await _pump(
      tester,
      Align(alignment: AlignmentDirectional.centerStart, child: _button()),
    );
    final reach = _reach(tester, find.byIcon(RetroDesktopGlyphs.chevronLeft));
    expect(reach.size, const Size(40, 40));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    "under a pointer a control reaches the desk's 40 high, its face's "
    'own width across',
    (tester) async {
      await _pump(
        tester,
        Align(alignment: AlignmentDirectional.centerStart, child: _button()),
      );
      final icon = find.byIcon(RetroDesktopGlyphs.chevronLeft);
      final reach = _reach(tester, icon);
      expect(reach.height, 40);
      expect(reach.width, _face(tester, icon).width);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets("an app's RawTapTargetScope sets the finger's floor", (
    tester,
  ) async {
    await _pump(
      tester,
      Align(alignment: AlignmentDirectional.centerStart, child: _button()),
      targets: const RawTapTargets(touch: Size.square(56)),
    );
    final reach = _reach(tester, find.byIcon(RetroDesktopGlyphs.chevronLeft));
    expect(reach.size, const Size(56, 56));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
    "a desk the app names a touch screen pads its controls across, at "
    "the finger's floor",
    (tester) async {
      await _pump(
        tester,
        Align(alignment: AlignmentDirectional.centerStart, child: _button()),
        targets: const RawTapTargets(input: RawInput.touch),
      );
      final reach = _reach(tester, find.byIcon(RetroDesktopGlyphs.chevronLeft));
      expect(reach.size, const Size(40, 40));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets("a phone the app names a pointer's keeps its faces' widths", (
    tester,
  ) async {
    await _pump(
      tester,
      Align(alignment: AlignmentDirectional.centerStart, child: _button()),
      targets: const RawTapTargets(input: RawInput.pointer),
    );
    final icon = find.byIcon(RetroDesktopGlyphs.chevronLeft);
    final reach = _reach(tester, icon);
    expect(reach.height, 40);
    expect(reach.width, _face(tester, icon).width);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  for (final direction in TextDirection.values) {
    testWidgets(
      "a breadcrumb's page on a line of its own keeps its links' rhythm and "
      'their start (${direction.name})',
      (tester) async {
        await _pump(
          tester,
          RetroDesktopBreadcrumb(
            items: [
              for (final name in const ['Everything', 'Letters', 'Spring'])
                RetroDesktopBreadcrumbItem(name, onPressed: () {}),
              const RetroDesktopBreadcrumbItem('Low Tide'),
            ],
          ),
          width: 80,
          direction: direction,
        );
        final words = [
          for (final name in const [
            'Everything',
            'Letters',
            'Spring',
            'Low Tide',
          ])
            tester.getRect(find.text(name)),
        ];
        for (var i = 1; i < words.length; i++) {
          expect(words[i].top, greaterThan(words[i - 1].top));
        }
        // Line to line the words stand one step apart: the page's words stand
        // in a slot as tall as its links' reach (they stood nearer).
        final step = words[1].top - words[0].top;
        // ... and that step is the links' reach: the reaches meet, the
        // trail's run spacing taken inside them, not added to them.
        expect(
          step,
          moreOrLessEquals(
            _reach(tester, find.text('Everything')).height,
            epsilon: .5,
          ),
        );
        for (var i = 2; i < words.length; i++) {
          expect(
            words[i].top - words[i - 1].top,
            moreOrLessEquals(step, epsilon: .5),
          );
        }
        // The page is one node, selected, named by its words.
        expect(
          tester.getSemantics(find.text('Low Tide')),
          matchesSemantics(
            label: 'Low Tide',
            hasSelectedState: true,
            isSelected: true,
          ),
        );
        // Every line starts on the trail's start edge, with a place's words
        // or the mark before them.
        final trail = tester.getRect(find.byType(RetroDesktopBreadcrumb));
        final marks = [
          for (final e in find.byType(RetroDesktopTriangleMark).evaluate())
            tester.getRect(find.byWidget(e.widget)),
        ];
        final lines = <double, List<Rect>>{};
        for (final r in [...words, ...marks]) {
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
            expect(start, moreOrLessEquals(trail.left, epsilon: 1));
          } else {
            final start = line
                .map((r) => r.right)
                .reduce((a, b) => a > b ? a : b);
            expect(start, moreOrLessEquals(trail.right, epsilon: 1));
          }
        }
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.macOS,
      }),
    );
  }

  for (final density in [
    RetroDesktopDensity.standard,
    RetroDesktopDensity.compact,
  ]) {
    testWidgets(
      "a toolbar's tools stand the toolbar's gap apart under a finger, "
      'or as far as their reaches need (${density.name})',
      (tester) async {
        await _pump(
          tester,
          Builder(
            builder: (context) => RetroDesktopTheme(
              data: RetroDesktopTheme.of(context).copyWith(density: density),
              child: RetroDesktopToolbar(
                children: [
                  RetroDesktopIconButton(
                    RetroDesktopGlyphs.chevronLeft,
                    label: 'Back',
                    onPressed: () {},
                  ),
                  RetroDesktopIconButton(
                    RetroDesktopGlyphs.chevronRight,
                    label: 'Next',
                    onPressed: () {},
                  ),
                  const Spacer(),
                  RetroDesktopIconButton(
                    RetroDesktopGlyphs.menu,
                    label: 'More',
                    onPressed: () {},
                  ),
                  RetroDesktopIconButton(
                    RetroDesktopGlyphs.close,
                    label: 'Close',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );
        final horizontal = RetroDesktopTheme.of(
          tester.element(find.byType(RetroDesktopToolbar)),
        ).density.horizontal;
        for (final (a, b) in [
          (RetroDesktopGlyphs.chevronLeft, RetroDesktopGlyphs.chevronRight),
          (RetroDesktopGlyphs.menu, RetroDesktopGlyphs.close),
        ]) {
          final fa = _face(tester, find.byIcon(a));
          final fb = _face(tester, find.byIcon(b));
          final ra = _reach(tester, find.byIcon(a));
          final rb = _reach(tester, find.byIcon(b));
          // The faces stand the gap apart where the reaches allow, else as far
          // as the reaches need to meet: never the gap and the reaches' room both.
          final need = (ra.width - fa.width) / 2 + (rb.width - fb.width) / 2;
          final gap = fb.left - fa.right;
          expect(
            gap,
            moreOrLessEquals(
              need > 8 * horizontal ? need : 8 * horizontal,
              epsilon: .5,
            ),
          );
          expect(rb.left, greaterThanOrEqualTo(ra.right - .5));
        }
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }

  for (final appearance in RetroDesktopAppearance.values) {
    testWidgets(
      "a window's close box reaches the finger's floor in effect across its "
      'bar (${appearance.name})',
      (tester) async {
        var closed = 0;
        await _pump(
          tester,
          Builder(
            builder: (context) => RetroDesktopTheme(
              data: RetroDesktopTheme.of(context)
                  .copyWith(appearance: appearance),
              child: RetroDesktopWindow(
                title: 'A window',
                onClose: () => closed++,
                child: const Text('Inside'),
              ),
            ),
          ),
          targets: const RawTapTargets(touch: Size.square(56)),
        );
        final press = tester.getRect(
          find
              .descendant(
                of: find.byType(RetroDesktopWindow),
                matching: find.bySemanticsLabel(RegExp(r'^Close$')),
              )
              .first,
        );
        expect(press.width, 56);
        await tester.tapAt(press.center);
        expect(closed, 1);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }
}

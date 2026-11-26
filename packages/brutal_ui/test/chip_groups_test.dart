// A tag input's tags and a breadcrumb's crumbs stand in a chip group
// (ui_core's RawChipGroup): each target reaches into the room between the
// faces, so the faces keep the look's spacing where the targets allow, never
// the spacing and the targets' room both. In a Wrap, tags 28 tall in 44
// targets stood 18 apart run to run.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 260,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      builder: (context, _) => Directionality(
        textDirection: direction,
        child: BrutalTheme(
          data: BrutalThemeData.light(),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _tag(WidgetTester tester, String label) => tester.getRect(
  find
      .ancestor(
        of: find.text(label),
        matching: find.byType(AnimatedBrutalSurface),
      )
      .first,
);

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('tags a run apart stand the floor less the face apart '
        '(${direction.name})', (tester) async {
      await _pump(
        tester,
        BrutalTagInput<String>(
          labelText: 'Kinds',
          values: const ['Choral', 'Organ', 'Brass'],
          options: const ['Choral', 'Organ', 'Brass'],
          displayStringForOption: (v) => v,
          onChanged: (_) {},
        ),
        width: 200,
        direction: direction,
      );
      final a = _tag(tester, 'Choral');
      final b = _tag(tester, 'Organ');
      // A tag a line: the runs' faces stand as far apart as their targets
      // need (40 less a 28 face), not that and the runs' spacing.
      expect(b.top, greaterThan(a.bottom));
      expect(b.top - a.bottom, moreOrLessEquals(40 - a.height, epsilon: .5));
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }

  testWidgets("under a pointer the tags' runs stand the look's small "
      'spacing apart, the first as far under the rule as from its sides', (
    tester,
  ) async {
    await _pump(
      tester,
      BrutalTagInput<String>(
        labelText: 'Kinds',
        values: const ['Choral', 'Organ', 'Brass'],
        options: const ['Choral', 'Organ', 'Brass'],
        displayStringForOption: (v) => v,
        onChanged: (_) {},
      ),
      width: 200,
    );
    final a = _tag(tester, 'Choral');
    final b = _tag(tester, 'Organ');
    // A pointer's floor (24) is under the faces: each tag's slot keeps the
    // look's tight spacing above and below it, so the runs stand the small
    // spacing apart and the first run the small spacing under the box's
    // rule, as from its sides, never their rules on each other.
    expect(
      b.top - a.bottom,
      moreOrLessEquals(BrutalSpacing.small, epsilon: .5),
    );
    final box = tester.getRect(
      find
          .ancestor(
            of: find.text('Choral'),
            matching: find.byType(AnimatedBrutalSurface),
          )
          .at(1),
    );
    final rule = BrutalThemeData.light().borderWidth;
    expect(
      a.top - (box.top + rule),
      moreOrLessEquals(BrutalSpacing.small, epsilon: .5),
    );
    expect(
      a.top - (box.top + rule),
      moreOrLessEquals(a.left - (box.left + rule), epsilon: .5),
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  for (final direction in TextDirection.values) {
    testWidgets(
      "a breadcrumb's page on a line of its own keeps its links' "
      'rhythm and their start (${direction.name})',
      (tester) async {
        await _pump(
          tester,
          BrutalBreadcrumb(
            crumbs: [
              for (final name in const ['Events', 'Spring', 'Hall 4', 'Doors'])
                BrutalCrumb(name, onPressed: () {}),
              const BrutalCrumb('Low Tide'),
            ],
          ),
          width: 150,
          direction: direction,
        );
        final words = [
          for (final name in const ['Events', 'Hall 4', 'Low Tide'])
            tester.getRect(find.text(name)),
        ];
        expect(words[1].top, greaterThan(words[0].top));
        expect(words[2].top, greaterThan(words[1].top));
        // Line to line, the words stand as far apart under a finger and a
        // pointer: the page's face is its words, in a target as tall as its
        // links' (under a finger it stood 14 nearer; under a pointer, 2 lower).
        expect(
          words[2].top - words[1].top,
          moreOrLessEquals(words[1].top - words[0].top, epsilon: .5),
        );
        // The page is one node, selected, named by its words.
        expect(
          tester.getSemantics(find.text('Low Tide')),
          matchesSemantics(
            label: 'Low Tide',
            hasSelectedState: true,
            isSelected: true,
          ),
        );
        // Every line starts on the path's start edge.
        for (final word in words.skip(1)) {
          if (direction == TextDirection.ltr) {
            expect(word.left, moreOrLessEquals(words[0].left, epsilon: .5));
          } else {
            expect(word.right, moreOrLessEquals(words[0].right, epsilon: .5));
          }
        }
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.macOS,
      }),
    );
  }

  testWidgets("under an app's 48 floor the tags' targets take the run "
      'spacing inside them', (tester) async {
    await _pump(
      tester,
      RawTapTargetScope(
        targets: BrutalTheme.tapTargets.copyWith(touch: const Size.square(48)),
        child: BrutalTagInput<String>(
          labelText: 'Kinds',
          values: const ['Choral', 'Organ', 'Brass'],
          options: const ['Choral', 'Organ', 'Brass'],
          displayStringForOption: (v) => v,
          onChanged: (_) {},
        ),
      ),
      width: 200,
    );
    final a = _tag(tester, 'Choral');
    final b = _tag(tester, 'Organ');
    // The run spacing (48 less the box's line, 6) stands inside the
    // targets' room (48 less the face): in a Wrap it stood on top of it.
    expect(b.top - a.bottom, moreOrLessEquals(48 - a.height, epsilon: .5));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  for (final direction in TextDirection.values) {
    testWidgets("a breadcrumb's lines: the links' targets meet, the run "
        'spacing taken inside them (${direction.name})', (tester) async {
      await _pump(
        tester,
        BrutalBreadcrumb(
          crumbs: [
            for (final name in const ['Events', 'Spring', 'Hall 4', 'Doors'])
              BrutalCrumb(name, onPressed: () {}),
            const BrutalCrumb('Low Tide'),
          ],
        ),
        width: 150,
        direction: direction,
      );
      // Each link's target, by line.
      final targets = [
        for (final name in const ['Events', 'Spring', 'Hall 4', 'Doors'])
          tester.getRect(
            find
                .ancestor(
                  of: find.text(name),
                  matching: find.byType(TapTargetPadding),
                )
                .first,
          ),
      ]..sort((a, b) => a.top.compareTo(b.top));
      final lines = <Rect>[];
      for (final t in targets) {
        if (lines.isEmpty || t.top > lines.last.bottom - 1) lines.add(t);
      }
      expect(lines.length, greaterThanOrEqualTo(2));
      for (var i = 1; i < lines.length; i++) {
        // In a Wrap they stood the run spacing (4) apart.
        expect(
          lines[i].top,
          moreOrLessEquals(lines[i - 1].bottom, epsilon: .5),
        );
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }
}

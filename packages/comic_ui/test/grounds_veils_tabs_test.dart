// Grounds, veils and tab bars that read by day and by night:
// - a reply field stands on the night card by night, its cream rim clear of its fill, and on paper by day;
// - a dialog dims the page with a flat veil, not a screen of dots that would cut its words into pieces;
// - at 200% on a phone a crowded tab bar holds its rim and shows the tab past it;
// - disabled faces keep their words legible on a single flat ink tint.
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/src/comic/press.dart'
    show ComicStateDecoration, comicDisabledWordsContrast;

import 'support.dart';

double _contrast(double a, double b) =>
    ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05);

void main() {
  setUpAll(loadComicFonts);

  for (final dark in [false, true]) {
    testWidgets(
      'a reply field ${dark ? 'by night is on the night card' : 'by day is on paper'}',
      (tester) async {
        await tester.pumpWidget(
          comicApp(
            const Padding(
              padding: EdgeInsets.all(16),
              child: ComicTextField(hint: 'Write a reply', onPaper: true),
            ),
            dark: dark,
          ),
        );
        final field = find.byType(ComicTextField);
        final c = ComicTheme.of(tester.element(field)).colors;
        final face = tester.widget<ComicStateDecoration>(
          find
              .descendant(
                of: field,
                matching: find.byType(ComicStateDecoration),
              )
              .first,
        );
        final fill = (face.decoration as ShapeDecoration).color;
        expect(fill, dark ? c.card : c.paper);
        final rim =
            ((face.decoration as ShapeDecoration).shape as OutlinedBorder)
                .side
                .color;
        expect(rim, isNot(fill), reason: 'Its rim shows on its fill');
      },
    );
  }

  for (final dark in [false, true]) {
    testWidgets(
      'a dialog dims the page with a flat veil in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        await tester.pumpWidget(
          comicApp(
            Builder(
              builder: (context) => ComicButton(
                'Open',
                onPressed: () => showComicDialog<void>(
                  context,
                  builder: (_) => const ComicDialog(
                    title: 'Keep this issue?',
                    message: 'Read it again whenever you like.',
                  ),
                ),
              ),
            ),
            dark: dark,
          ),
        );
        final c = ComicTheme.of(tester.element(find.byType(ComicButton)))
            .colors;
        await tester.tap(find.byType(ComicButton));
        await tester.pumpAndSettle();
        final ink = tester
            .widget<ComicScreenScrim>(find.byType(ComicScreenScrim))
            .ink;
        expect(ink, c.scrim);
        expect(ink.r + ink.g + ink.b, 0);
        expect(ink.a, inExclusiveRange(0, 1));
      },
    );
  }

  for (final axis in Axis.values) {
    testWidgets(
      'A fixed tab strip leaves its enclosing ${axis.name} scroll position alone',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final outer = ScrollController();
        addTearDown(outer.dispose);
        final strip = SizedBox(
          width: 280,
          child: ComicTabBar(
            tabs: const ['All', 'Saved', 'Read'],
            selectedIndex: 1,
            onChanged: (_) {},
          ),
        );
        const spacer = SizedBox(width: 800, height: 600);
        await tester.pumpWidget(
          comicApp(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 300,
                height: 160,
                child: SingleChildScrollView(
                  controller: outer,
                  scrollDirection: axis,
                  child: Flex(
                    direction: axis,
                    mainAxisSize: MainAxisSize.min,
                    children: [spacer, strip],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(outer.position.maxScrollExtent, greaterThan(0));
        expect(outer.offset, 0);
      },
    );
  }

  for (final chosen in [0, 2]) {
    testWidgets(
      'at 200% on a phone a crowded tab bar holds its rim and shows the tab past it (chosen $chosen)',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 800);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          comicApp(
            Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ComicTabBar(
                      tabs: const ['All', 'Saved', 'Finished'],
                      selectedIndex: chosen,
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final bar = tester.getRect(find.byType(ComicTabBar));
        expect(bar.left, closeTo(12, .5));
        expect(bar.right, closeTo(378, .5));
        // The rim is drawn at the row's own ends, over the tabs.
        final frame = find
            .descendant(
              of: find.byType(ComicTabBar),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is DecoratedBox &&
                    w.position == DecorationPosition.foreground,
              ),
            )
            .first;
        expect(tester.getRect(frame), bar);
        final first = tester.getRect(find.text('All'));
        final last = tester.getRect(find.text('Finished'));
        if (chosen == 0) {
          expect(first.left, greaterThan(bar.left));
          expect(last.left, lessThan(bar.right), reason: 'The last tab shows');
          expect(last.right, greaterThan(bar.right), reason: 'cut by the rim');
        } else {
          expect(
            last.right,
            lessThan(bar.right),
            reason: 'The chosen tab shows',
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  // Measure the uniform fill and the actual lettering pixels of every disabled ink face.
  for (final preset in ['offset', 'reprint', 'newsstand', 'pulp', 'sunday']) {
    for (final dark in [false, true]) {
      for (final danger in [false, true]) {
        testWidgets(
          'a disabled ${danger ? 'danger' : 'filled'} button in $preset ${dark ? 'by night' : 'by day'} retains flat, legible lettering',
          (tester) async {
            tester.view.devicePixelRatio = 2;
            tester.view.physicalSize = const Size(780, 400);
            addTearDown(tester.view.reset);
            const shot = ValueKey('shot');
            await tester.pumpWidget(
              comicApp(
                Center(
                  child: RepaintBoundary(
                    key: shot,
                    child: ComicButton.filled(
                      'Print the whole issue',
                      isDestructiveAction: danger,
                      size: ComicButtonSize.large,
                    ),
                  ),
                ),
                preset: preset,
                dark: dark,
              ),
            );
            await tester.pumpAndSettle();
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(shot),
            );
            final image = (await tester.runAsync(
              () => boundary.toImage(pixelRatio: 2),
            ))!;
            final data = (await tester.runAsync(
              () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
            ))!;
            final px = data.buffer.asUint8List();
            final width = image.width;
            image.dispose();
            final origin = tester.getTopLeft(find.byKey(shot));
            final face = tester
                .getRect(
                  find
                      .descendant(
                        of: find.byType(ComicButton),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .shift(-origin);
            final words = tester
                .getRect(find.text('PRINT THE WHOLE ISSUE'))
                .shift(-origin);
            // The fill, clear of the rim and the words.
            final fill = <int>{};
            int pixel(int i) => px[i] << 16 | px[i + 1] << 8 | px[i + 2];
            for (var y = face.top + 7; y < face.bottom - 7; y += .5) {
              for (var x = face.left + 7; x < face.right - 7; x += .5) {
                if (words.inflate(3).contains(Offset(x, y))) continue;
                fill.add(
                  pixel(((y * 2).floor() * width + (x * 2).floor()) * 4),
                );
              }
            }
            expect(
              fill,
              hasLength(1),
              reason: 'One flat ground behind the label',
            );
            final ground = Color(0xff000000 | fill.single).computeLuminance();
            var ratio = 1.0;
            for (var y = words.top; y < words.bottom; y += .5) {
              for (var x = words.left; x < words.right; x += .5) {
                final value = pixel(
                  ((y * 2).floor() * width + (x * 2).floor()) * 4,
                );
                final contrast = _contrast(
                  Color(0xff000000 | value).computeLuminance(),
                  ground,
                );
                if (contrast > ratio) ratio = contrast;
              }
            }
            expect(
              ratio,
              greaterThanOrEqualTo(comicDisabledWordsContrast - .03),
            );
          },
        );
      }
    }
  }
}

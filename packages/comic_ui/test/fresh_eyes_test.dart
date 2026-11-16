// Faults the 0.2.0 fresh-eyes read of the ten screens showed (shots of 0cac91b12a), each held here:
// - by night a reply field stood on day paper, its cream rim lost in its fill;
// - by night a modal's screen of black dots on the black ground screened nothing and cut the cream words into pieces;
// - at 200% on a phone a tab bar's rim scrolled off with its last tab, and nothing showed there was one;
// - unavailable was a flat tint of the fill, not the dot screen the look prints every tone and state in.
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/src/comic/press.dart'
    show
        ComicStateDecoration,
        comicDisabledDotPitch,
        comicDisabledDotRadius,
        comicDisabledWordsContrast;

import 'support.dart';

double _contrast(double a, double b) =>
    ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05);

bool _near(List<int> px, int i, Color c, [int by = 8]) =>
    (px[i] - (c.r * 255).round()).abs() <= by &&
    (px[i + 1] - (c.g * 255).round()).abs() <= by &&
    (px[i + 2] - (c.b * 255).round()).abs() <= by;

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
      'a dialog ${dark ? 'by night screens the page in cream' : 'by day screens the page in black'}',
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
        // The page's own ink: black dots knock the paper back by day, cream ones the black ground by night, and
        // neither cuts into words of its own colour.
        expect(
          ink.withValues(alpha: 1),
          dark ? c.nightLine : const Color(0xff000000),
        );
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

  // The coordinator's yes to the fresh-eyes M1: a disabled ink fill is a Ben-Day screen of its own ink on the paper,
  // never a flat tint (a chosen fill is flat) nor dots of the letters' ink (the pointer's shade), and the words, solid
  // in one screened ink, keep 3:1 against the paper and the dots as the eye mixes them, by day and by night.
  for (final preset in ['offset', 'reprint', 'newsstand', 'pulp', 'sunday']) {
    for (final dark in [false, true]) {
      for (final danger in [false, true]) {
        testWidgets(
          'a disabled ${danger ? 'danger' : 'filled'} button in $preset ${dark ? 'by night' : 'by day'} is dots of its '
          'ink on the paper, its words 3:1 on them',
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
            final c = ComicTheme.of(tester.element(find.byType(ComicButton)))
                .colors;
            final ink = danger ? c.tones.danger : c.primary, paper = c.card;
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
            var dots = 0, gaps = 0, letters = 0, all = 0;
            for (var y = face.top + 6; y < face.bottom - 6; y += .5) {
              for (var x = face.left + 6; x < face.right - 6; x += .5) {
                if (words.inflate(3).contains(Offset(x, y))) continue;
                final i = ((y * 2).floor() * width + (x * 2).floor()) * 4;
                all++;
                if (_near(px, i, ink)) dots++;
                if (_near(px, i, paper)) gaps++;
                if (_near(px, i, c.text, 4)) letters++;
              }
            }
            expect(gaps / all, greaterThan(.5), reason: 'Paper between dots');
            expect(dots / all, greaterThan(.06), reason: 'Dots of its ink');
            expect(
              letters / all,
              lessThan(.01),
              reason: "Not the letters' ink",
            );
            // The words' one ink: the commonest colour of the label that is neither paper nor dot.
            final seen = <int, int>{};
            for (var y = words.top; y < words.bottom; y += .5) {
              for (var x = words.left; x < words.right; x += .5) {
                final i = ((y * 2).floor() * width + (x * 2).floor()) * 4;
                if (_near(px, i, ink, 24) || _near(px, i, paper, 24)) continue;
                final key = (px[i] << 16) | (px[i + 1] << 8) | px[i + 2];
                seen[key] = (seen[key] ?? 0) + 1;
              }
            }
            final top = seen.entries.reduce(
              (a, b) => a.value >= b.value ? a : b,
            );
            final w = Color(0xff000000 | top.key).computeLuminance();
            final cover =
                3.14159265 *
                comicDisabledDotRadius *
                comicDisabledDotRadius /
                (comicDisabledDotPitch * comicDisabledDotPitch / 2);
            final mixed =
                cover * ink.computeLuminance() +
                (1 - cover) * paper.computeLuminance();
            expect(
              _contrast(w, paper.computeLuminance()),
              greaterThanOrEqualTo(comicDisabledWordsContrast - .05),
            );
            expect(
              _contrast(w, mixed),
              greaterThanOrEqualTo(comicDisabledWordsContrast - .05),
            );
          },
        );
      }
    }
  }
}

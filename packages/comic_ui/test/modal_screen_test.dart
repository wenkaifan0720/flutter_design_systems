// The page behind a modal is screened in Ben-Day dots: solid dots of the scrim's ink that cover as much of the page as
// the scrim's alpha would darken it. By day that's all, no flat wash, and the dots only darken, so a letter they land on
// stays whole; at night one overprint of the page's ground dims it first, and the dots over it only lighten, so they
// never punch a hole in the lettering behind. The dots stand clear
// of each other, at least a dot's radius of page between neighbours, so the screen reads as dots, never a checker.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadComicFonts);

  for (final dark in const [false, true]) {
    testWidgets(
      'a dialog screens the page in dots (${dark ? 'night' : 'day'})',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          comicApp(
            Builder(
              builder: (context) => Center(
                child: ComicButton(
                  'Sign out',
                  onPressed: () => showComicDialog<void>(
                    context,
                    builder: (_) => const ComicDialog(title: 'Sign out'),
                  ),
                ),
              ),
            ),
            dark: dark,
            width: 1440,
          ),
        );
        final colors = ComicTheme.of(tester.element(find.byType(ComicButton)))
            .colors;
        final ink = colors.scrim;
        await tester.tap(find.byType(ComicButton));
        await tester.pumpAndSettle();
        final scrim = find.byType(ComicScreenScrim);
        expect(scrim, findsOneWidget);
        final dots = <Paint>[];
        final washes = <Color>[];
        final layers = <BlendMode>[];
        expect(
          scrim,
          paints..everything((method, arguments) {
            if (method == #drawRawPoints) dots.add(arguments[2] as Paint);
            if (method == #drawRect &&
                (arguments[1] as Paint).color.a > 0 &&
                (arguments[0] as Rect).width > 1000) {
              washes.add((arguments[1] as Paint).color);
            }
            if (method == #saveLayer) {
              layers.add((arguments[1] as Paint).blendMode);
            }
            return true;
          }),
        );
        if (dark) {
          // One overprint of the ground, then dots that only lighten.
          expect(washes.map((c) => c.toARGB32()), [
            colors.background.withValues(alpha: .65).toARGB32(),
          ]);
          expect(layers, [BlendMode.lighten]);
        } else {
          expect(washes, isEmpty, reason: 'a flat wash over the page');
          expect(layers, [BlendMode.darken]);
        }
        expect(dots, hasLength(1));
        final dot = dots.single;
        // The scrim's ink, opaque (a paint holds its colour in single precision).
        expect(dot.color.toARGB32(), ink.withValues(alpha: 1).toARGB32());
        // Two dots a 6 px pitch square (staggered rows half a pitch apart).
        final radius = dot.strokeWidth / 2;
        final cover = 2 * math.pi * radius * radius / 36;
        expect(cover, closeTo(ink.a, 0.01));
        // Neighbours, on rows half a pitch apart, stand a half diagonal apart.
        final gap = comicScrimPitch / math.sqrt2 - 2 * radius;
        expect(gap, greaterThanOrEqualTo(radius), reason: 'dots run together');
      },
    );
  }
}

// The page behind a modal is screened in Ben-Day dots, not dimmed by a flat wash: solid dots of the scrim's ink that
// cover as much of the page as the scrim's alpha would darken it, by day and by night. The dots stand clear of each
// other, at least a dot's radius of page between neighbours, so the screen reads as dots: never a checker by day, never
// a sieve of the page's light by night.
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
        final ink = ComicTheme.of(tester.element(find.byType(ComicButton)))
            .colors
            .scrim;
        await tester.tap(find.byType(ComicButton));
        await tester.pumpAndSettle();
        final scrim = find.byType(ComicScreenScrim);
        expect(scrim, findsOneWidget);
        final dots = <Paint>[];
        var washes = 0;
        expect(
          scrim,
          paints..everything((method, arguments) {
            if (method == #drawRawPoints) dots.add(arguments[2] as Paint);
            if (method == #drawRect &&
                (arguments[1] as Paint).color.a > 0 &&
                (arguments[0] as Rect).width > 1000) {
              washes++;
            }
            return true;
          }),
        );
        expect(washes, 0, reason: 'a flat wash over the page');
        expect(dots, hasLength(1));
        final dot = dots.single;
        expect(dot.color, ink.withValues(alpha: 1));
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

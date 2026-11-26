// A breadcrumb trail that wraps on a phone starts every run on the trail's keyline, in either direction: a step after
// the first leads with its separator, so a wrapped run starts with the chevron where the first step's words start, and
// no run ends on a chevron.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart' show loadComicFonts;

const _steps = ['Home', 'Garden', 'Seeds', 'Specials', 'Annuals', 'Sweet peas'];

Future<void> _pump(WidgetTester tester, TextDirection direction) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFFFF3E92),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, animation, secondary) => builder(context),
      ),
      builder: (context, navigator) => Directionality(
        textDirection: direction,
        child: ComicTheme(data: ComicThemeData.offset(), child: navigator!),
      ),
      home: Align(
        alignment: AlignmentDirectional.topStart,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ComicBreadcrumb([
            for (final (i, s) in _steps.indexed)
              ComicCrumb(s, onPressed: i == _steps.length - 1 ? null : () {}),
          ]),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadComicFonts);

  for (final direction in TextDirection.values) {
    testWidgets(
      'a wrapped trail starts every run on its keyline, ${direction.name}',
      (tester) async {
        await _pump(tester, direction);
        final rtl = direction == TextDirection.rtl;
        final chevrons = tester
            .widgetList<Icon>(find.byType(Icon))
            .where(
              (i) =>
                  i.icon ==
                  (rtl ? ComicGlyphs.chevronLeft : ComicGlyphs.chevronRight),
            );
        expect(chevrons, hasLength(_steps.length - 1));
        final marks = [
          for (final i in chevrons) tester.getRect(find.byWidget(i)),
        ];
        final words = [for (final s in _steps) tester.getRect(find.text(s))];
        // The start edge in the run's direction: left in ltr, right in rtl, so it grows along a run either way.
        double start(Rect r) => rtl ? -r.right : r.left;
        double end(Rect r) => rtl ? -r.left : r.right;
        final keyline = start(words.first);
        final runs = {for (final w in words) w.center.dy.round()};
        expect(runs.length, greaterThan(1), reason: 'the trail wraps at 390');
        for (var i = 1; i < _steps.length; i++) {
          final mark = marks[i - 1], step = words[i];
          // Its separator leads it, on its run.
          expect(
            mark.center.dy,
            moreOrLessEquals(step.center.dy, epsilon: 1),
            reason: '${_steps[i]}: its chevron on its run',
          );
          expect(
            end(mark),
            lessThanOrEqualTo(start(step)),
            reason: '${_steps[i]}: its chevron before it',
          );
          // A step that starts a run starts it with its chevron on the keyline.
          final first = words
              .where((w) => w.center.dy.round() == step.center.dy.round())
              .reduce((a, b) => start(a) < start(b) ? a : b);
          if (first == step) {
            expect(
              start(mark),
              moreOrLessEquals(keyline, epsilon: .5),
              reason: '${_steps[i]} starts a run',
            );
          }
        }
        // No run ends on a chevron: every chevron has its step after it on its run.
        for (final mark in marks) {
          expect(
            words.any(
              (w) =>
                  (w.center.dy - mark.center.dy).abs() < 1 &&
                  start(w) >= end(mark),
            ),
            isTrue,
            reason: 'a chevron with no step after it on its run',
          );
        }
      },
    );
  }
}

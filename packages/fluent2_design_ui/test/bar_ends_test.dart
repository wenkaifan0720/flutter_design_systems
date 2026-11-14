// A phone's top bar stands its ends on the page's keylines: on a tab's root the avatar's face starts
// where the page's words start and the bell's glyph ends where they end; on
// a pushed page the back arrow's glyph starts there and the last command's
// glyph ends there. Under a finger and with a pointer, from either side;
// every target stays whole on the screen (48 under a finger), and a count
// badge rides the bell's face, not the screen's edge.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

const _width = 390.0;

Widget _screen(RoutePresentation presentation, TextDirection direction) {
  final theme = Fluent2ThemeData.preset('lapis', Brightness.light);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, route) =>
        Fluent2Host(light: theme, brightness: Brightness.light, child: route!),
    home: Directionality(
      textDirection: direction,
      child: Fluent2AccountScope(
        account: Fluent2Account(
          name: 'Ines Duarte',
          initials: 'ID',
          unread: 3,
          onProfile: (_) {},
          onNotifications: (_) {},
        ),
        child: RoutePresentationScope(
          presentation: presentation,
          child: Fluent2Scaffold(
            topBar: Fluent2AppBar(
              title: 'Files',
              actions: [
                Fluent2IconButton(
                  Fluent2Icons.moreHorizontal,
                  label: 'More',
                  onPressed: () {},
                ),
              ],
            ),
            body: const Text('Body words'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.macOS]) {
    for (final presentation in [
      RoutePresentation.root,
      RoutePresentation.pushed,
    ]) {
      for (final direction in TextDirection.values) {
        testWidgets('${platform.name}, ${presentation.name}, '
            '${direction.name}: the bar\'s ends on the page\'s keylines', (
          t,
        ) async {
          addTearDown(t.view.reset);
          t.view.physicalSize = const Size(_width, 844);
          t.view.devicePixelRatio = 1;
          debugDefaultTargetPlatformOverride = platform;
          try {
            await t.pumpWidget(_screen(presentation, direction));
            await t.pumpAndSettle();
            final ltr = direction == TextDirection.ltr;
            final body = t.getRect(find.text('Body words'));
            // The page's keylines: where its words start, and as far in
            // from the other edge.
            final start = ltr ? body.left : body.right;
            final end = ltr ? _width - body.left : _width - body.right;
            double startOf(Rect r) => ltr ? r.left : r.right;
            double endOf(Rect r) => ltr ? r.right : r.left;
            final bar = find.byType(Fluent2AppBar);

            // The start: the avatar's face on a root, the back glyph on a
            // pushed page.
            final Rect first;
            if (presentation == RoutePresentation.root) {
              final avatar = find.descendant(
                of: bar,
                matching: find.byType(Fluent2Avatar),
              );
              first = t.getRect(
                find
                    .descendant(
                      of: avatar,
                      matching: find.byWidgetPredicate(
                        (w) => w is SizedBox && w.width == 32 && w.height == 32,
                      ),
                    )
                    .first,
              );
            } else {
              first = t.getRect(
                find.descendant(
                  of: find.byType(Fluent2Back),
                  matching: find.byType(Icon),
                ),
              );
            }
            expect(
              startOf(first),
              moreOrLessEquals(start, epsilon: .01),
              reason: 'the start part shows at ${startOf(first)}',
            );

            // The end: the bell's glyph on a root, the last command's on a
            // pushed page.
            final last = t.getRect(
              find
                  .descendant(
                    of: presentation == RoutePresentation.root
                        ? find.byType(Fluent2Bell)
                        : find.byWidgetPredicate(
                            (w) => w is Fluent2IconButton && w.label == 'More',
                          ),
                    matching: find.byType(Icon),
                  )
                  .first,
            );
            expect(
              endOf(last),
              moreOrLessEquals(end, epsilon: .01),
              reason: 'the end glyph shows at ${endOf(last)}',
            );

            // Every target whole, on the screen.
            final touch = platform == TargetPlatform.android;
            for (final e
                in find
                    .descendant(
                      of: bar,
                      matching: find.byType(Fluent2Pressable),
                    )
                    .evaluate()) {
              final box = e.renderObject! as RenderBox;
              final r = box.localToGlobal(Offset.zero) & box.size;
              expect(r.left, greaterThanOrEqualTo(0));
              expect(r.right, lessThanOrEqualTo(_width));
              if (touch) {
                expect(r.width, greaterThanOrEqualTo(48));
                expect(r.height, greaterThanOrEqualTo(48));
              }
            }

            // The bell's count rides its face, inside the screen.
            if (presentation == RoutePresentation.root) {
              final count = t.getRect(find.text('3'));
              expect(count.left, greaterThanOrEqualTo(0));
              expect(count.right, lessThanOrEqualTo(_width - 2));
            }
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        });
      }
    }
  }
}

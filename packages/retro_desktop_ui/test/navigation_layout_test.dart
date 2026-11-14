import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

import 'support.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadRetroDesktopFonts();
  });

  for (final width in [390.0, 1440.0]) {
    for (final mode in ['sheet', 'drawer', 'full screen', 'page']) {
      testWidgets(
        '$mode updates its page and returns to its parent at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final navigator = GlobalKey<NavigatorState>();
          late StateSetter update;
          var opened = false;
          var label = 'First content';
          const childKey = ValueKey('route-content');
          await tester.pumpWidget(
            retroDesktopApp(
              StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  final content = SizedBox(
                    key: childKey,
                    height: mode == 'drawer' ? 120 : null,
                    child: Center(child: Text(label)),
                  );
                  return Navigator(
                    key: navigator,
                    onDidRemovePage: (_) => update(() => opened = false),
                    pages: [
                      const RetroDesktopPage<void>(
                        key: ValueKey('root'),
                        child: Center(child: Text('Parent page')),
                      ),
                      if (opened)
                        if (mode == 'page')
                          RetroDesktopPage<void>(
                            key: const ValueKey('detail'),
                            child: content,
                          )
                        else
                          RetroDesktopSheetPage<void>(
                            key: const ValueKey('detail'),
                            drawer: mode == 'drawer',
                            fullScreen: mode == 'full screen',
                            child: content,
                          ),
                    ],
                  );
                },
              ),
            ),
          );
          update(() => opened = true);
          await tester.pumpAndSettle();
          expect(find.text('First content'), findsOneWidget);
          final bounds = tester.getRect(find.byKey(childKey));
          if (mode == 'page' || mode == 'full screen') {
            expect(bounds, Rect.fromLTWH(0, 0, width, 800));
          } else {
            // The content sits inside the sheet face's rim: its stroke, the
            // window step's corner allowance and the bevel's hairline.
            final t = RetroDesktopThemeData.classic();
            final rim =
                t.shapes.large
                    .copyWith(side: BorderSide(width: t.strokes.regular))
                    .dimensions
                    .resolve(TextDirection.ltr)
                    .left +
                t.strokes.hairline;
            final face = tester.getRect(
              find
                  .ancestor(
                    of: find.byKey(childKey),
                    matching: find.byWidgetPredicate(
                      (w) => w.runtimeType.toString() == '_Face',
                    ),
                  )
                  .first,
            );
            expect(face.width, width > 1024 ? 560 : width);
            expect(bounds.width, face.width - 2 * rim);
            expect(
              bounds.height,
              mode == 'drawer' ? 120 : face.height - 2 * rim,
            );
            expect(bounds.center.dx, width / 2);
            expect(bounds.bottom, lessThanOrEqualTo(800));
          }
          final route = ModalRoute.of(tester.element(find.byKey(childKey)))!;
          update(() => label = 'Revised content');
          await tester.pumpAndSettle();
          expect(find.text('First content'), findsNothing);
          expect(find.text('Revised content'), findsOneWidget);
          expect(
            ModalRoute.of(tester.element(find.byKey(childKey))),
            same(route),
            reason: 'Updating a Page preserves its route and local state',
          );
          navigator.currentState!.pop();
          await tester.pumpAndSettle();
          expect(find.text('Parent page'), findsOneWidget);
          expect(opened, isFalse);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('preview presentation and palette changes reach routed content', (
    tester,
  ) async {
    for (final presentation in RetroDesktopPresentation.values) {
      for (final dark in [false, true]) {
        RetroDesktopThemeData? observed;
        await tester.pumpWidget(
          RetroDesktopPreview(
            presentation: presentation,
            brightness: dark ? Brightness.dark : Brightness.light,
            light: RetroDesktopThemeData.lagoon(),
            dark: RetroDesktopThemeData.lagoon(Brightness.dark),
            child: Builder(
              builder: (context) {
                observed = RetroDesktopTheme.of(context);
                return const Center(child: Text('Preview body'));
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Preview body'), findsOneWidget);
        expect(observed!.id, 'lagoon');
        expect(observed!.dark, dark, reason: presentation.name);
        expect(tester.takeException(), isNull);
      }
    }
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'automatic columns retain content and hit targets in $direction',
      (tester) async {
        var taps = 0;
        Widget row(double width, double gap) => retroDesktopApp(
          Center(
            child: SizedBox(
              width: width,
              child: RetroDesktopAutoRow(
                gap: gap,
                children: [
                  GestureDetector(
                    onTap: () => taps++,
                    child: const Text('Short', key: ValueKey('short')),
                  ),
                  const Text(
                    'A longer column that wraps onto several lines',
                    key: ValueKey('long'),
                  ),
                ],
              ),
            ),
          ),
          direction: direction,
        );
        for (final width in [360.0, 200.0]) {
          await tester.pumpWidget(row(width, width == 360 ? 14 : 8));
          final box = tester.renderObject<RenderBox>(
            find.byType(RetroDesktopAutoRow),
          );
          expect(box.getMinIntrinsicWidth(100), greaterThan(0));
          expect(
            box.getMaxIntrinsicWidth(100),
            greaterThanOrEqualTo(box.getMinIntrinsicWidth(100)),
          );
          expect(box.getMinIntrinsicHeight(width), greaterThan(0));
          expect(
            box.getMaxIntrinsicHeight(width),
            box.getMinIntrinsicHeight(width),
          );
          final short = tester.getRect(find.byKey(const ValueKey('short')));
          final long = tester.getRect(find.byKey(const ValueKey('long')));
          final outer = tester.getRect(find.byType(RetroDesktopAutoRow));
          expect(outer.contains(short.center), isTrue);
          expect(outer.contains(long.center), isTrue);
          expect(short.overlaps(long), isFalse);
          expect(
            short.center.dx < long.center.dx,
            direction == TextDirection.ltr,
          );
          await tester.tap(find.byKey(const ValueKey('short')));
          expect(tester.takeException(), isNull);
        }
        expect(taps, 2);
      },
    );

    testWidgets('split wraps, then aligns the bottom edges in $direction', (
      tester,
    ) async {
      for (final width in [120.0, 240.0]) {
        await tester.pumpWidget(
          retroDesktopApp(
            Center(
              child: SizedBox(
                width: width,
                child: RetroDesktopSplit(
                  gap: 14,
                  runGap: 9,
                  bottoms: width == 240,
                  start: const SizedBox(
                    key: ValueKey('start'),
                    width: 90,
                    height: 30,
                  ),
                  end: const SizedBox(
                    key: ValueKey('end'),
                    width: 60,
                    height: 20,
                  ),
                ),
              ),
            ),
            direction: direction,
          ),
        );
        final box = tester.renderObject<RenderBox>(
          find.byType(RetroDesktopSplit),
        );
        expect(box.getMinIntrinsicWidth(100), 90);
        expect(box.getMaxIntrinsicWidth(100), 164);
        expect(box.getMinIntrinsicHeight(width), 50);
        expect(box.getMaxIntrinsicHeight(width), 50);
        final start = tester.getRect(find.byKey(const ValueKey('start')));
        final end = tester.getRect(find.byKey(const ValueKey('end')));
        if (width == 120) {
          expect(end.top, start.bottom + 9);
        } else {
          expect(end.bottom, start.bottom);
          expect(
            start.center.dx < end.center.dx,
            direction == TextDirection.ltr,
          );
        }
        expect(tester.takeException(), isNull);
      }
    });
  }
}

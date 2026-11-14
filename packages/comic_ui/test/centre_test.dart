// Text sits centred in its box, on a desktop and a phone. Line boxes, measured from the layout; the glyphs themselves are
// compared with the concept's by tools/compare.py (baseline to baseline).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  Future<void> pump(WidgetTester tester, double width, Widget child) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      comicApp(
        Center(
          child: SizedBox(width: width - 40, child: child),
        ),
      ),
    );
    await tester.pump();
  }

  void centred(
    WidgetTester tester,
    Finder box,
    Finder text, {
    double tolerance = 1,
  }) {
    final b = tester.getRect(box), t = tester.getRect(text);
    expect(
      (b.center.dy - t.center.dy).abs(),
      lessThanOrEqualTo(tolerance),
      reason: 'box $b, text $t',
    );
  }

  for (final width in [390.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      for (final density in [
        ComicDensity.standard,
        ComicDensity.compact,
        ComicDensity.comfortable,
      ]) {
        for (final kind in ['outlined', 'quiet', 'danger']) {
          testWidgets(
            'mixed $kind actions share height and label centre / $width / $brightness / ${density.vertical}',
            (tester) async {
              const first = ValueKey('first-action'),
                  second = ValueKey('second-action');
              await pump(
                tester,
                width,
                ComicTheme(
                  data: ComicThemeData.offset(brightness)
                      .copyWith(density: density),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      switch (kind) {
                        'outlined' => ComicButton(
                          'Cancel',
                          key: first,
                          onPressed: () {},
                        ),
                        'quiet' => ComicButton.text(
                          'Cancel',
                          key: first,
                          onPressed: () {},
                        ),
                        _ => ComicButton(
                          'Cancel',
                          isDestructiveAction: true,
                          icon: ComicGlyphs.trash2,
                          key: first,
                          onPressed: () {},
                        ),
                      },
                      const SizedBox(width: 8),
                      ComicButton.filled(
                        'Keep them',
                        key: second,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              );
              await tester.pumpAndSettle();
              expect(
                tester.getSize(find.byKey(first)).height,
                closeTo(tester.getSize(find.byKey(second)).height, .01),
              );
              expect(
                tester.getCenter(find.text('CANCEL')).dy,
                closeTo(tester.getCenter(find.text('KEEP THEM')).dy, .01),
              );
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }

  for (final width in [390.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'list action fits or stacks / $width / $direction / $scale',
          (tester) async {
            await pump(
              tester,
              width,
              Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: Directionality(
                    textDirection: direction,
                    child: ComicListTile(
                      title: 'Alex Morgan',
                      subtitle: 'Project owner',
                      leading: const ComicAvatar('AM'),
                      action: ComicIconButton(
                        ComicGlyphs.more,
                        label: 'Options',
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final action = tester.getRect(
              find
                  .descendant(
                    of: find.byType(ComicIconButton),
                    matching: find.byType(ComicPressable),
                  )
                  .first,
            );
            final title = tester.getRect(find.text('Alex Morgan'));
            final meta = tester.getRect(find.text('Project owner'));
            if (width == 390 && scale == 2) {
              expect(action.top, greaterThan(meta.bottom));
            } else {
              // To half a pixel: the title's DesignCapCenter keeps room round it to put its capitals on its middle,
              // so the words' painted block stands up to 0.2 px off the row's centre, where the action stands.
              expect(
                action.center.dy,
                closeTo((title.top + meta.bottom) / 2, .5),
              );
              if (direction == TextDirection.ltr) {
                expect(action.left, greaterThan(title.right));
              } else {
                expect(action.right, lessThan(title.left));
              }
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final w in const [390.0, 1440.0]) {
    testWidgets('act button @$w', (tester) async {
      await pump(tester, w, ComicButton.filled('Pay now', onPressed: () {}));
      centred(
        tester,
        find.byWidgetPredicate((w) => '${w.runtimeType}' == '_Filled'),
        find.text('PAY NOW'),
        tolerance: 2,
      );
    });
    testWidgets('line button @$w', (tester) async {
      await pump(tester, w, ComicButton('Back', onPressed: () {}));
      centred(
        tester,
        find.byWidgetPredicate((w) => '${w.runtimeType}' == '_Outlined'),
        find.text('BACK'),
      );
    });
    testWidgets('chip @$w', (tester) async {
      await pump(tester, w, const ComicChip('Taxi'));
      centred(tester, find.byType(ComicChip), find.text('Taxi'));
    });
    testWidgets('select field @$w', (tester) async {
      await pump(tester, w, const ComicSelectField(value: 'Current ··3108'));
      centred(
        tester,
        find.byType(ComicSelectField),
        find.text('Current ··3108'),
      );
    });
    testWidgets('field, with InputDecoration, on standard density @$w', (
      tester,
    ) async {
      await pump(tester, w, const ComicTextField(initialValue: 'Pepper'));
      centred(tester, find.byType(ComicTextField), find.byType(EditableText));
      final theme = Theme.of(tester.element(find.byType(InputDecorator)));
      expect(theme.visualDensity, VisualDensity.standard);
    });
    testWidgets('person @$w', (tester) async {
      await pump(tester, w, const ComicPerson(initials: 'AC'));
      centred(
        tester,
        find.byType(ComicPerson),
        find.text('AC'),
        tolerance: 1.5,
      );
    });
    testWidgets('tag @$w', (tester) async {
      await pump(tester, w, const ComicTag('Fish'));
      centred(tester, find.byType(ComicTag), find.text('FISH'), tolerance: 1.5);
    });
  }
}

// What a careful eye measured on the example's crops: a neutral tag stands
// as tall as a toned one (its hairline inside its edge, not round it), a
// select row's glyph ends its ink on the row's end keyline as a row's
// chevron does, and the example's form rows stand hairline to hairline.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:minimal_ui/minimal_ui.dart';

// The example app is the adopter's copy, tested where it stands.
// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';

Widget _page(Widget body, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: MinimalHost(brightness: Brightness.light, child: app!),
      ),
      home: MinimalScaffold(body: body),
    );

Finder _glyph(IconData icon) =>
    find.byWidgetPredicate((w) => w is MinimalIcon && w.icon == icon);

void main() {
  testWidgets('a neutral tag stands as tall and as tight as a toned one', (
    tester,
  ) async {
    await tester.pumpWidget(
      _page(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MinimalTag('Want to read'),
            MinimalTag('Want to read', tone: MinimalTone.primary),
          ],
        ),
      ),
    );
    final neutral = tester.getSize(find.byType(MinimalTag).at(0));
    final toned = tester.getSize(find.byType(MinimalTag).at(1));
    expect(neutral, toned);
  });

  for (final direction in TextDirection.values) {
    for (final (presentation, icon, bearing) in [
      (MinimalSelectPresentation.menu, LucideIcons.chevronsUpDown, 6 / 24),
      (MinimalSelectPresentation.sheet, LucideIcons.chevronRightDir, 8 / 24),
    ]) {
      testWidgets(
        "a ${presentation.name} select row's glyph ends its ink on the "
        "row's end keyline (${direction.name})",
        (tester) async {
          await tester.pumpWidget(
            _page(
              MinimalSelect<String>(
                labelText: 'Status',
                value: 'a',
                presentation: presentation,
                options: const [
                  MinimalSelectOption('a', 'Want to read'),
                  MinimalSelectOption('b', 'Reading'),
                ],
                onChanged: (_) {},
              ),
              direction: direction,
            ),
          );
          final row = tester.getRect(find.byType(MinimalSelect<String>));
          final glyph = tester.getRect(_glyph(icon));
          final bare = glyph.width * bearing;
          if (direction == TextDirection.ltr) {
            expect(glyph.right - bare, moreOrLessEquals(row.right));
          } else {
            expect(glyph.left + bare, moreOrLessEquals(row.left));
          }
        },
      );
    }
  }

  for (final width in const [390.0, 1440.0]) {
    testWidgets(
      'the form rows stand hairline to hairline (${width.toInt()})',
      (tester) async {
        tester.view
          ..physicalSize = Size(width, 900)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(ShelfApp());
        await tester.pumpAndSettle();
        final add = find.byWidgetPredicate(
          (w) => w is MinimalIconButton && w.semanticLabel == 'Add a book',
        );
        await tester.tap(add.first);
        await tester.pumpAndSettle();
        final status = tester.getRect(
          find.byWidgetPredicate((w) => w is MinimalSelect),
        );
        final started = tester.getRect(
          find.byWidgetPredicate((w) => w is MinimalDatePicker),
        );
        // The Started row's top rule is the Status row's foot: its words stand
        // midway between the two rules.
        expect(started.top, status.bottom);
        // The example's library lives as long as the app, as an app's model
        // does: it is never disposed.
      },
      experimentalLeakTesting: LeakTesting.settings.withIgnored(
        notDisposed: {'Library': null},
      ),
    );
  }
}

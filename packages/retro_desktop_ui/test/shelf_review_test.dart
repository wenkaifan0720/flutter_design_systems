// What the example's review caught (Shelf at 390 and 1440): a date field in a form's column stands as tall as the text
// fields above it, by finger and by pointer; a page bar's way back stands clear of its title; a page's footer puts its
// buttons at its end on a phone as on a desk, as a dialog's.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final width in const [390.0, 1440.0]) {
    testWidgets(
      'at ${width.toInt()} a date field is as tall as the text field above it',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          retroDesktopApp(
            width: width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const RetroDesktopTextField(labelText: 'Title'),
                RetroDesktopDateField(
                  labelText: 'Started',
                  value: null,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(RetroDesktopDateField)).height,
          tester.getSize(find.byType(RetroDesktopTextField)).height,
          reason: Theme.of(tester.element(find.byType(RetroDesktopDateField)))
              .platform
              .name,
        );
      },
      variant: TargetPlatformVariant.only(
        width < 600 ? TargetPlatform.android : TargetPlatform.macOS,
      ),
    );

    for (final direction in TextDirection.values) {
      testWidgets(
        'at ${width.toInt()} ${direction.name} a page bar\'s way back stands clear of its title',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 900);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            retroDesktopApp(
              width: width,
              direction: direction,
              RetroDesktopAppBar(
                title: 'Piranesi',
                leading: RetroDesktopBackButton(onPressed: () {}),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final back = tester.getRect(find.byType(RetroDesktopBackButton));
          final title = tester.getRect(find.text('Piranesi'));
          final gap = direction == TextDirection.ltr
              ? title.left - back.right
              : back.left - title.right;
          expect(gap, greaterThanOrEqualTo(RetroDesktopSpacing.s8));
        },
      );

      testWidgets(
        'at ${width.toInt()} ${direction.name} a page\'s footer puts its button at its end',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 900);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            retroDesktopApp(
              width: width,
              direction: direction,
              RetroDesktopScaffold(
                appBar: const RetroDesktopAppBar(title: 'Add a book'),
                body: const Text('A form'),
                footer: RetroDesktopButton('Save', onPressed: () {}),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final save = tester.getCenter(find.text('Save'));
          final page = tester.getRect(find.text('A form'));
          // The end of the page's column: its window's end on a desk, the screen's on a phone.
          expect(
            direction == TextDirection.ltr
                ? save.dx > page.left + width / 4
                : save.dx < page.right - width / 4,
            isTrue,
            reason:
                'Save at ${save.dx}, the page from ${page.left} to ${page.right}',
          );
        },
      );
    }
  }
}

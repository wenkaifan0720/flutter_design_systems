// The public example uses the same full-screen presenter as applications.
// ignore_for_file: avoid_relative_lib_imports
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../example/lib/kit_gallery/demos/ordinary.dart';

import 'support.dart';

void main() {
  setUpAll(loadRetroDesktopFonts);
  for (final dark in [false, true]) {
    for (final width in [390.0, 1440.0]) {
      testWidgets('ordinary modal covers the desktop: $width dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          kitOrdinaryScreen(
            'dialog',
            dark ? Brightness.dark : Brightness.light,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RetroDesktopDialog), findsOneWidget);
        expect(
          tester.getRect(find.byType(ModalBarrier).last),
          Rect.fromLTWH(0, 0, width, 900),
        );
        expect(
          find.descendant(
            of: find.byType(RetroDesktopWindow),
            matching: find.byType(RetroDesktopDialog),
          ),
          findsNothing,
        );
        expect(find.text('Retro Desktop'), findsOneWidget);
        await tester.tap(find.text('Keep editing'));
        await tester.pumpAndSettle();
        expect(find.byType(RetroDesktopDialog), findsNothing);
        expect(find.text('Back to your document'), findsOneWidget);
        await tester.tap(find.text('Open dialog'));
        await tester.pumpAndSettle();
        expect(find.byType(RetroDesktopDialog), findsOneWidget);
        await tester.tap(find.text('Save changes'));
        await tester.pumpAndSettle();
        expect(find.text('Document saved'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
    for (final direction in TextDirection.values) {
      testWidgets(
        'switch preserves its track and lever: dark=$dark $direction',
        (tester) async {
          var value = false;
          await tester.pumpWidget(
            retroDesktopApp(
              StatefulBuilder(
                builder: (context, change) => RetroDesktopSwitch(
                  label: 'Notifications',
                  value: value,
                  onChanged: (next) => change(() => value = next),
                ),
              ),
              dark: dark,
              direction: direction,
            ),
          );
          await tester.pumpAndSettle();
          // The lever is a raised face of its own inside the sliding align.
          final lever = find
              .descendant(
                of: find.byType(AnimatedAlign),
                matching: find.byWidgetPredicate(
                  (w) => w.runtimeType.toString() == '_Face',
                ),
              )
              .first;
          // What the lever wears: its gradient, flat face and fill.
          Object? leverLook() {
            final face = tester.widget(lever) as dynamic;
            final fill = (face.component as RetroDesktopStyle).fill;
            return (face.gradient, face.flat, fill?.resolve(const {}));
          }

          final track = find
              .descendant(
                of: find.byType(RetroDesktopSwitch),
                matching: find.byWidgetPredicate(
                  (w) => w.runtimeType.toString() == '_Face',
                ),
              )
              .first;
          final offLook = leverLook();
          final offSize = tester.getSize(lever);
          final offX = tester.getCenter(lever).dx;
          expect(tester.getSize(track), const Size(48, 28));
          await tester.tap(find.byType(RetroDesktopSwitch));
          await tester.pumpAndSettle();
          expect(value, isTrue);
          expect(tester.getSize(track), const Size(48, 28));
          expect(tester.getSize(lever), offSize);
          expect(leverLook(), offLook);
          expect(
            tester.getCenter(lever).dx,
            direction == TextDirection.ltr ? greaterThan(offX) : lessThan(offX),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets(
      'card heading leads body; phone type remains legible dark=$dark',
      (tester) async {
        await tester.pumpWidget(
          retroDesktopApp(
            const RetroDesktopCard(
              title: 'Website refresh',
              child: Text('Design and content'),
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        final heading = tester
            .widget<Text>(find.text('Website refresh'))
            .style!;
        final body = DefaultTextStyle.of(
          tester.element(find.text('Design and content')),
        ).style;
        final theme = RetroDesktopTheme.of(
          tester.element(find.byType(RetroDesktopCard)),
        );
        expect(heading.fontSize!, greaterThan(body.fontSize!));
        expect(body.fontSize, greaterThanOrEqualTo(16));
        expect(theme.type.chrome.fontSize, greaterThanOrEqualTo(20));
        expect(theme.type.caption.fontSize, greaterThanOrEqualTo(14));
        expect(theme.type.meta.fontSize, greaterThanOrEqualTo(14));
        expect(
          tester.getTopLeft(find.text('Website refresh')).dx,
          tester.getTopLeft(find.text('Design and content')).dx,
        );
        expect(find.byType(RetroDesktopWindow), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

// ignore_for_file: avoid_relative_lib_imports
// The example's three apps, each filling the window.
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import '../example/lib/kit_gallery/apps/app_frame.dart';
import '../example/lib/gallery.dart';
import 'flutter_test_config.dart' show longWalkLeakTesting;

void main() {
  // The apps fill the window and lay themselves out for it: the bar on a
  // phone, the rail on a tablet, the sidebar on a
  // laptop; the content spans the body; nothing overflows; nothing a person
  // reads is under 11 px; no card stands in a card.
  group('the apps', () {
    const phone = Size(390, 844);
    const tablet = Size(768, 1024);
    const laptop = Size(1440, 900);

    Future<void> openApp(
      WidgetTester tester,
      String slug,
      Size size, {
      Brightness brightness = Brightness.light,
    }) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final dark = brightness == Brightness.dark ? '&appearance=dark' : '';
      // A fresh start: the same app type pumped again would keep its State,
      // and with it the page the last open left.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        GalleryApp.at(Uri.parse('http://localhost/?app=$slug$dark')),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    /// Every font size set on a span on screen, with its text.
    List<String> small(WidgetTester tester) {
      final found = <String>[];
      for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
        final scale = text.textScaler.scale(1);
        void check(InlineSpan span, double? inherited) {
          final size = span.style?.fontSize ?? inherited;
          if (span is TextSpan) {
            final words = span.text ?? '';
            if (size != null && size * scale < 11 && words.trim().isNotEmpty) {
              found.add('"$words" at ${size * scale}');
            }
            for (final child in span.children ?? const <InlineSpan>[]) {
              check(child, size);
            }
          }
        }

        check(text.text, null);
      }
      return found;
    }

    // Each app at each width, by day and by night. The everyday tier opens
    // each app once, the first on a phone by day, the next on a tablet by
    // night, the third on a laptop by day; the sweep tier the rest.
    for (final (a, app) in exampleApps.indexed) {
      for (final (s, size) in const [phone, tablet, laptop].indexed) {
        for (final brightness in Brightness.values) {
          final everyday =
              s == a % 3 &&
              brightness == (a.isEven ? Brightness.light : Brightness.dark);
          testWidgets(
            '${app.name} at ${size.width.round()}, ${brightness.name}',
            tags: everyday ? null : 'sweep',
            experimentalLeakTesting: longWalkLeakTesting,
            (tester) async {
              await openApp(tester, app.slug, size, brightness: brightness);
              expect(
                find.byType(MinimalNavigationBar),
                size == phone ? findsOneWidget : findsNothing,
              );
              expect(
                find.byType(MinimalNavigationRail),
                size == tablet ? findsOneWidget : findsNothing,
              );
              expect(
                find.byType(MinimalNavigationDrawer),
                size == laptop ? findsOneWidget : findsNothing,
              );
              // The pages reach the window's end edge: no stranded column.
              final ends = [
                for (final e in find.byType(MinimalScaffold).evaluate())
                  tester.getRect(find.byWidget(e.widget)).right,
              ];
              expect(ends, isNotEmpty);
              expect(ends.reduce((a, b) => a > b ? a : b), size.width);
              expect(small(tester), isEmpty, reason: 'text under 11 px');
              expect(
                find.descendant(
                  of: find.byType(MinimalCard),
                  matching: find.byType(MinimalCard),
                ),
                findsNothing,
                reason: 'a card in a card',
              );
            },
          );
        }
      }
    }

    // Every mark on Today presses (a paused habit's resumes it), so each
    // lays out the same tap target and the titles keep one keyline.
    testWidgets('Today\'s titles share one keyline, the paused one too', (
      tester,
    ) async {
      await openApp(tester, 'habits', phone);
      final start = tester.getTopLeft(find.text('Meditate')).dx;
      expect(
        tester.getTopLeft(find.text('Water the plants')).dx,
        closeTo(start, 0.01),
      );
      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text('Water the plants'),
            matching: find.byType(MinimalListTile),
          ),
          matching: find.byType(MinimalStatusIcon),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Water the plants resumed'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Paused'), findsWidgets);
    });

    testWidgets('Ritual runs its happy path, every change undone', (
      tester,
    ) async {
      await openApp(tester, 'habits', phone);
      // Create: the sheet's primary action sits in its footer, at the
      // bottom of a phone.
      await tester.tap(find.bySemanticsLabel('New habit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, 'Stretch');
      await tester.pump();
      final create = find.text('Create habit');
      expect(tester.getRect(create).bottom, greaterThan(phone.height - 120));
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(find.text('Stretch'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Stretch'), findsNothing);

      // Open a habit, pause it from its menu, undo.
      await tester.tap(find.text('Morning run'));
      await tester.pumpAndSettle();
      // The pushed bar prints the trail, `Today / HAB-4`, as one line.
      expect(find.textContaining('HAB-4'), findsOneWidget);
      expect(find.byType(MinimalNavigationBar), findsNothing);
      await tester.tap(find.bySemanticsLabel('Habit actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pause'));
      await tester.pumpAndSettle();
      expect(find.text('Paused'), findsWidgets);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Active'), findsOneWidget);

      // Archive asks first, then leaves the list, undoable.
      await tester.tap(find.bySemanticsLabel('Habit actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(find.text('Archive Morning run?'), findsOneWidget);
      await tester.tap(find.text('Archive').last);
      await tester.pumpAndSettle();
      expect(find.text('Morning run'), findsNothing);
      expect(find.byType(MinimalNavigationBar), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Morning run'), findsOneWidget);
      // Let the last toast's time run out.
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
    });

    // At each width: the everyday tier on a phone, the sweep tier the rest.
    for (final (s, size) in const [phone, tablet, laptop].indexed) {
      testWidgets(
        'the Gallery control leads back at '
        '${size.width.round()}',
        (tester) async {
          await openApp(tester, 'orders', size);
          final gallery = find.byType(KitGalleryButton);
          final at = 'at ${size.width.round()}';
          expect(gallery, findsOneWidget, reason: 'no Gallery control $at');
          // A screen reader finds it, by its name, at every width.
          expect(
            find.bySemanticsLabel('Gallery'),
            findsOneWidget,
            reason: 'no Gallery for a screen reader $at',
          );
          await tester.tap(gallery);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Back to the gallery'));
          await tester.pumpAndSettle();
          // Back in the gallery: no app with a way out (a wide Overview shows
          // Ritual live in its window, with none).
          expect(
            find.byWidgetPredicate((w) => w is KitApp && w.gallery != null),
            findsNothing,
            reason: 'still in the app $at',
          );
          expect(find.text('Minimal'), findsWidgets);
        },
        tags: s == 0 ? null : 'sweep',
        experimentalLeakTesting: longWalkLeakTesting,
      );
    }

    // The apps are apps on Flutter's own Material, whose page routes read
    // the app's theme: the example gives it Minimal's motion, so a drill-in
    // never takes the platform's slide or zoom (on the web a look's pages
    // once flew in).
    // Every platform at both widths: the everyday tier Android on a phone
    // and macOS on a laptop, the sweep tier the rest.
    for (final platform in TargetPlatform.values) {
      for (final size in const [phone, laptop]) {
        final everyday =
            (platform == TargetPlatform.android && size == phone) ||
            (platform == TargetPlatform.macOS && size == laptop);
        testWidgets(
          'a drill-in fades in Minimal\'s few pixels on '
          '${platform.name} at ${size.width.round()}',
          (tester) async {
            debugDefaultTargetPlatformOverride = platform;
            // Unset before the test ends, pass or fail: the binding checks
            // it before tear-downs.
            try {
              final why = '$platform at ${size.width.round()}';
              tester.view
                ..physicalSize = size
                ..devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              await tester.pumpWidget(const SizedBox());
              await tester.pumpWidget(
                GalleryApp.at(
                  Uri.parse('http://localhost/?app=habits&screen=habits'),
                ),
              );
              await tester.pumpAndSettle();
              // The Habits tab's row (Today, kept in its stack, lists it too).
              await tester.tap(find.text('Meditate').last);
              await tester.pump();
              await tester.pump(MinimalChromeMetrics.push ~/ 2);
              final words = find.text('Ten minutes, before the phone.').last;
              final mid = tester.getTopLeft(words);
              await tester.pumpAndSettle();
              final end = tester.getTopLeft(words);
              expect(mid.dy, end.dy, reason: why);
              expect(
                (mid.dx - end.dx).abs(),
                lessThanOrEqualTo(MinimalChromeMetrics.pushSlide),
                reason: why,
              );
            } finally {
              debugDefaultTargetPlatformOverride = null;
            }
          },
          tags: everyday ? null : 'sweep',
          experimentalLeakTesting: longWalkLeakTesting,
        );
      }
    }
  });
}

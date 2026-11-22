// Each platform's own way back, under the look's page change: on iOS the edge swipe pops a page (a page change of its
// own can drop the swipe Flutter's Cupertino slide carries); on Android, system back closes what is open over a page
// (a dialog, a sheet, a select's list, a menu bar's menu) before it pops the page; on a desk, Tab reaches every button
// and field of Papers, the look's own application, in each of its windows.
// ignore_for_file: avoid_relative_lib_imports — the example app's pages are what this test checks; example/ is not a dependency of the package.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../example/lib/kit_gallery/demos/papers.dart';

// A first page whose 'Open' pushes the second by [push]; the look's page change in the app's theme.
Widget _app(
  Route<void> Function(WidgetBuilder page) push,
  WidgetBuilder second,
) => MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: retroDesktopPageTransitions,
    ),
  ),
  builder: (context, child) =>
      RetroDesktopTheme(data: RetroDesktopThemeData.classic(), child: child!),
  home: Builder(
    builder: (context) => ColoredBox(
      color: const Color(0xFFDDDDDD),
      child: Center(
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(push(second)),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

Widget _plainSecond(BuildContext context) => const ColoredBox(
  color: Color(0xFFFFFFFF),
  child: Center(child: Text('Second')),
);

final _routes = <String, Route<void> Function(WidgetBuilder)>{
  'MaterialPageRoute': (page) => MaterialPageRoute<void>(builder: page),
  'RetroDesktopPageRoute': (page) => RetroDesktopPageRoute<void>(builder: page),
};

void main() {
  for (final MapEntry(key: kind, value: push) in _routes.entries) {
    testWidgets(
      'on iOS, the edge swipe pops a page pushed with $kind',
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      (tester) async {
        await tester.pumpWidget(_app(push, _plainSecond));
        await tester.tap(find.text('Open'));
        await tester.pump();
        expect(
          find.text('Second'),
          findsOneWidget,
          reason: 'in place in the first frame',
        );
        await tester.pumpAndSettle();

        // A drag that starts in the page, not at its edge, is the page's own.
        await tester.dragFrom(const Offset(200, 300), const Offset(500, 0));
        await tester.pumpAndSettle();
        expect(find.text('Second'), findsOneWidget);

        await tester.dragFrom(const Offset(4, 300), const Offset(500, 0));
        await tester.pumpAndSettle();
        expect(
          find.text('Second'),
          findsNothing,
          reason: 'the edge swipe pops it',
        );
        expect(find.text('Open'), findsOneWidget);

        // Pushed again, a pop by the app stands in place again: the swipe left no slide behind.
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.text('Second'))).pop();
        await tester.pump();
        expect(
          find.text('Second'),
          findsNothing,
          reason: 'gone in the first frame',
        );
        expect(find.text('Open'), findsOneWidget);
        expect(tester.hasRunningAnimations, isFalse, reason: 'nothing slides');
      },
    );
  }

  testWidgets(
    'on Android, back closes a dialog, a sheet, a select\'s list and '
    'a menu bar\'s menu before it pops the page',
    variant: TargetPlatformVariant.only(TargetPlatform.android),
    (tester) async {
      Widget second(BuildContext context) => ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RetroDesktopMenuBar(
                  menus: [
                    RawMenuEntry(
                      label: 'File',
                      children: [RawMenuEntry(label: 'New', onPressed: () {})],
                    ),
                  ],
                ),
                const Text('Second'),
                Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => showRetroDesktopDialog<void>(
                      context,
                      builder: (_) => const RetroDesktopDialog(
                        title: 'An alert',
                        message: 'Alert words',
                      ),
                    ),
                    child: const Text('Alert'),
                  ),
                ),
                Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => showRetroDesktopBottomSheet<void>(
                      context,
                      builder: (_) => const Text('Sheet words'),
                    ),
                    child: const Text('Sheet'),
                  ),
                ),
                RetroDesktopSelect<String>(
                  label: 'Save to',
                  value: 'disk',
                  options: const [
                    RetroDesktopOption('computer', 'This computer'),
                    RetroDesktopOption('disk', 'The shared disk'),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      Future<void> back() async {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(_app(_routes['RetroDesktopPageRoute']!, second));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alert'));
      await tester.pumpAndSettle();
      expect(find.text('Alert words'), findsOneWidget);
      await back();
      expect(
        find.text('Alert words'),
        findsNothing,
        reason: 'back closes the alert',
      );
      expect(find.text('Second'), findsOneWidget, reason: 'and only the alert');

      await tester.tap(find.text('Sheet'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet words'), findsOneWidget);
      await back();
      expect(
        find.text('Sheet words'),
        findsNothing,
        reason: 'back closes the sheet',
      );
      expect(find.text('Second'), findsOneWidget);

      await tester.tap(find.text('The shared disk'));
      await tester.pumpAndSettle();
      expect(find.text('This computer'), findsOneWidget);
      await back();
      expect(
        find.text('This computer'),
        findsNothing,
        reason: 'back closes the list',
      );
      expect(find.text('Second'), findsOneWidget);

      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();
      expect(find.text('New'), findsOneWidget);
      await back();
      expect(find.text('New'), findsNothing, reason: 'back closes the menu');
      expect(
        find.text('Second'),
        findsOneWidget,
        reason: 'and leaves the page',
      );

      await back();
      expect(
        find.text('Second'),
        findsNothing,
        reason: 'then back pops the page',
      );
      expect(find.text('Open'), findsOneWidget);
    },
  );

  // A desk: Tab goes round every button and field Papers shows, in front and behind, as a keyboard user needs. A list,
  // a menu bar and a group of radios are one stop each, their arrows going within (their own tests).
  for (final front in [
    KitPapersWindow.documents,
    KitPapersWindow.document,
    KitPapersWindow.details,
    KitPapersWindow.settings,
    KitPapersWindow.prints,
    KitPapersWindow.bin,
  ]) {
    testWidgets(
      'on a desk, Tab reaches every button and field: ${front.name} in front',
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
      (tester) async {
        tester.view
          ..physicalSize = const Size(1440, 900)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final base = RetroDesktopThemeData.preset('classic', Brightness.light);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => RetroDesktopTheme(
              data: base.atWidth(MediaQuery.sizeOf(context).width),
              child: child!,
            ),
            home: KitPapers(front: front),
          ),
        );
        await tester.pumpAndSettle();
        final reached = <Element>{};
        for (var i = 0; i < 80; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          final at = FocusManager.instance.primaryFocus?.context;
          if (at is Element) reached.add(at);
        }
        bool under(Element part) => reached.any((r) {
          if (r == part) return true;
          var found = false;
          r.visitAncestorElements((a) => !(found = a == part));
          return found;
        });
        final missed = [
          for (final e in find.byType(RetroDesktopButton).evaluate())
            if ((e.widget as RetroDesktopButton).onPressed != null && !under(e))
              'button "${(e.widget as RetroDesktopButton).label}"',
          for (final e in find.byType(EditableText).evaluate())
            if (!under(e))
              'field "${(e.widget as EditableText).controller.text}"',
        ];
        expect(missed, isEmpty);
        expect(reached.length, greaterThan(1));
      },
    );
  }
}

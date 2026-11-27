// ui_core_test's node checks on Retro Desktop: every control a screen shows keeps a node a screen reader reaches, each
// field's controls take their own taps and its label is read once, and the app's places stay in the semantics tree
// beside a pushed page. On the example app (Shelf) at a phone's, a tablet's and a desk's width, and on every gallery
// page by day and by night.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'support.dart';

List<String> _problems(BuildContext context) => [
  ...const DesignControlNodesCheck(look: 'Retro Desktop')
      .check(context)
      .problems,
  ...const DesignFieldSemanticsCheck(look: 'Retro Desktop')
      .check(context)
      .problems,
];

void _nodes(WidgetTester tester, String where) {
  final failed = _problems(tester.element(find.byType(ShelfApp)));
  expect(failed, isEmpty, reason: '$where:\n${failed.join('\n')}');
}

Future<void> _goTo(WidgetTester tester, String place) async {
  await tester.tap(find.bySemanticsLabel(RegExp('^$place')).first);
  await settle(tester);
}

void main() {
  setUpAll(() async {
    await loadRetroDesktopFonts();
    await loadBundledFonts();
  });

  for (final width in const [390.0, 800.0, 1440.0]) {
    testWidgets(
      "Shelf at $width: each screen's controls and fields, and the places beside a page",
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(const ShelfApp());
          await settle(tester);
          _nodes(tester, 'Books');
          await tester.tap(find.text('Piranesi'));
          await settle(tester);
          _nodes(tester, 'a book');
          // On a phone the strip steps away from a pushed page (back pops it); the menu bar stays on a desk.
          if (RetroDesktopAppShell.modeFor(width) != RawNavigationMode.bar) {
            const DesignNavigationCheck(look: 'Retro Desktop')
                .check(
                  tester.element(find.byType(ShelfApp)),
                  destinations: ['Books', 'Add a book', 'Settings'],
                )
                .verify();
          }
          await tester.tap(find.bySemanticsLabel('Back'));
          await settle(tester);
          await _goTo(tester, 'Add a book');
          await tester.tap(find.text('Save'));
          await settle(tester);
          _nodes(tester, 'the form with its errors');
          await _goTo(tester, 'Settings');
          _nodes(tester, 'Settings');
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  for (final page in galleryPages) {
    for (final brightness in Brightness.values) {
      testWidgets(
        "the ${page.id} page by ${brightness == Brightness.light ? 'day' : 'night'}: its controls and fields",
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await pumpGalleryPage(tester, page, 'classic', brightness);
            final failed = _problems(
              tester.element(find.byType(Directionality).first),
            );
            expect(failed, isEmpty, reason: failed.join('\n'));
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}

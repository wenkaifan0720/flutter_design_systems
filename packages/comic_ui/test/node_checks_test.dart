// ui_core_test 0.6.0's node checks on Comic, the round's proof: every control a screen shows keeps a node a screen
// reader reaches, each field's controls take their own taps and its label is read once, and the app's places stay in
// the semantics tree beside a pushed page. On the example app (Shelf) at a phone's, a tablet's and a desk's width, and
// on every gallery page by day and by night.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'support.dart';

Finder _words(String text) => find.byWidgetPredicate(
  (w) =>
      w is RichText &&
      w.text.toPlainText().trim().toLowerCase() == text.toLowerCase(),
);

void _nodes(WidgetTester tester, String where) {
  final context = tester.element(find.byType(ShelfApp));
  final failed = [
    ...const DesignControlNodesCheck(look: 'Comic').check(context).problems,
    ...const DesignFieldSemanticsCheck(look: 'Comic').check(context).problems,
  ];
  expect(failed, isEmpty, reason: '$where:\n${failed.join('\n')}');
}

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });

  for (final width in const [390.0, 800.0, 1440.0]) {
    testWidgets(
      'Shelf at $width: each screen\'s controls and fields, and the places beside a page',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 900);
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(const ShelfApp());
          await settle(tester);
          _nodes(tester, 'Books');
          await tester.tap(_words('Piranesi'));
          await settle(tester);
          _nodes(tester, 'a book');
          // On a phone the tab bar steps away from a pushed page (back pops it); the rail and the masthead stay.
          if (width >= 600) {
            const DesignNavigationCheck(look: 'Comic')
                .check(
                  tester.element(find.byType(ShelfApp)),
                  destinations: ['Books', 'Add a book', 'Settings'],
                )
                .verify();
          }
          await tester.tap(find.byType(ComicBackButton));
          await settle(tester);
          await tester.tap(find.bySemanticsLabel(RegExp('^Add a book')).first);
          await settle(tester);
          await tester.tap(_words('Save'));
          await settle(tester);
          _nodes(tester, 'the form with its errors');
          await tester.tap(find.bySemanticsLabel(RegExp('^Settings')).first);
          await settle(tester);
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
        'the ${page.id} page by ${brightness == Brightness.light ? 'day' : 'night'}: its controls and fields',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await pumpGalleryPage(tester, page, 'offset', brightness);
            final context = tester.element(find.byType(Directionality).first);
            final failed = [
              ...const DesignControlNodesCheck(look: 'Comic')
                  .check(context)
                  .problems,
              ...const DesignFieldSemanticsCheck(look: 'Comic')
                  .check(context)
                  .problems,
            ];
            expect(failed, isEmpty, reason: failed.join('\n'));
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}

// A screen reader hears every section of the gallery. material_ui's MaterialApp (Flutter's Material from 3.50) puts no
// semantics container round its Navigator, as Flutter's own did, so an app or Navigator nested in a page brings a
// modal barrier whose semantics hide everything painted before it in the same container (Minimal's Navigation page
// lost its bars this way). On each page every section heading is in the semantics tree; and ComicPreview, the one app
// the library nests, leaves what is above it readable.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/comic_host.dart' show ComicPreview;

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import '../example/lib/kit_gallery/live_pages.dart';
import 'gallery_support.dart';
import 'support.dart';
import 'tiers.dart';

/// [words] as one node's label, or as one line of a label merged from several.
Finder _heard(String words) =>
    find.bySemanticsLabel(RegExp('(^|\n)${RegExp.escape(words)}(\n|\$)'));

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });

  // Each page once, at a phone's width and a desk's in turn; the sweep opens it at the other width. The window is tall,
  // so every section of the page is built and none is cut off by the scroll.
  for (final (w, width) in [390.0, 1440.0].indexed) {
    for (final (p, page) in livePages.indexed) {
      testWidgets(
        '${page.id} at ${width.toInt()}: every section heading is heard',
        (tester) async {
          final semantics = tester.ensureSemantics();
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 24000);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(GalleryApp(page: page.id));
          await settle(tester);
          expect(tester.takeException(), isNull);
          final heads = find.descendant(
            of: find.byKey(ValueKey('live/${page.id}')),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is RepaintBoundary &&
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith('kit-section/'),
            ),
          );
          final labels = [
            for (final e in heads.evaluate())
              (e.widget.key! as ValueKey<String>).value
                  .substring('kit-section/'.length)
                  .toUpperCase(),
          ];
          final unheard = [
            for (final label in labels)
              if (_heard(label).evaluate().isEmpty) label,
          ];
          // Before the expectation: flutter_test checks the handle is gone before tear-downs run.
          semantics.dispose();
          expect(unheard, isEmpty, reason: 'of ${labels.length} headings');
        },
        tags: sweepUnless(p % 2 == w),
      );
    }
  }

  testWidgets('ComicPreview leaves what is above it heard', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            ComicTheme(data: ComicThemeData.offset(), child: child!),
        home: const Column(
          children: [
            Text('Above the preview'),
            Expanded(
              child: ComicPreview(
                child: ComicScaffold(body: Text('Inside the preview')),
              ),
            ),
          ],
        ),
      ),
    );
    await settle(tester);
    final above = _heard('Above the preview').evaluate().length;
    final inside = _heard('Inside the preview').evaluate().length;
    semantics.dispose();
    expect(above, 1, reason: 'the words above the preview');
    expect(inside, 1, reason: 'the words inside the preview');
  });
}

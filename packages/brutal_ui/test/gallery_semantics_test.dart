// A screen reader meets the whole of every gallery page at a desk's width:
// each section's heading, the brand and the side list's places.
// The desk swaps its places on a Navigator of its own inside the app, and
// BrutalPreview runs an app of its own inside a page: a route's barrier
// hides from a screen reader everything painted before it in the same
// semantics container, so each is a container of its own.
// ignore_for_file: avoid_relative_lib_imports
import 'package:brutal_ui/brutal_ui.dart';
import 'package:brutal_ui/brutal_host.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/admit/admit.dart';
import '../example/lib/kit_gallery/kit.dart';

// Whether a node of the semantics tree says [words] (a node merges its
// children's labels, one to a line).
SemanticsFinder _heard(String words) => find.semantics.byPredicate(
  (node) => node.label
      .split('\n')
      .any((line) => line.trim().toLowerCase() == words.toLowerCase()),
  describeMatch: (_) => 'a node that says "$words"',
);

void main() {
  testWidgets('every gallery page at 1440: each heading, the brand and the '
      'places are in the semantics tree', (tester) async {
    // Tall enough that every section stands on screen: a scrolled-away one
    // is left out of the semantics tree until scrolled to, by design.
    tester.view.physicalSize = const Size(1440, 12000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    for (final (i, page) in galleryPages.indexed) {
      await tester.pumpWidget(
        AdmitApp(
          key: ValueKey(page.id),
          parts: [
            for (final p in galleryPages) (title: p.title, build: p.build),
          ],
          initialPart: i,
        ),
      );
      // The part's page arrives after the first frame; a spinner on some
      // pages never settles, so pump past the arrival.
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      final headings = [
        for (final s in tester.widgetList<KitSection>(find.byType(KitSection)))
          s.title,
      ];
      expect(headings, isNotEmpty, reason: '${page.id}: no sections');
      for (final words in ['ADMIT', 'Home', 'Settings', ...headings]) {
        expect(
          _heard(words),
          findsAtLeast(1),
          reason: '${page.id}: "$words" is not in the semantics tree',
        );
      }
    }
    semantics.dispose();
  });

  testWidgets('a BrutalPreview hides nothing painted before it from a '
      'screen reader', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            const Text('Painted before the preview'),
            Expanded(
              child: BrutalPreview(
                theme: BrutalThemeData.light(),
                child: const Text('Inside the preview'),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_heard('Painted before the preview'), findsOneWidget);
    expect(_heard('Inside the preview'), findsOneWidget);
    semantics.dispose();
  });
}

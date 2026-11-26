// A nested app (a gallery demo's kitApp, a CivicPreview) stands in a
// semantics container of its own. material_ui's MaterialApp has none of the
// containers Flutter's own MaterialApp had, so without one the modal barrier
// under a nested app's routes hid everything painted before it in the same
// container from a screen reader: the page round the demo, or round the
// preview. And on each of the gallery's pages, every section's heading is
// heard.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_host.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/permits/permits.dart';

// Whether a screen reader hears [words]: some node of the semantics tree
// says them.
bool _heard(String words) =>
    find.semantics.byLabel(RegExp(RegExp.escape(words))).evaluate().isNotEmpty;

// [nested] under a line of the page round it.
Widget _round(Widget nested) => MaterialApp(
  home: Column(
    children: [
      const Text('The page round it'),
      Expanded(child: nested),
    ],
  ),
);

Future<void> _wide(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets("a gallery demo's app hides nothing round it", (tester) async {
    final semantics = tester.ensureSemantics();
    await _wide(tester);
    await tester.pumpWidget(
      _round(kitApp(brightness: Brightness.light, home: const Text('Inside'))),
    );
    await tester.pumpAndSettle();
    expect(_heard('The page round it'), isTrue);
    expect(_heard('Inside'), isTrue);
    semantics.dispose();
  });

  for (final presentation in CivicPresentation.values) {
    testWidgets('a preview (${presentation.name}) hides nothing round it', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _wide(tester);
      await tester.pumpWidget(
        _round(
          CivicPreview(presentation: presentation, child: const Text('Inside')),
        ),
      );
      await tester.pumpAndSettle();
      expect(_heard('The page round it'), isTrue);
      expect(_heard('Inside'), isTrue);
      semantics.dispose();
    });
  }

  for (final (i, page) in galleryPages.indexed) {
    testWidgets("every section's heading is heard on ${page.id}", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _wide(tester);
      await tester.pumpWidget(
        PermitsApp(
          parts: [
            for (final page in galleryPages)
              (title: page.title, build: page.build),
          ],
          initialPart: i,
        ),
      );
      // A page with a wait on it (an arc turning) never settles: give it
      // a second.
      for (var f = 0; f < 20; f++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final headings = [
        for (final section in tester.widgetList<KitSection>(
          find.byType(KitSection, skipOffstage: false),
        ))
          section.title,
      ];
      for (final heading in headings) {
        expect(_heard(heading), isTrue, reason: heading);
      }
      semantics.dispose();
    });
  }
}

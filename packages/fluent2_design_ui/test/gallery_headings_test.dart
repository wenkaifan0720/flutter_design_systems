// Every section heading of every gallery page reaches a screen reader. A
// demo's own app or navigator stands a route's modal barrier, which hides from
// a screen reader whatever painted before it in its semantics container (on
// material_ui's MaterialApp, which has no container of its own, the page's
// headings above a demo); each stands in a container of its own.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/northwind.dart';
import 'gallery_support.dart';

void main() {
  setUpAll(loadFluent2TestFonts);
  for (final page in galleryPages) {
    testWidgets('${page.id}: every section heading is in the semantics', (
      t,
    ) async {
      final semantics = t.ensureSemantics();
      await pumpGalleryPage(t, page, 'lapis', Brightness.light);
      final sections = find.byWidgetPredicate(
        (w) =>
            w is RepaintBoundary &&
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('kit-section/'),
      );
      final headings = [
        for (final section in sections.evaluate())
          t
              .widget<Text>(
                find
                    .descendant(
                      of: find.byWidget(section.widget),
                      matching: find.byType(Text),
                    )
                    .first,
              )
              .data!,
      ];
      for (final heading in headings) {
        expect(
          find.bySemanticsLabel(heading),
          findsWidgets,
          reason: '${page.id}: "$heading" is out of the semantics',
        );
      }
      await t.pumpWidget(const SizedBox());
      semantics.dispose();
    });
  }

  // The sample app's Files root runs its own navigator beside the nav pane,
  // which paints first: without a container of its own the navigator's
  // route took the pane out of the semantics.
  testWidgets('Northwind on Files: the nav pane stays with a screen reader', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    t.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      const KitNorthwind(
        brightness: Brightness.light,
        root: KitNorthwindRoot.files,
      ),
    );
    await settle(t);
    for (final label in ['Home', 'Requests', 'Settings']) {
      expect(
        find.bySemanticsLabel(RegExp('^$label')),
        findsWidgets,
        reason: '"$label" is out of the semantics',
      );
    }
    await t.pumpWidget(const SizedBox());
    semantics.dispose();
  });
}

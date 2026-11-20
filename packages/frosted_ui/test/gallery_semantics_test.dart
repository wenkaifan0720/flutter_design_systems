// A nested app no longer hides what stands above it from a screen reader. Each gallery page is an app of its own
// (kit.dart's _kitApp) under the gallery's bar, and the route under a nested app or navigator stands a modal barrier,
// which hides whatever painted before it in its semantics container: on material_ui's MaterialApp, which holds no
// container of its own as Flutter 3.47's did, the bar's Pages and Customize left the page's semantics. The nested apps
// and Harbor's navigator, and the library's FrostedPreview, each stand in a container of their own.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

// The bar is the example app's; a test opens its pages there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
import 'gallery_support.dart';

/// [words] as a node's whole label or one of its lines (a node merges its texts a line each).
Finder _heard(String words) =>
    find.bySemanticsLabel(RegExp('(^|\\n)${RegExp.escape(words)}(\\n|\$)'));

void main() {
  setUpAll(() async {
    await frostedLoadFonts();
    await loadBundledFonts();
  });

  for (final page in galleryPages) {
    testWidgets('${page.title}: the gallery bar and every section heading '
        'reach a screen reader', (tester) async {
      final semantics = tester.ensureSemantics();
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(galleryWidth, 844);
      await tester.pumpWidget(const GalleryApp());
      await settle(tester);
      final entry = find.text(page.title).first;
      await tester.ensureVisible(entry);
      await settle(tester);
      await tester.tap(entry);
      await settle(tester);

      final heard = <String>[
        // The gallery's bar, painted before the page's own app.
        'Pages',
        'Customize',
        // Every band of the page, inside its app.
        for (final w in tester.widgetList(find.byType(RepaintBoundary)))
          if (w.key case ValueKey<String>(:final value)
              when value.startsWith('kit-section/'))
            value.substring('kit-section/'.length),
      ];
      for (final words in heard) {
        expect(
          _heard(words),
          findsWidgets,
          reason: '${page.title}: "$words" is out of the semantics',
        );
      }
      semantics.dispose();
    });
  }

  // ui_core 0.3.4's DesignDataTable: a row that can be chosen is a checkbox,
  // checked or not, that a tap toggles, not a button. The data page's five
  // file rows, as a screen reader meets them at 390.
  testWidgets('Data: each row that can be chosen is heard as a checkbox, '
      'not a button', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(galleryWidth, 844);
    await tester.pumpWidget(const GalleryApp());
    await settle(tester);
    final entry = find.text(
      galleryPages.firstWhere((p) => p.id == 'data').title,
    );
    await tester.ensureVisible(entry.first);
    await settle(tester);
    await tester.tap(entry.first);
    await settle(tester);
    final rows = find.semantics.byPredicate(
      (node) => node.getSemanticsData().label.endsWith('\nSelect row'),
    );
    final heard = [
      for (final node in rows.evaluate())
        node.getSemanticsData().label.split('\n').first,
    ];
    expect(heard, ['Brief', 'Cover', 'Budget', 'Interview', 'Notes']);
    for (final node in rows.evaluate()) {
      expect(
        node,
        isSemantics(
          hasCheckedState: true,
          isChecked: false,
          isButton: false,
          hasTapAction: true,
        ),
        reason: node.getSemanticsData().label,
      );
    }
    semantics.dispose();
  });

  testWidgets('a heading above a FrostedPreview reaches a screen reader', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: FrostedHost(
          child: Column(
            children: [
              Text('Your app, previewed'),
              Expanded(
                child: FrostedPreview(child: Center(child: Text('Today'))),
              ),
            ],
          ),
        ),
      ),
    );
    await settle(tester);
    expect(_heard('Your app, previewed'), findsOneWidget);
    expect(_heard('Today'), findsWidgets);
    semantics.dispose();
  });
}

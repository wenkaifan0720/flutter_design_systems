// A screen reader reads every gallery page whole: each section heading and
// each top bar a page draws is in the semantics tree. On material_ui's
// MaterialApp (the gallery's since Flutter 3.50) a nested app or a bare
// Navigator inside a page puts a modal barrier whose semantics hide all that
// was painted before it in the same container; Terminal's gallery and
// library nest none, and this keeps it so. The control case shows the check
// catches the fault: a bare Navigator hides the headings above it, and
// `Semantics(container: true)` round it gives them back.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

// The example's pages are the ones under test.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'faces.dart';
import 'tiers.dart';

/// The headings and top bars [tester]'s page draws that the semantics tree
/// leaves out.
List<String> unheard(WidgetTester tester) => [
  for (final title in {
    for (final h in tester.widgetList<TermSectionHeader>(
      find.byType(TermSectionHeader),
    ))
      h.title,
    for (final b in tester.widgetList<TermTopBar>(find.byType(TermTopBar)))
      b.title,
  })
    if (find.semantics.byLabel(RegExp(RegExp.escape(title))).evaluate().isEmpty)
      title,
];

void main() {
  setUpAll(loadFaces);

  // Tall enough that no page scrolls: every heading built is on the screen.
  const configs = [(390.0, Brightness.dark), (1440.0, Brightness.light)];

  for (var i = 0; i < galleryPages.length; i++) {
    final page = galleryPages[i];
    for (var c = 0; c < configs.length; c++) {
      final (width, b) = configs[c];
      testWidgets(
        '${page.id} at ${width.toInt()} ${b.name}: every heading is heard',
        tags: sweepUnlessTurn(i, c, configs.length),
        (tester) async {
          final semantics = tester.ensureSemantics();
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 8000);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(page.build(b));
          for (var k = 0; k < 8; k++) {
            await tester.pump(const Duration(milliseconds: 50));
          }
          expect(
            find.byType(TermSectionHeader).evaluate().isNotEmpty ||
                find.byType(TermTopBar).evaluate().isNotEmpty,
            isTrue,
            reason: '${page.id} draws a heading or a top bar',
          );
          expect(unheard(tester), isEmpty);
          semantics.dispose();
        },
      );
    }
  }

  testWidgets('a bare Navigator in a page hides the headings above it; '
      'a semantics container round it does not', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    Widget page({required bool contained}) {
      final navigator = SizedBox(
        height: 48,
        child: Navigator(
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => const Text('nested'),
          ),
        ),
      );
      return kitScreen(
        brightness: Brightness.dark,
        title: 'control',
        sections: [
          kitSection('above the navigator', children: [const Text('a')]),
          kitSection(
            'the navigator',
            children: [
              if (contained)
                Semantics(container: true, child: navigator)
              else
                navigator,
            ],
          ),
        ],
      );
    }

    await tester.pumpWidget(page(contained: false));
    await tester.pump();
    expect(unheard(tester), contains('above the navigator'));

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page(contained: true));
    await tester.pump();
    expect(unheard(tester), isEmpty);
    semantics.dispose();
  });
}

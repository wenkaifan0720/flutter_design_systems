// ignore_for_file: avoid_relative_lib_imports
// Accessibility and languages across the live gallery, through the shared
// world checks: every page builds at twice the platform's text size (which
// MinimalHost clamps at MinimalChromeMetrics.maxTextScale) and right to left
// with no overflow and no error, and the everyday pages meet Flutter's
// tap-target, label and contrast guidelines by day and by night. Minimal's
// targets are 44 px on every platform by design, so Android's 48 is not
// asked.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import '../example/lib/kit_gallery/demos/foundations.dart';
import '../example/lib/kit_gallery/demos/input_group.dart';
import '../example/lib/kit_gallery/demos/shell.dart';
import '../example/lib/kit_gallery/demos/status.dart';
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/main.dart';
import 'world_checks.dart';

Widget _gallery(
  ExamplePage page, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  builder: (context, child) => Directionality(
    textDirection: direction,
    child: MinimalHost(
      light: kitTheme(Brightness.light),
      dark: kitTheme(Brightness.dark),
      brightness: brightness,
      child: child!,
    ),
  ),
  home: ExamplePageView(
    page: page,
    brightness: brightness,
    onOpen: (_) {},
    bar: MinimalAppBar(title: page.name),
  ),
);

/// [home] on a gallery page's host, read in [direction].
Widget _onPage(
  Widget home, {
  TextDirection direction = TextDirection.ltr,
  GlobalKey<NavigatorState>? navigator,
}) => MaterialApp(
  navigatorKey: navigator,
  builder: (context, child) => Directionality(
    textDirection: direction,
    child: MinimalHost(
      light: kitTheme(Brightness.light),
      dark: kitTheme(Brightness.dark),
      brightness: Brightness.light,
      child: child!,
    ),
  ),
  home: home,
);

/// Where [piece] of [paragraph]'s text starts, from the left.
double _leftOf(RenderParagraph paragraph, String piece) {
  final at = paragraph.text.toPlainText().indexOf(piece);
  expect(at, isNonNegative, reason: piece);
  return paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: at, extentOffset: at + piece.length),
      )
      .first
      .left;
}

void _onAPhone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  kitEmbedded = true;
  // Spinners and skeletons hold still, so every page settles.
  MinimalMotion.animate = false;
  addTearDown(() => MinimalMotion.animate = true);
}

/// The pages a person meets first, whose every part must clear the floors.
const Set<String> _everyday = {
  'Overview',
  'Buttons',
  'Text fields',
  'Selection',
  'Pickers',
  'Navigation',
  'Lists and tables',
  'Dialogs and sheets',
  'Feedback',
};

void main() {
  testWidgets('a link with dir=rtl reads the whole gallery right to left', (
    tester,
  ) async {
    _onAPhone(tester);
    await tester.pumpWidget(
      GalleryApp.at(Uri.parse('http://localhost/?page=overview&dir=rtl')),
    );
    await tester.pumpAndSettle();
    for (final words in ['Minimal', 'Overview']) {
      expect(
        Directionality.of(tester.element(find.text(words).first)),
        TextDirection.rtl,
        reason: words,
      );
    }
  });

  // A demo's own app has an English locale, which sets the direction again
  // under it; the page's direction must still reach it.
  testWidgets('a demo with an app of its own reads right to left too', (
    tester,
  ) async {
    _onAPhone(tester);
    await tester.pumpWidget(
      _onPage(
        SingleChildScrollView(child: kitShellDemo(Brightness.light)),
        direction: TextDirection.rtl,
      ),
    );
    await tester.pumpAndSettle();
    final rows = find.text('Meditate');
    expect(rows, findsWidgets);
    for (final row in rows.evaluate()) {
      expect(Directionality.of(row), TextDirection.rtl);
    }
  });

  testWidgets('a preview reads the way the tree around it does', (
    tester,
  ) async {
    _onAPhone(tester);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: MinimalPreview(
          light: kitTheme(Brightness.light),
          dark: kitTheme(Brightness.dark),
          brightness: Brightness.light,
          child: const Text('Water the plants'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.text('Water the plants'))),
      TextDirection.rtl,
    );
  });

  testWidgets('a pushed bar sets its crumb, title and id right to left', (
    tester,
  ) async {
    _onAPhone(tester);
    // The test font's square glyphs run the line past a phone's bar, which
    // ellipsizes it; a wider window keeps every piece on the line.
    tester.view.physicalSize = const Size(1024, 844);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      _onPage(
        const SizedBox.shrink(),
        direction: TextDirection.rtl,
        navigator: navigator,
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Column(
          children: [
            MinimalAppBar(
              parent: 'Habits',
              title: 'Morning run',
              subtitle: 'HAB-4',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final line = tester.renderObject<RenderParagraph>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Morning run'),
      ),
    );
    // Right to left the crumb leads at the right, the id ends at the left.
    expect(_leftOf(line, 'Habits'), greaterThan(_leftOf(line, 'Morning run')));
    expect(_leftOf(line, 'Morning run'), greaterThan(_leftOf(line, 'HAB-4')));
  });

  testWidgets('a hex code reads left to right on a right-to-left page', (
    tester,
  ) async {
    _onAPhone(tester);
    await tester.pumpWidget(
      _onPage(
        SingleChildScrollView(child: kitFoundationsDemo(Brightness.light)),
        direction: TextDirection.rtl,
      ),
    );
    await tester.pumpAndSettle();
    // A code that starts with a letter: right to left, its hash would trail.
    final codes = find.byWidgetPredicate(
      (w) => w is Text && RegExp(r'^#[A-F]').hasMatch(w.data ?? ''),
    );
    expect(codes, findsWidgets);
    final code = tester.renderObject<RenderParagraph>(
      find.descendant(of: codes.first, matching: find.byType(RichText)),
    );
    final text = code.text.toPlainText();
    expect(_leftOf(code, '#'), lessThan(_leftOf(code, text.substring(1))));
  });

  testWidgets('a URL and an issue id read left to right on a right-to-left '
      'page', (tester) async {
    _onAPhone(tester);
    await tester.pumpWidget(
      _onPage(
        SingleChildScrollView(child: kitInputGroupDemo(Brightness.light)),
        direction: TextDirection.rtl,
      ),
    );
    await tester.pumpAndSettle();
    // The add-ons keep their order: the scheme before the name, the domain
    // after it.
    expect(
      tester.getCenter(find.text('https://')).dx,
      lessThan(tester.getCenter(find.text('.com')).dx),
    );
    // The scheme reads as written, its slashes after its colon.
    final scheme = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.text('https://'),
        matching: find.byType(RichText),
      ),
    );
    expect(_leftOf(scheme, 'https'), lessThan(_leftOf(scheme, '//')));
    // The typed id keeps its hyphen after its letters.
    final id = find.byWidgetPredicate(
      (w) => w is EditableText && w.controller.text == 'HAB-',
    );
    expect(Directionality.of(tester.element(id)), TextDirection.ltr);
    // The field's name still stands where the page's words start: the right.
    final label = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.text('Website'),
        matching: find.byType(RichText),
      ),
    );
    expect(_leftOf(label, 'Website'), greaterThan(label.size.width / 2));
  });

  testWidgets('a collapsible group mutes its done rows', (tester) async {
    _onAPhone(tester);
    await tester.pumpWidget(
      _onPage(SingleChildScrollView(child: kitStatusDemo(Brightness.light))),
    );
    await tester.pumpAndSettle();
    final t = tester.element(find.text('Read 20 pages')).minimalTheme;
    Color? ink(String name) =>
        tester.widget<Text>(find.text(name)).style?.color;
    expect(ink('Read 20 pages'), t.mutedForeground);
    expect(ink('Stretch before bed'), t.foreground);
  });

  for (final page in galleryPagesAll) {
    testWidgets('${page.name} at twice the text size', (tester) async {
      _onAPhone(tester);
      await expectNoOverflowAtTextScale(tester, _gallery(page));
    });

    testWidgets('${page.name} right to left', (tester) async {
      _onAPhone(tester);
      await tester.pumpWidget(_gallery(page, direction: TextDirection.rtl));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  for (final page in galleryPagesAll.where((p) => _everyday.contains(p.name))) {
    for (final brightness in Brightness.values) {
      testWidgets('${page.name} meets the guidelines, ${brightness.name}', (
        tester,
      ) async {
        _onAPhone(tester);
        await tester.pumpWidget(_gallery(page, brightness: brightness));
        await tester.pumpAndSettle();
        await expectMeetsGuidelines(tester, android: false);
      }, tags: 'goldens');
    }
  }
}

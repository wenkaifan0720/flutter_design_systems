// The shared world checks every look runs (world_checks.dart, copied unchanged): the everyday parts mirror right to
// left, every gallery page lays out at text scale 2.0 (the 200% a reader may ask for), and the main gallery pages meet
// Flutter's four accessibility guidelines by day and by night.
import 'package:fluent2_ui/fluent2_ui.dart';
import 'package:fluent2_ui/fluent2_host.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gallery_support.dart';
import 'world_checks.dart';

void _noop() {}
void _drop(Object? _) {}

/// [part] at the reading start of a phone's page, in [direction].
Widget _app(TextDirection direction, Widget part) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) => Directionality(
    textDirection: direction,
    child: Fluent2Host(brightness: Brightness.light, child: child!),
  ),
  home: Align(
    alignment: AlignmentDirectional.topStart,
    child: Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, top: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: part,
      ),
    ),
  ),
);

const _mains = [
  'app-overview',
  'app-files',
  'app-request',
  'app-settings',
  'buttons',
  'selection',
  'inputs',
  'lists',
  'tabs',
  'dialog',
];

void main() {
  setUpAll(loadFluent2TestFonts);
  // The checks settle the screen, so what runs for ever (a spinner, a shimmer) stands still: Reduce Motion, Flutter's
  // own switch, which every part heeds.
  setUp(
    () =>
        TestWidgetsFlutterBinding.ensureInitialized()
            .platformDispatcher
            .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        ),
  );
  tearDown(
    () => TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  void phone(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(galleryWidth, 844);
    addTearDown(tester.view.reset);
  }

  final parts = <(String, Widget, List<Finder>)>[
    (
      'a button',
      const Fluent2Button('Send', icon: Fluent2Icons.send, onPressed: _noop),
      [find.byIcon(Fluent2Icons.send), find.byType(Fluent2Button)],
    ),
    (
      'a check box',
      const Fluent2Checkbox(
        value: true,
        label: 'Remember me',
        onChanged: _drop,
      ),
      [find.text('Remember me'), find.byType(Fluent2Checkbox)],
    ),
    (
      'a radio group',
      const Fluent2RadioGroup<int>(
        options: [Fluent2Radio(1, 'Daily'), Fluent2Radio(2, 'Weekly')],
        value: 1,
        onChanged: _drop,
      ),
      [find.text('Daily'), find.text('Weekly')],
    ),
    (
      'a switch',
      const Fluent2Switch(
        value: true,
        label: 'Show me as away',
        onChanged: _drop,
      ),
      [find.text('Show me as away'), find.byType(Fluent2Switch)],
    ),
    (
      'a text field',
      const Fluent2TextField(
        label: 'Search',
        value: 'Northwind',
        onChanged: _drop,
        prefixIcon: Fluent2Icons.search,
      ),
      [find.byIcon(Fluent2Icons.search), find.byType(Fluent2TextField)],
    ),
    (
      'a list row',
      const Fluent2ListItem(
        icon: Fluent2Icons.document,
        title: 'Q3 plan.docx',
        chevron: true,
        onTap: _noop,
      ),
      [
        find.byIcon(Fluent2Icons.document),
        find.text('Q3 plan.docx'),
        find.byIcon(Fluent2Icons.chevronRight16),
      ],
    ),
    (
      'tabs',
      const Fluent2TabList(
        tabs: ['Chat', 'Files', 'Notes'],
        selectedIndex: 0,
        onChanged: _drop,
      ),
      [find.text('Chat').first, find.text('Notes').first],
    ),
    (
      'segments',
      const Fluent2SegmentedButton<String>(
        label: 'Calendar view',
        segments: [
          Fluent2ButtonSegment('day', 'Day'),
          Fluent2ButtonSegment('week', 'Week'),
        ],
        value: 'day',
        onChanged: _drop,
      ),
      [find.text('Day'), find.text('Week')],
    ),
    (
      'a tag',
      const Fluent2Tag('Launch', onDeleted: _noop),
      [find.text('Launch'), find.byIcon(Fluent2Icons.dismiss)],
    ),
    (
      'a navigation item',
      const Fluent2NavigationDrawerItem(
        icon: Fluent2Icons.folder,
        label: 'Files',
        selected: false,
        onPressed: _noop,
      ),
      [find.byIcon(Fluent2Icons.folder), find.text('Files')],
    ),
  ];

  for (final (name, part, marks) in parts) {
    testWidgets('$name mirrors right to left', (tester) async {
      phone(tester);
      await expectMirrorsInRtl(
        tester,
        (direction) => _app(direction, part),
        parts: marks,
      );
    });
  }

  for (final page in galleryPages) {
    testWidgets('${page.id} lays out at text scale 2', (tester) async {
      phone(tester);
      await expectNoOverflowAtTextScale(
        tester,
        KeyedSubtree(
          key: ValueKey(page.id),
          child: page.build(Brightness.light),
        ),
      );
    });
  }

  for (final id in _mains) {
    for (final b in Brightness.values) {
      testWidgets('$id meets the target guidelines, ${b.name}', (tester) async {
        phone(tester);
        await tester.pumpWidget(
          galleryPages.firstWhere((p) => p.id == id).build(b),
        );
        await settle(tester);
        // expectMeetsGuidelines' three target and label guidelines, as they are.
        final semantics = tester.ensureSemantics();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        semantics.dispose();
      });

      // Its fourth, text contrast, read from each paragraph's own ink. Flutter's textContrastGuideline reads both
      // colours from a capture at one pixel per logical pixel, whatever the device: Selawik's 12 px strokes never
      // fill a pixel there, so it takes an anti-aliased grey for the ink, and it reads a 24 px button's words
      // against the page round its 48 px target. Both inks are read here as drawn, against the colour most of the
      // words' box is painted (gallery_support.dart): drawn pixels, the rasterizer's, so tagged as a golden is.
      testWidgets('$id meets the text contrast guideline, ${b.name}', (
        tester,
      ) async {
        phone(tester);
        await tester.pumpWidget(
          galleryPages.firstWhere((p) => p.id == id).build(b),
        );
        await settle(tester);
        final semantics = tester.ensureSemantics();
        expect(await inkedContrastFailures(tester), isEmpty);
        semantics.dispose();
      }, tags: const ['goldens']);
    }
  }
}

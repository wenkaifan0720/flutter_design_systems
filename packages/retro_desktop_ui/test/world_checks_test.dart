// The shared world checks (world_checks.dart, the same file in every look): the everyday parts mirror right to left,
// every gallery page holds at twice the text size, and every gallery page meets Flutter's guidelines by day and by
// night (text contrast read from the ink; see the guidelines group).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

// The gallery is the example app; a test reads its default preset from there.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/theme.dart' show kitPreset;
import 'gallery_support.dart';
import 'support.dart';
import 'world_checks.dart';

void _none() {}
void _take(Object? _) {}

// Each everyday part, and what in it must stand mirrored: its words, its marks, what leads and what trails.
final _parts = <(String, Widget, List<Finder> Function())>[
  (
    'a button',
    const RetroDesktopButton(
      'Open',
      icon: RetroDesktopGlyphs.plus,
      onPressed: _none,
    ),
    () => [find.byIcon(RetroDesktopGlyphs.plus), find.text('Open')],
  ),
  (
    'a list row',
    const RetroDesktopListTile(
      title: 'Notes',
      leading: Icon(RetroDesktopGlyphs.folder),
      trailing: Text('12'),
      isFirst: true,
    ),
    () => [
      find.byIcon(RetroDesktopGlyphs.folder),
      find.text('Notes'),
      find.text('12'),
    ],
  ),
  (
    'a text field',
    const RetroDesktopTextField(
      hint: 'Find',
      leading: Icon(RetroDesktopGlyphs.search),
    ),
    () => [find.byIcon(RetroDesktopGlyphs.search)],
  ),
  (
    'an input group',
    const RetroDesktopInputGroup(
      prefix: 'https://',
      suffix: '.com',
      hint: 'studio',
    ),
    () => [find.text('https://'), find.text('.com')],
  ),
  (
    'a check row',
    const RetroDesktopCheckRow(
      label: 'Keep a backup',
      value: true,
      onChanged: _take,
    ),
    () => [find.text('Keep a backup')],
  ),
  (
    'a switch row',
    const RetroDesktopSwitchRow(label: 'Sounds', value: true, onChanged: _take),
    () => [find.text('Sounds')],
  ),
  (
    'a chip',
    const RetroDesktopChip(
      'Tag',
      icon: RetroDesktopGlyphs.plus,
      onPressed: _none,
    ),
    () => [find.byIcon(RetroDesktopGlyphs.plus), find.text('Tag')],
  ),
  (
    'folder tabs',
    const RetroDesktopTabBar(
      tabs: ['Today', 'Later'],
      onChanged: _take,
      child: SizedBox(height: 40),
    ),
    () => [find.text('Today'), find.text('Later')],
  ),
  (
    'a segmented button',
    const RetroDesktopSegmentedButton<int>(
      label: 'View',
      showLabel: false,
      value: 0,
      onChanged: _take,
      segments: [
        RetroDesktopButtonSegment(0, 'List'),
        RetroDesktopButtonSegment(1, 'Icons'),
      ],
    ),
    () => [find.text('List'), find.text('Icons')],
  ),
  (
    'a disclosure',
    const RetroDesktopDisclosure(title: 'Cut list', child: Text('Seat first')),
    () => [find.text('Cut list')],
  ),
  (
    'a breadcrumb',
    const RetroDesktopBreadcrumb(
      items: [
        RetroDesktopBreadcrumbItem('Home'),
        RetroDesktopBreadcrumbItem('Notes'),
      ],
    ),
    () => [find.text('Home'), find.text('Notes')],
  ),
];

// A part at the start of a phone's screen, 16 px in from its start edge and its top.
Widget _host(TextDirection direction, Widget part) => retroDesktopApp(
  Padding(
    padding: const EdgeInsets.all(16),
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(width: 320, child: part),
    ),
  ),
  direction: direction,
);

void main() {
  setUpAll(loadRetroDesktopFonts);

  group('right to left', () {
    for (final (name, part, parts) in _parts) {
      testWidgets('$name mirrors', (tester) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await expectMirrorsInRtl(
          tester,
          (direction) => _host(direction, part),
          parts: parts(),
        );
      });
    }
  });

  group('twice the text size', () {
    for (final page in galleryPages) {
      testWidgets('${page.id}: nothing overflows', (tester) async {
        tester.view.physicalSize = const Size(galleryWidth, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        // Still: a spinner that never stops would keep the frames coming.
        final app = TickerMode(
          enabled: false,
          child: page.build(Brightness.light),
        );
        await expectNoOverflowAtTextScale(tester, app);
        // Then the whole page at once, the view as tall as the page has grown.
        final scrollables = tester
            .stateList<ScrollableState>(find.byType(Scrollable))
            .where((s) => s.position.axis == Axis.vertical);
        final extent = scrollables.isEmpty
            ? 0.0
            : scrollables.first.position.maxScrollExtent;
        if (extent > 0) {
          tester.view.physicalSize = Size(galleryWidth, 844 + extent);
          await expectNoOverflowAtTextScale(tester, app);
        }
      });
    }
  });

  // The guidelines, with one named exception: text contrast is read from each word's own ink (`inkedContrastFailures`)
  // instead of Flutter's `textContrastGuideline`. That guideline captures at one pixel per logical pixel, where
  // Atkinson's 11-13 px strokes are only ever anti-aliased grey, and reads a small word inside a 48 px target against
  // the page around it: both fail words whose real ink passes (msg_b67b7685bbab). The tap-target and label guidelines
  // are Flutter's own, as expectMeetsGuidelines runs them.
  group('the guidelines', () {
    for (final page in galleryPages) {
      for (final b in Brightness.values) {
        testWidgets(
          '${page.id} by ${b == Brightness.light ? 'day' : 'night'}',
          (tester) async {
            final semantics = tester.ensureSemantics();
            await pumpGalleryPage(tester, page, kitPreset, b);
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            final inked = await inkedContrastFailures(tester);
            expect(inked, isEmpty, reason: inked.join('\n'));
            semantics.dispose();
          },
          tags: const ['goldens'],
        );
      }
    }
  });
}

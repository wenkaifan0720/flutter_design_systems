// What holds and shows a page's things (ui_core's behaviour where it has
// one, Civic's painting): a card that is a link is one link; an accordion
// opens a section or all of them and hides a shut one from the keys and a
// screen reader; the step indicator and the page marks say the place in
// words; the carousel turns only on Previous, Next and its marks; a scroll
// area scrolls by the keys; the split view's grip moves on the arrows; a
// reorderable list moves a row by its words; a swipe row's actions are in
// sight in its menu too; a tree opens on a press; avatars, badges,
// pictures, figures and amounts are read in words; the grid's columns
// follow the room. Leak tracking is on for every test here.
import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// [body] on a page at [size].
Future<void> _app(
  WidgetTester tester,
  Widget body, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => CivicHost(child: child!),
      home: CivicScreen(
        body: Padding(
          padding: const EdgeInsets.all(CivicSpacing.s16),
          child: Align(alignment: Alignment.topLeft, child: body),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

/// The colour painted at the middle of [target], read from the repaint
/// boundary keyed [stage].
Future<Color> _middle(WidgetTester tester, Key stage, Finder target) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(stage),
  );
  final at = tester.getCenter(target) - boundary.localToGlobal(Offset.zero);
  final rgba = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    final i = (at.dy.round() * image.width + at.dx.round()) * 4;
    image.dispose();
    return data!.buffer.asUint8List().sublist(i, i + 4);
  });
  return Color.fromARGB(rgba![3], rgba[0], rgba[1], rgba[2]);
}

/// A picture that never arrives: what a slow network gives.
class _Loading extends ImageProvider<_Loading> {
  const _Loading();

  @override
  Future<_Loading> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_Loading key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
}

void main() {
  group('a card', () {
    testWidgets('that is a link is one link, worded by its title', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var opened = 0;
      await _app(
        tester,
        CivicCard(
          title: 'Visitor permits',
          url: Uri.parse('/permits/visitor'),
          onPressed: () => opened++,
          child: const Text('8 of 10 days left'),
        ),
      );
      final data = tester
          .getSemantics(find.byType(CivicCard))
          .getSemanticsData();
      expect(data.flagsCollection.isLink, isTrue);
      expect(data.linkUrl, Uri.parse('/permits/visitor'));
      expect(data.label, contains('Visitor permits'));
      await tester.tap(find.text('8 of 10 days left'));
      expect(opened, 1, reason: 'a press anywhere on the card follows it');
      handle.dispose();
    });

    testWidgets('that is not a link has a heading and no action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _app(
        tester,
        const CivicCard(title: 'Your permit', child: Text('Zone B')),
      );
      expect(
        tester.getSemantics(find.text('Your permit')),
        matchesSemantics(label: 'Your permit', isHeader: true),
      );
      handle.dispose();
    });
  });

  group('an accordion', () {
    const sections = [
      CivicAccordionSection(title: 'Who can apply', child: Text('Residents')),
      CivicAccordionSection(title: 'What it costs', child: Text('€60 a year')),
    ];

    testWidgets('opens a section on its heading, and all at once', (
      tester,
    ) async {
      await _app(tester, const CivicAccordion(sections: sections));
      expect(find.text('Residents'), findsNothing);
      await tester.tap(find.text('Who can apply'));
      await tester.pumpAndSettle();
      expect(find.text('Residents'), findsOneWidget);
      expect(find.text('€60 a year'), findsNothing);
      await tester.tap(find.text('Show all sections'));
      await tester.pumpAndSettle();
      expect(find.text('€60 a year'), findsOneWidget);
      expect(find.text('Hide all sections'), findsOneWidget);
      await tester.tap(find.text('Hide all sections'));
      await tester.pumpAndSettle();
      expect(find.text('Residents'), findsNothing);
    });

    testWidgets('says each heading is a heading and whether it is open', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      Set<int>? told;
      await _app(
        tester,
        CivicAccordion(sections: sections, onExpandedChanged: (s) => told = s),
      );
      final heading = find.bySemanticsLabel('What it costs');
      var data = tester.getSemantics(heading).getSemanticsData();
      expect(data.flagsCollection.isHeader, isTrue);
      expect(data.flagsCollection.isExpanded, Tristate.isFalse);
      await tester.tap(find.text('What it costs'));
      await tester.pumpAndSettle();
      data = tester.getSemantics(heading).getSemanticsData();
      expect(data.flagsCollection.isExpanded, Tristate.isTrue);
      expect(told, {1});
      handle.dispose();
    });
  });

  group('the step indicator', () {
    const steps = ['Your vehicle', 'Your details', 'Proof of address'];

    testWidgets('says the step in words below 600', (tester) async {
      await _app(
        tester,
        const CivicStepIndicator(steps: steps, currentStep: 1),
      );
      expect(find.text('Step 2 of 3: Your details'), findsOneWidget);
      expect(find.text('Proof of address'), findsNothing);
    });

    testWidgets("names every step from 600, heard as one line", (tester) async {
      final handle = tester.ensureSemantics();
      await _app(
        tester,
        const SizedBox(
          width: 640,
          child: CivicStepIndicator(steps: steps, currentStep: 1),
        ),
        size: const Size(1024, 768),
      );
      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(find.text('Proof of address'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Step 2 of 3: Your details'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('the step indicator draws', () {
    testWidgets("each step's band across its share of the row", (tester) async {
      await _app(
        tester,
        const SizedBox(
          width: 600,
          child: CivicStepIndicator(
            steps: ['Your vehicle', 'Your details', 'Proof of address'],
            currentStep: 1,
          ),
        ),
        size: const Size(1024, 768),
      );
      final bands = find.descendant(
        of: find.byType(CivicStepIndicator),
        matching: find.byType(DecoratedBox),
      );
      expect(bands, findsNWidgets(3));
      for (final band in bands.evaluate()) {
        final size = (band.renderObject! as RenderBox).size;
        expect(size.width, greaterThan(180));
        expect(size.height, 8);
      }
    });
  });

  group('the page marks', () {
    testWidgets('that only say the place still show it', (tester) async {
      await _app(tester, const CivicPageDots(pageCount: 3, selectedIndex: 1));
      final marks = find.descendant(
        of: find.byType(CivicPageDots),
        matching: find.byType(DecoratedBox),
      );
      expect(
        [for (final m in marks.evaluate()) (m.renderObject! as RenderBox).size],
        [const Size(8, 8), const Size(24, 8), const Size(8, 8)],
      );
    });

    testWidgets('say the place in words and show a page on a press', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      int? shown;
      await _app(
        tester,
        CivicPageDots(
          pageCount: 5,
          selectedIndex: 1,
          onPageChanged: (p) => shown = p,
        ),
      );
      expect(find.text('2 of 5'), findsOneWidget);
      final current = tester
          .getSemantics(find.bySemanticsLabel('Page 2 of 5'))
          .getSemanticsData();
      expect(current.flagsCollection.isSelected, Tristate.isTrue);
      await tester.tap(find.bySemanticsLabel('Page 4 of 5'));
      expect(shown, 3);
      handle.dispose();
    });

    testWidgets('are 24 wide and 48 tall to a pointer', (tester) async {
      await _app(
        tester,
        CivicPageDots(pageCount: 3, selectedIndex: 0, onPageChanged: (_) {}),
      );
      final mark = tester.getSize(find.bySemanticsLabel('Page 2 of 3'));
      expect(mark.width, greaterThanOrEqualTo(24));
      expect(mark.height, greaterThanOrEqualTo(48));
    });
  });

  group('the carousel', () {
    testWidgets('turns on Next and Previous, never on its own', (tester) async {
      final pages = <int>[];
      await _app(
        tester,
        SizedBox(
          width: 358,
          child: CivicCarousel(
            semanticLabel: 'Zones',
            itemCount: 3,
            height: 120,
            onPageChanged: pages.add,
            itemBuilder: (context, i) => Text('Zone ${'ABC'[i]}'),
          ),
        ),
      );
      expect(find.text('1 of 3'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('1 of 3'), findsOneWidget, reason: 'no autoplay');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('2 of 3'), findsOneWidget);
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();
      expect(find.text('1 of 3'), findsOneWidget);
      expect(pages, [1, 0]);
    });
  });

  group('the scroll area', () {
    testWidgets('scrolls by the keys when it is a tab stop', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await _app(
        tester,
        SizedBox(
          width: 300,
          height: 120,
          child: CivicScrollArea(
            controller: scroll,
            focusable: true,
            semanticLabel: 'Terms',
            child: SingleChildScrollView(
              controller: scroll,
              child: const SizedBox(height: 900),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(scroll.offset, greaterThan(0));
    });
  });

  group('a focused region', () {
    const green = Color(0xFF00A000);
    const stage = ValueKey('stage');

    testWidgets('a scroll area keeps its words in sight', (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await _app(
        tester,
        RepaintBoundary(
          key: stage,
          child: Padding(
            padding: const EdgeInsets.all(CivicSpacing.s16),
            child: SizedBox(
              width: 300,
              height: 120,
              child: CivicScrollArea(
                controller: scroll,
                focusable: true,
                semanticLabel: 'Terms',
                child: SingleChildScrollView(
                  controller: scroll,
                  child: const ColoredBox(
                    color: green,
                    child: SizedBox(height: 400, width: 300),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(await _middle(tester, stage, find.byType(CivicScrollArea)), green);
    });

    testWidgets('a carousel keeps its slide in sight', (tester) async {
      await _app(
        tester,
        RepaintBoundary(
          key: stage,
          child: Padding(
            padding: const EdgeInsets.all(CivicSpacing.s16),
            child: SizedBox(
              width: 300,
              child: CivicCarousel(
                semanticLabel: 'Zones',
                itemCount: 2,
                height: 120,
                itemBuilder: (_, _) => const ColoredBox(color: green),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final slides = find.descendant(
        of: find.byType(CivicCarousel),
        matching: find.byType(ClipRRect),
      );
      expect(await _middle(tester, stage, slides.first), green);
    });
  });

  group('the split view', () {
    testWidgets('moves its grip on the arrow keys', (tester) async {
      final shares = <double>[];
      await _app(
        tester,
        SizedBox(
          width: 600,
          height: 200,
          child: CivicSplitView(
            first: const Text('List'),
            second: const Text('Record'),
            onChanged: shares.add,
          ),
        ),
        size: const Size(800, 600),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(shares, isNotEmpty);
      expect(shares.last, greaterThan(0.5));
    });

    testWidgets('below 600 shows one pane at a time, the record with a '
        'way back', (tester) async {
      final handle = tester.ensureSemantics();
      var second = false;
      var backs = 0;
      late StateSetter set;
      await _app(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return SizedBox(
              width: 358,
              height: 300,
              child: CivicSplitView(
                showSecond: second,
                onBack: () {
                  backs++;
                  setState(() => second = false);
                },
                first: const Text('List'),
                second: const Text('Record'),
              ),
            );
          },
        ),
      );
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Record'), findsNothing);
      expect(find.bySemanticsLabel('Record'), findsNothing);
      set(() => second = true);
      await tester.pumpAndSettle();
      expect(find.text('List'), findsNothing, reason: 'kept, not shown');
      expect(find.text('List', skipOffstage: false), findsOneWidget);
      expect(find.text('Record'), findsOneWidget);
      expect(find.bySemanticsLabel('List'), findsNothing);
      // The keyboard starts at the way back.
      expect(Focus.of(tester.element(find.text('Back'))).hasFocus, isTrue);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(backs, 1);
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Record'), findsNothing);
      handle.dispose();
    });

    testWidgets('has a 24-wide gutter for its grip', (tester) async {
      await _app(
        tester,
        const SizedBox(
          width: 600,
          height: 200,
          child: CivicSplitView(first: Text('List'), second: Text('Record')),
        ),
        size: const Size(800, 600),
      );
      final split = tester.getRect(find.byType(CivicSplitView));
      final list = tester.getRect(find.text('List'));
      final record = tester.getRect(find.text('Record'));
      // Shared evenly, the second pane starts half the gutter past the middle.
      expect(record.left - split.center.dx, closeTo(12, 1));
      expect(list.left, lessThan(record.left));
    });
  });

  group('a reorderable list', () {
    testWidgets('moves a row by its words', (tester) async {
      final order = ['Proof of address', 'Vehicle logbook', 'Photo ID'];
      await _app(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 358,
            child: CivicReorderableList<String>(
              items: order,
              labelOf: (d) => d,
              onReorder: (from, to) =>
                  setState(() => order.insert(to, order.removeAt(from))),
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Move down: Proof of address'));
      await tester.pumpAndSettle();
      expect(order, ['Vehicle logbook', 'Proof of address', 'Photo ID']);
      await tester.tap(find.bySemanticsLabel('Move up: Photo ID'));
      await tester.pumpAndSettle();
      expect(order, ['Vehicle logbook', 'Photo ID', 'Proof of address']);
    });

    testWidgets("keeps the first row's Move up off", (tester) async {
      final handle = tester.ensureSemantics();
      await _app(
        tester,
        SizedBox(
          width: 358,
          child: CivicReorderableList<String>(
            items: const ['A', 'B'],
            labelOf: (d) => d,
            onReorder: (_, _) {},
          ),
        ),
      );
      final up = tester
          .getSemantics(find.bySemanticsLabel('Move up: A'))
          .getSemanticsData();
      expect(up.hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });
  });

  group('a swipe row', () {
    testWidgets('has its actions in sight in its menu', (tester) async {
      final done = <String>[];
      await _app(
        tester,
        SizedBox(
          width: 358,
          child: CivicSwipeActions(
            menuLabel: 'Actions for Resident permit',
            endActions: [
              CivicSwipeAction(
                label: 'Archive',
                onPressed: () => done.add('archive'),
              ),
            ],
            child: const CivicListRow(title: Text('Resident permit')),
          ),
        ),
      );
      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is CivicIconButton &&
              w.semanticLabel == 'Actions for Resident permit',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive').last);
      await tester.pumpAndSettle();
      expect(done, ['archive']);
    });

    testWidgets('gives a screen reader its actions', (tester) async {
      final handle = tester.ensureSemantics();
      await _app(
        tester,
        SizedBox(
          width: 358,
          child: CivicSwipeActions(
            menuLabel: 'Actions for Resident permit',
            inSight: false,
            endActions: [CivicSwipeAction(label: 'Archive', onPressed: () {})],
            child: const CivicListRow(title: Text('Resident permit')),
          ),
        ),
      );
      final row = tester
          .getSemantics(find.text('Resident permit'))
          .getSemanticsData();
      expect(row.customSemanticsActionIds, isNotEmpty);
      handle.dispose();
    });
  });

  group('a tree', () {
    testWidgets('opens a row on a press and on Right', (tester) async {
      final tree = RawTreeController<String>(
        roots: const ['Parking', 'Bins'],
        childrenOf: (s) => switch (s) {
          'Parking' => const ['Permits'],
          'Bins' => const ['Collections'],
          _ => const [],
        },
      );
      addTearDown(tree.dispose);
      await _app(
        tester,
        SizedBox(
          width: 358,
          child: CivicTree<String>(controller: tree, labelOf: (s) => s),
        ),
      );
      expect(find.text('Permits'), findsNothing);
      await tester.tap(find.text('Parking'));
      await tester.pumpAndSettle();
      expect(find.text('Permits'), findsOneWidget);
      // The tree's one tab stop is the row last pressed.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(find.text('Collections'), findsOneWidget);
    });
  });

  group('people and figures', () {
    test("an avatar's initials are its name's first and last", () {
      expect(CivicAvatar.initialsOf('Ana Ruiz'), 'AR');
      expect(CivicAvatar.initialsOf('Ana María Ruiz'), 'AR');
      expect(CivicAvatar.initialsOf('Ana'), 'A');
      expect(CivicAvatar.initialsOf('  '), '');
    });

    testWidgets('an avatar group is read in words', (tester) async {
      final handle = tester.ensureSemantics();
      await _app(
        tester,
        const CivicAvatarGroup(
          names: ['Ana Ruiz', 'Ben Okafor', 'Chi Lee', 'Dev Rao'],
        ),
      );
      expect(find.text('+1'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Ana Ruiz, Ben Okafor, Chi Lee and 1 other'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a badge is read with its noun, and 0 shows nothing', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _app(
        tester,
        const Column(
          children: [
            CivicBadge(count: 2, noun: 'update', child: Text('Applications')),
            CivicBadge(count: 140, noun: 'message', child: Text('Messages')),
            CivicBadge(count: 0, noun: 'update', child: Text('Permits')),
          ],
        ),
      );
      expect(find.bySemanticsLabel(RegExp('2 updates')), findsOneWidget);
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      handle.dispose();
    });

    testWidgets('a picture is described, and a missing one says so', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _app(
        tester,
        const SizedBox(
          width: 300,
          child: CivicImage(
            image: null,
            description: 'Map of Zone B',
            caption: 'Zone B',
          ),
        ),
      );
      expect(find.text('Picture not available'), findsOneWidget);
      final picture = tester
          .getSemantics(find.bySemanticsLabel('Map of Zone B'))
          .getSemanticsData();
      expect(picture.flagsCollection.isImage, isTrue);
      handle.dispose();
    });

    testWidgets('a picture still loading holds its place at its ratio', (
      tester,
    ) async {
      await _app(
        tester,
        const SizedBox(
          width: 320,
          child: CivicImage(
            image: _Loading(),
            description: 'Map of Zone B',
            aspectRatio: 16 / 9,
          ),
        ),
      );
      final frame = tester.getSize(find.byType(AspectRatio));
      expect(frame.width / frame.height, closeTo(16 / 9, 0.01));
      final ground = tester.element(find.byType(CivicImage)).civicTheme.surface;
      expect(
        find.descendant(
          of: find.byType(CivicImage),
          matching: find.byWidgetPredicate(
            (w) => w is ColoredBox && w.color == ground,
          ),
        ),
        findsOneWidget,
      );
    });

    test('an amount is shown in figures and read whole', () {
      expect(CivicAmount.show(6250), '€62.50');
      expect(CivicAmount.show(6000), '€60');
      expect(CivicAmount.show(-500), '−€5');
      expect(CivicCurrency.euro.read(6250), '62 euros 50 cents');
      expect(CivicCurrency.euro.read(100), '1 euro');
      expect(CivicCurrency.euro.read(5), '5 cents');
      expect(CivicCurrency.pound.read(-201), 'minus 2 pounds 1 penny');
    });

    test("an amount's figures are the reader's", () async {
      final en = await RawWidgetsLocalizations.delegate.load(
        const Locale('en'),
      );
      final ar = await RawWidgetsLocalizations.delegate.load(
        const Locale('ar'),
      );
      expect(CivicAmount.show(6250, words: en), '€62.50');
      expect(CivicAmount.show(124000, words: en), '€1,240');
      expect(CivicAmount.show(-500, words: en), '−€5');
      expect(CivicAmount.show(6250, words: ar), '€٦٢٫٥٠');
    });

    testWidgets('a key figure is heard as one line', (tester) async {
      final handle = tester.ensureSemantics();
      await _app(
        tester,
        const CivicKeyFigure(
          label: 'Paid this year',
          value: '€120',
          semanticValue: '120 euros',
          detail: 'To 31 October',
        ),
      );
      expect(
        find.bySemanticsLabel('Paid this year, 120 euros, To 31 October'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('the grid', () {
    test('takes one column below 600, two to 1024, three from there', () {
      expect(CivicGrid.columnsFor(390), 1);
      expect(CivicGrid.columnsFor(700), 2);
      expect(CivicGrid.columnsFor(1200), 3);
      expect(CivicGrid.columnsFor(1200, maxColumns: 2), 2);
    });

    testWidgets("stands a row's cells as tall as its tallest", (tester) async {
      // The page's reading column (640) holds two.
      await _app(
        tester,
        const SizedBox(
          width: 640,
          child: CivicGrid(
            children: [
              CivicCard(title: 'Parking', child: Text('Permits')),
              CivicCard(
                title: 'Bins',
                child: Text('Collections\nNew bins\nRecycling'),
              ),
              CivicCard(title: 'Roads', child: Text('Potholes')),
              CivicCard(title: 'Libraries', child: Text('Join')),
            ],
          ),
        ),
        size: const Size(1440, 900),
      );
      final a = tester.getRect(find.widgetWithText(CivicCard, 'Parking'));
      final b = tester.getRect(find.widgetWithText(CivicCard, 'Bins'));
      final c = tester.getRect(find.widgetWithText(CivicCard, 'Roads'));
      expect(a.height, b.height);
      expect(a.top, b.top);
      expect(b.left, greaterThan(a.right));
      expect(c.top, greaterThan(a.bottom), reason: 'the third starts a row');
      expect(c.left, a.left);
    });
  });
}

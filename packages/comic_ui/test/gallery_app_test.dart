// The example's controls change the mounted gallery at phone and desktop widths.
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/main.dart';
import 'gallery_support.dart';
import 'support.dart';

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets('the gallery moves through its own navigation at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(const GalleryApp());
        await settle(tester);
        for (final destination in ['Today', 'Places', 'Figures', 'You']) {
          expect(
            find.bySemanticsLabel(destination),
            findsNothing,
            reason:
                'The live example does not advertise fixed app destinations',
          );
        }
        expect(
          find.byType(ComicSelect<String>),
          findsNothing,
          reason: 'No page picker: the look\'s navigation moves the pages',
        );
        if (width < 840) {
          await tester.tap(find.bySemanticsLabel('Pages').first);
          await settle(tester);
        }
        final settings = find.byKey(const ValueKey('nav/settings'));
        await tester.ensureVisible(settings);
        await settle(tester);
        await tester.tap(settings);
        await settle(tester);
        expect(find.byKey(const ValueKey('live/settings')), findsOneWidget);
        // A row of the page's own (gateSettings, the live page since 11-11).
        expect(find.bySemanticsLabel('Weekly summary'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets(
    'visited pages retain their controls independently per appearance',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1000);
      addTearDown(tester.view.reset);
      final built = <String>[];
      final pages = <GalleryPage>[
        (
          id: 'first',
          title: 'First',
          build: (brightness) {
            built.add('first/${brightness.name}');
            return kitScreen(
              brightness: brightness,
              title: 'First',
              sections: [
                kitState(
                  false,
                  (context, value, change) => ComicCheckRow(
                    label: 'Remember selection',
                    value: value,
                    onChanged: change,
                  ),
                ),
              ],
            );
          },
        ),
        (
          id: 'second',
          title: 'Second',
          build: (brightness) => kitScreen(
            brightness: brightness,
            title: 'Second',
            sections: const [Text('The other page')],
          ),
        ),
      ];
      Widget deck(String id, [Brightness brightness = Brightness.light]) =>
          GalleryPageDeck(
            pages: pages,
            pageId: id,
            brightness: brightness,
            preset: 'offset',
          );
      await tester.pumpWidget(deck('first'));
      await settle(tester);
      final first = tester.element(
        find.byKey(const ValueKey('first/offset/light')),
      );
      await tester.tap(find.byType(ComicCheckRow));
      await settle(tester);
      expect(
        tester.widget<ComicCheckRow>(find.byType(ComicCheckRow)).value,
        isTrue,
      );
      await tester.pumpWidget(deck('second'));
      await settle(tester);
      expect(find.byType(ComicCheckRow), findsNothing);
      await tester.pumpWidget(deck('first'));
      await settle(tester);
      expect(
        tester.element(find.byKey(const ValueKey('first/offset/light'))),
        same(first),
      );
      expect(
        tester.widget<ComicCheckRow>(find.byType(ComicCheckRow)).value,
        isTrue,
      );
      expect(built, ['first/light']);
      await tester.pumpWidget(deck('first', Brightness.dark));
      await settle(tester);
      expect(
        tester.widget<ComicCheckRow>(find.byType(ComicCheckRow)).value,
        isFalse,
      );
      await tester.pumpWidget(deck('first'));
      await settle(tester);
      expect(
        tester.widget<ComicCheckRow>(find.byType(ComicCheckRow)).value,
        isTrue,
      );
      expect(built, ['first/light', 'first/dark']);
      expect(
        find.byType(WidgetsApp, skipOffstage: false),
        findsOneWidget,
        reason: 'Retained pages share one application host',
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final embedded in [false, true]) {
    testWidgets(
      'changing pages dismisses the previous page modal (${embedded ? 'embedded' : 'standalone'})',
      (tester) async {
        Future<bool?>? result;
        final pages = <GalleryPage>[
          (
            id: 'first',
            title: 'First',
            build: (brightness) => kitScreen(
              brightness: brightness,
              title: 'First',
              sections: [
                Builder(
                  builder: (context) => ComicButton.filled(
                    'Open details',
                    onPressed: () => result = showComicDialog<bool>(
                      context,
                      builder: (_) => const ComicDialog(title: 'Page details'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          (
            id: 'second',
            title: 'Second',
            build: (brightness) => kitScreen(
              brightness: brightness,
              title: 'Second',
              sections: const [Text('The other page')],
            ),
          ),
        ];
        Widget deck(String id) {
          final child = GalleryPageDeck(
            pages: pages,
            pageId: id,
            preset: 'offset',
            brightness: Brightness.light,
          );
          return embedded ? MaterialApp(home: child) : child;
        }

        await tester.pumpWidget(deck('first'));
        await settle(tester);
        await tester.tap(find.text('OPEN DETAILS'));
        await settle(tester);
        expect(find.byType(ComicDialog), findsOneWidget);
        await tester.pumpWidget(deck('second'));
        await settle(tester);
        expect(find.byType(ComicDialog), findsNothing);
        expect(await result, isNull);
        await tester.pumpWidget(deck('first'));
        await settle(tester);
        expect(find.byType(ComicDialog), findsNothing);
        expect(find.byType(WidgetsApp, skipOffstage: false), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'hidden retained pages stop ticking and leave the semantics tree',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var ticks = 0;
      final pages = <GalleryPage>[
        (
          id: 'moving',
          title: 'Moving',
          build: (brightness) => kitScreen(
            brightness: brightness,
            title: 'Moving',
            sections: [
              const Text('Only the moving page'),
              _TickCounter(onTick: () => ticks++),
            ],
          ),
        ),
        (
          id: 'still',
          title: 'Still',
          build: (brightness) => kitScreen(
            brightness: brightness,
            title: 'Still',
            sections: const [Text('Only the still page')],
          ),
        ),
      ];
      Widget deck(String id) => GalleryPageDeck(
        pages: pages,
        pageId: id,
        preset: 'offset',
        brightness: Brightness.light,
      );
      await tester.pumpWidget(deck('moving'));
      await settle(tester);
      expect(ticks, greaterThan(0));
      await tester.pumpWidget(deck('still'));
      await settle(tester);
      final paused = ticks;
      await tester.pump(const Duration(seconds: 1));
      expect(ticks, paused);
      expect(find.bySemanticsLabel('Only the moving page'), findsNothing);
      expect(find.bySemanticsLabel('Only the still page'), findsOneWidget);
      await tester.pumpWidget(deck('moving'));
      await settle(tester);
      expect(ticks, greaterThan(paused));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  for (final width in [390.0, 1440.0]) {
    testWidgets('Customize updates the mounted page at $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.reset);
      addTearDown(() {
        kitShownTheme = null;
        kitShownPreset = 'offset';
      });
      await tester.pumpWidget(const GalleryApp());
      await settle(tester);
      final page = find.byKey(const ValueKey('overview/offset/light'));
      final element = tester.element(page);
      ComicThemeData shown() => ComicTheme.of(
        tester.element(find.byKey(const ValueKey('live/overview'))),
      );
      expect(shown().shapes, const ComicShapes());
      await tester.tap(find.bySemanticsLabel('Customize'));
      await settle(tester);

      Future<void> choose(String text) async {
        final choice = find.descendant(
          of: find.byType(CustomizePanel),
          matching: find.text(text),
        );
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await settle(tester);
        expect(tester.element(page), same(element));
        expect(tester.takeException(), isNull);
      }

      await choose('Medium');
      expect(shown().shapes, ComicShapes.rounded(8));
      await choose('Bold');
      expect(shown().strokes, ComicStrokes.bold);
      await choose('Compact');
      expect(shown().density, ComicDensity.compact);
      await tester.tap(find.bySemanticsLabel('Customize'));
      await settle(tester);
      expect(find.byType(CustomizePanel), findsNothing);
      expect(shown().strokes, ComicStrokes.bold);
    });
  }
}

class _TickCounter extends StatefulWidget {
  const _TickCounter({required this.onTick});
  final VoidCallback onTick;
  @override
  State<_TickCounter> createState() => _TickCounterState();
}

class _TickCounterState extends State<_TickCounter>
    with SingleTickerProviderStateMixin {
  late final _ticker = createTicker((_) => widget.onTick());
  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(height: 20);
}

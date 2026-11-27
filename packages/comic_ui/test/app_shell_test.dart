// ComicAppShell: comic's places through ui_core's shell at every width. On a phone a tab bar a screen reader hears as
// tabs, the chosen one selected; on a desktop the masthead's links, the page's bar under it with its way back; a page
// pushed on a place keeps the masthead while the tab bar steps away, and back pops it; a toast stands above the bar.
import 'dart:ui' show SemanticsRole;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

const _places = [
  ComicNavItem(
    key: ValueKey('place Books'),
    label: 'Books',
    short: 'Books',
    icon: ComicGlyphs.house,
  ),
  ComicNavItem(
    key: ValueKey('place Alerts'),
    label: 'Alerts',
    short: 'Alerts',
    icon: ComicGlyphs.bell,
    badge: '3',
    badgeLabel: '3 new',
  ),
  ComicNavItem(
    key: ValueKey('place Settings'),
    label: 'Settings',
    short: 'Me',
    icon: ComicGlyphs.person,
  ),
];

Future<void> _size(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

// A place's first page: its title in the page's bar and a button that pushes a detail page on the place's stack.
Widget _root(String name) => Builder(
  builder: (context) => ComicScaffold(
    topBar: ComicAppBar(title: '$name page'),
    body: Column(
      children: [
        ComicButton.filled(
          'Open $name',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const ComicScaffold(
                topBar: ComicAppBar(title: 'Detail'),
                body: Text('Detail body'),
              ),
            ),
          ),
        ),
        // Raised from inside the page, under its own footer's scope.
        Builder(
          builder: (context) => ComicButton.text(
            'Toast $name',
            onPressed: () => showComicToast(context, 'Saved $name'),
          ),
        ),
      ],
    ),
  ),
);

class _App extends StatefulWidget {
  const _App({super.key, this.action, this.mode, this.body = false});
  final ComicAppAction? action;
  final RawNavigationMode? mode;
  final bool body;
  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  int place = 0;
  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    void choose(int index) => setState(() => place = index);
    return widget.body
        ? ComicAppShell(
            brand: 'Shelf',
            destinations: _places,
            selectedIndex: place,
            onDestinationSelected: choose,
            action: widget.action,
            modeForWidth: mode == null ? ComicAppShell.modeFor : (_) => mode,
            body: IndexedStack(
              index: place,
              children: [for (final p in _places) _root(p.label)],
            ),
          )
        : ComicAppShell.branches(
            brand: 'Shelf',
            destinations: _places,
            selectedIndex: place,
            onDestinationSelected: choose,
            action: widget.action,
            modeForWidth: mode == null ? ComicAppShell.modeFor : (_) => mode,
            branches: [for (final p in _places) (context) => _root(p.label)],
          );
  }
}

Rect _rect(WidgetTester tester, Finder finder) => tester.getRect(finder);

// A title, in whatever case the look letters it.
Finder _title(String words) => find.byWidgetPredicate(
  (w) => w is Text && w.data?.toUpperCase() == words.toUpperCase(),
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  testWidgets(
    'on a phone the places are a tab bar at the foot: tabs, the chosen one selected',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _size(tester, 390);
      await tester.pumpWidget(comicApp(const _App(), width: 390));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final books = tester.getSemantics(
        find.byKey(const ValueKey('place Books')),
      );
      expect(books.getSemanticsData().role, SemanticsRole.tab);
      expect(books.parent!.role, SemanticsRole.tabBar);
      expect(books, isSemantics(isSelected: true));
      final alerts = tester.getSemantics(
        find.byKey(const ValueKey('place Alerts')),
      );
      expect(alerts, isSemantics(isSelected: false));
      expect(alerts.getSemanticsData().label, startsWith('Alerts, 3 new'));
      // At the window's foot.
      expect(
        _rect(tester, find.byKey(const ValueKey('place Books'))).bottom,
        greaterThan(800),
      );
      await tester.tap(find.byKey(const ValueKey('place Alerts')));
      await tester.pumpAndSettle();
      expect(_title('Alerts page'), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const ValueKey('place Alerts'))),
        isSemantics(isSelected: true),
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'the act stands in the bar outside its tab bar, on the tabs\' lines',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var calls = 0;
      await _size(tester, 390);
      await tester.pumpWidget(
        comicApp(
          _App(
            action: ComicAppAction(
              icon: ComicGlyphs.plus,
              label: 'New',
              onPressed: () => calls++,
            ),
          ),
          width: 390,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final act = find.byWidgetPredicate(
        (w) => w is ComicPressable && w.semanticLabel == 'New',
      );
      expect(act, findsOneWidget);
      await tester.tap(act);
      expect(calls, 1);
      final tabBar = tester
          .getSemantics(find.byKey(const ValueKey('place Books')))
          .parent!;
      var tabs = 0;
      tabBar.visitChildren((child) {
        expect(child.getSemanticsData().role, SemanticsRole.tab);
        tabs++;
        return true;
      });
      expect(tabs, 3);
      // The act's middle stands between the second and third tabs.
      final middle = _rect(tester, act).center.dx;
      expect(
        middle,
        greaterThan(
          _rect(tester, find.byKey(const ValueKey('place Alerts'))).right,
        ),
      );
      expect(
        middle,
        lessThan(
          _rect(tester, find.byKey(const ValueKey('place Settings'))).left,
        ),
      );
      // Its glyph on the tabs' glyph line, its words' foot on theirs: one row, not a balloon above it.
      final glyph = _rect(tester, find.byIcon(ComicGlyphs.plus));
      final tabGlyph = _rect(tester, find.byIcon(ComicGlyphs.house));
      expect(
        glyph.center.dy,
        moreOrLessEquals(tabGlyph.center.dy, epsilon: .5),
      );
      expect(
        _rect(tester, act).bottom,
        moreOrLessEquals(
          _rect(tester, find.byKey(const ValueKey('place Books'))).bottom,
          epsilon: .5,
        ),
      );
      semantics.dispose();
    },
  );

  test('its places: a tab bar on a phone, a rail from 600, the masthead on a desktop', () {
    expect(ComicAppShell.modeFor(390), RawNavigationMode.bar);
    expect(ComicAppShell.modeFor(599), RawNavigationMode.bar);
    expect(ComicAppShell.modeFor(600), RawNavigationMode.rail);
    expect(ComicAppShell.modeFor(comicDeskWidth - 1), RawNavigationMode.rail);
    expect(ComicAppShell.modeFor(comicDeskWidth), RawNavigationMode.top);
  });

  testWidgets(
    'on a tablet the places stand in a rail at the start, the act at its head',
    (tester) async {
      await _size(tester, 800);
      await tester.pumpWidget(
        comicApp(
          _App(
            action: ComicAppAction(
              icon: ComicGlyphs.plus,
              label: 'New',
              onPressed: () {},
            ),
          ),
          width: 800,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final books = _rect(tester, find.byKey(const ValueKey('place Books')));
      expect(books.right, lessThanOrEqualTo(120));
      final page = _rect(tester, _title('Books page'));
      expect(page.left, greaterThanOrEqualTo(books.right));
      expect(
        _rect(tester, find.byIcon(ComicGlyphs.plus)).bottom,
        lessThan(books.top),
      );
    },
  );

  for (final direction in TextDirection.values) {
    testWidgets(
      'on a desktop the places are the masthead\'s links ($direction)',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _size(tester, 1440);
        await tester.pumpWidget(
          comicApp(
            _App(
              action: ComicAppAction(
                icon: ComicGlyphs.plus,
                label: 'New',
                onPressed: () {},
              ),
            ),
            width: 1440,
            direction: direction,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final books = find.byKey(const ValueKey('place Books'));
        expect(_rect(tester, books).top, lessThan(75));
        expect(
          tester.getSemantics(books).getSemanticsData().role,
          SemanticsRole.tab,
        );
        expect(tester.getSemantics(books).parent!.role, SemanticsRole.tabBar);
        expect(find.text('BOOKS'), findsOneWidget);
        // The app's name once, at the masthead's start; the act at its end.
        expect(find.byType(ComicLogo), findsOneWidget);
        final logo = _rect(tester, find.byType(ComicLogo));
        final act = _rect(
          tester,
          find.byWidgetPredicate(
            (w) => w is ComicPressable && w.semanticLabel == 'New',
          ),
        );
        if (direction == TextDirection.ltr) {
          expect(logo.right, lessThan(_rect(tester, books).left));
          expect(act.left, greaterThan(_rect(tester, books).right));
        } else {
          expect(logo.left, greaterThan(_rect(tester, books).right));
          expect(act.right, lessThan(_rect(tester, books).left));
        }
        // The page's title stands under the masthead, once.
        expect(_title('Books page'), findsOneWidget);
        expect(
          _rect(tester, _title('Books page')).top,
          greaterThan(_rect(tester, books).bottom),
        );
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'a page pushed on a place: on a phone the bar steps away, back pops it and the bar returns',
    (tester) async {
      await _size(tester, 390);
      await tester.pumpWidget(comicApp(const _App(), width: 390));
      await tester.pumpAndSettle();
      final books = find.byKey(const ValueKey('place Books'));
      final barTop = _rect(tester, books).top;
      await tester.tap(_title('Open Books'));
      await tester.pumpAndSettle();
      expect(find.text('Detail body'), findsOneWidget);
      expect(books.hitTestable(), findsNothing, reason: 'the bar stepped away');
      // Back pops the place's own page, not the app's.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Detail body'), findsNothing);
      expect(_title('Books page'), findsOneWidget);
      expect(_rect(tester, books).top, barTop);
      expect(books.hitTestable(), findsOneWidget);
    },
  );

  testWidgets('a page pushed on a place keeps the masthead on a desktop', (
    tester,
  ) async {
    await _size(tester, 1440);
    await tester.pumpWidget(comicApp(const _App(), width: 1440));
    await tester.pumpAndSettle();
    await tester.tap(_title('Open Books'));
    await tester.pumpAndSettle();
    expect(find.text('Detail body'), findsOneWidget);
    final books = find.byKey(const ValueKey('place Books'));
    expect(books.hitTestable(), findsOneWidget);
    expect(_rect(tester, books).top, lessThan(75));
    // The pushed page's bar keeps its way back under the masthead.
    expect(find.byType(ComicLogo), findsOneWidget);
    expect(_title('Detail'), findsOneWidget);
  });

  for (final body in [false, true]) {
    testWidgets('a toast stands above the tab bar (body: $body)', (
      tester,
    ) async {
      await _size(tester, 390);
      await tester.pumpWidget(comicApp(_App(body: body), width: 390));
      await tester.pumpAndSettle();
      await tester.tap(_title('Toast Books'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final toast = _rect(tester, find.byType(ComicToast));
      final bar = _rect(tester, find.byKey(const ValueKey('place Books')));
      expect(toast.bottom, lessThanOrEqualTo(bar.top));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    });
  }

  for (final direction in TextDirection.values) {
    testWidgets('a rail and a sidebar stand at the start ($direction)', (
      tester,
    ) async {
      await _size(tester, 1100);
      for (final (mode, width) in const [
        (RawNavigationMode.rail, 88.0),
        (RawNavigationMode.sidebar, 304.0),
      ]) {
        await tester.pumpWidget(
          comicApp(
            _App(mode: mode, key: ValueKey(mode)),
            width: 1100,
            direction: direction,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final books = _rect(tester, find.byKey(const ValueKey('place Books')));
        final settings = _rect(
          tester,
          find.byKey(const ValueKey('place Settings')),
        );
        expect(settings.top, greaterThan(books.bottom - 1), reason: '$mode');
        if (direction == TextDirection.ltr) {
          expect(books.right, lessThanOrEqualTo(width), reason: '$mode');
        } else {
          expect(
            books.left,
            greaterThanOrEqualTo(1100 - width),
            reason: '$mode',
          );
        }
        // The page beside them, not under them.
        final page = _rect(tester, _title('Books page'));
        if (direction == TextDirection.ltr) {
          expect(page.left, greaterThanOrEqualTo(width), reason: '$mode');
        } else {
          expect(page.right, lessThanOrEqualTo(1100 - width), reason: '$mode');
        }
      }
    });
  }
}

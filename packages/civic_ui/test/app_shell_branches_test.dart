// CivicAppShell.branches: each place keeps its own stack of pages. A page
// pushed over a place keeps the rail or the side navigation beside it, in
// the semantics tree and on Tab's way, while a phone's bar steps away; back
// pops it, and choosing the place again goes back to its first page; a
// toast shown once the page is popped keeps clear of the bar; from a
// desktop's width a pushed page's title keeps the column line, its way back
// hung in the gutter before it. At 390, 800
// and 1440 wide, left to right and right to left. And CivicSideNavigation,
// standing alone in a row beside a page, keeps a width of its own.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'screens_matrix.dart' show loadScreenFonts;

const _keys = ['books', 'add', 'settings'];

const _places = [
  CivicNavItem(LucideIcons.libraryBig, 'Books', ValueKey('books')),
  CivicNavItem(LucideIcons.plus, 'Add', ValueKey('add')),
  CivicNavItem(LucideIcons.settings, 'Settings', ValueKey('settings')),
];

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => CivicAppShell.branches(
    destinations: _places,
    selectedIndex: _index,
    onDestinationSelected: (i) => setState(() => _index = i),
    branches: [
      (context) => CivicScreen(
        topBar: const CivicTopBar(title: 'Books'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CivicButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => CivicScreen(
                    topBar: CivicTopBar(
                      title: 'Dune',
                      leading: CivicTopBar.autoLeading(context),
                    ),
                    body: const Text('Frank Herbert'),
                  ),
                ),
              ),
              child: const Text('Open Dune'),
            ),
            Builder(
              builder: (context) => CivicButton.secondary(
                onPressed: () => CivicToast.show(context, 'Saved'),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
      (context) => const CivicScreen(
        topBar: CivicTopBar(title: 'Add'),
        body: Text('Add a book'),
      ),
      (context) => const CivicScreen(
        topBar: CivicTopBar(title: 'Settings'),
        body: Text('Appearance'),
      ),
    ],
  );
}

Future<void> _show(
  WidgetTester tester,
  double width,
  TextDirection direction,
) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Directionality(
        textDirection: direction,
        child: CivicHost(child: child ?? const SizedBox.shrink()),
      ),
      home: const _Shell(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openDune(WidgetTester tester) async {
  await tester.tap(find.text('Open Dune'));
  await tester.pumpAndSettle();
  expect(find.text('Frank Herbert'), findsOneWidget);
}

/// The labels a screen reader walks through, in order: each one's first
/// line (a tab's place in the bar follows it).
List<String> _heard(WidgetTester tester) => [
  for (final node in tester.semantics.simulatedAccessibilityTraversal())
    node.getSemanticsData().label.split('\n').first,
];

/// Whether the focus is on one of the places.
bool _onAPlace() {
  final at = FocusManager.instance.primaryFocus?.context;
  if (at == null) return false;
  var places = 0;
  void visit(Element e) {
    final key = e.widget.key;
    if (key is ValueKey && _keys.contains(key.value)) places++;
    e.visitChildren(visit);
  }

  (at as Element).visitChildren(visit);
  return places == 1;
}

void main() {
  setUpAll(loadScreenFonts);

  for (final width in [390.0, 800.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      final where = '${width.toInt()}, ${direction.name}';
      final phone = width < 600;

      testWidgets(
        phone
            ? 'a pushed page takes the bar away, and back brings it ($where)'
            : 'a pushed page keeps the places beside it, heard and on '
                  "Tab's way ($where)",
        (tester) async {
          final semantics = tester.ensureSemantics();
          await _show(tester, width, direction);
          await _openDune(tester);
          final settings = find.byKey(const ValueKey('settings'));
          if (phone) {
            expect(settings.hitTestable(), findsNothing);
            expect(_heard(tester), isNot(contains('Settings')));
          } else {
            expect(settings.hitTestable(), findsOneWidget);
            expect(_heard(tester), containsAll(['Add', 'Settings']));
            // Tab reaches the places from the pushed page.
            var reached = false;
            for (var i = 0; i < 24 && !reached; i++) {
              await tester.sendKeyEvent(LogicalKeyboardKey.tab);
              await tester.pump();
              reached = _onAPlace();
            }
            expect(reached, isTrue, reason: 'Tab reaches the places');
          }
          // Back pops the page over the place, the places all there.
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text('Frank Herbert'), findsNothing);
          expect(find.text('Open Dune'), findsOneWidget);
          expect(settings.hitTestable(), findsOneWidget);
          expect(_heard(tester), containsAll(['Add', 'Settings']));
          semantics.dispose();
        },
      );

      testWidgets('choosing the place again goes back to its first page, '
          'and another place keeps its own stack ($where)', (tester) async {
        await _show(tester, width, direction);
        await _openDune(tester);
        if (phone) {
          // The bar is away: back first, then the place again.
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await _openDune(tester);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
        } else {
          await tester.tap(find.byKey(const ValueKey('settings')));
          await tester.pumpAndSettle();
          expect(find.text('Appearance'), findsOneWidget);
          // Back on Books, Dune still stands over it.
          await tester.tap(find.byKey(const ValueKey('books')));
          await tester.pumpAndSettle();
          expect(find.text('Frank Herbert'), findsOneWidget);
          // Books again: its first page.
          await tester.tap(find.byKey(const ValueKey('books')));
          await tester.pumpAndSettle();
        }
        expect(find.text('Frank Herbert'), findsNothing);
        expect(find.text('Open Dune'), findsOneWidget);
      });

      testWidgets('a toast shown after a page is popped keeps clear of the '
          'bar, and of the places beside the page ($where)', (tester) async {
        await _show(tester, width, direction);
        await _openDune(tester);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        final toast = tester.getRect(find.text('Saved'));
        final books = tester.getRect(find.byKey(const ValueKey('books')));
        if (phone) {
          expect(toast.bottom, lessThanOrEqualTo(books.top));
        } else if (direction == TextDirection.ltr) {
          expect(toast.left, greaterThanOrEqualTo(books.right));
        } else {
          expect(toast.right, lessThanOrEqualTo(books.left));
        }
        await tester.pumpAndSettle(const Duration(seconds: 7));
      });
    }
  }

  testWidgets('CivicSideNavigation alone in a row keeps a width of its own', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            CivicHost(child: child ?? const SizedBox.shrink()),
        home: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CivicSideNavigation(
              destinations: _places,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
            const Expanded(child: CivicScreen(body: Text('Page'))),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final side = tester.getRect(find.byType(CivicSideNavigation));
    final page = tester.getRect(find.byType(CivicScreen));
    expect(side.width, greaterThan(120));
    expect(side.width, lessThanOrEqualTo(1440 / 3));
    expect(page.left, moreOrLessEquals(side.right));
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 800.0, 1024.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      final where = '${width.toInt()}, ${direction.name}';
      final desktop = width >= CivicLayout.expanded;
      testWidgets(
        desktop
            ? "a pushed page's title keeps the column line, the way back in "
                  'the gutter before it ($where)'
            : "a pushed page's way back stands before its title ($where)",
        (tester) async {
          await _show(tester, width, direction);
          final ltr = direction == TextDirection.ltr;
          Rect title(String words) => tester.getRect(
            find.descendant(
              of: find.byType(CivicTopBar),
              matching: find.text(words),
            ),
          );
          final root = title('Books');
          await _openDune(tester);
          final pushed = title('Dune');
          final bar = tester.getRect(find.byType(CivicTopBar));
          final back = tester.getRect(
            find
                .ancestor(
                  of: find.byIcon(LucideIcons.chevronLeft),
                  matching: find.byType(CivicIconButton),
                )
                .first,
          );
          // The way back never takes less than the touch floor.
          expect(back.width, greaterThanOrEqualTo(40));
          expect(back.height, greaterThanOrEqualTo(40));
          // It stands within the bar, before the words.
          expect(back.left, greaterThanOrEqualTo(bar.left - 0.5));
          expect(back.right, lessThanOrEqualTo(bar.right + 0.5));
          if (ltr) {
            expect(back.right, lessThanOrEqualTo(pushed.left + 0.5));
          } else {
            expect(back.left, greaterThanOrEqualTo(pushed.right - 0.5));
          }
          if (desktop) {
            // The words don't move as the page is pushed.
            expect(
              ltr ? pushed.left : pushed.right,
              moreOrLessEquals(ltr ? root.left : root.right, epsilon: 0.5),
            );
          }
          // It goes back.
          await tester.tapAt(back.center);
          await tester.pumpAndSettle();
          expect(find.text('Frank Herbert'), findsNothing);
          expect(find.text('Open Dune'), findsOneWidget);
        },
      );
    }
  }
}

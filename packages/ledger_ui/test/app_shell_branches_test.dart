// LedgerAppShell.branches: each place keeps its own stack of pages. A page
// pushed over a place keeps the rail or the sidebar beside it, in the
// semantics tree and on Tab's way, while a phone's bar steps away; back pops
// it, and choosing the place again goes back to its first page; a toast shown
// once the page is popped keeps clear of the bar and stands where it stood
// before the page was pushed. At 390, 800 and 1440 wide, left to right and
// right to left. And LedgerSideBar, standing alone in a row beside a page,
// keeps a width of its own.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

const _keys = ['books', 'add', 'settings'];

const _places = [
  LedgerNavItem(LucideIcons.libraryBig, 'Books', ValueKey('books')),
  LedgerNavItem(LucideIcons.plus, 'Add', ValueKey('add')),
  LedgerNavItem(LucideIcons.settings, 'Settings', ValueKey('settings')),
];

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => LedgerAppShell.branches(
    destinations: _places,
    selectedIndex: _index,
    onDestinationSelected: (i) => setState(() => _index = i),
    brand: 'Shelf',
    branches: [
      (context) => LedgerScreen(
        topBar: const LedgerTopBar(title: 'Books'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LedgerButton(
              'Open Dune',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const LedgerScreen(
                    topBar: LedgerTopBar(title: 'Dune', backLabel: 'Books'),
                    body: Text('Frank Herbert'),
                  ),
                ),
              ),
            ),
            Builder(
              builder: (context) => LedgerButton(
                'Save',
                onPressed: () => LedgerToast.show(context, 'Saved'),
              ),
            ),
          ],
        ),
      ),
      (context) => const LedgerScreen(
        topBar: LedgerTopBar(title: 'Add'),
        body: Text('Add a book'),
      ),
      (context) => const LedgerScreen(
        topBar: LedgerTopBar(title: 'Settings'),
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
        child: LedgerHost(child: child ?? const SizedBox.shrink()),
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

/// The labels a screen reader walks through, in order: each one's first line.
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

/// Where the toast "Saved" stands once it has come in.
Future<Rect> _toast(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  final at = tester.getRect(find.text('Saved'));
  await tester.pumpAndSettle(const Duration(seconds: 7));
  return at;
}

void main() {
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
            var reached = false;
            for (var i = 0; i < 24 && !reached; i++) {
              await tester.sendKeyEvent(LogicalKeyboardKey.tab);
              await tester.pump();
              reached = _onAPlace();
            }
            expect(reached, isTrue, reason: 'Tab reaches the places');
          }
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
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
        } else {
          await tester.tap(find.byKey(const ValueKey('settings')));
          await tester.pumpAndSettle();
          expect(find.text('Appearance'), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('books')));
          await tester.pumpAndSettle();
          expect(find.text('Frank Herbert'), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('books')));
          await tester.pumpAndSettle();
        }
        expect(find.text('Frank Herbert'), findsNothing);
        expect(find.text('Open Dune'), findsOneWidget);
      });

      testWidgets('a toast keeps clear of the places, and stands where it '
          'stood once a pushed page is popped ($where)', (tester) async {
        await _show(tester, width, direction);
        final before = await _toast(tester);
        await _openDune(tester);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        final after = await _toast(tester);
        expect(after, before);
        final books = tester.getRect(find.byKey(const ValueKey('books')));
        if (phone) {
          expect(after.bottom, lessThanOrEqualTo(books.top));
        } else if (direction == TextDirection.ltr) {
          expect(after.left, greaterThanOrEqualTo(books.right));
        } else {
          expect(after.right, lessThanOrEqualTo(books.left));
        }
      });
    }
  }

  testWidgets('LedgerSideBar alone in a row keeps a width of its own', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            LedgerHost(child: child ?? const SizedBox.shrink()),
        home: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LedgerSideBar(
              items: _places,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
            const Expanded(child: LedgerScreen(body: Text('Page'))),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(LedgerSideBar)).width,
      LedgerSideBar.width,
    );
    expect(tester.takeException(), isNull);
  });
}

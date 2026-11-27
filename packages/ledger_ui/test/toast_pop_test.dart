// A toast raised on a pushed page that then pops (a book deleted from its
// own page) rides up with the phone's bar as it comes back: it never stands
// over the bar and never jumps, frame to frame.
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

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
                  builder: (context) => LedgerScreen(
                    topBar: const LedgerTopBar(
                      title: 'Dune',
                      backLabel: 'Books',
                    ),
                    body: Column(
                      children: [
                        const Text('Frank Herbert'),
                        LedgerButton(
                          'Delete',
                          onPressed: () {
                            LedgerToast.show(context, 'Saved');
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
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

void main() {
  testWidgets('a toast raised as a pushed page pops rides up with the bar', (
    tester,
  ) async {
    await _show(tester, 390, TextDirection.ltr);
    await _openDune(tester);
    await tester.tap(find.text('Delete'));
    final books = find.byKey(const ValueKey('books'));
    double? was;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (find.text('Saved').evaluate().isEmpty) continue;
      final toast = tester.getRect(find.text('Saved'));
      if (books.evaluate().isNotEmpty) {
        expect(toast.bottom, lessThan(tester.getRect(books.first).top));
      }
      if (was != null) expect((toast.bottom - was).abs(), lessThan(24));
      was = toast.bottom;
    }
    await tester.pumpAndSettle();
  });
}

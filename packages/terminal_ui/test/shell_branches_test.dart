// TermScaffold.branches: each place keeps its own stack of screens. A
// screen pushed over a place keeps the rail or the side pane beside it while
// a phone's window list steps away; back pops it; choosing the place again
// goes back to its first screen. At 390, 800 and 1440 wide, left to right
// and right to left.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _place = 0;

  @override
  Widget build(BuildContext context) => TermScaffold.branches(
    title: 'shelf',
    destinations: const [
      TermNavigationDestination(label: 'books'),
      TermNavigationDestination(label: 'add'),
      TermNavigationDestination(label: 'settings'),
    ],
    selectedIndex: _place,
    onDestinationSelected: (i) => setState(() => _place = i),
    branches: [
      (context) => Center(
        child: TermButton(
          label: 'open dune',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const Center(child: Text('Frank Herbert')),
            ),
          ),
        ),
      ),
      (context) => const Center(child: Text('a new book')),
      (context) => const Center(child: Text('appearance')),
    ],
  );
}

Future<void> _show(WidgetTester tester, double width, TextDirection d) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => Directionality(
        textDirection: d,
        child: TermHost(brightness: Brightness.dark, child: child!),
      ),
      home: const _Shell(),
    ),
  );
  await tester.pumpAndSettle();
}

// The rail draws a place's number alone: a place is found as a screen
// reader hears it.
Finder _place(String label) =>
    find.bySemanticsLabel(RegExp(label)).hitTestable();

void main() {
  setUpAll(loadFaces);

  for (final width in [390.0, 800.0, 1440.0]) {
    for (final d in TextDirection.values) {
      final where = '${width.round()}, ${d.name}';
      final phone = width < 600;
      testWidgets(
        phone
            ? 'a pushed screen takes the window list away; back brings it ($where)'
            : 'a pushed screen keeps the places beside it ($where)',
        (tester) async {
          final semantics = tester.ensureSemantics();

          await _show(tester, width, d);
          expect(_place('settings'), findsWidgets);
          await tester.tap(find.text('open dune'));
          await tester.pumpAndSettle();
          expect(find.text('Frank Herbert'), findsOneWidget);
          expect(_place('settings'), phone ? findsNothing : findsWidgets);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.text('Frank Herbert'), findsNothing);
          expect(find.text('open dune'), findsOneWidget);
          expect(_place('settings'), findsWidgets);
          semantics.dispose();
        },
      );

      if (!phone) {
        testWidgets('another place keeps its own stack; the place again goes '
            'to its first screen ($where)', (tester) async {
          final semantics = tester.ensureSemantics();

          await _show(tester, width, d);
          await tester.tap(find.text('open dune'));
          await tester.pumpAndSettle();
          await tester.tap(_place('settings').first);
          await tester.pumpAndSettle();
          expect(find.text('appearance'), findsOneWidget);
          await tester.tap(_place('books').first);
          await tester.pumpAndSettle();
          expect(find.text('Frank Herbert'), findsOneWidget);
          await tester.tap(_place('books').first);
          await tester.pumpAndSettle();
          expect(find.text('Frank Herbert'), findsNothing);
          expect(find.text('open dune'), findsOneWidget);
          semantics.dispose();
        });
      }
    }
  }
}

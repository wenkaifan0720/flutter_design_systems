// TermScreen: a screen's title line (a back key when its route can go back),
// then its body, scrolling, on a column at most maxCols cells wide at the
// screen's start; the whole width when null.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

Widget _app(Widget home, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      builder: (context, child) => Directionality(
        textDirection: direction,
        child: TermTheme(data: TermThemeData.dark(), child: child!),
      ),
      home: home,
    );

void main() {
  setUpAll(loadFaces);

  testWidgets("a place's first screen has no back key; a pushed one has, and "
      'it goes back', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TermScreen(
            title: 'books',
            body: TermButton(
              label: 'open',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const TermScreen(
                    title: 'Middlemarch',
                    subtitle: 'books',
                    body: Text('George Eliot'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('←'), findsNothing);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('←'), findsOneWidget);
    expect(find.bySemanticsLabel('back'), findsOneWidget);
    expect(find.text('Middlemarch'), findsOneWidget);
    await tester.tap(find.text('←'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('right to left, the back key points right', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TermButton(
            label: 'open',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) =>
                    const TermScreen(title: 'book', body: SizedBox()),
              ),
            ),
          ),
        ),
        direction: TextDirection.rtl,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('→'), findsOneWidget);
  });

  testWidgets('the body keeps to maxCols cells at the start, or the whole '
      'width', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    const body = ValueKey('body');
    await tester.pumpWidget(
      _app(
        const TermScreen(
          title: 'add a book',
          maxCols: TermScreen.formCols,
          body: SizedBox(key: body, height: 40, width: double.infinity),
        ),
      ),
    );
    final grid = TermThemeData.dark().grid;
    final r = tester.getRect(find.byKey(body));
    expect(r.width, closeTo(grid.cols(TermScreen.formCols), 0.5));
    expect(r.left, closeTo(grid.cellWidth, 0.5));
    await tester.pumpWidget(
      _app(
        const TermScreen(
          title: 'books',
          body: SizedBox(key: body, height: 40, width: double.infinity),
        ),
      ),
    );
    expect(
      tester.getRect(find.byKey(body)).width,
      closeTo(1440 - 2 * grid.cellWidth, 0.5),
    );
  });

  testWidgets('a tall body scrolls under the title line', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        TermScreen(
          title: 'books',
          body: Column(
            children: [for (var i = 0; i < 60; i++) Text('line $i')],
          ),
        ),
      ),
    );
    final top = tester.getRect(find.byType(TermTopBar)).top;
    final before = tester.getRect(find.text('line 20')).top;
    expect(before, greaterThan(400));
    await tester.drag(find.text('line 3'), const Offset(0, -300));
    await tester.pumpAndSettle();
    // The body moved up under the title line, which stayed.
    expect(tester.getRect(find.text('line 20')).top, lessThan(before - 200));
    expect(tester.getRect(find.byType(TermTopBar)).top, top);
    expect(
      tester.getRect(find.text('line 20')).top,
      greaterThanOrEqualTo(tester.getRect(find.byType(TermTopBar)).bottom),
    );
    expect(tester.takeException(), isNull);
  });
}

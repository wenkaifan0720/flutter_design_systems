// A screen's title wins over its path: on a line too short for both the path
// goes and the title stays, cut with an ellipsis when it must be; where both
// fit, the path's last steps stand whole after the title as before.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

Future<void> _bar(WidgetTester tester, double width, TermTopBar bar) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: TermTheme(
        data: TermThemeData.dark(),
        child: Align(alignment: Alignment.topLeft, child: bar),
      ),
    ),
  );
}

String _drawn(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(of: find.byType(TermTopBar), matching: find.byType(Text)),
    )
    .map((t) => t.data ?? t.textSpan!.toPlainText())
    .join(' | ');

void main() {
  setUpAll(loadFaces);

  testWidgets('a long title and a short path on a phone: the title stays', (
    tester,
  ) async {
    await _bar(
      tester,
      390,
      const TermTopBar(
        title: 'The Dispossessed: An Ambiguous Utopia',
        subtitle: 'books',
      ),
    );
    final title = find.text('The Dispossessed: An Ambiguous Utopia');
    expect(title, findsOneWidget, reason: _drawn(tester));
    expect(
      tester.getRect(title).right,
      lessThanOrEqualTo(tester.getRect(find.byType(TermTopBar)).right),
    );
    expect(find.textContaining('books'), findsNothing, reason: _drawn(tester));
    expect(tester.takeException(), isNull);
  });

  testWidgets("an edit screen's title stays when its path is long", (
    tester,
  ) async {
    await _bar(
      tester,
      390,
      const TermTopBar(
        title: 'edit book',
        subtitle: 'books › The Dispossessed: An Ambiguous Utopia',
      ),
    );
    expect(find.text('edit book'), findsOneWidget, reason: _drawn(tester));
  });

  testWidgets('the path the title leaves no room for is still heard', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _bar(
      tester,
      390,
      const TermTopBar(
        title: 'edit book',
        subtitle: 'books › The Dispossessed: An Ambiguous Utopia',
      ),
    );
    expect(
      find.bySemanticsLabel(RegExp('^edit book, books › The Dispossessed')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('where both fit, the path stands after the title', (
    tester,
  ) async {
    await _bar(
      tester,
      390,
      const TermTopBar(title: 'run', subtitle: 'atlas-api › runs'),
    );
    expect(find.text('run'), findsOneWidget);
    expect(find.textContaining('runs'), findsOneWidget);
  });
}

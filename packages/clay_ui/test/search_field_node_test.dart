// A search field keeps its text entry's semantics node as its clear key
// shows with the first letter and goes with the last. On the web that node
// is the browser's input: a new one loses the keys typed after it, while
// the field still looks focused.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Widget _app() => MaterialApp(
  builder: (context, app) =>
      ClayTheme(data: ClayThemeData.clay(Brightness.light), child: app!),
  home: const Padding(
    padding: EdgeInsets.all(24),
    child: Align(
      alignment: Alignment.topCenter,
      child: ClaySearchField(hintText: 'Habits, notes'),
    ),
  ),
);

void main() {
  testWidgets('a search field keeps its node as its clear key comes and goes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    final field = find.byType(EditableText);
    await tester.tap(field);
    await tester.pumpAndSettle();
    final before = tester.getSemantics(field).id;
    expect(find.byTooltip('Clear'), findsNothing);
    await tester.enterText(field, 's');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Clear'), findsOneWidget);
    expect(
      tester.getSemantics(field).id,
      before,
      reason: 'the typed letter keeps the input the browser holds',
    );
    await tester.enterText(field, '');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Clear'), findsNothing);
    expect(tester.getSemantics(field).id, before);
    semantics.dispose();
  });
}

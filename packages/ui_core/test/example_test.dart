// The package's example app runs: a save with no name is refused and the
// name is focused; with one, the chosen period is saved and toasted, and
// the toast times out.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// The example is its own app beside the package, not the package's lib.
// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';

void main() {
  testWidgets('the example refuses an empty name, then saves and toasts', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Give the report a name'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
      reason: 'the refused field takes the focus',
    );

    await tester.enterText(find.byType(EditableText), 'Sales');
    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Saved "Sales" for the Month'), findsOneWidget);
    expect(find.text('Give the report a name'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Saved'),
      findsNothing,
      reason: 'the toast times out',
    );
    semantics.dispose();
  });
}

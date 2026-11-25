// The package's example app runs: a save with no name is refused and the
// name is focused; with one, the chosen period is saved and toasted, and
// the toast times out.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// The example is its own app beside the package, not the package's lib.
// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';
// As main.dart.
// ignore: avoid_relative_lib_imports
import '../example/lib/routes.dart';

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
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .focusNode
          .hasFocus,
      isTrue,
      reason: 'the refused field takes the focus',
    );

    await tester.enterText(find.byType(EditableText).first, 'Sales');
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

  testWidgets('the routes page: an alert, a sheet, tabs and swipe rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          pageBuilder: (context, _, _) => builder(context),
        ),
        home: const RoutesPage(),
      ),
    );
    await tester.tap(find.text('Delete the draft…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Deleted'), findsOneWidget);

    await tester.tap(find.text('Recent reports'));
    await tester.pumpAndSettle();
    expect(find.text('Report 1'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Report 1'), findsNothing);

    await tester.tap(find.text('Mail'));
    await tester.pumpAndSettle();
    expect(find.text('Message 1'), findsOneWidget, reason: 'the Mail tab');
    await tester.tap(find.text("Show the first row's actions"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();
    expect(find.text('Message 1'), findsNothing);

    // The mail app: a rail at 800 wide; the inbox's detail pushed in its
    // branch, back popping it.
    await tester.tap(find.text('Routes').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mail app'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Message 2'));
    await tester.pumpAndSettle();
    expect(find.text('Message 2, in full'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Message 2, in full'), findsNothing);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsNWidgets(2));
  });
}

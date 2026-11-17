// Brindlemere parking permits' everyday screens, each once a run in a
// setting dealt round them (screens_matrix.dart: every width, each theme,
// right to left and twice the text met every run; the rest is the sweep).
// And the service's behaviours a reader leans on: a details page sent empty
// shows the error summary with a link per problem and moves the focus to
// it; a summary's Change says which answer it changes; a tap on the bar's
// title goes home, never to the hidden skip link; the arrow keys move a
// question's answer.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/permits/permits.dart';
import 'screens_matrix.dart';

void main() {
  setUpAll(loadScreenFonts);
  screensMatrix(everyRun);

  testWidgets('a details page sent empty shows its problems and takes the '
      'focus to them', (tester) async {
    await showScreen(
      tester,
      const PermitsApp(initialPage: PermitsPage.details),
      width: 390,
    );
    expect(find.byType(CivicErrorSummary), findsNothing);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(CivicErrorSummary), findsOneWidget);
    expect(find.text('There is a problem'), findsOneWidget);
    // Each problem in the summary and at its field.
    expect(find.text('Enter your full name'), findsNWidgets(2));
    expect(
      find.text('Choose a file that proves your address'),
      findsNWidgets(2),
    );
    final summary = tester.widget<Focus>(
      find
          .descendant(
            of: find.byType(CivicErrorSummary),
            matching: find.byType(Focus),
          )
          .first,
    );
    expect(summary.focusNode?.hasFocus, isTrue);
  });

  testWidgets("a summary's Change says which answer it changes", (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await showScreen(
      tester,
      const PermitsApp(initialPage: PermitsPage.check),
      width: 1440,
    );
    expect(find.bySemanticsLabel('Change Date of birth'), findsOneWidget);
    handle.dispose();
  });

  // The site's masthead: an app's inner page holds its way back and its
  // place in the bar instead.
  testWidgets("a tap on the bar's title goes to the start, past the hidden "
      'skip link', (tester) async {
    await showScreen(
      tester,
      const PermitsApp(initialPage: PermitsPage.check),
      width: 1440,
    );
    final title = find.descendant(
      of: find.byType(CivicTopBar),
      matching: find.text('Brindlemere parking permits'),
    );
    // The title's start, where the skip link stands while it is hidden.
    await tester.tapAt(tester.getTopLeft(title) + const Offset(4, 8));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Apply for a resident parking permit'), findsOneWidget);
  });

  testWidgets("the arrow keys move a question's answer", (tester) async {
    await showScreen(
      tester,
      const PermitsApp(initialPage: PermitsPage.vehicle),
      width: 390,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    // Tab to the first answer, past the skip link, the title and the back
    // link.
    for (var i = 0; i < 6; i++) {
      final focused = FocusManager.instance.primaryFocus;
      final radio = focused?.context
          ?.findAncestorWidgetOfExactType<CivicRadio<String>>();
      if (radio != null) break;
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final group = tester.widget<CivicRadioGroup<String>>(
      find.byType(CivicRadioGroup<String>),
    );
    expect(group.groupValue, isNotNull);
  });
}

// A y/N question's default is no, so nothing outshines it: the no has the
// focus and the yes is an ordinary key, in the danger ink when it destroys.
// The question names its keys once, in its `[y/N]`, and the line under it
// says what Escape does. y and n still answer it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  for (final destructive in [true, false]) {
    final kind = destructive ? 'a destructive' : 'a';
    testWidgets('$kind y/N question names its keys once', (tester) async {
      bool? answer;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: TermTheme(
            data: TermThemeData.light(),
            child: Builder(
              builder: (context) => RawTapTargetScope(
                targets: RawTapTargets.of(context)
                    .copyWith(input: RawInput.pointer),
                child: Center(
                  child: TermConfirmDialog(
                    title: 'sign out',
                    message: 'sign out of fieldwork studio?',
                    confirmLabel: 'sign out',
                    isDestructiveAction: destructive,
                    onConfirm: () => answer = true,
                    onCancel: () => answer = false,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final keys = find.byType(TermButton);
      expect(keys, findsNWidgets(2));
      final [no, yes] = tester.widgetList<TermButton>(keys).toList();
      expect(yes.filled, isFalse, reason: 'the yes is an ordinary key');
      expect(yes.isDestructiveAction, destructive);
      expect(no.autofocus, isTrue, reason: 'the no has the focus');
      expect(yes.shortcut, isNull, reason: 'its key is in the [y/N]');
      expect(no.shortcut, isNull, reason: 'its key is in the [y/N]');
      // The pane sets its border's words in bidi isolates.
      expect(
        find.textContaining('esc cancel', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('y yes', findRichText: true), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
      expect(answer, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      expect(answer, isFalse);
    });
  }
}

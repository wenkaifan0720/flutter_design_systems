// A pane's doubled line follows the keyboard's focus: once a dialog its
// button opened takes the focus, the pane behind it is single again, whether
// the button was clicked, pressed with Enter or pressed by a screen reader.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

enum _Press { pointer, keys, semantics }

void main() {
  setUpAll(loadFaces);

  for (final press in _Press.values) {
    testWidgets(
      'a pane behind the dialog its button opened is single (${press.name})',
      (tester) async {
        final semantics = tester.ensureSemantics();
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, app) =>
                TermTheme(data: TermThemeData.light(), child: app!),
            home: Builder(
              builder: (context) => Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 400,
                  child: TermPane(
                    title: 'Week total',
                    child: TermButton.filled(
                      label: 'Add entry',
                      onPressed: () => showTermDialog<void>(
                        context: context,
                        semanticLabel: 'Add entry',
                        builder: (dialog) => TermDialog(
                          title: 'Add entry',
                          actions: [
                            TermButton(
                              label: 'Cancel',
                              onPressed: () => Navigator.pop(dialog),
                            ),
                          ],
                          content: const TermTextField(labelText: 'Date'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        bool doubled() => tester
            .widget<TermPaneScope>(
              find
                  .descendant(
                    of: find.byType(TermPane).first,
                    matching: find.byType(TermPaneScope),
                  )
                  .first,
            )
            .active;
        switch (press) {
          case _Press.pointer:
            final mouse = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
            );
            await mouse.addPointer(location: Offset.zero);
            addTearDown(mouse.removePointer);
            await mouse.moveTo(tester.getCenter(find.text('Add entry')));
            await tester.pump();
            await tester.tap(
              find.text('Add entry'),
              kind: PointerDeviceKind.mouse,
            );
          case _Press.keys:
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pumpAndSettle();
            expect(doubled(), isTrue, reason: 'the keys are in the pane');
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          case _Press.semantics:
            tester.semantics.tap(
              find.semantics.byPredicate(
                (n) =>
                    n.label == 'Add entry' &&
                    n.getSemanticsData().hasAction(SemanticsAction.tap),
              ),
            );
        }
        await tester.pumpAndSettle();
        expect(find.byType(TermDialog), findsOneWidget);
        expect(doubled(), isFalse);
        semantics.dispose();
      },
    );
  }
}

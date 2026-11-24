// The dialog (ui_core's RawModalDialogRoute, Civic's painting): it opens over
// the page with its question, closes with the answer its button gives,
// closes on Escape and Android's back unless it must be answered (then a
// screen reader hears an alert), gives the focus back to what opened it,
// and leaves nothing behind (leak tracking is on for every test here: a
// fade made per frame and never disposed fails it).
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The page, pumped; what opens the dialog over it.
Future<Future<bool?> Function()> _app(
  WidgetTester tester, {
  bool barrierDismissible = true,
}) async {
  late BuildContext page;
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => CivicHost(child: child!),
      home: Builder(
        builder: (context) {
          page = context;
          return const CivicScreen(body: Text('Your application'));
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return () => showCivicDialog<bool>(
    context: page,
    barrierDismissible: barrierDismissible,
    builder: (context) => CivicDialog(
      title: 'Withdraw this application?',
      content: const Text('You will need to apply again.'),
      actions: [
        CivicButton(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Withdraw application'),
        ),
        CivicButton.secondary(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep it'),
        ),
      ],
    ),
  );
}

void main() {
  for (final (button, answer) in [
    ('Withdraw application', true),
    ('Keep it', false),
  ]) {
    testWidgets('"$button" closes it with $answer', (tester) async {
      final open = await _app(tester);
      final answered = open();
      await tester.pumpAndSettle();
      expect(find.text('Withdraw this application?'), findsOneWidget);
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      expect(await answered, answer);
      expect(find.text('Withdraw this application?'), findsNothing);
    });
  }

  for (final dismissible in [true, false]) {
    testWidgets(
      'Escape ${dismissible ? 'closes it' : 'leaves one that must be answered'}',
      (tester) async {
        final open = await _app(tester, barrierDismissible: dismissible);
        final answered = open();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(
          find.text('Withdraw this application?'),
          dismissible ? findsNothing : findsOneWidget,
        );
        if (dismissible) {
          expect(await answered, isNull);
        } else {
          await tester.tap(find.text('Keep it'));
          await tester.pumpAndSettle();
          expect(await answered, isFalse);
        }
      },
    );
  }

  for (final dismissible in [true, false]) {
    testWidgets(
      "Android's back ${dismissible ? 'closes it' : 'leaves one that must be answered'}",
      (tester) async {
        final open = await _app(tester, barrierDismissible: dismissible);
        final answered = open();
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          find.text('Withdraw this application?'),
          dismissible ? findsNothing : findsOneWidget,
        );
        if (dismissible) expect(await answered, isNull);
      },
    );
  }

  for (final dismissible in [true, false]) {
    testWidgets('a screen reader hears ${dismissible ? 'a dialog' : 'an alert'}'
        ', named by its question', (tester) async {
      final semantics = tester.ensureSemantics();
      final open = await _app(tester, barrierDismissible: dismissible);
      open().ignore();
      await tester.pumpAndSettle();
      final role = dismissible
          ? SemanticsRole.dialog
          : SemanticsRole.alertDialog;
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.role == role,
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Withdraw this application?'), findsWidgets);
      semantics.dispose();
    });
  }

  testWidgets('as it closes the focus goes back to the button that opened '
      'it', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const opener = ValueKey('opener');
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => CivicHost(child: child!),
        home: Builder(
          builder: (context) => CivicScreen(
            body: CivicButton(
              key: opener,
              onPressed: () => showCivicDialog<void>(
                context: context,
                builder: (context) => CivicDialog(
                  title: 'Withdraw this application?',
                  actions: [
                    CivicButton.secondary(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Keep it'),
                    ),
                  ],
                ),
              ),
              child: const Text('Withdraw'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.text('Withdraw'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Withdraw this application?'), findsOneWidget);
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    final focused = FocusManager.instance.primaryFocus?.context;
    expect(focused, isNotNull);
    expect(
      find.descendant(
        of: find.byKey(opener),
        matching: find.byWidget(focused!.widget),
      ),
      findsOneWidget,
    );
  });
}

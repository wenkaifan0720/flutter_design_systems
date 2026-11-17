// Ledger's push on an app built on Flutter's own MaterialApp, as most apps that take Ledger are (and its example):
// ui_core's example/test/page_transitions_test.dart with Ledger's map in place of its stand-in. Ledger's library is
// on material_ui, so the PageTransitionsTheme LedgerTheme installs in the Material theme it builds is material_ui's:
// Flutter's MaterialPageRoute never reads it, and on a Mac plays the Cupertino slide. Ledger exposes its push as a map
// of widgets-level PageTransitionsBuilders instead, ledgerPageTransitions, one map for both Materials, and the app
// puts it in its own ThemeData (the README's setup line).
import 'package:flutter/cupertino.dart' show CupertinoPageTransition;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart'
    show LedgerPageTransitions, ledgerPageTransitions;

// An app on Flutter's MaterialApp, its ThemeData carrying [transitions], with a page that pushes a MaterialPageRoute.
Widget _app({Map<TargetPlatform, PageTransitionsBuilder>? transitions}) =>
    MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: transitions == null
            ? const PageTransitionsTheme()
            : PageTransitionsTheme(builders: transitions),
      ),
      home: Builder(
        builder: (context) => Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const Text('Second')),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

/// The opacity the pushed page is drawn at: its nearest fade's.
double _fade(WidgetTester tester) {
  final fades = tester.widgetList<FadeTransition>(
    find.ancestor(
      of: find.text('Second'),
      matching: find.byType(FadeTransition),
    ),
  );
  return fades.isEmpty ? 1 : fades.first.opacity.value;
}

void main() {
  testWidgets(
    "Ledger's map in the app's ThemeData is the push a MaterialPageRoute plays",
    (tester) async {
      await tester.pumpWidget(_app(transitions: ledgerPageTransitions));
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // Ledger's leaf, laid down: fading in as it rises onto the page, never slid across.
      final moving = tester.getTopLeft(find.text('Second'));
      final fading = _fade(tester);
      expect(find.byType(CupertinoPageTransition), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);
      final rest = tester.getTopLeft(find.text('Second'));
      expect(fading, inExclusiveRange(0, 1), reason: 'it fades in');
      expect(moving.dx, closeTo(rest.dx, 0.01), reason: 'no slide across');
      expect(
        moving.dy - rest.dy,
        inExclusiveRange(0, LedgerPageTransitions.rise + 0.01),
        reason: 'a rise of 8 at most',
      );
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets(
    "without it, a Mac's MaterialPageRoute plays the Cupertino slide",
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CupertinoPageTransition), findsWidgets);
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}

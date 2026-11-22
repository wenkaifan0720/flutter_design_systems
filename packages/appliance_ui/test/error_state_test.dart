// A failed list is the empty list's sibling: the same faceplate and display
// window, the window reading a fault code at full strength where the empty
// one's dashes are dim, the danger lamp lit beside the heading, and a key to
// try again. A screen reader hears the failure as it happens.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

Future<void> _show(WidgetTester tester, Widget part, Brightness b) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(780, 1000);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => ApplianceHost(brightness: b, child: app!),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: 358, child: part),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color _ink(WidgetTester tester, String words) =>
    tester.widget<Text>(find.text(words)).style!.color!;

void main() {
  setUpAll(applianceLoadFonts);

  for (final b in Brightness.values) {
    testWidgets('error and empty states share their faceplate ($b)', (
      tester,
    ) async {
      await _show(tester, const ApplianceEmptyState(title: 'No tasks here'), b);
      final dim = _ink(tester, '- - -');
      expect(
        find.ancestor(
          of: find.text('No tasks here'),
          matching: find.byType(AppliancePanel),
        ),
        findsOneWidget,
      );

      var retried = false;
      await _show(
        tester,
        ApplianceErrorState(
          title: 'Couldn’t load the workspace',
          message: 'Try again to load the team’s latest work.',
          onRetry: () => retried = true,
        ),
        b,
      );
      final error = find.byType(ApplianceErrorState);
      expect(
        find.ancestor(
          of: find.text('Couldn’t load the workspace'),
          matching: find.byType(AppliancePanel),
        ),
        findsOneWidget,
      );
      // The window reads its code at full strength, the dashes' own ink.
      final code = _ink(tester, 'Err');
      expect(code.a, 1);
      expect(code.withValues(alpha: 1), dim.withValues(alpha: 1));
      // The danger lamp, lit beside the heading: the palette's own red.
      final lamp = tester.widget<ApplianceLamp>(
        find.descendant(of: error, matching: find.byType(ApplianceLamp)),
      );
      final context = tester.element(error);
      expect(lamp.lit, isTrue);
      expect(lamp.color, ApplianceTheme.of(context).colors.danger);
      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });
  }

  testWidgets('a screen reader hears the failure as it happens', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _show(
      tester,
      ApplianceErrorState(title: 'Couldn’t load', onRetry: () {}),
      Brightness.light,
    );
    expect(
      tester.getSemantics(find.byType(ApplianceErrorState)),
      isSemantics(isLiveRegion: true),
    );
    semantics.dispose();
  });
}

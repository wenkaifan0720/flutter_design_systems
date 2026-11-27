// A filled key after a press, hovered or focused: its words carry no line
// under them (it read as a link); its rim glows a pale light instead,
// clear when it has no focus.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

TextDecoration? _decoration(WidgetTester tester) {
  final rich = tester.widget<RichText>(
    find.descendant(
      of: find.byType(ApplianceButton),
      matching: find.byType(RichText),
    ),
  );
  return rich.text.style?.decoration;
}

void main() {
  testWidgets('a focused filled key draws no line under its words', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            ApplianceHost(brightness: Brightness.light, child: app!),
        home: Scaffold(
          body: Center(
            child: ApplianceButton.filled(
              'Check out',
              focusNode: focus,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Check out'));
    await tester.pumpAndSettle();
    expect(_decoration(tester), anyOf(isNull, TextDecoration.none));
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    expect(_decoration(tester), anyOf(isNull, TextDecoration.none));
  });

  testWidgets("a focused filled key's rim glows a pale light, clear without", (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            ApplianceHost(brightness: Brightness.light, child: app!),
        home: Scaffold(
          body: Center(
            child: ApplianceButton.filled(
              'Check out',
              focusNode: focus,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    Color rim() => tester
        .widget<ApplianceSurface>(
          find
              .descendant(
                of: find.byType(ApplianceButton),
                matching: find.byType(ApplianceSurface),
              )
              .first,
        )
        .face
        .focus;
    await tester.pumpAndSettle();
    expect(rim().a, 0);
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    focus.requestFocus();
    await tester.pumpAndSettle();
    // Lamp-light, not the signal's own colour, which would not show on it.
    expect(rim().a, greaterThan(0.5));
    expect(rim().computeLuminance(), greaterThan(0.75));
  });
}

// Enter in a browser: Flutter maps it there to a button's press alone
// (ButtonActivateIntent), not every control's (ActivateIntent), as the web
// does. Minimal's buttons take it; a checkbox keeps to Space.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

/// The keys as a browser maps them.
final Map<ShortcutActivator, Intent> _webShortcuts = {
  ...WidgetsApp.defaultShortcuts,
  const SingleActivator(LogicalKeyboardKey.enter): const ButtonActivateIntent(),
  const SingleActivator(LogicalKeyboardKey.numpadEnter):
      const ButtonActivateIntent(),
};

Widget _page(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  shortcuts: _webShortcuts,
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(body: Center(child: child)),
);

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('in a browser Enter presses a button, as Space does', (
    tester,
  ) async {
    final pressed = <String>[];
    await tester.pumpWidget(
      _page(MinimalButton('Save', onPressed: () => pressed.add('save'))),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(pressed, ['save'], reason: 'Enter');
    await _key(tester, LogicalKeyboardKey.numpadEnter);
    expect(pressed, ['save', 'save'], reason: 'the keypad Enter');
    await _key(tester, LogicalKeyboardKey.space);
    expect(pressed, ['save', 'save', 'save'], reason: 'Space');
  });

  testWidgets('in a browser a checkbox keeps to Space: Enter leaves it', (
    tester,
  ) async {
    final pressed = <String>[];
    await tester.pumpWidget(
      _page(
        MinimalStatusIcon(
          MinimalTaskStatus.todo,
          onPressed: () => pressed.add('check'),
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(pressed, isEmpty, reason: 'Enter');
    await _key(tester, LogicalKeyboardKey.space);
    expect(pressed, ['check'], reason: 'Space');
  });
}

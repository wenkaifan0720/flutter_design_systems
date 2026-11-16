/// Enter in a browser: Flutter maps it there to a button's press alone
/// (ButtonActivateIntent), not every control's (ActivateIntent), as the web
/// does. A menu's anchor, its items, a select and a menu bar take it, as
/// Space.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

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
  builder: (context, app) => ExpressiveHost(
    light: ExpressiveThemeData.preset('bloom', Brightness.light),
    brightness: Brightness.light,
    child: app!,
  ),
  home: Padding(
    padding: const EdgeInsets.all(24),
    child: Align(alignment: AlignmentDirectional.topStart, child: child),
  ),
);

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  for (final open in [
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
  ]) {
    testWidgets('in a browser ${open.keyLabel} opens a menu from its anchor '
        'and presses its item', (tester) async {
      final pressed = <String>[];
      await tester.pumpWidget(
        _page(
          ExpressiveMenu(
            label: 'More',
            entries: [
              ExpressiveMenuItem('Rename', onPressed: () => pressed.add('r')),
              ExpressiveMenuItem('Delete', onPressed: () => pressed.add('d')),
            ],
            child: const SizedBox(width: 48, height: 48),
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, open);
      expect(find.text('Rename'), findsOneWidget, reason: 'opened');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, open);
      expect(pressed, ['d']);
      expect(find.text('Rename'), findsNothing, reason: 'closed');
    });
  }

  testWidgets('in a browser Enter opens a select and chooses', (tester) async {
    String? value;
    await tester.pumpWidget(
      _page(
        SizedBox(
          width: 300,
          child: StatefulBuilder(
            builder: (context, update) => ExpressiveSelect<String>(
              options: const [
                ExpressiveSelectOption('s', 'Small'),
                ExpressiveSelectOption('m', 'Medium'),
              ],
              value: value,
              label: 'Size',
              onChanged: (v) => update(() => value = v),
            ),
          ),
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(find.text('Medium'), findsOneWidget, reason: 'opened');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(value, 'm');
  });

  testWidgets("in a browser Enter opens a menu bar's menu and presses its "
      'item', (tester) async {
    final pressed = <String>[];
    await tester.pumpWidget(
      _page(
        ExpressiveMenuBar(
          menus: [
            ExpressiveMenuBarEntry(
              'File',
              children: [
                ExpressiveMenuBarEntry(
                  'New',
                  onPressed: () => pressed.add('n'),
                ),
                ExpressiveMenuBarEntry(
                  'Open',
                  onPressed: () => pressed.add('o'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(find.text('New'), findsOneWidget, reason: 'opened, on New');
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(pressed, ['o']);
  });
}

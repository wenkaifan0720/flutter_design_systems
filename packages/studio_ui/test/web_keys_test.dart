// Enter on the web. Flutter's web shortcuts map Enter to ButtonActivateIntent (not ActivateIntent), and Space to
// ActivateIntent: every Studio part a press acts on stands on ui_core's RawButton, which takes both. Under the
// web's map (a copy of WidgetsApp's, which a test on the VM never reads), Enter and Space press each kind of part,
// a select's window opens its list on Enter and Enter chooses the row the keyboard is on.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:studio_ui/studio_ui.dart';

// WidgetsApp's web activation keys.
const _webKeys = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  SingleActivator(LogicalKeyboardKey.enter): ButtonActivateIntent(),
  SingleActivator(LogicalKeyboardKey.numpadEnter): ButtonActivateIntent(),
  SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(
    TraversalDirection.down,
  ),
  SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
    TraversalDirection.up,
  ),
};

Widget _app(Widget child) => MaterialApp(
  shortcuts: _webKeys,
  builder: (context, page) => StudioTheme(
    data: StudioThemeData.light(),
    child: StudioToaster(child: page!),
  ),
  home: Builder(
    builder: (context) => ColoredBox(
      color: StudioTheme.of(context).colors.chassis,
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  ),
);

void main() {
  final parts = <String, Widget Function(VoidCallback)>{
    'a key': (hit) => StudioButton('Save', onPressed: hit),
    'a lit key': (hit) => StudioButton.lit('Publish', onPressed: hit),
    'a capless key': (hit) => StudioButton.text('Details', onPressed: hit),
    'an icon key': (hit) => StudioIconButton(
      icon: const Icon(LucideIcons.search),
      tooltip: 'Search',
      onPressed: hit,
    ),
    'a transport key': (hit) => StudioTransportKey(
      icon: const Icon(LucideIcons.play),
      tooltip: 'Play',
      onPressed: hit,
    ),
    'a row': (hit) => StudioListGroup(
      children: [StudioListTile(title: 'Audio quality', onTap: hit)],
    ),
    'a switch row': (hit) => StudioListGroup(
      children: [
        StudioListTile.toggle(
          title: 'New episodes',
          value: false,
          onChanged: (_) => hit(),
        ),
      ],
    ),
    'a card': (hit) => StudioDisplay(
      onTap: hit,
      semanticLabel: 'Episode',
      child: const Text('Episode'),
    ),
    'the key bank bar': (hit) => StudioNavigationBar(
      destinations: const [
        StudioDestination(icon: Icon(LucideIcons.house), label: 'Home'),
        StudioDestination(icon: Icon(LucideIcons.mic), label: 'Record'),
      ],
      selectedIndex: 0,
      onDestinationSelected: (_) => hit(),
    ),
    'the side panel': (hit) => SizedBox(
      height: 300,
      child: StudioSideNavigation(
        destinations: const [
          StudioDestination(icon: Icon(LucideIcons.house), label: 'Home'),
          StudioDestination(icon: Icon(LucideIcons.mic), label: 'Record'),
        ],
        selectedIndex: 0,
        onDestinationSelected: (_) => hit(),
      ),
    ),
    'a checkbox': (hit) => StudioCheckbox(
      value: false,
      onChanged: (_) => hit(),
      semanticLabel: 'Explicit',
    ),
    'a switch': (hit) => StudioSwitch(
      value: false,
      onChanged: (_) => hit(),
      semanticLabel: 'Live',
    ),
  };
  for (final MapEntry(key: name, value: build) in parts.entries) {
    for (final key in const [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
    ]) {
      testWidgets('${key.keyLabel} presses $name on the web', (tester) async {
        var hits = 0;
        await tester.pumpWidget(_app(build(() => hits++)));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(hits, 1);
      });
    }
  }

  // A tab bar is one stop on ui_core's tabs: the arrows choose (a tab is
  // chosen as focus reaches it), and the chosen tab pressed again is no
  // change.
  testWidgets('the arrows choose a tab on the web', (tester) async {
    final chosen = <int>[];
    await tester.pumpWidget(
      _app(
        StudioTabBar(
          tabs: const ['Notes', 'Chapters'],
          selectedIndex: 0,
          onChanged: chosen.add,
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(chosen, [1]);
  });

  // A key bank is a radio group: one stop, on the latched key, where Enter
  // and Space change nothing, and the arrows latch as they move.
  testWidgets('the arrows latch a key in a bank on the web', (tester) async {
    final chosen = <int>[];
    await tester.pumpWidget(
      _app(
        StudioSegmentedButton<int>(
          semanticLabel: 'Speed',
          segments: const [
            StudioSegment(value: 1, label: '1×'),
            StudioSegment(value: 2, label: '2×'),
          ],
          value: 1,
          onChanged: chosen.add,
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    for (final key in const [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
    ]) {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }
    expect(chosen, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(chosen, [2]);
  });

  testWidgets(
    "Enter opens a select's list and chooses the row the keyboard is on",
    (tester) async {
      String? chosen;
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 320,
            child: StudioSelect<String>(
              labelText: 'Audio quality',
              value: 'high',
              items: const [
                StudioSelectItem(value: 'standard', label: 'Standard'),
                StudioSelectItem(value: 'high', label: 'High'),
                StudioSelectItem(value: 'lossless', label: 'Lossless'),
              ],
              onChanged: (v) => chosen = v,
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Lossless'), findsOneWidget, reason: 'the list is open');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(chosen, 'lossless');
      expect(find.text('Lossless'), findsNothing, reason: 'the list closed');
    },
  );
}

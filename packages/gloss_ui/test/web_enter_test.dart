// On the web Flutter maps Enter to ButtonActivateIntent, not ActivateIntent. Every part of Gloss a key presses is
// built on ui_core's DesignPressable, which takes both; this holds each of them to it under the web's own Enter.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

/// The web's own keys (Flutter's map on the web), wherever the test runs: Enter
/// is ButtonActivateIntent, and the arrows scroll unless a part takes them.
const _web = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.space): PrioritizedIntents(
    orderedIntents: [
      ActivateIntent(),
      ScrollIntent(
        direction: AxisDirection.down,
        type: ScrollIncrementType.page,
      ),
    ],
  ),
  SingleActivator(LogicalKeyboardKey.enter): ButtonActivateIntent(),
  SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
  SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
  SingleActivator(LogicalKeyboardKey.arrowUp): ScrollIntent(
    direction: AxisDirection.up,
  ),
  SingleActivator(LogicalKeyboardKey.arrowDown): ScrollIntent(
    direction: AxisDirection.down,
  ),
  SingleActivator(LogicalKeyboardKey.arrowLeft): ScrollIntent(
    direction: AxisDirection.left,
  ),
  SingleActivator(LogicalKeyboardKey.arrowRight): ScrollIntent(
    direction: AxisDirection.right,
  ),
};

const _glyph = IconData(0x41);

Widget _app(Widget part) => WidgetsApp(
  color: const Color(0xFF0E7652),
  shortcuts: _web,
  pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
      PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
  home: GlossTheme(
    data: GlossThemeData.light(),
    child: Center(child: part),
  ),
);

/// Tabs to the part's first key and presses Enter.
Future<void> _enter(WidgetTester tester, Widget part) async {
  await tester.pumpWidget(_app(part));
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

void main() {
  final parts = <String, Widget Function(VoidCallback hit)>{
    'a pearl key': (hit) => GlossButton('Save', onPressed: hit),
    'a gel key': (hit) => GlossButton.filled('Save', onPressed: hit),
    'a text key': (hit) => GlossButton.text('Swap', onPressed: hit),
    'a bead': (hit) => GlossIconButton(
      onPressed: hit,
      tooltip: 'Add',
      icon: const Icon(_glyph),
    ),
    'a switch': (hit) => GlossSwitch(
      value: false,
      semanticLabel: 'Reminders',
      onChanged: (_) => hit(),
    ),
    'a checkbox': (hit) => GlossCheckbox(value: false, onChanged: (_) => hit()),
    'a radio': (hit) =>
        GlossRadio<int>(value: 1, groupValue: 0, onChanged: (_) => hit()),
    'a chip': (hit) =>
        GlossChip(label: 'Vegan', selected: false, onSelected: (_) => hit()),
    'a row': (hit) => GlossListTile(title: 'Household', onTap: hit),
    'a card': (hit) => GlossCard(onTap: hit, child: const Text('Tonight')),
    'a place in the bar below': (hit) => GlossNavigationBar(
      destinations: const [
        GlossDestination(icon: _glyph, label: 'Today'),
        GlossDestination(icon: _glyph, label: 'List'),
      ],
      selectedIndex: 1,
      onSelected: (_) => hit(),
    ),
  };
  for (final MapEntry(key: name, value: build) in parts.entries) {
    testWidgets('Enter presses $name', (tester) async {
      var hits = 0;
      await _enter(tester, build(() => hits++));
      expect(hits, 1);
    });
  }

  // A tab bar is one stop, on the chosen tab (ui_core's): Enter there changes
  // nothing, and the arrows choose as they move.
  testWidgets('a tab bar is one stop; the arrows choose', (tester) async {
    final chosen = <int>[];
    await _enter(
      tester,
      GlossTabBar(
        tabs: const ['Ingredients', 'Method'],
        selectedIndex: 0,
        onSelected: chosen.add,
      ),
    );
    expect(chosen, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(chosen, [1]);
  });

  // A segmented button is a radio group: one stop, on the chosen segment,
  // where Enter changes nothing, and the arrows choose as they move.
  testWidgets('a segmented button is one stop; the arrows choose', (
    tester,
  ) async {
    final chosen = <int>[];
    await _enter(
      tester,
      GlossSegmentedButton<int>(
        segments: const [
          GlossSegment(value: 0, label: 'Daily'),
          GlossSegment(value: 1, label: 'Weekly'),
        ],
        selected: 1,
        onChanged: chosen.add,
      ),
    );
    expect(chosen, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(chosen, [0]);
  });

  testWidgets('Enter opens a select, and Enter chooses in its list', (
    tester,
  ) async {
    String? chosen;
    await _enter(
      tester,
      SizedBox(
        width: 280,
        child: GlossSelect<String>(
          value: 'metric',
          items: const [
            GlossSelectItem(value: 'metric', label: 'Metric'),
            GlossSelectItem(value: 'imperial', label: 'Imperial'),
          ],
          onChanged: (v) => chosen = v,
        ),
      ),
    );
    // Open: the list's rows are there, its chosen row holding the focus.
    expect(find.text('Imperial'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chosen, 'imperial');
  });
}

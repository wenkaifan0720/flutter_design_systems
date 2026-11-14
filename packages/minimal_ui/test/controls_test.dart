import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

// The host stands above the Navigator, as an app mounts it, so overlays (a
// sheet, a toast) read the same tokens as the page.
Widget _host(Widget child) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('a button taps, and says it is an enabled button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      _host(MinimalButton('Create habit', onPressed: () => taps += 1)),
    );
    await tester.tap(find.text('Create habit'));
    expect(taps, 1);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Create habit')),
      matchesSemantics(
        label: 'Create habit',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a button with no action is disabled, and says so', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const MinimalButton('Create habit')));
    final semantics = tester.getSemantics(
      find.bySemanticsLabel('Create habit'),
    );
    expect(
      semantics,
      matchesSemantics(
        label: 'Create habit',
        isButton: true,
        hasEnabledState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a 32 px control lands taps across a 44 px target', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        MinimalIconButton(Icons.add, label: 'Add', onPressed: () => taps += 1),
      ),
    );
    final box = tester.getRect(find.byType(MinimalIconButton));
    expect(box.height, MinimalChromeMetrics.barControl);
    await tester.tapAt(box.topCenter - const Offset(0, 5));
    expect(taps, 1);
    await tester.tapAt(box.topCenter - const Offset(0, 10));
    expect(taps, 1);
  });

  testWidgets('an icon button announces its label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(MinimalIconButton(Icons.search, label: 'Search', onPressed: () {})),
    );
    expect(find.bySemanticsLabel('Search'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the keyboard focuses a control and Enter activates it', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(MinimalButton('Create habit', onPressed: () => taps += 1)),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('an icon button is ghost in a row, outlined in a bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            MinimalIconButton(Icons.add, onPressed: () {}),
            MinimalAppBar(
              title: 'Today',
              large: true,
              actions: [MinimalIconButton(Icons.search, onPressed: () {})],
            ),
          ],
        ),
      ),
    );
    // A ghost face paints nothing, so it carries no decoration at all.
    BoxDecoration? face(IconData icon) =>
        tester
                .widget<Container>(
                  find
                      .ancestor(
                        of: find.byIcon(icon, skipOffstage: false),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration?;
    expect(face(Icons.add)?.border, isNull);
    expect(face(Icons.search)?.border, isNotNull);
  });

  testWidgets('the current tab is announced as selected', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        MinimalNavigationBar(
          items: const [
            MinimalNavItem(Icons.today, 'Today'),
            MinimalNavItem(Icons.list, 'Habits'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Today')),
      matchesSemantics(
        label: 'Today',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Habits')),
      matchesSemantics(
        label: 'Habits',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a busy button leads with a spinner, takes no presses and does '
      'not dim', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(MinimalButton('Creating…', busy: true, onPressed: () => taps += 1)),
    );
    await tester.tap(find.text('Creating…'), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
    // A spinner, painted in the label's ink, before the words.
    final mark = find.descendant(
      of: find.byType(MinimalButton),
      matching: find.byType(RotationTransition),
    );
    expect(mark, findsOneWidget);
    expect(
      tester.getRect(mark).right,
      lessThan(tester.getRect(find.text('Creating…')).left),
    );
    // Busy is not disabled: nothing fades the face.
    final faded = tester
        .widgetList<AnimatedOpacity>(
          find.descendant(
            of: find.byType(MinimalButton),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .where((o) => o.opacity < 1);
    expect(faded, isEmpty);
  });

  testWidgets('a sheet\'s close keeps its whole 44 px target', (tester) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => MinimalButton(
            'Open',
            onPressed: () => showMinimalBottomSheet<void>(
              context,
              title: 'New habit',
              builder: (_) => const Text('Sheet body'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final close = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is MinimalIconButton && w.label == 'Close',
      ),
    );
    await tester.tapAt(close.center - const Offset(0, 21));
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsNothing);
  });

  testWidgets('on a wide window a sheet stands centred at its width; on a '
      'phone it spans the screen inside its margins', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    for (final width in [1440.0, 390.0]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => MinimalButton(
              'Open',
              onPressed: () => showMinimalBottomSheet<void>(
                context,
                title: 'New habit',
                builder: (_) => const Text('Sheet body'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final card = tester.getRect(find.byType(MinimalBottomSheet));
      if (width > 600) {
        expect(card.width, MinimalBottomSheet.centredWidth);
        expect(card.center.dx, width / 2);
      } else {
        expect(card.width, width - 2 * MinimalChromeMetrics.sheetInset);
      }
      Navigator.of(tester.element(find.text('Sheet body'))).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a toast\'s action keeps its whole 44 px target', (tester) async {
    var undone = 0;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => MinimalButton(
            'Archive',
            onPressed: () => showMinimalSnackBar(
              context,
              'Habit archived',
              actionLabel: 'Undo',
              onAction: () => undone += 1,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    // 21 px below the action's face's middle: inside its 44 px target, past
    // the face (its label stands on its capitals, so not on the label's).
    final action = tester.getRect(
      find
          .ancestor(
            of: find.text('Undo'),
            matching: find.byType(MinimalPressable),
          )
          .first,
    );
    await tester.tapAt(action.center + const Offset(0, 21));
    await tester.pump();
    expect(undone, 1);
    await tester.pump(MinimalChromeMetrics.toastWithAction);
  });

  testWidgets('a pressable with nothing to do is not a control', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const MinimalPressable(child: Text('Plain'))),
    );
    expect(find.byType(FocusableActionDetector), findsNothing);
    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets('a pressable takes focus through the node it is given', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    var taps = 0;
    await tester.pumpWidget(
      _host(
        MinimalPressable(
          focusNode: node,
          onPressed: () => taps += 1,
          child: const Text('Agree'),
        ),
      ),
    );
    node.requestFocus();
    await tester.pump();
    expect(node.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(taps, 1);
  });
}

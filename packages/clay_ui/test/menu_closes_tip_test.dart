// A tooltip goes when its control opens a menu: the overflow button's tip
// ("Task actions · ST-109") stood over the menu it opened, at 390 RTL over
// its Delete. Opened by a click after the tip shows, by a quick click and a
// rest on the button, by Enter and by the Down arrow, and by the semantics
// tree's tap (a click on the web with its semantics on), the menu stands
// alone.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _tip = 'Task actions · ST-109';

Widget _app() => MaterialApp(
  builder: (context, app) =>
      ClayTheme(data: ClayThemeData.clay(Brightness.light), child: app!),
  home: Align(
    alignment: const Alignment(0, -0.6),
    child: ClayMenu(
      alignEnd: true,
      semanticLabel: 'Task actions',
      items: [
        ClayMenuItem(label: 'Complete', onPressed: () {}),
        ClayMenuItem(label: 'Move', onPressed: () {}),
        ClayMenuItem(
          label: 'Delete',
          isDestructiveAction: true,
          onPressed: () {},
        ),
      ],
      builder: (context, toggle, open) => ClayIconButton.plain(
        tooltip: _tip,
        icon: const Icon(IconData(0x2026)),
        onPressed: toggle,
      ),
    ),
  ),
);

Future<TestGesture> _mouse(WidgetTester tester) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  return mouse;
}

Offset _button(WidgetTester tester) =>
    tester.getCenter(find.byType(ClayIconButton));

void main() {
  testWidgets('a click after the tip shows opens the menu alone', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final mouse = await _mouse(tester);
    await mouse.moveTo(_button(tester));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsOneWidget, reason: 'the tip shows on hover');
    await mouse.down(_button(tester));
    await mouse.up();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget, reason: 'the menu is open');
    expect(find.text(_tip), findsNothing);
  });

  testWidgets('a quick click and a rest on the button open the menu alone', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    final mouse = await _mouse(tester);
    await mouse.moveTo(_button(tester));
    await tester.pump(const Duration(milliseconds: 50));
    await mouse.down(_button(tester));
    await mouse.up();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget, reason: 'the menu is open');
    expect(find.text(_tip), findsNothing);
  });

  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.arrowDown]) {
    testWidgets('Tab then ${key.keyLabel} opens the menu alone', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        find.text(_tip),
        findsOneWidget,
        reason: "the tip shows on the keys' focus",
      );
      await tester.sendKeyEvent(key);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget, reason: 'the menu is open');
      expect(find.text(_tip), findsNothing);
    });
  }

  // Flutter's web engine, its semantics on (a screen reader, a browser's
  // own automation), turns a click on a button into the tree's tap: the
  // tooltip hears no pointer go down, and nothing used to hide it.
  for (final rest in [true, false]) {
    testWidgets(
      rest
          ? "the tree's tap after the tip shows opens the menu alone"
          : "the tree's tap at once, then a rest, opens the menu alone",
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_app());
        final mouse = await _mouse(tester);
        await mouse.moveTo(_button(tester));
        if (rest) {
          await tester.pump(const Duration(seconds: 1));
          await tester.pumpAndSettle();
          expect(find.text(_tip), findsOneWidget, reason: 'the tip shows');
        } else {
          await tester.pump(const Duration(milliseconds: 50));
        }
        final node = tester.getSemantics(
          find.descendant(
            of: find.byType(ClayIconButton),
            matching: find.byType(RawButton),
          ),
        );
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.text('Delete'), findsOneWidget, reason: 'the menu is open');
        expect(find.text(_tip), findsNothing);
        handle.dispose();
      },
    );
  }

  testWidgets(
    "a popover's key: the tree's tap after the tip shows opens it alone",
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => ClayTheme(
            data: ClayThemeData.clay(Brightness.light),
            child: app!,
          ),
          home: Align(
            alignment: const Alignment(0, -0.6),
            child: ClayPopover(
              semanticLabel: 'Streak',
              content: (context, close) => const Text('Twelve days running'),
              builder: (context, toggle, open) => ClayIconButton.plain(
                tooltip: _tip,
                icon: const Icon(IconData(0x2026)),
                onPressed: toggle,
              ),
            ),
          ),
        ),
      );
      final mouse = await _mouse(tester);
      await mouse.moveTo(_button(tester));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text(_tip), findsOneWidget, reason: 'the tip shows');
      final node = tester.getSemantics(
        find.descendant(
          of: find.byType(ClayIconButton),
          matching: find.byType(RawButton),
        ),
      );
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Twelve days running'), findsOneWidget);
      expect(find.text(_tip), findsNothing);
      handle.dispose();
    },
  );
}

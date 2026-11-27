// A key's tooltip stays away while its own menu or popover is open: a pointer that leaves the key and comes back
// over it shows the open menu, not the key's name over the menu, and Escape then closes the menu at once (no tooltip
// is open to take it: Flutter 3.50's RawTooltip dismisses open tips before anything else hears Escape). The key keeps
// its own focus and press as the tooltip round it comes and goes, and a mouse resting on it as the menu closes brings
// no name back until it leaves and returns, as a press had put the name away before the menu opened.
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _name = 'Task actions';

Widget _key(VoidCallback toggle) => KeycapTooltip(
  message: _name,
  child: KeycapIconButton(
    icon: const Icon(LucideIcons.ellipsis),
    semanticLabel: _name,
    onPressed: toggle,
  ),
);

final _opens = <String, Widget>{
  'menu': KeycapMenu(
    semanticLabel: _name,
    entries: [
      RawMenuEntry(label: 'Mark done', onPressed: () {}),
      RawMenuEntry(
        label: 'Delete',
        isDestructiveAction: true,
        onPressed: () {},
      ),
    ],
    builder: (_, anchor) => _key(anchor.toggle),
  ),
  'popover': KeycapPopover(
    builder: (_, anchor) => _key(anchor.toggle),
    content: (_, close) => const Text('Delete'),
  ),
};

void main() {
  for (final MapEntry(key: kind, value: opener) in _opens.entries) {
    testWidgets('a pointer back over the key leaves its open $kind clear', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) =>
              KeycapHost(brightness: Brightness.dark, child: app!),
          home: Align(alignment: const Alignment(0.8, 0.2), child: opener),
        ),
      );
      await tester.pumpAndSettle();
      final key = tester.getCenter(find.byType(KeycapIconButton));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(key);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.text(_name), findsOneWidget, reason: 'its name on a hover');

      await tester.tap(find.byType(KeycapIconButton));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(KeycapTooltip),
          matching: find.byType(RawTooltip),
        ),
        findsNothing,
        reason: 'no tooltip at all, not an empty one, while the $kind is open',
      );
      await mouse.moveTo(key + const Offset(0, 200));
      await tester.pumpAndSettle();
      await mouse.moveTo(key);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text(_name), findsNothing);

      // Closed again, the key names itself on the next hover.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsNothing);
      await mouse.moveTo(key + const Offset(0, 200));
      await tester.pumpAndSettle();
      await mouse.moveTo(key);
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.text(_name), findsOneWidget);
    });
  }

  bool within(Element key) {
    final focus = FocusManager.instance.primaryFocus?.context;
    if (focus == null) return false;
    if (focus == key) return true;
    var found = false;
    focus.visitAncestorElements((e) {
      found = e == key;
      return !found;
    });
    return found;
  }

  for (final MapEntry(key: kind, value: opener) in _opens.entries) {
    testWidgets(
      'the key keeps its focus as its $kind opens and closes by the keys',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, app) =>
                KeycapHost(brightness: Brightness.dark, child: app!),
            home: Align(alignment: const Alignment(0.8, 0.2), child: opener),
          ),
        );
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final key = tester.element(find.byType(KeycapIconButton));
        expect(within(key), isTrue, reason: 'Tab reaches the key');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('Delete'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Delete'), findsNothing);
        // The same key, its own focus given back.
        expect(tester.element(find.byType(KeycapIconButton)), same(key));
        expect(within(key), isTrue, reason: 'the focus back on the key');
      },
    );

    testWidgets(
      'a mouse resting on the key as its $kind closes brings no name until '
      'it comes back',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, app) =>
                KeycapHost(brightness: Brightness.dark, child: app!),
            home: Align(alignment: const Alignment(0.8, 0.2), child: opener),
          ),
        );
        await tester.pumpAndSettle();
        final key = tester.getCenter(find.byType(KeycapIconButton));
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(key);
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
        expect(find.text(_name), findsOneWidget);

        // A click opens it, and a click on the key closes it again.
        await mouse.down(key);
        await mouse.up();
        await tester.pumpAndSettle();
        expect(find.text('Delete'), findsOneWidget);
        await mouse.down(key);
        await mouse.up();
        await tester.pumpAndSettle();
        expect(find.text('Delete'), findsNothing);
        // The press had put the name away; the pointer resting there does not
        // bring it back, as before the $kind opened.
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
        expect(find.text(_name), findsNothing);

        await mouse.moveTo(key + const Offset(0, 200));
        await tester.pumpAndSettle();
        await mouse.moveTo(key);
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
        expect(find.text(_name), findsOneWidget);
      },
    );

    testWidgets('the key is named the same with its $kind open', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) =>
              KeycapHost(brightness: Brightness.dark, child: app!),
          home: Align(alignment: const Alignment(0.8, 0.2), child: opener),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byType(KeycapIconButton);
      expect(tester.getSemantics(button), isSemantics(tooltip: _name));
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);
      expect(tester.getSemantics(button), isSemantics(tooltip: _name));
      semantics.dispose();
    });

    testWidgets('a press on the key closes its open $kind', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) =>
              KeycapHost(brightness: Brightness.dark, child: app!),
          home: Align(alignment: const Alignment(0.8, 0.2), child: opener),
        ),
      );
      await tester.pumpAndSettle();
      final key = tester.element(find.byType(KeycapIconButton));
      await tester.tap(find.byType(KeycapIconButton));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);
      expect(tester.element(find.byType(KeycapIconButton)), same(key));
      await tester.tap(find.byType(KeycapIconButton), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsNothing);
    });
  }
}

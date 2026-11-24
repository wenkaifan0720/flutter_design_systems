// A key's tooltip stays away while its own menu or popover is open: a pointer that leaves the key and comes back
// over it shows the open menu, not the key's name over the menu.
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
}

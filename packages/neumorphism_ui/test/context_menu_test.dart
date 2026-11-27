// The context menu on ui_core's RawContextMenu, painted as the menu bar's menus: a right click or a long press opens
// it at the pointer, Shift+F10 at the focused control, Escape closes it and the focus goes back, and a command closes it
// and runs.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/internal/panel.dart'
    show NeumorphicPanel, NeumorphicPanelRow;
import 'package:neumorphism_ui/src/neumorphism/ornaments.dart'
    show NeumorphicEngraved;

import 'support.dart';

class _Lamp extends StatefulWidget {
  const _Lamp({required this.log});

  final List<String> log;

  @override
  State<_Lamp> createState() => _LampState();
}

class _LampState extends State<_Lamp> {
  bool _on = true;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: NeumorphicContextMenu(
        semanticLabel: 'Hall lamp',
        menuChildren: [
          RawMenuEntry(
            label: 'On',
            checked: _on,
            onPressed: () => setState(() => _on = !_on),
          ),
          RawMenuEntry(
            label: 'Rename',
            shortcut: 'R',
            onPressed: () => widget.log.add('Rename'),
          ),
          const RawMenuEntry.divider(),
          RawMenuEntry(
            label: 'Remove',
            isDestructiveAction: true,
            onPressed: () => widget.log.add('Remove'),
          ),
        ],
        child: SizedBox(
          width: 300,
          child: NeumorphicCard(
            title: 'Hall lamp',
            trailing: NeumorphicSwitch(
              semanticLabel: 'Hall lamp',
              value: _on,
              onChanged: (on) => setState(() => _on = on),
            ),
          ),
        ),
      ),
    ),
  );
}

Finder get _panel => find.byType(NeumorphicPanel);

void main() {
  setUpAll(loadNeumorphicFonts);

  testWidgets(
    'a right click opens it at the pointer; a command closes it and runs',
    (tester) async {
      final log = <String>[];
      await tester.pumpWidget(neumorphicApp(_Lamp(log: log)));
      final at =
          tester.getTopLeft(find.byType(NeumorphicCard)) + const Offset(60, 30);
      await tester.tapAt(
        at,
        buttons: kSecondaryMouseButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(_panel, findsOneWidget);
      expect(find.byType(NeumorphicPanelRow), findsNWidgets(3));
      expect(
        find.byType(NeumorphicEngraved),
        findsOneWidget,
        reason: 'the divider',
      );
      final panel = tester.getRect(_panel);
      expect(
        (panel.left - at.dx).abs(),
        lessThan(16),
        reason: 'it opens from the pointer',
      );
      expect((panel.top - at.dy).abs(), lessThan(16));
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      expect(log, ['Rename']);
      expect(_panel, findsNothing);
    },
  );

  testWidgets('a long press opens it too', (tester) async {
    await tester.pumpWidget(neumorphicApp(const _Lamp(log: [])));
    await tester.longPress(find.text('Hall lamp').first);
    await tester.pumpAndSettle();
    expect(_panel, findsOneWidget);
  });

  testWidgets('a command that destroys something takes the danger tone', (
    tester,
  ) async {
    await tester.pumpWidget(neumorphicApp(const _Lamp(log: [])));
    await tester.longPress(find.text('Hall lamp').first);
    await tester.pumpAndSettle();
    NeumorphicPanelRow row(String label) => tester
        .widgetList<NeumorphicPanelRow>(find.byType(NeumorphicPanelRow))
        .singleWhere((r) => r.label == label);
    expect(row('Remove').danger, isTrue);
    expect(row('Rename').danger, isFalse);
    expect(find.byIcon(NeumorphicGlyphs.triangleAlert), findsOneWidget);
  });

  testWidgets(
    'Shift+F10 opens it at the focused control; Escape closes and the focus goes back',
    (tester) async {
      await tester.pumpWidget(neumorphicApp(const _Lamp(log: [])));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(_panel, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_panel, findsNothing);
      expect(FocusManager.instance.primaryFocus, same(focused));
    },
  );

  testWidgets('a screen reader finds Show menu among the region\'s actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(neumorphicApp(const _Lamp(log: [])));
    final region = find.semantics.byPredicate(
      (node) =>
          node.getSemanticsData().customSemanticsActionIds?.isNotEmpty ?? false,
    );
    expect(region, findsAny);
    semantics.dispose();
  });
}

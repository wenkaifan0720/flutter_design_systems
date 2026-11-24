// A control's tooltip shows nothing over the menu or the popover that
// control opened, as Material's PopupMenuButton's tooltip goes as its menu
// opens. A press by a screen reader (or the web's semantics, which a mouse
// click there becomes) brings no pointer down to stop the tip a resting
// pointer had asked for.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  Widget anchor(RawOverlayAnchor a) => TermTooltip(
    message: 'Task actions',
    child: TermIconButton(
      glyph: '⋯',
      semanticLabel: 'Task actions',
      onPressed: a.toggle,
    ),
  );

  for (final (kind, surface) in [
    (
      'menu',
      TermMenu(
        semanticLabel: 'Task actions',
        anchorBuilder: (context, a) => anchor(a),
        items: [
          TermMenuItem(label: 'Mark done', onPressed: () {}),
          TermMenuItem(label: 'Delete', onPressed: () {}),
        ],
      ),
    ),
    (
      'popover',
      TermPopover(
        title: 'Mark done',
        anchorBuilder: (context, a) => anchor(a),
        builder: (context) => const Text('Due Friday'),
      ),
    ),
  ]) {
    testWidgets(
      'at a phone\'s foot the tip shows nothing over the open $kind',
      (tester) async {
        final semantics = tester.ensureSemantics();
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, app) =>
                TermTheme(data: TermThemeData.dark(), child: app!),
            home: Align(alignment: const Alignment(0.8, 0.9), child: surface),
          ),
        );
        await tester.pumpAndSettle();
        final button = find.byType(TermIconButton);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(button));
        await tester.pump(const Duration(milliseconds: 40));
        tester.semantics.tap(
          find.semantics
              .byPredicate(
                (n) =>
                    n.getSemanticsData().hasAction(SemanticsAction.tap) &&
                    (n.label == 'Task actions' || n.tooltip == 'Task actions'),
              )
              .first,
        );
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(seconds: 1));
        expect(
          find.text(kind == 'menu' ? 'Mark done' : 'Due Friday'),
          findsOneWidget,
          reason: 'the $kind is open',
        );
        expect(
          find.text('Task actions'),
          findsNothing,
          reason: 'the tip shows',
        );
        semantics.dispose();
      },
    );
  }
}

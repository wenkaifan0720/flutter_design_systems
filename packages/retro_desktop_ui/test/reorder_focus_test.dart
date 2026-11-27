// A reorderable row's ring follows the keyboard: it shows on Tab, also after a mouse that connected and moved over the
// list before any key (an iPad's trackpad, a mouse on Android), and goes when a mouse presses the row.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

const _rows = ['Fonts', 'Sounds', 'Scripts'];

Future<void> _host(WidgetTester tester) async {
  await tester.pumpWidget(
    retroDesktopApp(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 320,
            child: RetroDesktopReorderableListView<String>(
              items: _rows,
              labelOf: (s) => s,
              itemBuilder: (context, s) => Text(s),
              onReorder: (from, to) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool _ringShown(WidgetTester tester) => tester
    .widgetList<RetroDesktopHighlight>(
      find.descendant(
        of: find.byType(RetroDesktopReorderableListView<String>),
        matching: find.byType(RetroDesktopHighlight),
      ),
    )
    .any((h) => h.focused);

Future<void> _tabToRing(WidgetTester tester) async {
  for (var tab = 0; tab < 6 && !_ringShown(tester); tab++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  testWidgets('a row shows its ring on Tab', (tester) async {
    await _host(tester);
    expect(_ringShown(tester), isFalse);
    await _tabToRing(tester);
    expect(_ringShown(tester), isTrue);
  });

  testWidgets(
    'after a mouse moved over the list, Tab still shows a row\'s ring',
    (tester) async {
      await _host(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Sounds')));
      await tester.pumpAndSettle();
      await mouse.moveTo(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(_ringShown(tester), isFalse);
      await _tabToRing(tester);
      expect(_ringShown(tester), isTrue);
    },
  );

  testWidgets('a mouse press takes the ring away', (tester) async {
    await _host(tester);
    await _tabToRing(tester);
    expect(_ringShown(tester), isTrue);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('Scripts')));
    await mouse.down(tester.getCenter(find.text('Scripts')));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(_ringShown(tester), isFalse);
  });
}

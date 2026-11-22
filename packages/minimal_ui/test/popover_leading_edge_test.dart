// A menu opens on its control's leading edge: its left in a left-to-right
// page, its right in a right-to-left one, as a field's list starts where the
// field does. With almost no room left (a keyboard up on a short screen) it
// still opens, in what room there is.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Widget _host(TextDirection direction) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: Directionality(textDirection: direction, child: navigator!),
  ),
  home: MinimalScaffold(
    padding: EdgeInsets.zero,
    body: Center(
      child: MinimalMenu.button(
        LucideIcons.ellipsis,
        label: 'Task actions',
        items: [
          MinimalMenuItem('Rename', onPressed: () {}),
          MinimalMenuItem('Delete', destructive: true, onPressed: () {}),
        ],
      ),
    ),
  ),
);

/// Where the open menu's card stands.
Rect _card(WidgetTester tester) {
  final layout = tester.renderObject<RenderCustomSingleChildLayoutBox>(
    find.ancestor(
      of: find.text('Rename'),
      matching: find.byType(CustomSingleChildLayout),
    ),
  );
  final card = layout.child!;
  return card.localToGlobal(Offset.zero) & card.size;
}

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('a menu opens on its key\'s leading edge (${direction.name})', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1000, 700);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(direction));
      final key = tester.getRect(find.byType(MinimalMenu));
      await tester.tap(find.byType(MinimalMenu));
      await tester.pumpAndSettle();
      final card = _card(tester);
      if (direction == TextDirection.ltr) {
        expect(card.left, closeTo(key.left, 0.5));
      } else {
        expect(card.right, closeTo(key.right, 0.5));
      }
    });
  }

  testWidgets('with almost no room it still opens', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 200);
    tester.view.viewInsets = const FakeViewPadding(bottom: 150);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(TextDirection.ltr));
    await tester.tap(find.byType(MinimalMenu), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

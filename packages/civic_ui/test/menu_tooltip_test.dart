// A control's tooltip goes when the menu the control opens shows, and stays
// away while the menu is open, as a Material MenuAnchor's button's does: on
// a phone the tip stood painted over the menu's rows it opened.
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _tip = 'Task actions';

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, navigator) =>
          CivicTheme(data: CivicThemeData.light(), child: navigator!),
      home: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: CivicMenu<String>(
            semanticLabel: _tip,
            items: const [
              CivicMenuItem(value: 'complete', label: 'Complete'),
              CivicMenuItem(value: 'move', label: 'Move'),
              CivicMenuItem(value: 'delete', label: 'Delete'),
            ],
            onSelected: (_) {},
            builder: (context, anchor) => CivicTooltip(
              message: _tip,
              excludeFromSemantics: true,
              child: CivicIconButton(
                icon: LucideIcons.ellipsis,
                semanticLabel: _tip,
                onPressed: anchor.toggle,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a finger: the menu opens with no tip over it', (tester) async {
    await _pump(tester, const Size(390, 844));
    await tester.tap(find.byType(CivicIconButton));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text(_tip), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('a finger held: the tip a long press brought goes as the menu '
      'opens', (tester) async {
    await _pump(tester, const Size(390, 844));
    await tester.longPress(find.byType(CivicIconButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CivicIconButton));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text(_tip), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    testWidgets('a pointer at ${size.width.round()} that clicks as it '
        'arrives: no tip comes over the menu while the pointer rests', (
      tester,
    ) async {
      await _pump(tester, size);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      final at = tester.getCenter(find.byType(CivicIconButton));
      await mouse.moveTo(at);
      await mouse.down(at);
      await mouse.up();
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text(_tip), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('a pointer at ${size.width.round()} resting while a screen '
        "reader's tap opens the menu (the web's click on its node): no tip "
        'comes over the menu', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, size);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(CivicIconButton)));
      tester.semantics.tap(
        find.semantics.byPredicate(
          (node) =>
              node.label == _tip &&
              node.getSemanticsData().hasAction(SemanticsAction.tap),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text(_tip), findsNothing);
      semantics.dispose();
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('a pointer at ${size.width.round()}: the tip it brought goes '
        'as the menu opens and stays away while it is open', (tester) async {
      await _pump(tester, size);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(CivicIconButton)));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text(_tip), findsOneWidget, reason: 'the tip shows on hover');
      await mouse.down(tester.getCenter(find.byType(CivicIconButton)));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);
      // The pointer rests on the control while the menu is open.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text(_tip), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  }
}

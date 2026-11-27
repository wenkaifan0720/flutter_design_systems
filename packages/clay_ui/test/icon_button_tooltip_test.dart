// An icon button's tooltip shows: over a hover or a long press its words
// stand in a tip, as Material's IconButton(tooltip:) shows them, a screen
// reader hears them once, and a test finds the button by them. They were
// only spoken.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  testWidgets('an icon button shows its tooltip and is found by it', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            ClayTheme(data: ClayThemeData.clay(Brightness.light), child: app!),
        home: Center(
          child: ClayIconButton.plain(
            onPressed: () {},
            icon: const Icon(IconData(0xe001)),
            tooltip: 'Delete Middlemarch',
          ),
        ),
      ),
    );
    expect(find.byTooltip('Delete Middlemarch'), findsOneWidget);
    expect(find.text('Delete Middlemarch'), findsNothing);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(ClayIconButton)));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Delete Middlemarch'), findsOneWidget);
    final data = tester
        .getSemantics(
          find.descendant(
            of: find.byType(ClayIconButton),
            matching: find.byType(RawButton),
          ),
        )
        .getSemanticsData();
    expect(
      [data.label, data.tooltip].where((s) => s.isNotEmpty).join(' / '),
      'Delete Middlemarch',
    );
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    handle.dispose();
  });
}

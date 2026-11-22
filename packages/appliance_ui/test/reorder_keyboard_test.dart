// A reorderable list moves the focused row with the keyboard: Alt and Down
// on a row's grip moves it one place down.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  double scale = 2,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 620);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, navigator) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: ApplianceTheme(
            data: ApplianceThemeData.light(),
            child: navigator!,
          ),
        ),
      ),
      home: Center(child: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(applianceLoadFonts);
  testWidgets('the reorder grip moves the focused row with Alt and Down', (
    tester,
  ) async {
    final items = ['Park', 'Market'];
    await _show(
      tester,
      StatefulBuilder(
        builder: (context, update) => ApplianceReorderableList<String>(
          items: List.of(items),
          labelOf: (item) => item,
          title: (item) => item,
          shrinkWrap: true,
          onReorder: (from, to) =>
              update(() => items.insert(to, items.removeAt(from))),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(items, ['Market', 'Park']);
  });
}

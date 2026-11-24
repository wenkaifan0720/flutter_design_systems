// A date picker's plate opened above its key stands over the field's label, not on it; opened below, it hangs from
// the key.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(WidgetTester tester, {required double top}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: ApplianceHost(
        brightness: Brightness.light,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, top, 16, 0),
          child: Align(
            alignment: Alignment.topCenter,
            child: ApplianceDatePicker(
              labelText: 'Due date',
              helperText: 'When it is needed',
              value: DateTime(2026, 11, 20),
              firstDate: DateTime(2020),
              lastDate: DateTime(2040),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Nov 20, 2026'));
  await tester.pumpAndSettle();
}

Rect _plate(WidgetTester tester) =>
    tester.getRect(find.byType(ApplianceMenuPlate));

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets('opened above, the plate stands clear of the label', (
    tester,
  ) async {
    await _open(tester, top: 700);
    final label = tester.getRect(find.text('Due date'));
    expect(_plate(tester).bottom, lessThanOrEqualTo(label.top));
  });

  testWidgets('opened below, the plate hangs from the key', (tester) async {
    await _open(tester, top: 24);
    final key = tester.getRect(find.text('Nov 20, 2026'));
    final label = tester.getRect(find.text('Due date'));
    expect(_plate(tester).top, greaterThan(key.bottom));
    expect(label.bottom, lessThan(key.top));
  });
}

// On the 12-hour face the half day's two keys stand the same width, AM as
// wide as PM, in either direction.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  setUpAll(keycapLoadFonts);

  for (final dir in TextDirection.values) {
    testWidgets('the AM and PM keys stand the same width (${dir.name})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: KeycapHost(brightness: Brightness.light, child: app!),
          ),
          home: Directionality(
            textDirection: dir,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: SizedBox(
                  width: 320,
                  child: KeycapTimePicker(
                    value: const RawTimeOfDay(hour: 9, minute: 5),
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(KeycapTimePicker));
      await tester.pumpAndSettle();
      Rect key(String label) => tester.getRect(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(KeycapRowKey),
        ),
      );
      final am = key('AM'), pm = key('PM');
      expect(am.width, moreOrLessEquals(pm.width, epsilon: 0.5));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    });
  }
}

// A key out of use has nothing left to press: it sits level with its panel,
// matte (no light down its face) and no brighter than a key in use (a brighter
// flat face reads as an outlined key, lit), where an enabled key stands raised.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

Future<void> _show(WidgetTester tester, Widget part, Brightness b) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(780, 600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => ApplianceHost(brightness: b, child: app!),
      home: Scaffold(body: Center(child: part)),
    ),
  );
  await tester.pumpAndSettle();
}

List<ApplianceFace> _faces(WidgetTester tester, Type part) => [
  for (final s in tester.widgetList<AnimatedApplianceSurface>(
    find.descendant(
      of: find.byWidgetPredicate((w) => w.runtimeType == part),
      matching: find.byType(AnimatedApplianceSurface),
    ),
  ))
    s.face,
];

Matcher get _level => predicate<ApplianceFace>(
  (f) => f.lift == 0 && f.top == f.bottom,
  'level and matte',
);

Matcher get _raised => predicate<ApplianceFace>((f) => f.lift > 0, 'raised');

void main() {
  setUpAll(applianceLoadFonts);

  for (final b in Brightness.values) {
    testWidgets('keys out of use sit level ($b)', (tester) async {
      await _show(
        tester,
        const ApplianceButton('Start a timer', onPressed: null),
        b,
      );
      expect(_faces(tester, ApplianceButton).first, _level);

      await _show(
        tester,
        const ApplianceButton.filled('Save changes', onPressed: null),
        b,
      );
      expect(_faces(tester, ApplianceButton).first, _level);

      await _show(
        tester,
        const ApplianceIconButton(
          icon: Icon(LucideIcons.play),
          semanticLabel: 'Start',
          onPressed: null,
        ),
        b,
      );
      expect(_faces(tester, ApplianceIconButton).first, _level);
    });

    testWidgets('a stepper key at its bound sits level ($b)', (tester) async {
      await _show(
        tester,
        ApplianceStepper(value: 0, max: 9, onChanged: (_) {}),
        b,
      );
      final keys = _faces(tester, ApplianceStepper);
      // The minus key at the least, the plus key still pressable.
      expect(keys.first, _level);
      expect(keys.last, _raised);
    });

    testWidgets('a key out of use stands no brighter than one in use ($b)', (
      tester,
    ) async {
      await _show(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ApplianceButton('Stop', onPressed: () {}),
            const ApplianceButton('Start a timer', onPressed: null),
          ],
        ),
        b,
      );
      final [live, off] = _faces(tester, ApplianceButton);
      double tone(ApplianceFace f) =>
          Color.lerp(f.top, f.bottom, .5)!.computeLuminance();
      expect(tone(off), lessThanOrEqualTo(tone(live)));
    });

    testWidgets('an enabled key stands raised ($b)', (tester) async {
      await _show(tester, ApplianceButton('Stop', onPressed: () {}), b);
      expect(_faces(tester, ApplianceButton).first, _raised);
    });
  }
}

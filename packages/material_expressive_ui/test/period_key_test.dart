// A time picker's period keys keep their words 4dp clear of each side of
// the key at every text size. At 200% text on a 390 phone the checked "AM"
// stood 2.9px from its key's left side (DesignFaceInsetCheck); the words
// now scale down to keep 4dp at either side.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:ui_core_test/ui_core_test.dart' show DesignFaceInsetCheck;

import 'gallery_support.dart' show loadExpressiveFonts;

const _picker = ValueKey<String>('picker');

void main() {
  setUpAll(loadExpressiveFonts);

  for (final scale in [1.0, 2.0]) {
    for (final (name, picker)
        in <(String, Widget Function(ExpressiveTimePickerController))>[
          ('dial', (time) => ExpressiveTimePicker(controller: time)),
          ('input', (time) => ExpressiveTimeInput(controller: time)),
        ]) {
      testWidgets(
        'the $name picker at ${(scale * 100).round()}% text, 390: the period '
        "keys' words keep 4dp from their sides",
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final time = ExpressiveTimePickerController(hour: 9, minute: 30);
          addTearDown(time.dispose);
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, app) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: ExpressiveHost(
                  theme: ExpressiveThemeData.baseline(),
                  brightness: Brightness.light,
                  child: app!,
                ),
              ),
              home: Center(
                child: KeyedSubtree(key: _picker, child: picker(time)),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('AM'), findsOneWidget);
          final report =
              await const DesignFaceInsetCheck(look: 'Material Expressive')
                  .check(
                    tester.element(find.byKey(_picker)),
                    runAsync: tester.runAsync,
                  );
          report.verify();
        },
      );
    }
  }
}

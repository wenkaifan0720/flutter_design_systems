// NeumorphicRadioGroup is Flutter's RadioGroup over RawRadio, and keeps its keyboard contract in both text directions:
// one Tab stop on the chosen option (or the first enabled one), arrows that choose as they move, wrap at the ends and skip
// an option out of use, Left advancing in right-to-left text, and a second Tab leaving the group, a disabled option
// chosen included.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final direction in TextDirection.values) {
    // The third chosen, nothing chosen, the first chosen, and the disabled B chosen.
    for (final initial in <String?>['C', null, 'A', 'B']) {
      testWidgets('radio group ${direction.name}, chosen $initial', (
        tester,
      ) async {
        final before = FocusNode();
        addTearDown(before.dispose);
        String? chosen = initial;
        final controls = StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(focusNode: before, child: const Text('Before')),
              SizedBox(
                width: 310,
                key: const ValueKey('radios'),
                child: NeumorphicRadioGroup<String>(
                  semanticLabel: 'Plan',
                  options: const [
                    NeumorphicRadio('A', 'A'),
                    NeumorphicRadio('B', 'B', enabled: false),
                    NeumorphicRadio('C', 'C'),
                    NeumorphicRadio('D', 'D'),
                  ],
                  value: chosen,
                  onChanged: (next) => setState(() => chosen = next),
                ),
              ),
              const Focus(child: Text('After')),
            ],
          ),
        );
        await tester.pumpWidget(neumorphicApp(controls, direction: direction));
        await tester.pumpAndSettle();
        (await const DesignRadioGroupCheck(look: 'Neumorphism').check(
          tester.element(find.byKey(const ValueKey('radios'))),
          before: before,
          sendKeyEvent: tester.sendKeyEvent,
          pump: tester.pump,
        )).verify();
      });
    }
  }
}

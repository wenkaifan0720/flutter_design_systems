// RetroDesktopRadioGroup keeps ui_core's keyboard contract for a radio group, in both appearances and both text
// directions: one Tab stop on the chosen option (or the first enabled one), arrows that choose as they move, wrap at
// the ends and skip an option out of use, Left advancing in right-to-left text, and a second Tab leaving the group.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'support.dart';

void main() {
  setUpAll(loadRetroDesktopFonts);
  for (final appearance in RetroDesktopAppearance.values) {
    for (final direction in TextDirection.values) {
      // C chosen, nothing chosen, and the disabled B chosen.
      for (final initial in <String?>['C', null, 'B']) {
        testWidgets(
          'radio group ${appearance.name} ${direction.name}, chosen $initial',
          (tester) async {
            final before = FocusNode();
            addTearDown(before.dispose);
            String? chosen = initial;
            final controls = StatefulBuilder(
              builder: (context, setState) => RetroDesktopTheme(
                data: RetroDesktopTheme.of(context)
                    .copyWith(appearance: appearance),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Focus(focusNode: before, child: const Text('Before')),
                    SizedBox(
                      width: 310,
                      key: const ValueKey('radios'),
                      child: RetroDesktopRadioGroup<String>(
                        label: 'Plan',
                        options: const [
                          RetroDesktopRadio('A', 'A'),
                          RetroDesktopRadio('B', 'B', enabled: false),
                          RetroDesktopRadio('C', 'C'),
                          RetroDesktopRadio('D', 'D'),
                        ],
                        value: chosen,
                        onChanged: (next) => setState(() => chosen = next),
                      ),
                    ),
                    const Focus(child: Text('After')),
                  ],
                ),
              ),
            );
            await tester.pumpWidget(
              retroDesktopApp(controls, direction: direction),
            );
            await tester.pumpAndSettle();
            (await DesignRadioGroupCheck(
                  look: 'Retro Desktop ${appearance.name}',
                ).check(
                  tester.element(find.byKey(const ValueKey('radios'))),
                  before: before,
                  sendKeyEvent: tester.sendKeyEvent,
                  pump: tester.pump,
                ))
                .verify();
          },
        );
      }
    }
  }
}

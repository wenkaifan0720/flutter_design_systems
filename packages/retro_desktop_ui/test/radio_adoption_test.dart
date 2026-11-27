// RetroDesktopRadioGroup is Flutter's RadioGroup over RawRadio, and keeps its keyboard contract in both appearances
// and both text directions: one Tab stop on the chosen option (or the first enabled one), arrows that choose as they
// move, wrap at the ends and skip an option out of use, Left advancing in right-to-left text, and a second Tab leaving
// the group, a disabled option chosen included. A toggle button reads as a button that is selected.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'support.dart';

void main() {
  setUpAll(loadRetroDesktopFonts);
  for (final appearance in RetroDesktopAppearance.values) {
    for (final direction in TextDirection.values) {
      // The third chosen, nothing chosen, the first chosen, and the disabled B chosen.
      for (final initial in <String?>['C', null, 'A', 'B']) {
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
                        labelText: 'Plan',
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

  testWidgets('a selected icon button reads as a button that is selected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        retroDesktopApp(
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RetroDesktopIconButton(
                  RetroDesktopGlyphs.add,
                  semanticLabel: 'Pin',
                  selected: true,
                  onPressed: () {},
                ),
                RetroDesktopIconButton(
                  RetroDesktopGlyphs.add,
                  semanticLabel: 'Mute',
                  selected: false,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Pin')),
        isSemantics(
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasToggledState: false,
          hasCheckedState: false,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Mute')),
        isSemantics(isButton: true, isSelected: false, hasToggledState: false),
      );
    } finally {
      semantics.dispose();
    }
  });
}

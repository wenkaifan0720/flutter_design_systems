import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'styled_controls_test.dart' show mount;
import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);
  {
    for (final (densityName, density) in [
      ('standard', NeumorphicDensity.standard),
      ('comfortable', NeumorphicDensity.comfortable),
      ('compact', NeumorphicDensity.compact),
    ]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        for (final kind in ['field', 'search', 'password']) {
          testWidgets(
            '$kind has an editable target at $densityName and $scale',
            (tester) async {
              final focus = FocusNode();
              addTearDown(focus.dispose);
              await mount(
                tester,
                kind == 'search'
                    ? NeumorphicSearchField(
                        label: 'Find',
                        hint: 'Search',
                        focusNode: focus,
                      )
                    : NeumorphicTextField(
                        label: 'Name',
                        focusNode: focus,
                        obscureText: kind == 'password',
                      ),
                NeumorphicThemeData.porcelain().copyWith(density: density),
                width: 390,
                scale: scale,
              );
              final input = find.byType(EditableText);
              final semantics = tester.getSemantics(input);
              final target = switch (defaultTargetPlatform) {
                TargetPlatform.android ||
                TargetPlatform.iOS ||
                TargetPlatform.fuchsia => 48.0,
                _ => 44.0,
              };
              expect(semantics.rect.height, greaterThanOrEqualTo(target - .01));
              expect(
                semantics.getSemanticsData().label,
                kind == 'search' ? 'Find\nSearch' : 'Name',
              );
              // The editable is one line; a press in its reach off the line (the field's node, round the groove the
              // density draws) still puts the caret in it.
              final band = tester.getRect(
                find
                    .ancestor(
                      of: input,
                      matching: find.byWidgetPredicate(
                        (w) => w is Semantics && w.container,
                      ),
                    )
                    .first,
              );
              expect(band.height, greaterThanOrEqualTo(target - .01));
              await tester.tapAt(Offset(band.center.dx, band.top + 2));
              await tester.pump();
              expect(focus.hasFocus, isTrue);
              await tester.enterText(input, 'Entered');
              expect(
                tester.widget<EditableText>(input).controller.text,
                'Entered',
              );
            },
            variant: TargetPlatformVariant.all(),
          );
        }
      }
    }
  }
  testWidgets('a level row names its switch target', (tester) async {
    await mount(
      tester,
      NeumorphicLevelRow(
        icon: NeumorphicGlyphs.lamp,
        title: 'Desk lamp',
        state: 'On',
        value: true,
        onChanged: (_) {},
      ),
      NeumorphicThemeData.porcelain(),
    );
    final guideline = await labeledTapTargetGuideline.evaluate(tester);
    expect(guideline.passed, isTrue, reason: guideline.reason);
    expect(
      tester
          .getSemantics(
            find.descendant(
              of: find.byType(NeumorphicSwitch),
              matching: find.byWidgetPredicate(
                (w) => w is Semantics && w.properties.toggled != null,
              ),
            ),
          )
          .getSemanticsData()
          .label,
      'Desk lamp',
    );
  }, variant: TargetPlatformVariant.all());
}

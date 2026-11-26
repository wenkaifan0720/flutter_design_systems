import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/internal/reach.dart'
    show NeumorphicReach;

import 'styled_controls_test.dart' show mount;
import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);
  {
    // Every time: the field at standard density and 1.0, the search at comfortable and 1.3, the password at compact
    // and 2.0, on every platform; the sweep runs the rest.
    for (final (d, (densityName, density)) in [
      ('standard', NeumorphicDensity.standard),
      ('comfortable', NeumorphicDensity.comfortable),
      ('compact', NeumorphicDensity.compact),
    ].indexed) {
      for (final (s, scale) in [1.0, 1.3, 2.0].indexed) {
        for (final (k, kind) in ['field', 'search', 'password'].indexed) {
          testWidgets(
            '$kind has an editable target at $densityName and $scale',
            (tester) async {
              final focus = FocusNode();
              addTearDown(focus.dispose);
              await mount(
                tester,
                kind == 'search'
                    ? NeumorphicSearchField(
                        labelText: 'Find',
                        hintText: 'Search',
                        focusNode: focus,
                      )
                    : NeumorphicTextField(
                        labelText: 'Name',
                        focusNode: focus,
                        obscureText: kind == 'password',
                      ),
                NeumorphicThemeData.porcelain().copyWith(density: density),
                width: 390,
                scale: scale,
              );
              final input = find.byType(EditableText);
              final semantics = tester.getSemantics(input);
              // ui_core's touch floor, 40 on every platform.
              expect(semantics.rect.height, greaterThanOrEqualTo(40 - .01));
              expect(
                semantics.getSemanticsData().label,
                kind == 'search' ? 'Find\nSearch' : 'Name',
              );
              // The editable is one line; a press in its reach off the line (round the groove the density draws) still
              // puts the caret in it.
              final band = tester.getRect(
                find
                    .ancestor(of: input, matching: find.byType(NeumorphicReach))
                    .first,
              );
              expect(band.height, greaterThanOrEqualTo(40 - .01));
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
            tags: d == k && s == k ? null : const ['sweep'],
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

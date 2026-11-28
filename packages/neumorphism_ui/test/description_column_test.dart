// On a reading page (760 wide) at a desk, a description list takes the page's column, as a list section does: its
// details end where the section's rows and the page's words end. It had kept to 480 at the start, its values ending
// about 110 px short of the edit key above them. On a phone it takes the width it is given.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final width in [390.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'the list stands on the page column at ${width.round()} (${direction.name})',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            neumorphicApp(
              const NeumorphicScaffold(
                maxWidth: 760,
                topBar: NeumorphicAppBar(title: 'Middlemarch'),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NeumorphicListSection(
                      children: [NeumorphicListTile(title: 'George Eliot')],
                    ),
                    NeumorphicDescriptionList([
                      NeumorphicDescription('Author', 'George Eliot'),
                      NeumorphicDescription('Started', 'Not yet'),
                    ]),
                  ],
                ),
              ),
              width: width,
              direction: direction,
            ),
          );
          await tester.pumpAndSettle();
          final section = tester.getRect(find.byType(NeumorphicListSection));
          // The rows' column, inside the list's own box (which always spans its slot).
          final list = tester.getRect(
            find
                .descendant(
                  of: find.byType(NeumorphicDescriptionList),
                  matching: find.byType(Column),
                )
                .first,
          );
          expect(
            list.left,
            moreOrLessEquals(section.left, epsilon: 0.5),
            reason: '$list by $section',
          );
          expect(
            list.right,
            moreOrLessEquals(section.right, epsilon: 0.5),
            reason: '$list by $section',
          );
        },
      );
    }
  }
}

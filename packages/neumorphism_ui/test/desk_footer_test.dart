// At a desk, a page's footer act stands on the page's column: on a reading page (760) its end is the end of the
// page's words, so a form that takes the column has its Save under its fields' end. On a phone it takes the width.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final direction in TextDirection.values) {
    testWidgets(
      'the footer act ends where the form ends at 1440 (${direction.name})',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          neumorphicApp(
            NeumorphicScaffold(
              maxWidth: 760,
              topBar: const NeumorphicAppBar(title: 'New book'),
              body: NeumorphicTextFormField(labelText: 'Title'),
              footer: NeumorphicButton.filled(
                'Save',
                wide: true,
                onPressed: () {},
              ),
            ),
            width: 1440,
            direction: direction,
          ),
        );
        await tester.pumpAndSettle();
        final field = tester.getRect(find.byType(NeumorphicTextField));
        final key = tester.getRect(find.byType(NeumorphicButton));
        final rtl = direction == TextDirection.rtl;
        expect(
          rtl ? key.left : key.right,
          moreOrLessEquals(rtl ? field.left : field.right, epsilon: 0.5),
          reason: 'the key ($key) is off the form ($field)',
        );
      },
    );
  }
}

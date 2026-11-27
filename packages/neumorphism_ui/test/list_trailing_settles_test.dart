// A row's trailing tag settles: deciding whether it stands beside the words or under them lays it out at its
// share and at the row's width, and the tag draws its shape from the width it is given. Laid out at the share only
// when it fits there on one line, it never flips between shapes, so a row whose tag stands under its words comes to
// rest.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final width in [320.0, 390.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'rows with tags come to rest at ${width.toInt()} ${direction.name}',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            neumorphicApp(
              Directionality(
                textDirection: direction,
                child: NeumorphicListSection(
                  children: [
                    for (final (title, author, status) in const [
                      ('Stoner', 'John Williams', 'Finished'),
                      ('The Remains of the Day', 'Kazuo Ishiguro', 'Reading'),
                      ('Middlemarch', 'George Eliot', 'Want to read'),
                      ('Pachinko', 'Min Jin Lee', 'Reading'),
                    ])
                      NeumorphicListTile(
                        leading: NeumorphicMonogram(
                          title.substring(0, 2).toUpperCase(),
                        ),
                        title: title,
                        subtitle: author,
                        trailing: NeumorphicTag(status),
                        onPressed: () {},
                      ),
                  ],
                ),
              ),
            ),
          );
          // pumpAndSettle throws when a frame is still scheduled after ten seconds.
          await tester.pumpAndSettle();
          expect(tester.binding.hasScheduledFrame, isFalse);
          expect(find.text('Want to read'), findsOneWidget);
        },
      );
    }
  }
}

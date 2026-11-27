// A row's value stands on its title's line: the value centred on its
// capitals as the title is (it sat 1 px under the title), left to right and
// right to left, at the reader's text sizes.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

// The middle of [text]'s line on screen (title and value share a size).
double _middle(WidgetTester tester, String text) =>
    tester.getRect(find.text(text)).center.dy;

void main() {
  setUpAll(glossLoadFonts);

  for (final direction in TextDirection.values) {
    for (final scale in [1.0, 1.3]) {
      testWidgets(
        "a row's value stands on its title's line (${direction.name}, x$scale)",
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, app) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: GlossHost(
                  child: Directionality(textDirection: direction, child: app!),
                ),
              ),
              home: const Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: GlossWell(
                    children: [
                      GlossListTile(
                        title: 'Name',
                        trailingText: 'Noa Ferreira',
                      ),
                      GlossListTile(
                        title: 'Email',
                        trailingText: 'noa@example.com',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          for (final (title, value) in [
            ('Name', 'Noa Ferreira'),
            ('Email', 'noa@example.com'),
          ]) {
            expect(
              _middle(tester, value),
              moreOrLessEquals(_middle(tester, title), epsilon: 0.5),
              reason: title,
            );
          }
        },
      );
    }
  }
}

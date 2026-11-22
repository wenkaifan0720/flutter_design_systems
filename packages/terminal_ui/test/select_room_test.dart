// A select low on a phone opens its list on the side with the room: above
// the field when the room under it is less than the list wants, rather than
// a sliver of list scrolling under the field.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

Widget _app(Widget page) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, app) => TermTheme(data: TermThemeData.dark(), child: app!),
  home: page,
);

void main() {
  setUpAll(loadFaces);
  for (final above in [640.0, 680.0, 720.0]) {
    testWidgets(
      'a select ${above.round()} down a phone opens its list above the field',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final select = TermSelect<int>(
          labelText: 'region',
          value: null,
          items: [
            for (var i = 0; i < 20; i++)
              TermSelectItem(value: i, label: 'region $i'),
          ],
          onChanged: (_) {},
        );
        await tester.pumpWidget(
          _app(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: above),
                  select,
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final field = tester.getRect(find.byWidget(select));
        await tester.tapAt(field.bottomCenter - const Offset(0, 16));
        await tester.pumpAndSettle();
        final list = tester.getRect(
          find
              .ancestor(
                of: find.text('region 0'),
                matching: find.byType(TermPane),
              )
              .first,
        );
        expect(list.top, greaterThanOrEqualTo(0));
        expect(
          list.bottom,
          lessThanOrEqualTo(field.top + 1),
          reason: 'the list stayed under the field: $list, field $field',
        );
      },
    );
  }
}

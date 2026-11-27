// A switch in a column that stretches its children (a form's column) keeps
// its track's own size at the column's start; it stood the column's width.
// With showLabel its words stand after the track.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  for (final rtl in [false, true]) {
    testWidgets('a switch in a stretched column keeps its size '
        '(${rtl ? 'rtl' : 'ltr'})', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: MinimalHost(brightness: Brightness.light, child: app!),
          ),
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MinimalSwitch(
                    key: const ValueKey('bare'),
                    label: 'Notify',
                    value: false,
                    onChanged: (_) {},
                  ),
                  MinimalSwitch(
                    label: 'Favourite',
                    showLabel: true,
                    value: false,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final column = tester.getRect(find.byType(Column).first);
      final bare = tester.getRect(
        find
            .descendant(
              of: find.byKey(const ValueKey('bare')),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(bare.width, lessThan(80));
      if (rtl) {
        expect((bare.right - column.right).abs(), lessThan(1));
      } else {
        expect((bare.left - column.left).abs(), lessThan(1));
      }
      expect(find.text('Favourite'), findsOneWidget);
    });
  }
}

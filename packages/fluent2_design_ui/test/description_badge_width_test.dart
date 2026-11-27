// A description's value that is a part of the caller's (a status badge)
// keeps its own width at the start of the value's column; it stretched across
// the whole row.
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  for (final rtl in [false, true]) {
    testWidgets('a badge in a description keeps its width '
        '(${rtl ? 'rtl' : 'ltr'})', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: Fluent2Host(brightness: Brightness.light, child: app!),
          ),
          home: const Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 800,
              child: Fluent2DescriptionList(
                properties: [
                  Fluent2DescriptionItem('Author', 'George Eliot'),
                  Fluent2DescriptionItem(
                    'Status',
                    'Want to read',
                    child: Fluent2LabelBadge(label: 'Want to read'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final badge = tester.getRect(find.byType(Fluent2LabelBadge));
      final author = tester.getRect(find.text('George Eliot'));
      expect(badge.width, lessThan(200));
      // At the start of the value's column, where the author's name starts.
      if (rtl) {
        expect((badge.right - author.right).abs(), lessThan(1));
      } else {
        expect((badge.left - author.left).abs(), lessThan(1));
      }
    });
  }
}

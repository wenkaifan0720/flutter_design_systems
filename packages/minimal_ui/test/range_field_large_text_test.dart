import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/directional_page.dart';

void main() {
  testWidgets('a range field grows with its words, as every field does', (
    tester,
  ) async {
    Future<double> fieldAt(double scale) async {
      await tester.pumpWidget(
        directionalPage(
          MinimalDateRangePicker(
            labelText: 'Stay',
            hintText: 'Choose',
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
            onChanged: (_) {},
          ),
          scale: scale,
        ),
      );
      await tester.pumpAndSettle();
      return tester
          .getSize(
            find
                .ancestor(
                  of: find.text('Choose'),
                  matching: find.byType(Container),
                )
                .first,
          )
          .height;
    }

    final at1 = await fieldAt(1);
    final at13 = await fieldAt(1.3);
    // The 16 px line grows to 20.8; the field grows by as much.
    expect(at13 - at1, moreOrLessEquals(16 * 0.3, epsilon: 0.01));
  });
}

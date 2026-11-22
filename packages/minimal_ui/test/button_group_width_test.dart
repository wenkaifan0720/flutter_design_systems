// An expanded button group stops at a control's measure on a laptop.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/scaled_page.dart';

void main() {
  testWidgets('an expanded button group stops at the control measure on a '
      'laptop and spans a phone', (tester) async {
    Widget group() => MinimalButtonGroup(
      expand: true,
      items: [
        MinimalButtonGroupItem(label: 'Day', onPressed: () {}),
        MinimalButtonGroupItem(label: 'Week', onPressed: () {}),
        MinimalButtonGroupItem(label: 'Month', onPressed: () {}),
      ],
    );
    // The bar: the frame the cells stand in.
    double bar() => tester
        .getSize(
          find
              .descendant(
                of: find.byType(MinimalButtonGroup),
                matching: find.byType(Container),
              )
              .first,
        )
        .width;
    setViewSize(tester, const Size(1440, 900));
    await tester.pumpWidget(scaledPage(group(), width: 1000));
    expect(bar(), MinimalLayout.controlMax);
    setViewSize(tester, const Size(390, 844));
    await tester.pumpWidget(scaledPage(group()));
    expect(bar(), 390);
  });
}

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/directional_page.dart';

void main() {
  testWidgets('a colour picker stops at the control measure from a tablet up', (
    tester,
  ) async {
    await tester.pumpWidget(
      directionalPage(
        MinimalColorPicker(value: const Color(0xFF2563EB), onChanged: (_) {}),
        width: 720,
      ),
    );
    await tester.pumpAndSettle();
    // The page's column is 720; the picker's own box (the cap's) is not.
    final held = find
        .descendant(
          of: find.byType(MinimalColorPicker),
          matching: find.byType(ConstrainedBox),
        )
        .first;
    expect(
      tester.getSize(held).width,
      lessThanOrEqualTo(MinimalLayout.controlMax),
    );
    expect(
      tester.getTopLeft(held).dx,
      tester.getTopLeft(find.byType(MinimalColorPicker)).dx,
    );
  });
}

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/directional_page.dart';

void main() {
  testWidgets('a scroll area keeps its content 16 px off the bar\'s edge', (
    tester,
  ) async {
    const content = Key('content');
    await tester.pumpWidget(
      directionalPage(
        const MinimalScrollArea(
          height: 80,
          alwaysShown: true,
          child: SizedBox(key: content, width: double.infinity, height: 400),
        ),
        width: 200,
      ),
    );
    await tester.pumpAndSettle();
    final area = tester.getRect(find.byType(MinimalScrollArea));
    expect(tester.getRect(find.byKey(content)).right, area.right - 16);
  });
}

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/directional_page.dart';

void main() {
  testWidgets('a tab strip\'s hairline runs the width it is given', (
    tester,
  ) async {
    await tester.pumpWidget(
      directionalPage(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MinimalTabBar(
              tabs: const ['Overview', 'Activity'],
              selectedIndex: 0,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MinimalTabBar)).width, 390);
  });
}

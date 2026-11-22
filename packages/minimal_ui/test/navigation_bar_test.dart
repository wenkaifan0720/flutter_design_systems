import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/centred_host.dart';

void main() {
  testWidgets('the current tab is announced as selected', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      centredHost(
        MinimalNavigationBar(
          items: const [
            MinimalNavItem(Icons.today, 'Today'),
            MinimalNavItem(Icons.list, 'Habits'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Today')),
      matchesSemantics(
        label: 'Today',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Habits')),
      matchesSemantics(
        label: 'Habits',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });
}

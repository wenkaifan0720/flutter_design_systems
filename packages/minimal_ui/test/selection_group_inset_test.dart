import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/text_scale_host.dart';

void main() {
  testWidgets('a selection group\'s padding insets its rows\' words and '
      'checks while its rules span the group', (tester) async {
    await tester.pumpWidget(
      textScaleHost(
        SizedBox(
          width: 390,
          child: MinimalSelectionGroup(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            children: [
              MinimalChoiceRow(
                title: 'Every day',
                selected: true,
                onPressed: () {},
              ),
              MinimalChoiceRow(
                title: 'Weekdays',
                selected: false,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final group = tester.getRect(find.byType(MinimalSelectionGroup));
    expect(startOf(tester, 'Weekdays'), moreOrLessEquals(group.left + 18));
    final check = find.byWidgetPredicate(
      (w) => w is MinimalIcon && w.icon == LucideIcons.check,
    );
    expect(tester.getRect(check).right, moreOrLessEquals(group.right - 18));
    // Each row is the group's whole width, so its rule is too.
    for (final row in tester.widgetList<MinimalChoiceRow>(
      find.byType(MinimalChoiceRow),
    )) {
      expect(tester.getRect(find.byWidget(row)).width, group.width);
    }
  });
}

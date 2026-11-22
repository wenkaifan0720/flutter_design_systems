import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/scrolling_host.dart';

void main() {
  testWidgets('two months stacked in a narrow column still step forward', (
    tester,
  ) async {
    await tester.pumpWidget(
      scrollingHost(
        SizedBox(
          width: 340,
          child: MinimalCalendar(
            firstDate: DateTime(2026),
            lastDate: DateTime(2026, 12, 31),
            value: DateTime(2026, 8, 12),
            onChanged: (_) {},
            months: 2,
          ),
        ),
      ),
    );
    // Stacked, both chevrons stand on the first month's header.
    final next = find.byWidgetPredicate(
      (w) => w is MinimalIconButton && w.icon == LucideIcons.chevronRightDir,
    );
    expect(next, findsOneWidget);
    expect(tester.widget<MinimalIconButton>(next).onPressed, isNotNull);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.textContaining('August'), findsNothing);
  });
}
